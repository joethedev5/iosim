/* Loader runtime fixture: Mach-O initializers, thread-local variables,
 * Darwin pthread static initializers, CommonCrypto, dispatch_data, signal
 * masks and Darwin stat/open flags, all without external libraries. */
#include <stdint.h>

extern int printf(const char *fmt, ...);
extern int open(const char *path, int flags, ...);
extern long write(int fd, const void *buf, unsigned long count);
extern int close(int fd);
extern int fstat(int fd, void *buf);

extern int CC_SHA256_Init(void *ctx);
extern int CC_SHA256_Update(void *ctx, const void *data, unsigned len);
extern int CC_SHA256_Final(unsigned char *digest, void *ctx);
extern int CC_MD5_Init(void *ctx);
extern int CC_MD5_Update(void *ctx, const void *data, unsigned len);
extern int CC_MD5_Final(unsigned char *digest, void *ctx);

extern void *dispatch_data_create(const void *buffer, unsigned long size,
                                  void *queue, void *destructor);
extern unsigned long dispatch_data_get_size(void *data);
extern int dispatch_data_apply(void *data, void *applier);

extern int sigprocmask(int how, const uint32_t *set, uint32_t *oldset);
extern int pthread_mutex_lock(void *mutex);
extern int pthread_mutex_unlock(void *mutex);

static __thread int tls_counter = 41;
static int ctor_ran;
static unsigned long ctor_mutex_word = 0xdeadbeef;
static int applied_size;

/* Darwin PTHREAD_MUTEX_INITIALIZER is { 0x32AAABA7, {0} }. The loader must
 * normalize it before constructors run. */
static unsigned long static_mutex[8] = {0x32AAABA7UL};

__attribute__((constructor)) static void before_main(void)
{
    ctor_ran = 1;
    tls_counter++;
    ctor_mutex_word = static_mutex[0];
}

static void hex(const unsigned char *p, int n)
{
    for (int i = 0; i < n; i++)
        printf("%02x", p[i]);
}

int main(int argc, char **argv)
{
    printf("[lrt] ctor %d tls %d\n", ctor_ran, tls_counter);
    printf("[lrt] mutex %s\n",
           ctor_mutex_word == 0x32AAABA7UL ? "raw" : "normalized");
    int mr = pthread_mutex_lock(static_mutex);
    int ur = pthread_mutex_unlock(static_mutex);
    printf("[lrt] lock %d %d\n", mr, ur);

    unsigned char digest[32];
    unsigned char ctx[160];
    CC_SHA256_Init(ctx);
    CC_SHA256_Update(ctx, "abc", 3);
    CC_SHA256_Final(digest, ctx);
    printf("[lrt] sha256 ");
    hex(digest, 32);
    printf("\n");
    CC_MD5_Init(ctx);
    CC_MD5_Update(ctx, "abc", 3);
    CC_MD5_Final(digest, ctx);
    printf("[lrt] md5 ");
    hex(digest, 16);
    printf("\n");

    static const char payload[] = "dispatch-data";
    void *data = dispatch_data_create(payload, sizeof(payload) - 1, 0, 0);
    /* dispatch_data_apply reads the applier's bool result; a void block
     * leaves an undefined value in the return register. */
    int (^applier)(void *, unsigned long, const void *, unsigned long) =
        ^(void *region, unsigned long offset, const void *buffer,
          unsigned long size)
    {
        (void)region;
        (void)offset;
        (void)buffer;
        applied_size = (int)size;
        return 1;
    };
    int applied = dispatch_data_apply(data, (void *)applier);
    printf("[lrt] data %lu %d %d\n", dispatch_data_get_size(data), applied,
           applied_size);

    uint32_t set = 1u << 1; /* Darwin SIGINT */
    uint32_t old = 0;
    int sr = sigprocmask(3, &set, &old); /* Darwin SIG_SETMASK */
    printf("[lrt] sigmask %d old %u\n", sr, old & 2u);

    int fd = open(argv[1], 0x200 | 0x2 | 0x400, 0644);
    if (fd < 0)
    {
        printf("[lrt] open failed\n");
        return 1;
    }
    write(fd, "abc", 3);
    unsigned char st[144];
    for (int i = 0; i < 144; i++)
        st[i] = 0;
    int stf = fstat(fd, st);
    close(fd);
    uint16_t mode;
    int64_t size;
    __builtin_memcpy(&mode, st + 4, 2);
    __builtin_memcpy(&size, st + 96, 8);
    printf("[lrt] stat %d %d %lld\n", stf, (mode & 0170000) == 0100000,
           (long long)size);
    return 0;
}
