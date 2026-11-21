#define _GNU_SOURCE
#include "shims.h"
#include "macho.h"
#include "objc_runtime.h"
#include "framebuffer.h"
#include "events.h"
#include "services.h"
#include "image.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <malloc.h>
#include <time.h>
#include <unistd.h>
#include <pthread.h>
#include <math.h>
#include <time.h>
#include <stdarg.h>
#include <limits.h>
#include <dlfcn.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <dirent.h>
#include <fcntl.h>
#include <signal.h>

/* ---------- guest file-system helpers ----------
 * Flag-free wrappers so guest dylibs never pass Darwin open(2) flags to the
 * host. All paths are NUL-terminated UTF-8 strings. */

int iosim_fs_exists(const char *path)
{
    return path && access(path, F_OK) == 0;
}

int iosim_fs_is_dir(const char *path)
{
    struct stat st;
    return path && stat(path, &st) == 0 && S_ISDIR(st.st_mode);
}

/* ---------- Darwin ABI stat/open ----------
 * Guests compiled for x86_64 Darwin pass a 144-byte struct stat whose field
 * order differs from glibc's, and open(2) flag bits differ as well. These
 * shims translate at the boundary so real macOS binaries can call them. */

struct darwin_timespec {
    long tv_sec;
    long tv_nsec;
};

struct darwin_stat {
    int32_t st_dev;
    uint16_t st_mode;
    uint16_t st_nlink;
    uint64_t st_ino;
    uint32_t st_uid;
    uint32_t st_gid;
    int32_t st_rdev;
    struct darwin_timespec st_atimespec;
    struct darwin_timespec st_mtimespec;
    struct darwin_timespec st_ctimespec;
    struct darwin_timespec st_birthtimespec;
    int64_t st_size;
    int64_t st_blocks;
    int32_t st_blksize;
    uint32_t st_flags;
    uint32_t st_gen;
    int32_t st_lspare;
    int64_t st_qspare[2];
};

_Static_assert(sizeof(struct darwin_stat) == 144, "Darwin stat layout");

static void darwin_fill_stat(struct darwin_stat *out, const struct stat *st)
{
    memset(out, 0, sizeof(*out));
    out->st_dev = (int32_t)st->st_dev;
    out->st_mode = (uint16_t)st->st_mode;
    out->st_nlink = (uint16_t)st->st_nlink;
    out->st_ino = (uint64_t)st->st_ino;
    out->st_uid = (uint32_t)st->st_uid;
    out->st_gid = (uint32_t)st->st_gid;
    out->st_rdev = (int32_t)st->st_rdev;
    out->st_atimespec.tv_sec = st->st_atim.tv_sec;
    out->st_atimespec.tv_nsec = st->st_atim.tv_nsec;
    out->st_mtimespec.tv_sec = st->st_mtim.tv_sec;
    out->st_mtimespec.tv_nsec = st->st_mtim.tv_nsec;
    out->st_ctimespec.tv_sec = st->st_ctim.tv_sec;
    out->st_ctimespec.tv_nsec = st->st_ctim.tv_nsec;
    out->st_birthtimespec = out->st_ctimespec;
    out->st_size = (int64_t)st->st_size;
    out->st_blocks = (int64_t)st->st_blocks;
    out->st_blksize = (int32_t)st->st_blksize;
}

static int shim_stat_ino64(const char *path, struct darwin_stat *out)
{
    struct stat st;
    if (!path || !out || stat(path, &st) != 0)
        return -1;
    darwin_fill_stat(out, &st);
    return 0;
}

static int shim_lstat_ino64(const char *path, struct darwin_stat *out)
{
    struct stat st;
    if (!path || !out || lstat(path, &st) != 0)
        return -1;
    darwin_fill_stat(out, &st);
    return 0;
}

static int shim_fstat_ino64(int fd, struct darwin_stat *out)
{
    struct stat st;
    if (!out || fstat(fd, &st) != 0)
        return -1;
    darwin_fill_stat(out, &st);
    return 0;
}

static int shim_fstatat_ino64(int fd, const char *path,
                              struct darwin_stat *out, int flags)
{
    struct stat st;
    if (!path || !out || fstatat(fd, path, &st, flags) != 0)
        return -1;
    darwin_fill_stat(out, &st);
    return 0;
}

static int darwin_to_host_open_flags(int flags)
{
    int host = flags & 3;
    if (flags & 0x4)       host |= O_NONBLOCK;
    if (flags & 0x8)       host |= O_APPEND;
    if (flags & 0x40)      host |= O_ASYNC;
    if (flags & 0x80)      host |= O_SYNC;
    if (flags & 0x100)     host |= O_NOFOLLOW;
    if (flags & 0x200)     host |= O_CREAT;
    if (flags & 0x400)     host |= O_TRUNC;
    if (flags & 0x800)     host |= O_EXCL;
    if (flags & 0x20000)   host |= O_NOCTTY;
    if (flags & 0x100000)  host |= O_DIRECTORY;
    if (flags & 0x1000000) host |= O_CLOEXEC;
    return host;
}

static int shim_open(const char *path, int flags, ...)
{
    int mode = 0;
    if (flags & 0x200)
    {
        va_list ap;
        va_start(ap, flags);
        mode = va_arg(ap, int);
        va_end(ap);
    }
    return open(path, darwin_to_host_open_flags(flags), mode);
}

static int shim_openat(int dirfd, const char *path, int flags, ...)
{
    int mode = 0;
    if (flags & 0x200)
    {
        va_list ap;
        va_start(ap, flags);
        mode = va_arg(ap, int);
        va_end(ap);
    }
    return openat(dirfd, path, darwin_to_host_open_flags(flags), mode);
}

long iosim_fs_size(const char *path)
{
    struct stat st;
    if (!path || stat(path, &st) != 0 || !S_ISREG(st.st_mode))
        return -1;
    return (long)st.st_size;
}

int iosim_fs_read(const char *path, unsigned char **out, unsigned long *out_len)
{
    if (!path || !out || !out_len)
        return -1;
    FILE *f = fopen(path, "rb");
    if (!f)
        return -1;
    if (fseek(f, 0, SEEK_END) != 0)
    {
        fclose(f);
        return -1;
    }
    long n = ftell(f);
    if (n < 0)
    {
        fclose(f);
        return -1;
    }
    rewind(f);
    unsigned char *buf = malloc((size_t)n + 1);
    if (!buf)
    {
        fclose(f);
        return -1;
    }
    size_t got = fread(buf, 1, (size_t)n, f);
    fclose(f);
    buf[got] = 0;
    *out = buf;
    *out_len = (unsigned long)got;
    return 0;
}

int iosim_fs_write(const char *path, const void *bytes, unsigned long len)
{
    if (!path || (!bytes && len))
        return -1;
    FILE *f = fopen(path, "wb");
    if (!f)
        return -1;
    size_t put = len ? fwrite(bytes, 1, len, f) : 0;
    int rc = fclose(f);
    return (put == len && rc == 0) ? 0 : -1;
}

int iosim_fs_remove(const char *path)
{
    return path ? remove(path) : -1;
}

int iosim_fs_rename(const char *from, const char *to)
{
    return (from && to) ? rename(from, to) : -1;
}

int iosim_fs_mkdir(const char *path, int intermediates)
{
    if (!path || !*path)
        return -1;
    if (!intermediates)
        return mkdir(path, 0755);
    char tmp[PATH_MAX];
    size_t n = strlen(path);
    if (n >= sizeof(tmp))
        return -1;
    memcpy(tmp, path, n + 1);
    for (char *p = tmp + 1; *p; p++)
    {
        if (*p != '/')
            continue;
        *p = 0;
        if (mkdir(tmp, 0755) != 0 && errno != EEXIST)
            return -1;
        *p = '/';
    }
    if (mkdir(tmp, 0755) != 0 && errno != EEXIST)
        return -1;
    return 0;
}

/* Newline-separated directory entries, with the dot entries filtered out. */
int iosim_fs_list(const char *path, char *out, unsigned long cap)
{
    if (!path || !out || !cap)
        return -1;
    DIR *dir = opendir(path);
    if (!dir)
        return -1;
    unsigned long used = 0;
    int count = 0;
    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL)
    {
        const char *name = entry->d_name;
        if (strcmp(name, ".") == 0 || strcmp(name, "..") == 0)
            continue;
        size_t len = strlen(name);
        if (used + len + 2 > cap)
            break;
        memcpy(out + used, name, len);
        used += len;
        out[used++] = '\n';
        count++;
    }
    out[used] = 0;
    closedir(dir);
    return count;
}

/* ---------- CommonCrypto (implemented in ccrypto.c) ---------- */

int iosim_CC_MD5_Init(void *ctx);
int iosim_CC_MD5_Update(void *ctx, const void *data, uint32_t len);
int iosim_CC_MD5_Final(unsigned char *digest, void *ctx);
int iosim_CC_SHA256_Init(void *ctx);
int iosim_CC_SHA256_Update(void *ctx, const void *data, uint32_t len);
int iosim_CC_SHA256_Final(unsigned char *digest, void *ctx);

/* ---------- launching apps from the system UI ---------- */

int iosim_spawn_app(const char *exe, const char *bundle, const char *home)
{
    if (!exe || !*exe)
        return -1;
    char self[PATH_MAX];
    ssize_t n = readlink("/proc/self/exe", self, sizeof(self) - 1);
    if (n <= 0)
        return -1;
    self[n] = 0;
    pid_t pid = fork();
    if (pid < 0)
        return -1;
    if (pid == 0)
    {
        /* The child is an app launch, not another SpringBoard. */
        unsetenv("IOSIM_SHELL");
        unsetenv("IOSIM_SHELL_APPS");
        if (bundle && *bundle)
        {
            char name[600];
            snprintf(name, sizeof(name), "UIKitApplication:%s[%d]", bundle,
                     (int)getpid());
            setenv("XPC_SERVICE_NAME", name, 1);
            setenv("IOSIM_BUNDLE_ID", bundle, 1);
        }
        if (home && *home)
        {
            char tmp[PATH_MAX + 16];
            setenv("HOME", home, 1);
            setenv("CFFIXED_USER_HOME", home, 1);
            snprintf(tmp, sizeof(tmp), "%s/tmp", home);
            setenv("TMPDIR", tmp, 1);
        }
        execl(self, self, exe, (char *)0);
        _exit(127);
    }
    return (int)pid;
}

/* Returns 1 when the app stopped itself (backgrounded/suspended), 0 when it
 * exited, -1 on error. */
int iosim_spawn_wait(int pid)
{
    int status = 0;
    if (pid <= 0)
        return -1;
    pid_t r;
    while ((r = waitpid(pid, &status, WUNTRACED)) < 0)
    {
        if (errno != EINTR)
            return -1;
    }
    if (WIFSTOPPED(status))
        return 1;
    return 0;
}

void iosim_suspend_self(void)
{
    raise(SIGSTOP);
}

int iosim_resume_app(int pid)
{
    if (pid <= 0)
        return -1;
    return kill(pid, SIGCONT);
}

/* Force-quit a suspended app the way SpringBoard does: continue it so the
 * pending SIGTERM is delivered, then reap it. */
int iosim_terminate_app(int pid)
{
    if (pid <= 0)
        return -1;
    kill(pid, SIGCONT);
    kill(pid, SIGTERM);
    int status = 0;
    pid_t r;
    while ((r = waitpid(pid, &status, 0)) < 0)
    {
        if (errno != EINTR)
            return -1;
    }
    return 0;
}

/* An app asks its SpringBoard parent to open the switcher when it suspends.
 * The handler only sets a flag; the guest supplies a plain C function. */
static void (*switcher_request_handler)(void);

static void switcher_signal_trampoline(int sig)
{
    (void)sig;
    if (switcher_request_handler)
        switcher_request_handler();
}

void iosim_on_switcher_request(void (*handler)(void))
{
    switcher_request_handler = handler;
    signal(SIGUSR1, switcher_signal_trampoline);
}

int iosim_request_switcher(void)
{
    return kill(getppid(), SIGUSR1);
}

/* An app that receives a lock event tells its SpringBoard parent to show the
 * lock screen once the process has stopped, just like the switcher request. */
static void (*lock_request_handler)(void);

static void lock_signal_trampoline(int sig)
{
    (void)sig;
    if (lock_request_handler)
        lock_request_handler();
}

void iosim_on_lock_request(void (*handler)(void))
{
    lock_request_handler = handler;
    signal(SIGUSR2, lock_signal_trampoline);
}

int iosim_request_lock(void)
{
    return kill(getppid(), SIGUSR2);
}

void  *objc_opt_class(void *obj);
void   objc_enumerationMutation(void *obj);
void  *iosim_tlv_bootstrap(void *thunk);
static void *shim_tlv_bootstrap(void *thunk) { return iosim_tlv_bootstrap(thunk); }
double iosim_now(void);
void *_Block_copy(void *block);
void _Block_release(void *block);
void _Block_object_assign(void *dest, const void *object, int flags);
void _Block_object_dispose(const void *object, int flags);
struct iosim_sincos_result { double sin_value; double cos_value; };
struct iosim_sincos_result __sincos_stret(double x);

int    iosim_argc = 0;
char **iosim_argv = NULL;
char **iosim_environ = NULL;
char   iosim_exec_path[1024] = "/";
char  *iosim_progname = (char *)"";

/* ---------- dyld / libSystem ---------- */

static void shim_dyld_stub_binder(void)
{
    fprintf(stderr, "iosim: unexpected call to dyld_stub_binder\n");
    _exit(126);
}

static int *shim_NSGetArgc(void) { return &iosim_argc; }
static char ***shim_NSGetArgv(void) { return &iosim_argv; }
static char ***shim_NSGetEnviron(void) { return &iosim_environ; }
static char **shim_NSGetProgname(void) { return &iosim_progname; }

static int shim_NSGetExecutablePath(char *buf, uint32_t *bufsize)
{
    size_t need = strlen(iosim_exec_path) + 1;
    if (!buf || !bufsize)
        return -1;
    if (*bufsize < need)
    {
        *bufsize = (uint32_t)need;
        return -1;
    }
    memcpy(buf, iosim_exec_path, need);
    return 0;
}

static const char *shim_getprogname(void) { return iosim_progname; }
static void shim_setprogname(const char *name) { iosim_progname = (char *)name; }
static int *shim___error(void) { return __errno_location(); }

/* ---------- malloc -------- */

static size_t shim_malloc_size(const void *p) { return malloc_usable_size((void *)p); }

static void *shim_malloc_default_zone(void)
{
    static int zone_token;
    return &zone_token;
}

static void *shim_malloc_create_zone(size_t start_size, unsigned flags)
{
    (void)start_size; (void)flags;
    return shim_malloc_default_zone();
}

static void *shim_malloc_zone_malloc(void *zone, size_t size)
{
    (void)zone;
    return malloc(size);
}

static void *shim_malloc_zone_calloc(void *zone, size_t n, size_t size)
{
    (void)zone;
    return calloc(n, size);
}

static void *shim_malloc_zone_realloc(void *zone, void *p, size_t size)
{
    (void)zone;
    return realloc(p, size);
}

static void shim_malloc_zone_free(void *zone, void *p)
{
    (void)zone;
    free(p);
}

static void shim_malloc_zone_destroy(void *zone) { (void)zone; }

/* Darwin's stack-probe helper: host-generated code does not need the probes
 * when a real kernel grows the stack, and guest frames are ordinary sizes. */
static void shim_chkstk_darwin(void) { }

/* ---------- mach time ---------- */

static uint64_t shim_mach_absolute_time(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

struct mach_timebase_info { uint32_t numer; uint32_t denom; };

static int shim_mach_timebase_info(struct mach_timebase_info *info)
{
    if (info)
    {
        info->numer = 1;
        info->denom = 1;
    }
    return 0;
}

/* ---------- os_log ---------- */

typedef void *os_log_t;

static os_log_t shim_os_log_create(const char *subsystem, const char *category)
{
    (void)subsystem; (void)category;
    return (os_log_t)1;
}

static int shim_os_log_type_enabled(os_log_t log, uint8_t type)
{
    (void)log; (void)type;
    return 0;
}

static void os_log_emit(const char *kind, os_log_t log, const char *format)
{
    (void)log;
    fprintf(stderr, "os_log(%s): %s\n", kind, format ? format : "(null)");
}

static void shim__os_log_impl(void *dso, os_log_t log, const char *format,
                              uint8_t *buf, unsigned size)
{
    (void)dso; (void)buf; (void)size;
    os_log_emit("default", log, format);
}

static void shim__os_log_error_impl(void *dso, os_log_t log, const char *format,
                                    uint8_t *buf, unsigned size)
{
    (void)dso; (void)buf; (void)size;
    os_log_emit("error", log, format);
}

static void shim__os_log_fault_impl(void *dso, os_log_t log, const char *format,
                                    uint8_t *buf, unsigned size)
{
    (void)dso; (void)buf; (void)size;
    os_log_emit("fault", log, format);
}

static void shim__os_log_debug_impl(void *dso, os_log_t log, const char *format,
                                    uint8_t *buf, unsigned size)
{
    (void)dso; (void)buf; (void)size;
    os_log_emit("debug", log, format);
}

static void shim__os_log(void *log, const char *format)
{
    os_log_emit("default", log, format);
}

static void *shim_os_retain(void *obj) { return obj; }
static void shim_os_release(void *obj) { (void)obj; }

/* ---------- Foundation / UIKit lite ---------- */

static void shim_iosim_nslog(const char *message)
{
    fprintf(stderr, "NSLog: %s\n", message ? message : "(null)");
}

struct cf_constant_string_min {
    void *isa;
    uint32_t flags;
    uint32_t pad;
    const char *cstr;
    uint64_t length;
};

static int shim_NSLog(void *format, ...)
{
    const char *s = NULL;
    if (format)
    {
        const struct cf_constant_string_min *cs = format;
        if (cs->flags == 0x7c8 && cs->cstr)
            s = cs->cstr;
    }
    shim_iosim_nslog(s ? s : "(NSLog format object)");
    return 0;
}

static int shim_UIApplicationMain(int argc, char **argv, void *principalClass,
                                  void *delegateClassName)
{
    (void)argv;
    printf("[UIKit-lite] UIApplicationMain argc=%d principal=%p delegate=%p\n",
           argc, principalClass, delegateClassName);
    printf("[UIKit-lite] no window server attached yet; returning.\n");
    return 0;
}

static char shim_CFConstantStringClassReference[8];
static char shim_NSConcreteStackBlock[64];
static char shim_NSConcreteGlobalBlock[64];
static char shim_NSConcreteMallocBlock[64];

/* ---------- sysctl (small subset used by startup code) ---------- */

static int shim_sysctlbyname(const char *name, void *oldp, size_t *oldlenp,
                             void *newp, size_t newlen)
{
    (void)newp; (void)newlen;

    static char osversion[128];
    static char model[128] = "iosim-x86_64";
    static char machine[128] = "x86_64";
    static uint64_t memsize;
    static uint32_t ncpu;

    if (!name || !oldlenp)
        return EINVAL;

    const void *src = NULL;
    size_t srclen = 0;

    if (strcmp(name, "hw.memsize") == 0 ||
        strcmp(name, "hw.memsize_usable") == 0)
    {
        long pages = sysconf(_SC_PHYS_PAGES);
        long psize = sysconf(_SC_PAGESIZE);
        memsize = (pages > 0 && psize > 0) ? (uint64_t)pages * (uint64_t)psize
                                           : (uint64_t)4 << 30;
        src = &memsize;
        srclen = sizeof(memsize);
    }
    else if (strcmp(name, "hw.ncpu") == 0 ||
             strcmp(name, "hw.logicalcpu") == 0 ||
             strcmp(name, "hw.physicalcpu") == 0 ||
             strcmp(name, "hw.availablecpu") == 0)
    {
        long n = sysconf(_SC_NPROCESSORS_ONLN);
        ncpu = n > 0 ? (uint32_t)n : 1;
        src = &ncpu;
        srclen = sizeof(ncpu);
    }
    else if (strcmp(name, "kern.osversion") == 0)
    {
        snprintf(osversion, sizeof(osversion), "26A434");
        src = osversion;
        srclen = strlen(osversion) + 1;
    }
    else if (strcmp(name, "kern.osproductversion") == 0)
    {
        snprintf(osversion, sizeof(osversion), "27.0.1");
        src = osversion;
        srclen = strlen(osversion) + 1;
    }
    else if (strcmp(name, "kern.ostype") == 0)
    {
        static const char ostype[] = "Darwin";
        src = ostype;
        srclen = sizeof(ostype);
    }
    else if (strcmp(name, "kern.osrelease") == 0)
    {
        snprintf(osversion, sizeof(osversion), "27.0.0");
        src = osversion;
        srclen = strlen(osversion) + 1;
    }
    else if (strcmp(name, "hw.pagesize") == 0)
    {
        static uint32_t pagesize = 4096;
        src = &pagesize;
        srclen = sizeof(pagesize);
    }
    else if (strcmp(name, "hw.cpu64bit_capable") == 0)
    {
        static uint32_t capable = 1;
        src = &capable;
        srclen = sizeof(capable);
    }
    else if (strcmp(name, "hw.model") == 0)
    {
        src = model;
        srclen = strlen(model) + 1;
    }
    else if (strcmp(name, "hw.machine") == 0 ||
             strcmp(name, "hw.product") == 0)
    {
        src = machine;
        srclen = strlen(machine) + 1;
    }
    else
    {
        return ENOENT;
    }

    if (!oldp)
    {
        *oldlenp = srclen;
        return 0;
    }
    if (*oldlenp < srclen)
    {
        *oldlenp = srclen;
        return ENOMEM;
    }
    memcpy(oldp, src, srclen);
    *oldlenp = srclen;
    return 0;
}

double iosim_wall_time(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (double)ts.tv_sec + ts.tv_nsec / 1e9;
}

/* ---------- Darwin signals ----------
 * Signal numbers, sigset_t (a 32-bit mask on Darwin) and struct sigaction
 * (16 bytes) differ from glibc's. Translate at the boundary. */

static const int darwin_signal_map[32] = {
    0, SIGHUP, SIGINT, SIGQUIT, SIGILL, SIGTRAP, SIGABRT, SIGSYS,
    SIGFPE, SIGKILL, SIGBUS, SIGSEGV, SIGSYS, SIGPIPE, SIGALRM,
    SIGTERM, SIGURG, SIGSTOP, SIGTSTP, SIGCONT, SIGCHLD, SIGTTIN,
    SIGTTOU, SIGIO, SIGXCPU, SIGXFSZ, SIGVTALRM, SIGPROF,
    SIGWINCH, SIGPWR, SIGUSR1, SIGUSR2,
};

static int darwin_to_host_signal(int sig)
{
    if (sig > 0 && sig < 32)
        return darwin_signal_map[sig];
    return sig;
}

static void darwin_set_to_host(const uint32_t *set, sigset_t *host)
{
    sigemptyset(host);
    if (!set)
        return;
    for (int s = 1; s < 32; s++)
        if (*set & (1u << (s - 1)))
            sigaddset(host, darwin_to_host_signal(s));
}

static void host_set_to_darwin(const sigset_t *host, uint32_t *set)
{
    uint32_t mask = 0;
    for (int s = 1; s < 32; s++)
        if (sigismember(host, darwin_to_host_signal(s)) == 1)
            mask |= 1u << (s - 1);
    *set = mask;
}

static int shim_sigprocmask(int how, const uint32_t *set, uint32_t *oldset)
{
    if (how == 1)
        how = SIG_BLOCK;
    else if (how == 2)
        how = SIG_UNBLOCK;
    else if (how == 3)
        how = SIG_SETMASK;
    else
    {
        errno = EINVAL;
        return -1;
    }
    sigset_t host_set, host_old;
    darwin_set_to_host(set, &host_set);
    int r = pthread_sigmask(how, set ? &host_set : NULL,
                            oldset ? &host_old : NULL);
    if (r != 0)
    {
        errno = r;
        return -1;
    }
    if (oldset)
        host_set_to_darwin(&host_old, oldset);
    return 0;
}

static int shim_pthread_sigmask(int how, const uint32_t *set, uint32_t *oldset)
{
    return shim_sigprocmask(how, set, oldset);
}

struct darwin_sigaction {
    union {
        void (*handler)(int);
        void (*sigaction_fn)(int, void *, void *);
    } u;
    uint32_t sa_mask;
    int sa_flags;
};

static int darwin_to_host_sa_flags(int flags)
{
    int host = 0;
    if (flags & 0x0001) host |= SA_ONSTACK;
    if (flags & 0x0002) host |= SA_RESTART;
    if (flags & 0x0004) host |= SA_RESETHAND;
    if (flags & 0x0008) host |= SA_NOCLDSTOP;
    if (flags & 0x0010) host |= SA_NODEFER;
    if (flags & 0x0020) host |= SA_NOCLDWAIT;
    if (flags & 0x0040) host |= SA_SIGINFO;
    return host;
}

static int host_to_darwin_sa_flags(int flags)
{
    int darwin = 0;
    if (flags & SA_ONSTACK) darwin |= 0x0001;
    if (flags & SA_RESTART) darwin |= 0x0002;
    if (flags & SA_RESETHAND) darwin |= 0x0004;
    if (flags & SA_NOCLDSTOP) darwin |= 0x0008;
    if (flags & SA_NODEFER) darwin |= 0x0010;
    if (flags & SA_NOCLDWAIT) darwin |= 0x0020;
    if (flags & SA_SIGINFO) darwin |= 0x0040;
    return darwin;
}

static int shim_sigaction(int sig, const struct darwin_sigaction *act,
                          struct darwin_sigaction *oldact)
{
    struct sigaction host_act, host_old;
    struct sigaction *host_act_p = NULL;
    if (act)
    {
        memset(&host_act, 0, sizeof(host_act));
        host_act.sa_handler = act->u.handler;
        darwin_set_to_host(&act->sa_mask, &host_act.sa_mask);
        host_act.sa_flags = darwin_to_host_sa_flags(act->sa_flags);
        host_act_p = &host_act;
    }
    int r = sigaction(darwin_to_host_signal(sig), host_act_p,
                      oldact ? &host_old : NULL);
    if (r != 0)
        return -1;
    if (oldact)
    {
        memset(oldact, 0, sizeof(*oldact));
        oldact->u.handler = host_old.sa_handler;
        host_set_to_darwin(&host_old.sa_mask, &oldact->sa_mask);
        oldact->sa_flags = host_to_darwin_sa_flags(host_old.sa_flags);
    }
    return 0;
}

static void (*shim_signal(int sig, void (*handler)(int)))(int)
{
    struct darwin_sigaction act, old;
    memset(&act, 0, sizeof(act));
    act.u.handler = handler;
    if (shim_sigaction(sig, &act, &old) != 0)
        return (void (*)(int))-1;
    return old.u.handler;
}

static int shim_raise(int sig)
{
    return raise(darwin_to_host_signal(sig));
}

static int shim_kill(int pid, int sig)
{
    return kill(pid, darwin_to_host_signal(sig));
}

/* ---------- table ---------- */

int shim_pthread_main_np(void);

#define SHIM(fn) { #fn, (void *)(uintptr_t)&shim_##fn }
#define SHIM_ALIAS(nm, fn) { nm, (void *)(uintptr_t)&shim_##fn }
#define SHIM_DIRECT(nm) { #nm, (void *)(uintptr_t)&nm }
#define SHIM_EXPORT(nm, fn) { nm, (void *)(uintptr_t)&iosim_##fn }

static const struct iosim_shim shims[] = {
    SHIM(dyld_stub_binder),
    SHIM_ALIAS("_NSGetArgc", NSGetArgc),
    SHIM_ALIAS("_NSGetArgv", NSGetArgv),
    SHIM_ALIAS("_NSGetEnviron", NSGetEnviron),
    SHIM_ALIAS("_NSGetProgname", NSGetProgname),
    SHIM_ALIAS("_NSGetExecutablePath", NSGetExecutablePath),
    SHIM_ALIAS("getprogname", getprogname),
    SHIM_ALIAS("setprogname", setprogname),
    SHIM_ALIAS("__error", __error),
    SHIM_ALIAS("malloc_size", malloc_size),
    SHIM_ALIAS("malloc_default_zone", malloc_default_zone),
    SHIM_ALIAS("___chkstk_darwin", chkstk_darwin),
    SHIM_ALIAS("stat$INODE64", stat_ino64),
    SHIM_ALIAS("lstat$INODE64", lstat_ino64),
    SHIM_ALIAS("fstat$INODE64", fstat_ino64),
    SHIM_ALIAS("fstatat$INODE64", fstatat_ino64),
    SHIM_ALIAS("stat", stat_ino64),
    SHIM_ALIAS("lstat", lstat_ino64),
    SHIM_ALIAS("fstat", fstat_ino64),
    SHIM_ALIAS("fstatat", fstatat_ino64),
    SHIM_ALIAS("open", open),
    SHIM_ALIAS("openat", openat),
    SHIM_DIRECT(read),
    SHIM_DIRECT(write),
    SHIM_DIRECT(close),
    SHIM_DIRECT(lseek),
    SHIM_DIRECT(pread),
    SHIM_DIRECT(pwrite),
    SHIM_DIRECT(fsync),
    SHIM_DIRECT(ftruncate),
    SHIM_ALIAS("sigprocmask", sigprocmask),
    SHIM_ALIAS("pthread_sigmask", pthread_sigmask),
    SHIM_ALIAS("sigaction", sigaction),
    SHIM_ALIAS("signal", signal),
    SHIM_ALIAS("raise", raise),
    SHIM_ALIAS("kill", kill),
    SHIM_ALIAS("_tlv_bootstrap", tlv_bootstrap),
    SHIM_ALIAS("__tlv_bootstrap", tlv_bootstrap),
    SHIM_ALIAS("___tlv_bootstrap", tlv_bootstrap),
    SHIM_EXPORT("CC_MD5_Init", CC_MD5_Init),
    SHIM_EXPORT("CC_MD5_Update", CC_MD5_Update),
    SHIM_EXPORT("CC_MD5_Final", CC_MD5_Final),
    SHIM_EXPORT("CC_SHA256_Init", CC_SHA256_Init),
    SHIM_EXPORT("CC_SHA256_Update", CC_SHA256_Update),
    SHIM_EXPORT("CC_SHA256_Final", CC_SHA256_Final),
    SHIM_ALIAS("malloc_create_zone", malloc_create_zone),
    SHIM_ALIAS("malloc_zone_malloc", malloc_zone_malloc),
    SHIM_ALIAS("malloc_zone_calloc", malloc_zone_calloc),
    SHIM_ALIAS("malloc_zone_realloc", malloc_zone_realloc),
    SHIM_ALIAS("malloc_zone_free", malloc_zone_free),
    SHIM_ALIAS("malloc_zone_destroy", malloc_zone_destroy),
    SHIM_ALIAS("mach_absolute_time", mach_absolute_time),
    SHIM_ALIAS("mach_timebase_info", mach_timebase_info),
    SHIM_ALIAS("os_log_create", os_log_create),
    SHIM_ALIAS("os_log_type_enabled", os_log_type_enabled),
    SHIM_ALIAS("_os_log_impl", _os_log_impl),
    SHIM_ALIAS("_os_log_error_impl", _os_log_error_impl),
    SHIM_ALIAS("_os_log_fault_impl", _os_log_fault_impl),
    SHIM_ALIAS("_os_log_debug_impl", _os_log_debug_impl),
    SHIM_ALIAS("_os_log", _os_log),
    SHIM_ALIAS("os_retain", os_retain),
    SHIM_ALIAS("os_release", os_release),
    SHIM_ALIAS("sysctlbyname", sysctlbyname),
    SHIM_ALIAS("iosim_nslog", iosim_nslog),
    SHIM_ALIAS("NSLog", NSLog),
    SHIM_ALIAS("UIApplicationMain", UIApplicationMain),
    SHIM_ALIAS("__CFConstantStringClassReference", CFConstantStringClassReference),
    SHIM_ALIAS("_NSConcreteStackBlock", NSConcreteStackBlock),
    SHIM_ALIAS("_NSConcreteGlobalBlock", NSConcreteGlobalBlock),
    SHIM_ALIAS("_NSConcreteMallocBlock", NSConcreteMallocBlock),
    SHIM_DIRECT(iosim_fb_begin),
    SHIM_DIRECT(iosim_fb_release),
    SHIM_DIRECT(iosim_fb_clear),
    SHIM_DIRECT(iosim_fb_fill_rect),
    SHIM_DIRECT(iosim_fb_fill_round_rect),
    SHIM_DIRECT(iosim_fb_fill_circle),
    SHIM_DIRECT(iosim_fb_fill_circle_gradient),
    SHIM_DIRECT(iosim_fb_fill_arc_gradient),
    SHIM_DIRECT(iosim_fb_fill_ellipse_ring_gradient),
    SHIM_DIRECT(iosim_fb_fill_ellipse_gradient),
    SHIM_DIRECT(iosim_fb_stroke_circle),
    SHIM_DIRECT(iosim_fb_fill_squircle),
    SHIM_DIRECT(iosim_fb_fill_squircle_gradient),
    SHIM_DIRECT(iosim_fb_draw_line),
    SHIM_DIRECT(iosim_fb_fill_ellipse),
    SHIM_DIRECT(iosim_fb_fill_polygon),
    SHIM_DIRECT(iosim_fb_fill_linear_gradient),
    SHIM_DIRECT(iosim_fb_fill_gradient_stops),
    SHIM_DIRECT(iosim_fb_fill_gradient_stops_alpha),
    SHIM_DIRECT(iosim_fb_fill_linear_gradient_round_rect),
    SHIM_DIRECT(iosim_fb_blit_rgba),
    SHIM_DIRECT(iosim_fb_blit_rgba_scaled),
    SHIM_DIRECT(iosim_fb_paste_xrgb),
    SHIM_DIRECT(iosim_fb_capture),
    SHIM_DIRECT(iosim_fb_begin_offscreen),
    SHIM_DIRECT(iosim_fb_end_offscreen),
    SHIM_DIRECT(iosim_fb_offscreen_pixels),
    SHIM_DIRECT(iosim_fb_activate_offscreen),
    SHIM_DIRECT(iosim_fb_restore_target),
    SHIM_DIRECT(iosim_fb_free_offscreen),
    SHIM_DIRECT(iosim_fb_mask_round_rect),
    SHIM_DIRECT(iosim_fb_blit_affine),
    SHIM_DIRECT(iosim_fb_fill_field),
    SHIM_DIRECT(iosim_fb_blit_xrgb_scaled),
    SHIM_DIRECT(iosim_fb_width),
    SHIM_DIRECT(iosim_fb_height),
    SHIM_DIRECT(iosim_png_load),
    SHIM_DIRECT(iosim_fb_set_opacity),
    SHIM_DIRECT(iosim_fb_push_clip),
    SHIM_DIRECT(iosim_fb_pop_clip),
    SHIM_DIRECT(iosim_fb_push_clip_polygon),
    SHIM_DIRECT(iosim_fb_push_clip_alpha),
    SHIM_DIRECT(iosim_fb_pop_clip_mask),
    SHIM_DIRECT(__sincos_stret),
    SHIM_DIRECT(iosim_fb_text),
    SHIM_DIRECT(iosim_fb_text_width),
    SHIM_DIRECT(iosim_fb_font_text_width),
    SHIM_DIRECT(iosim_fb_font_text),
    SHIM_DIRECT(iosim_fb_font_metrics),
    SHIM_DIRECT(iosim_fb_present),
    SHIM_DIRECT(iosim_event_open),
    SHIM_DIRECT(iosim_event_next),
    SHIM_DIRECT(iosim_event_second_point),
    SHIM_DIRECT(iosim_event_close),
    SHIM_DIRECT(iosim_fs_exists),
    SHIM_DIRECT(iosim_fs_is_dir),
    SHIM_DIRECT(iosim_fs_size),
    SHIM_DIRECT(iosim_fs_read),
    SHIM_DIRECT(iosim_fs_write),
    SHIM_DIRECT(iosim_fs_remove),
    SHIM_DIRECT(iosim_fs_rename),
    SHIM_DIRECT(iosim_fs_mkdir),
    SHIM_DIRECT(iosim_fs_list),
    SHIM_DIRECT(iosim_spawn_app),
    SHIM_DIRECT(iosim_spawn_wait),
    SHIM_DIRECT(iosim_suspend_self),
    SHIM_DIRECT(iosim_resume_app),
    SHIM_DIRECT(iosim_terminate_app),
    SHIM_DIRECT(iosim_on_switcher_request),
    SHIM_DIRECT(iosim_request_switcher),
    SHIM_DIRECT(iosim_on_lock_request),
    SHIM_DIRECT(iosim_request_lock),
    SHIM_DIRECT(iosim_dispatch_drain_main),
    SHIM_DIRECT(_Block_copy),
    SHIM_DIRECT(_Block_release),
    SHIM_DIRECT(_Block_object_assign),
    SHIM_DIRECT(_Block_object_dispose),
    SHIM_DIRECT(iosim_now),
    SHIM_DIRECT(iosim_wall_time),
    SHIM_DIRECT(usleep),
    SHIM_ALIAS("pthread_main_np", pthread_main_np),
    SHIM_DIRECT(malloc),
    SHIM_DIRECT(calloc),
    SHIM_DIRECT(realloc),
    SHIM_DIRECT(free),
    SHIM_DIRECT(strlen),
    SHIM_DIRECT(strcmp),
    SHIM_DIRECT(strncmp),
    SHIM_DIRECT(strcpy),
    SHIM_DIRECT(strncpy),
    SHIM_DIRECT(strcat),
    SHIM_DIRECT(memcpy),
    SHIM_DIRECT(memmove),
    SHIM_DIRECT(memset),
    SHIM_DIRECT(snprintf),
    SHIM_DIRECT(vsnprintf),
    SHIM_DIRECT(strtol),
    SHIM_DIRECT(strtod),
    SHIM_DIRECT(objc_msgSend),
    SHIM_DIRECT(objc_msgSendSuper2),
    SHIM_DIRECT(objc_msgSend_stret),
    SHIM_DIRECT(iosim_objc_alloc),
    SHIM_DIRECT(iosim_objc_class_of),
    SHIM_DIRECT(iosim_objc_superclass),
    SHIM_DIRECT(iosim_objc_is_kind_of),
    SHIM_DIRECT(iosim_objc_responds),
    SHIM_DIRECT(objc_opt_class),
    SHIM_DIRECT(objc_enumerationMutation),
    SHIM_DIRECT(objc_setProperty_nonatomic),
    SHIM_DIRECT(objc_setProperty_nonatomic_copy),
    SHIM_DIRECT(objc_setProperty_atomic),
    SHIM_DIRECT(objc_setProperty_atomic_copy),
    SHIM_DIRECT(objc_alloc_init),
    SHIM_DIRECT(objc_alloc),
    SHIM_DIRECT(objc_autorelease),
    SHIM_DIRECT(objc_retain),
    SHIM_DIRECT(objc_release),
    SHIM_DIRECT(objc_autoreleasePoolPush),
    SHIM_DIRECT(objc_autoreleasePoolPop),
    SHIM_DIRECT(objc_retain),
    SHIM_DIRECT(objc_release),
    SHIM_DIRECT(objc_getClass),
    SHIM_DIRECT(class_getName),
    SHIM_DIRECT(object_getClassName),
    SHIM_DIRECT(sel_registerName),
    SHIM_DIRECT(sel_getName),
    SHIM_DIRECT(sel_getUid),
    SHIM_DIRECT(objc_allocateClassPair),
    SHIM_DIRECT(objc_registerClassPair),
    SHIM_DIRECT(class_addMethod),
    SHIM_DIRECT(class_getInstanceMethod),
    SHIM_DIRECT(class_getMethodImplementation),
    SHIM_DIRECT(method_getTypeEncoding),
    SHIM_DIRECT(method_getImplementation),
    SHIM_DIRECT(method_setImplementation),
    SHIM_DIRECT(class_getSuperclass),
    SHIM_DIRECT(class_getInstanceSize),
    SHIM_DIRECT(object_getClass),
    SHIM_DIRECT(object_setClass),
    SHIM_DIRECT(_objc_empty_cache),
};

/* Optional bridge for running unmodified host-platform Darwin tools: when
 * IOSIM_HOST_SYMBOLS is set, symbols the shim table does not provide are
 * looked up in the loader's own process after dlopen'ing the colon-separated
 * IOSIM_HOST_LIBS list. Guest binaries otherwise keep the closed shim
 * namespace, so Darwin open(2) flags never reach a glibc function by accident. */
static void *host_symbol(const char *name)
{
    static int loaded;
    if (!loaded)
    {
        loaded = 1;
        const char *libs = getenv("IOSIM_HOST_LIBS");
        if (libs && *libs)
        {
            char buf[1024];
            snprintf(buf, sizeof(buf), "%s", libs);
            char *save = NULL;
            for (char *lib = strtok_r(buf, ":", &save); lib;
                 lib = strtok_r(NULL, ":", &save))
                dlopen(lib, RTLD_NOW | RTLD_GLOBAL);
        }
    }
    return dlsym(RTLD_DEFAULT, name);
}

void *iosim_lookup_shim(const char *name)
{
    if (!name)
        return NULL;
    for (size_t i = 0; i < sizeof(shims) / sizeof(shims[0]); i++)
    {
        if (strcmp(shims[i].name, name) == 0)
            return shims[i].addr;
    }
    void *found = iosim_services_lookup(name);
    if (found)
        return found;
    if (getenv("IOSIM_HOST_SYMBOLS"))
        return host_symbol(name);
    return NULL;
}

void *objc_opt_class(void *obj)
{
    return iosim_objc_normalize_class(obj);
}

struct iosim_sincos_result __sincos_stret(double x)
{
    struct iosim_sincos_result r;
    double s, c;
    sincos(x, &s, &c);
    r.sin_value = s;
    r.cos_value = c;
    return r;
}

double iosim_now(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + ts.tv_nsec / 1e9;
}

/* pthread_main_np: the guest asks whether it runs on the process's first
 * thread. Record that thread here, while the host loader is still single
 * threaded, and compare against it. */
static pthread_t g_main_pthread;
static int g_main_pthread_set;

__attribute__((constructor)) static void iosim_record_main_thread(void)
{
    g_main_pthread = pthread_self();
    g_main_pthread_set = 1;
}

int shim_pthread_main_np(void)
{
    if (!g_main_pthread_set)
    {
        g_main_pthread = pthread_self();
        g_main_pthread_set = 1;
        return 1;
    }
    return pthread_equal(pthread_self(), g_main_pthread) ? 1 : 0;
}

struct iosim_block_descriptor {
    unsigned long reserved;
    unsigned long size;
    void (*copy)(void *dst, const void *src);
    void (*dispose)(const void *src);
};

struct iosim_block_layout {
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    struct iosim_block_descriptor *descriptor;
};

#define IOSIM_BLOCK_IS_GLOBAL  (1 << 28)
#define IOSIM_BLOCK_HAS_COPY_DISPOSE (1 << 25)
#define IOSIM_BLOCK_IS_HEAP (1 << 24)

void *_Block_copy(void *block)
{
    struct iosim_block_layout *b = block;
    if (!b)
        return NULL;
    if (b->flags & IOSIM_BLOCK_IS_GLOBAL)
        return block;
    if (b->flags & IOSIM_BLOCK_IS_HEAP)
        return block;
    if (!b->descriptor || b->descriptor->size < sizeof(struct iosim_block_layout))
        return block;
    struct iosim_block_layout *copy = malloc(b->descriptor->size);
    memcpy(copy, b, b->descriptor->size);
    copy->flags |= IOSIM_BLOCK_IS_HEAP;
    if ((b->flags & IOSIM_BLOCK_HAS_COPY_DISPOSE) && b->descriptor->copy)
        b->descriptor->copy(copy, b);
    return copy;
}

void _Block_object_assign(void *dest, const void *object, int flags)
{
    (void)flags;
    if (dest)
        *(const void **)dest = object;
}

void _Block_object_dispose(const void *object, int flags)
{
    (void)object; (void)flags;
}

void _Block_release(void *block)
{
    struct iosim_block_layout *b = block;
    if (!b || (b->flags & IOSIM_BLOCK_IS_GLOBAL) == 0)
    {
        if (!b)
            return;
    }
    if (!(b->flags & IOSIM_BLOCK_IS_HEAP))
        return;
    if ((b->flags & IOSIM_BLOCK_HAS_COPY_DISPOSE) && b->descriptor && b->descriptor->dispose)
        b->descriptor->dispose(b);
    free(b);
}
