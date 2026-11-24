/* A small AArch64 interpreter for app images.
 *
 * This is the first stage of the execution design in
 * docs/ARM64-TRANSLATION.md: guest code runs on an internal machine while
 * every call into a framework, a loader shim or libc stays in native
 * x86_64 code. The instruction set grows fixture by fixture; a block
 * translator can replace the fetch loop without changing the call gates. */
#define _GNU_SOURCE
#include "arm64.h"
#include "arm64_cpu.h"
#include "arm64_jit.h"
#include "objc_runtime.h"
#include "shims.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <math.h>
#include <unistd.h>
#include <dlfcn.h>
#include <sys/mman.h>

#ifndef MAP_ANONYMOUS
#define MAP_ANONYMOUS MAP_ANON
#endif

extern void iosim_arm64_native_invoke(void *imp, void *self, void *sel,
                                      void *gp, void *sse, void *retbuf);
extern void iosim_arm64_native_invoke_stret(void *imp, void *ret, void *self,
                                            void *sel, void *gp, void *sse);
extern void iosim_arm64_native_invoke_stack(void *imp, void *self, void *sel,
                                           void *gp, void *sse, void *args,
                                           uint64_t args_size, void *retbuf);
extern void iosim_arm64_native_invoke_stack_stret(void *imp, void *ret,
                                                 void *self, void *sel,
                                                 void *gp, void *sse,
                                                 void *args, uint64_t size);

#define A64_STACK_SIZE (8u * 1024 * 1024)
#define A64_RETURN_SENTINEL 0ull

/* The arm64 main image. Block copy/dispose and byref keep/destroy helpers
 * are function pointers into this image, so the block runtime asks back
 * here when it needs to run them. */
static struct iosim_image *g_arm64_img;

static int a64_fail(struct a64_cpu *c, const char *what, uint32_t insn)
{
    fprintf(stderr,
            "iosim: arm64: %s at pc=0x%llx (insn 0x%08x)\n", what,
            (unsigned long long)c->pc, insn);
    return -1;
}

static uint64_t rd_x(struct a64_cpu *c, int r)
{
    return r == 31 ? 0 : c->x[r];
}

static uint64_t rd_sp(struct a64_cpu *c, int r)
{
    return r == 31 ? c->sp : c->x[r];
}

static void wr_x(struct a64_cpu *c, int r, uint64_t v)
{
    if (r != 31)
        c->x[r] = v;
}

static void wr_w(struct a64_cpu *c, int r, uint32_t v)
{
    if (r != 31)
        c->x[r] = v;
}

static uint64_t mask_for(int bits)
{
    return bits == 64 ? ~0ull : 0xffffffffull;
}

static void a64_set_nz(struct a64_cpu *c, uint64_t res, int bits)
{
    c->nzcv &= ~(A64_N | A64_Z);
    if (res & (1ull << (bits - 1)))
        c->nzcv |= A64_N;
    if (res == 0)
        c->nzcv |= A64_Z;
}

static uint64_t a64_add_flags(struct a64_cpu *c, uint64_t a, uint64_t b,
                              int bits, int setflags)
{
    uint64_t m = mask_for(bits);
    unsigned __int128 u = (unsigned __int128)(a & m) + (b & m);
    uint64_t res = (uint64_t)u & m;
    if (setflags)
    {
        c->nzcv = 0;
        a64_set_nz(c, res, bits);
        if ((u >> bits) & 1)
            c->nzcv |= A64_C;
        if (((a ^ res) & (b ^ res)) & (1ull << (bits - 1)))
            c->nzcv |= A64_V;
    }
    return res;
}

static uint64_t a64_sub_flags(struct a64_cpu *c, uint64_t a, uint64_t b,
                              int bits, int setflags)
{
    uint64_t m = mask_for(bits);
    uint64_t res = ((a & m) - (b & m)) & m;
    if (setflags)
    {
        c->nzcv = 0;
        a64_set_nz(c, res, bits);
        if ((a & m) >= (b & m))
            c->nzcv |= A64_C;
        if (((a ^ b) & (a ^ res)) & (1ull << (bits - 1)))
            c->nzcv |= A64_V;
    }
    return res;
}

static int a64_cond(uint32_t nzcv, unsigned cond)
{
    unsigned n = (nzcv & A64_N) != 0;
    unsigned z = (nzcv & A64_Z) != 0;
    unsigned c = (nzcv & A64_C) != 0;
    unsigned v = (nzcv & A64_V) != 0;
    switch (cond)
    {
    case 0: return z;
    case 1: return !z;
    case 2: return c;
    case 3: return !c;
    case 4: return n;
    case 5: return !n;
    case 6: return v;
    case 7: return !v;
    case 8: return c && !z;
    case 9: return !c || z;
    case 10: return n == v;
    case 11: return n != v;
    case 12: return !z && n == v;
    case 13: return z || n != v;
    default: return 1;
    }
}

static uint64_t a64_ror(uint64_t v, unsigned shift, int bits)
{
    uint64_t m = mask_for(bits);
    shift &= (unsigned)(bits - 1);
    v &= m;
    if (!shift)
        return v;
    return ((v >> shift) | (v << (bits - shift))) & m;
}

static int a64_mem_ok(uint64_t addr, int size)
{
    return addr != 0 && addr + (uint64_t)size > addr;
}

static uint64_t a64_load(struct a64_cpu *c, uint64_t addr, int size, int sign)
{
    (void)c;
    if (!a64_mem_ok(addr, size))
    {
        fprintf(stderr, "iosim: arm64: bad load address 0x%llx\n",
                (unsigned long long)addr);
        return 0;
    }
    if (size == 1)
    {
        uint8_t v;
        memcpy(&v, (const void *)(uintptr_t)addr, 1);
        return sign ? (uint64_t)(int64_t)(int8_t)v : v;
    }
    if (size == 2)
    {
        uint16_t v;
        memcpy(&v, (const void *)(uintptr_t)addr, 2);
        return sign ? (uint64_t)(int64_t)(int16_t)v : v;
    }
    if (size == 4)
    {
        uint32_t v;
        memcpy(&v, (const void *)(uintptr_t)addr, 4);
        return sign ? (uint64_t)(int64_t)(int32_t)v : v;
    }
    uint64_t v;
    memcpy(&v, (const void *)(uintptr_t)addr, 8);
    return v;
}

static void a64_store(struct a64_cpu *c, uint64_t addr, uint64_t value,
                      int size)
{
    (void)c;
    if (!a64_mem_ok(addr, size))
    {
        fprintf(stderr, "iosim: arm64: bad store address 0x%llx\n",
                (unsigned long long)addr);
        return;
    }
    if (size == 1)
    {
        uint8_t v = (uint8_t)value;
        memcpy((void *)(uintptr_t)addr, &v, 1);
    }
    else if (size == 2)
    {
        uint16_t v = (uint16_t)value;
        memcpy((void *)(uintptr_t)addr, &v, 2);
    }
    else if (size == 4)
    {
        uint32_t v = (uint32_t)value;
        memcpy((void *)(uintptr_t)addr, &v, 4);
    }
    else
    {
        memcpy((void *)(uintptr_t)addr, &value, 8);
    }
}

static uint64_t a64_width_mask(int size)
{
    return size == 8 ? ~0ull : ((1ull << (size * 8)) - 1);
}

static int64_t a64_sign_extend(uint64_t v, int size)
{
    int bits = size * 8;
    if (bits == 64)
        return (int64_t)v;
    uint64_t sign = 1ull << (bits - 1);
    v &= (1ull << bits) - 1;
    return (int64_t)((v ^ sign) - sign);
}

/* DecodeBitMasks for the logical-immediate instructions (AND/ORR/EOR/ANDS
 * with a bitmask immediate). Returns the replicated mask; ok is cleared
 * for the reserved encodings. */
static uint64_t a64_bitmask_imm(uint32_t insn, int bits, int *ok)
{
    int n = (insn >> 22) & 1;
    unsigned immr = (insn >> 16) & 0x3f;
    unsigned imms = (insn >> 10) & 0x3f;
    unsigned v = ((unsigned)n << 6) | ((~imms) & 0x3f);
    int len = -1;
    for (int i = 6; i >= 0; i--)
    {
        if (v & (1u << i))
        {
            len = i;
            break;
        }
    }
    if (len < 1 || bits < (1 << len))
    {
        *ok = 0;
        return 0;
    }
    unsigned levels = (1u << len) - 1;
    unsigned s = imms & levels;
    unsigned r = immr & levels;
    unsigned esize = 1u << len;
    uint64_t welem = s + 1 >= 64 ? ~0ull : ((1ull << (s + 1)) - 1);
    uint64_t emask = esize == 64 ? ~0ull : ((1ull << esize) - 1);
    if (r)
        welem = ((welem >> r) | (welem << (esize - r))) & emask;
    uint64_t mask = 0;
    for (unsigned i = 0; i < (unsigned)bits; i += esize)
        mask |= welem << i;
    *ok = 1;
    return mask;
}

/* Atomic memory operations (LSE) and load/store exclusive. The guest is
 * single-threaded here, so each operation is a plain read-modify-write and
 * the acquire/release suffixes select semantics x86's memory model already
 * provides. Called before the ordinary load/store decoders. */
static int a64_atomic_insn(struct a64_cpu *c, uint32_t insn)
{
    /* LDAPR/LDAPRB/LDAPRH: load-acquire RCpc; clang emits this form for
     * __ATOMIC_ACQUIRE loads. */
    if ((insn & 0x3ffffc00) == 0x38bfc000)
    {
        int size = 1 << ((insn >> 30) & 3);
        int rn = (insn >> 5) & 31;
        int rt = insn & 31;
        uint64_t v = a64_load(c, rd_sp(c, rn), size, 0);
        if (size == 8)
            wr_x(c, rt, v);
        else
            wr_w(c, rt, (uint32_t)v);
        c->pc += 4;
        return 1;
    }
    /* LSE atomic memory operations. o3=0 selects LD<opc>; o3=1 with opc=0
     * is SWP. Rs carries the operand and receives the old value. */
    if ((insn & 0x3f200c00) == 0x38200000)
    {
        int size = 1 << ((insn >> 30) & 3);
        int rs = (insn >> 16) & 31;
        int o3 = (insn >> 15) & 1;
        unsigned opc = (insn >> 12) & 7;
        int rn = (insn >> 5) & 31;
        int rt = insn & 31;
        if (o3 && opc != 0)
            return 0;
        uint64_t addr = rd_sp(c, rn);
        uint64_t m = a64_width_mask(size);
        uint64_t operand = rd_x(c, rs) & m;
        uint64_t old = a64_load(c, addr, size, 0);
        uint64_t neu;
        if (o3)
            neu = operand;
        else
        {
            switch (opc)
            {
            case 0: neu = old + operand; break;
            case 1: neu = old & ~operand; break;
            case 2: neu = old ^ operand; break;
            case 3: neu = old | operand; break;
            case 4:
                neu = a64_sign_extend(old, size) >=
                              a64_sign_extend(operand, size)
                          ? old : operand;
                break;
            case 5:
                neu = a64_sign_extend(old, size) <=
                              a64_sign_extend(operand, size)
                          ? old : operand;
                break;
            case 6: neu = old >= operand ? old : operand; break;
            default: neu = old <= operand ? old : operand; break;
            }
        }
        a64_store(c, addr, neu & m, size);
        if (size == 8)
            wr_x(c, rt, old);
        else
            wr_w(c, rt, (uint32_t)old);
        c->pc += 4;
        return 1;
    }
    /* CAS/CASA/CASL/CASAL: compare-and-swap; Rs receives the old value. */
    if ((insn & 0x3fa07c00) == 0x08a07c00)
    {
        int size = 1 << ((insn >> 30) & 3);
        int rs = (insn >> 16) & 31;
        int rn = (insn >> 5) & 31;
        int rt = insn & 31;
        uint64_t addr = rd_sp(c, rn);
        uint64_t m = a64_width_mask(size);
        uint64_t old = a64_load(c, addr, size, 0);
        if (old == (rd_x(c, rs) & m))
            a64_store(c, addr, rd_x(c, rt), size);
        if (size == 8)
            wr_x(c, rs, old);
        else
            wr_w(c, rs, (uint32_t)old);
        c->pc += 4;
        return 1;
    }
    /* Load/store exclusive pairs. A store attempt clears the monitor; the
     * status word is 0 on success and 1 otherwise. */
    if ((insn & 0x3ffffc00) == 0x085f7c00 ||
        (insn & 0x3ffffc00) == 0x085ffc00)
    {
        int size = 1 << ((insn >> 30) & 3);
        int rn = (insn >> 5) & 31;
        int rt = insn & 31;
        uint64_t addr = rd_sp(c, rn);
        uint64_t v = a64_load(c, addr, size, 0);
        if (size == 8)
            wr_x(c, rt, v);
        else
            wr_w(c, rt, (uint32_t)v);
        c->excl_valid = 1;
        c->excl_addr = addr;
        c->excl_size = size;
        c->pc += 4;
        return 1;
    }
    if ((insn & 0x3fe0fc00) == 0x08007c00 ||
        (insn & 0x3fe0fc00) == 0x0800fc00)
    {
        int size = 1 << ((insn >> 30) & 3);
        int rs = (insn >> 16) & 31;
        int rn = (insn >> 5) & 31;
        int rt = insn & 31;
        uint64_t addr = rd_sp(c, rn);
        int ok = c->excl_valid && c->excl_addr == addr &&
                 c->excl_size == size;
        if (ok)
            a64_store(c, addr, rd_x(c, rt), size);
        c->excl_valid = 0;
        wr_w(c, rs, ok ? 0 : 1);
        c->pc += 4;
        return 1;
    }
    /* LDAR/STLR: ordered loads and stores without a monitor. */
    if ((insn & 0x3ffffc00) == 0x08dffc00 ||
        (insn & 0x3ffffc00) == 0x089ffc00)
    {
        int is_load = (insn & 0x3ffffc00) == 0x08dffc00;
        int size = 1 << ((insn >> 30) & 3);
        int rn = (insn >> 5) & 31;
        int rt = insn & 31;
        uint64_t addr = rd_sp(c, rn);
        if (is_load)
        {
            uint64_t v = a64_load(c, addr, size, 0);
            if (size == 8)
                wr_x(c, rt, v);
            else
                wr_w(c, rt, (uint32_t)v);
        }
        else
            a64_store(c, addr, rd_x(c, rt), size);
        c->pc += 4;
        return 1;
    }
    /* CLREX clears the monitor; DMB/DSB/ISB need no work on x86. */
    if (insn == 0xd5033f5f)
    {
        c->excl_valid = 0;
        c->pc += 4;
        return 1;
    }
    if ((insn & 0xfffff09f) == 0xd503309f)
    {
        c->pc += 4;
        return 1;
    }
    return 0;
}

/* Bitfield move: UBFM/SBFM common cases. bitfield_fill covers
 * UBFM/SBFM (opc 2/0); BFM (opc 1) is not implemented. */
static uint64_t a64_bitfield(struct a64_cpu *c, uint32_t insn, int *ok)
{
    int sf = (insn >> 31) & 1;
    int bits = sf ? 64 : 32;
    unsigned immr = (insn >> 16) & 0x3f;
    unsigned imms = (insn >> 10) & 0x3f;
    int rn = (insn >> 5) & 31;
    uint64_t src = rd_x(c, rn);
    uint64_t m = mask_for(bits);
    uint64_t res;
    unsigned opc = (insn >> 29) & 3;
    *ok = 1;
    if (opc == 1) /* BFM: bit insert is not implemented */
    {
        *ok = 0;
        return 0;
    }
    if (imms >= immr)
    {
        unsigned width = imms - immr + 1;
        uint64_t low = (src >> immr) & ((width == 64) ? ~0ull
                                                      : ((1ull << width) - 1));
        res = low;
        if (((insn >> 29) & 3) == 0 && width < 64) /* SBFM */
        {
            if (low & (1ull << (width - 1)))
                res |= m & ~((1ull << width) - 1);
        }
    }
    else
    {
        uint64_t tmp = a64_ror(src, immr, bits);
        unsigned width = imms + 1;
        res = tmp & ((width == 64) ? ~0ull : ((1ull << width) - 1));
        if (((insn >> 29) & 3) == 0 && width < 64 &&
            (res & (1ull << (width - 1))))
            res |= m & ~((1ull << width) - 1);
    }
    return res & m;
}

/* Native call gates. The arm64 image's imports bind to x86_64 addresses;
 * when a branch leaves every arm64 image we identify the target and make
 * the call with the arm64 argument registers. */
struct native_gate {
    const char *name;
    void *addr;
    int kind;
};

enum {
    NG_PUTS = 1,
    NG_PRINTF,
    NG_FPRINTF,
    NG_SPRINTF,
    NG_SNPRINTF,
    NG_NSLOG,
    NG_EXIT,
    NG_MALLOC,
    NG_FREE,
    NG_MEMCPY,
    NG_MEMSET,
    NG_STRLEN,
    NG_STRCMP,
    NG_MSG_SEND,
    NG_MSG_SEND_SUPER2,
    NG_GET_CLASS,
    NG_SEL_REGISTER,
    NG_MMAP,
    NG_MPROTECT,
};

static struct native_gate g_gates[32];
static int g_ngates;

static void native_gate_add(const char *name, void *addr, int kind)
{
    if (!addr || g_ngates >= 32)
        return;
    g_gates[g_ngates].name = name;
    g_gates[g_ngates].addr = addr;
    g_gates[g_ngates].kind = kind;
    g_ngates++;
}

static void *gate_symbol(const char *name)
{
    void *p = iosim_lookup_shim(name);
    if (p)
        return p;
    return dlsym(RTLD_DEFAULT, name);
}

static void native_gates_init(void)
{
    if (g_ngates)
        return;
    native_gate_add("puts", gate_symbol("puts"), NG_PUTS);
    native_gate_add("printf", gate_symbol("printf"), NG_PRINTF);
    native_gate_add("fprintf", gate_symbol("fprintf"), NG_FPRINTF);
    native_gate_add("sprintf", gate_symbol("sprintf"), NG_SPRINTF);
    native_gate_add("snprintf", gate_symbol("snprintf"), NG_SNPRINTF);
    native_gate_add("NSLog", gate_symbol("NSLog"), NG_NSLOG);
    native_gate_add("exit", gate_symbol("exit"), NG_EXIT);
    native_gate_add("malloc", gate_symbol("malloc"), NG_MALLOC);
    native_gate_add("free", gate_symbol("free"), NG_FREE);
    native_gate_add("memcpy", gate_symbol("memcpy"), NG_MEMCPY);
    native_gate_add("memset", gate_symbol("memset"), NG_MEMSET);
    native_gate_add("strlen", gate_symbol("strlen"), NG_STRLEN);
    native_gate_add("strcmp", gate_symbol("strcmp"), NG_STRCMP);
    native_gate_add("objc_msgSend", (void *)&objc_msgSend, NG_MSG_SEND);
    native_gate_add("objc_msgSendSuper2", (void *)&objc_msgSendSuper2,
                    NG_MSG_SEND_SUPER2);
    native_gate_add("objc_getClass", gate_symbol("objc_getClass"),
                    NG_GET_CLASS);
    native_gate_add("sel_registerName", gate_symbol("sel_registerName"),
                    NG_SEL_REGISTER);
    native_gate_add("mmap", gate_symbol("mmap"), NG_MMAP);
    native_gate_add("mprotect", gate_symbol("mprotect"), NG_MPROTECT);
}

static int image_contains(struct iosim_image *img, uint64_t addr)
{
    for (int i = 0; i < img->nsegs; i++)
    {
        struct iosim_segment *s = &img->segs[i];
        if (!(s->initprot & 4))
            continue;
        uint64_t base = s->vmaddr + img->slide;
        if (addr >= base && addr < base + s->vmsize)
            return 1;
    }
    return 0;
}

/* Runtime-generated arm64 code: guest mmap/mprotect calls that ask for
 * PROT_EXEC register their ranges, so branches into them enter the
 * interpreter and the block translator instead of the native dispatch
 * path. The registry is per process; the guest is single-threaded. */
#define A64_MAX_EXEC_REGIONS 32
static struct
{
    uint64_t lo, hi;
} g_exec_regions[A64_MAX_EXEC_REGIONS];
static int g_nexec_regions;

static void a64_exec_region_add(uint64_t lo, uint64_t len)
{
    if (!len || g_nexec_regions >= A64_MAX_EXEC_REGIONS)
        return;
    uint64_t hi = lo + len;
    for (int i = 0; i < g_nexec_regions; i++)
    {
        if (lo <= g_exec_regions[i].hi && hi >= g_exec_regions[i].lo)
        {
            if (lo < g_exec_regions[i].lo)
                g_exec_regions[i].lo = lo;
            if (hi > g_exec_regions[i].hi)
                g_exec_regions[i].hi = hi;
            return;
        }
    }
    g_exec_regions[g_nexec_regions].lo = lo;
    g_exec_regions[g_nexec_regions].hi = hi;
    g_nexec_regions++;
}

static int a64_exec_region_contains(uint64_t addr)
{
    for (int i = 0; i < g_nexec_regions; i++)
        if (addr >= g_exec_regions[i].lo && addr < g_exec_regions[i].hi)
            return 1;
    return 0;
}

static int in_any_arm64_image(struct a64_cpu *c, uint64_t addr)
{
    return image_contains(c->img, addr) || a64_exec_region_contains(addr);
}

/* Returns the UTF-8 text behind an NSString object the guest passed to a
 * printf-family gate. Constant strings carry the bytes directly; other
 * strings ask their native description for UTF8String. */
static const char *a64_nsstring_cstr(uint64_t obj)
{
    if (!obj)
        return NULL;
    struct {
        void *isa;
        uint32_t flags;
        uint32_t pad;
        const char *cstr;
        uint64_t length;
    } *cs = (void *)(uintptr_t)obj;
    if (cs->flags == 0x7c8 && cs->cstr)
        return cs->cstr;
    void *text = objc_msgSend((void *)(uintptr_t)obj,
                              sel_registerName("UTF8String"));
    return (const char *)text;
}

/* Renders a printf-style format with Darwin arm64 variadic arguments,
 * which arrive on the stack one eight-byte slot each. Integer, pointer,
 * character, string and floating-point conversions are rendered; with
 * objects set, %@ asks the object for its description and UTF-8 text.
 * The rendered text is truncated to cap-1 bytes. */
static size_t a64_render_format(struct a64_cpu *c, const char *fmt,
                                char *out, size_t cap, int objects)
{
    uint64_t argbase = c->sp;
    int argi = 0;
    size_t o = 0;

    if (!fmt)
        fmt = "(null)";
    for (const char *p = fmt; *p && o + 1 < cap; p++)
    {
        if (*p != '%')
        {
            out[o++] = *p;
            continue;
        }
        p++;
        if (*p == '%')
        {
            out[o++] = '%';
            continue;
        }
        const char *spec_begin = p - 1;
        int is_long = 0;
        while (*p && strchr("-+ #0", *p))
            p++;
        while (*p >= '0' && *p <= '9')
            p++;
        if (*p == '.')
        {
            p++;
            while (*p >= '0' && *p <= '9')
                p++;
        }
        while (*p == 'l')
        {
            is_long = 1;
            p++;
        }
        while (*p == 'z' || *p == 't' || *p == 'j')
        {
            is_long = 1;
            p++;
        }
        while (*p == 'h')
            p++;
        uint64_t arg = a64_load(c, argbase + 8ull * (unsigned)argi, 8, 0);
        argi++;
        if (*p == 's')
        {
            const char *s = (const char *)(uintptr_t)arg;
            if (!s)
                s = "(null)";
            size_t l = strlen(s);
            if (l > cap - o - 1)
                l = cap - o - 1;
            memcpy(out + o, s, l);
            o += l;
        }
        else if (*p == '@' && objects)
        {
            const char *s = arg ? a64_nsstring_cstr(arg) : NULL;
            if (!s && arg)
            {
                void *desc = objc_msgSend((void *)(uintptr_t)arg,
                                          sel_registerName("description"));
                if (desc)
                    s = objc_msgSend(desc, sel_registerName("UTF8String"));
            }
            if (!s)
                s = "(null)";
            size_t l = strlen(s);
            if (l > cap - o - 1)
                l = cap - o - 1;
            memcpy(out + o, s, l);
            o += l;
        }
        else if (*p == 'd' || *p == 'i')
        {
            long long v = (long long)arg;
            if (!is_long)
                v = (int)v;
            o += (size_t)snprintf(out + o, cap - o, "%lld", v);
        }
        else if (*p == 'u' || *p == 'x' || *p == 'X')
        {
            unsigned long long v = arg;
            if (!is_long)
                v = (unsigned)v;
            const char *spec = *p == 'x' ? "%llx"
                               : *p == 'X' ? "%llX" : "%llu";
            o += (size_t)snprintf(out + o, cap - o, spec, v);
        }
        else if (*p == 'p')
        {
            o += (size_t)snprintf(out + o, cap - o, "%p",
                                  (void *)(uintptr_t)arg);
        }
        else if (*p == 'c')
        {
            out[o++] = (char)arg;
        }
        else if (*p == 'f' || *p == 'F' || *p == 'e' || *p == 'E' ||
                 *p == 'g' || *p == 'G' || *p == 'a' || *p == 'A')
        {
            /* Variadic doubles arrive in one stack slot; keep the
             * caller's flags and precision in the spec. */
            size_t sl = (size_t)(p - spec_begin + 1);
            char spec[32];
            if (sl >= sizeof spec)
                sl = sizeof spec - 1;
            memcpy(spec, spec_begin, sl);
            spec[sl] = 0;
            double d;
            memcpy(&d, &arg, 8);
            o += (size_t)snprintf(out + o, cap - o, spec, d);
        }
        else
        {
            out[o++] = '%';
            if (o + 1 < cap)
                out[o++] = *p;
        }
    }
    out[o] = 0;
    return o;
}

/* Runs one of the printf-family calls. Darwin arm64 passes anonymous
 * variadic arguments on the stack; the format's fixed position depends on
 * the function. NSLog's format is an NSString and may use %@. */
static int a64_variadic_call(struct a64_cpu *c, int kind, uint64_t *ret)
{
    char out[4096];
    if (kind == NG_PRINTF)
    {
        size_t n = a64_render_format(c, (const char *)(uintptr_t)c->x[0],
                                     out, sizeof(out), 0);
        fputs(out, stdout);
        fflush(stdout);
        *ret = (uint64_t)(int64_t)(int)n;
        return 1;
    }
    if (kind == NG_FPRINTF)
    {
        FILE *stream = (FILE *)(uintptr_t)c->x[0];
        size_t n = a64_render_format(c, (const char *)(uintptr_t)c->x[1],
                                     out, sizeof(out), 0);
        if (!stream)
            stream = stdout;
        fputs(out, stream);
        fflush(stream);
        *ret = (uint64_t)(int64_t)(int)n;
        return 1;
    }
    if (kind == NG_SPRINTF)
    {
        char *dst = (char *)(uintptr_t)c->x[0];
        size_t n = a64_render_format(c, (const char *)(uintptr_t)c->x[1],
                                     out, sizeof(out), 0);
        if (dst)
            memcpy(dst, out, n + 1);
        *ret = (uint64_t)(int64_t)(int)n;
        return 1;
    }
    if (kind == NG_SNPRINTF)
    {
        char *dst = (char *)(uintptr_t)c->x[0];
        size_t size = (size_t)c->x[1];
        size_t n = a64_render_format(c, (const char *)(uintptr_t)c->x[2],
                                     out, sizeof(out), 0);
        if (dst && size)
        {
            size_t k = n < size - 1 ? n : size - 1;
            memcpy(dst, out, k);
            dst[k] = 0;
        }
        *ret = (uint64_t)(int64_t)(int)n;
        return 1;
    }
    const char *fmt = a64_nsstring_cstr(c->x[0]);
    a64_render_format(c, fmt, out, sizeof(out), 1);
    fprintf(stderr, "NSLog: %s\n", out);
    fflush(stderr);
    *ret = 0;
    return 1;
}

static int a64_native_call(struct a64_cpu *c, uint64_t target, uint64_t *ret)
{
    native_gates_init();
    for (int i = 0; i < g_ngates; i++)
    {
        if ((uint64_t)(uintptr_t)g_gates[i].addr != target)
            continue;
        switch (g_gates[i].kind)
        {
        case NG_PUTS:
            *ret = (uint64_t)(int64_t)puts((const char *)(uintptr_t)c->x[0]);
            return 1;
        case NG_PRINTF:
        case NG_FPRINTF:
        case NG_SPRINTF:
        case NG_SNPRINTF:
        case NG_NSLOG:
            return a64_variadic_call(c, g_gates[i].kind, ret);
        case NG_EXIT:
            exit((int)c->x[0]);
        case NG_MALLOC:
            *ret = (uint64_t)(uintptr_t)malloc((size_t)c->x[0]);
            return 1;
        case NG_FREE:
            free((void *)(uintptr_t)c->x[0]);
            *ret = 0;
            return 1;
        case NG_MEMCPY:
            *ret = (uint64_t)(uintptr_t)memcpy((void *)(uintptr_t)c->x[0],
                                               (const void *)(uintptr_t)c->x[1],
                                               (size_t)c->x[2]);
            return 1;
        case NG_MEMSET:
            *ret = (uint64_t)(uintptr_t)memset((void *)(uintptr_t)c->x[0],
                                               (int)c->x[1], (size_t)c->x[2]);
            return 1;
        case NG_STRLEN:
            *ret = (uint64_t)strlen((const char *)(uintptr_t)c->x[0]);
            return 1;
        case NG_STRCMP:
            *ret = (uint64_t)(int64_t)strcmp(
                (const char *)(uintptr_t)c->x[0],
                (const char *)(uintptr_t)c->x[1]);
            return 1;
        case NG_GET_CLASS:
            *ret = (uint64_t)(uintptr_t)objc_getClass(
                (const char *)(uintptr_t)c->x[0]);
            return 1;
        case NG_SEL_REGISTER:
            *ret = (uint64_t)(uintptr_t)sel_registerName(
                (const char *)(uintptr_t)c->x[0]);
            return 1;
        case NG_MMAP: {
            /* Darwin flags: MAP_SHARED 0x1, MAP_PRIVATE 0x2, MAP_FIXED
             * 0x10, MAP_NORESERVE 0x40, MAP_JIT 0x800, MAP_ANON 0x1000.
             * Linux wants MAP_ANONYMOUS 0x20 and MAP_NORESERVE 0x4000. */
            int dflags = (int)c->x[3];
            int flags = dflags & (0x1 | 0x2 | 0x10);
            if (dflags & 0x1000)
                flags |= MAP_ANONYMOUS;
            if (dflags & 0x40)
                flags |= MAP_NORESERVE;
            int prot = (int)c->x[2];
            size_t len = (size_t)c->x[1];
            void *p = mmap((void *)(uintptr_t)c->x[0], len, prot, flags,
                           (int)c->x[4], (long)c->x[5]);
            if (p != MAP_FAILED && (prot & PROT_EXEC))
                a64_exec_region_add((uint64_t)(uintptr_t)p, len);
            *ret = p == MAP_FAILED ? (uint64_t)-1
                                   : (uint64_t)(uintptr_t)p;
            return 1;
        }
        case NG_MPROTECT: {
            uint64_t addr = c->x[0];
            size_t len = (size_t)c->x[1];
            int prot = (int)c->x[2];
            int rc = mprotect((void *)(uintptr_t)addr, len, prot);
            if (rc == 0)
            {
                if (prot & PROT_EXEC)
                    a64_exec_region_add(addr, len);
                /* The range may have been rewritten as code or data; drop
                 * translations that started in it. The arena is not
                 * reclaimed, so a running block stays valid. */
                a64_jit_invalidate_range(addr, addr + len);
            }
            *ret = (uint64_t)(int64_t)rc;
            return 1;
        }
        case NG_MSG_SEND:
            return 0; /* handled by the caller, needs the method encoding */
        case NG_MSG_SEND_SUPER2:
            return 2; /* handled by the caller, needs a super lookup */
        }
    }
    /* Any other shim is a plain native function: marshal the arm64
     * argument registers into the x86_64 ones. The call gate covers six
     * integer and eight floating-point arguments, which is what the
     * runtime and framework C entry points use. Variadic functions cannot
     * be called this way and keep their dedicated gates. */
    const char *shim_name = NULL;
    int known = iosim_shim_lookup_addr((void *)(uintptr_t)target, &shim_name);
    if (!known)
        known = iosim_native_symbol_lookup((void *)(uintptr_t)target,
                                           &shim_name);
    const char *base_name = shim_name && shim_name[0] == '_'
                                ? shim_name + 1
                                : shim_name;
    if (known && base_name)
    {
        int vk = 0;
        if (strcmp(base_name, "printf") == 0)
            vk = NG_PRINTF;
        else if (strcmp(base_name, "fprintf") == 0)
            vk = NG_FPRINTF;
        else if (strcmp(base_name, "sprintf") == 0)
            vk = NG_SPRINTF;
        else if (strcmp(base_name, "snprintf") == 0)
            vk = NG_SNPRINTF;
        else if (strcmp(base_name, "NSLog") == 0)
            vk = NG_NSLOG;
        if (vk)
            return a64_variadic_call(c, vk, ret);
    }
    if (known && base_name)
    {
        uint64_t gp_args[4] = {c->x[2], c->x[3], c->x[4], c->x[5]};
        uint64_t sse_args[8];
        for (int i = 0; i < 8; i++)
            sse_args[i] = c->d[i];
        uint64_t retbuf[6] = {0, 0, 0, 0, 0, 0};
        iosim_arm64_native_invoke((void *)(uintptr_t)target,
                                  (void *)(uintptr_t)c->x[0],
                                  (void *)(uintptr_t)c->x[1], gp_args,
                                  sse_args, retbuf);
        /* Both possible scalar results are published; the caller reads the
         * one its own type calls for. */
        *ret = retbuf[0];
        uint64_t fpr = retbuf[1];
        if (c->trace)
            fprintf(stderr, "arm64 native call %s -> 0x%llx\n", base_name,
                    (unsigned long long)retbuf[0]);
        c->x[0] = retbuf[0];
        c->d[0] = fpr;
        return 1;
    }
    fprintf(stderr,
            "iosim: arm64: unsupported native call to 0x%llx from pc 0x%llx\n",
            (unsigned long long)target, (unsigned long long)c->pc);
    return -1;
}

static const char *a64_skip_qualifiers(const char *p)
{
    while (*p && strchr("rnNoORVAg", *p))
        p++;
    return p;
}

static const char *a64_skip_type(const char *p)
{
    p = a64_skip_qualifiers(p);
    if (!*p)
        return p;
    if (*p == '{' || *p == '(')
    {
        char open = *p;
        char close = open == '{' ? '}' : ')';
        int depth = 0;
        do
        {
            if (*p == open)
                depth++;
            else if (*p == close)
                depth--;
            p++;
        } while (*p && depth > 0);
        return p;
    }
    if (*p == '[')
    {
        while (*p && *p != ']')
            p++;
        if (*p)
            p++;
        return p;
    }
    if (*p == '^')
        return a64_skip_type(p + 1);
    if (*p == 'b')
    {
        p++;
        while (*p >= '0' && *p <= '9')
            p++;
        return p;
    }
    if (*p == '@')
    {
        p++;
        if (*p == '?')
            return p + 1;
        if (*p == '"')
        {
            p++;
            while (*p && *p != '"')
                p++;
            if (*p)
                p++;
        }
        return p;
    }
    if (*p == '"')
    {
        p++;
        while (*p && *p != '"')
            p++;
        if (*p)
            p++;
        return p;
    }
    return p + 1;
}

/* Type encodings carry frame offsets between arguments ("i16@0:8"). */
static const char *a64_skip_number(const char *p)
{
    if (*p == '-')
        p++;
    while (*p >= '0' && *p <= '9')
        p++;
    return p;
}

/* Field metadata for an aggregate type encoding. The native bridge needs
 * the total size, whether every leaf is floating point, and whether the
 * leaves form a homogeneous floating-point aggregate (one to four fields
 * of the same FP type), which arm64 returns in d0..d3. */
struct a64_type_meta {
    int size;
    int all_sse;
    int fp_count;
    int fp_size; /* 0 = no FP leaf yet, -1 = mixed, 4 or 8 = homogeneous */
    int ok;
};

static const char *a64_measure_type(const char *p, struct a64_type_meta *m,
                                    int depth)
{
    if (depth > 16)
    {
        m->ok = 0;
        return p;
    }
    p = a64_skip_qualifiers(p);
    if (!*p)
    {
        m->ok = 0;
        return p;
    }
    if (*p == '{' || *p == '(')
    {
        char close = *p == '{' ? '}' : ')';
        p++;
        while (*p && *p != '=' && *p != close)
            p++;
        struct a64_type_meta total;
        memset(&total, 0, sizeof total);
        total.all_sse = 1;
        total.ok = 1;
        if (*p == '=')
        {
            p++;
            while (*p && *p != close)
            {
                struct a64_type_meta f;
                memset(&f, 0, sizeof f);
                f.ok = 1;
                p = a64_measure_type(p, &f, depth + 1);
                if (!f.ok)
                {
                    m->ok = 0;
                    return p;
                }
                total.size += f.size;
                if (!f.all_sse)
                    total.all_sse = 0;
                total.fp_count += f.fp_count;
                if (f.fp_size == -1)
                    total.fp_size = -1;
                else if (f.fp_size != 0)
                {
                    if (total.fp_size == 0)
                        total.fp_size = f.fp_size;
                    else if (total.fp_size != f.fp_size)
                        total.fp_size = -1;
                }
            }
        }
        if (*p == close)
            p++;
        *m = total;
        return p;
    }
    if (*p == '[')
    {
        p++;
        int n = 0;
        while (*p >= '0' && *p <= '9')
        {
            n = n * 10 + (*p - '0');
            p++;
        }
        struct a64_type_meta e;
        memset(&e, 0, sizeof e);
        e.ok = 1;
        p = a64_measure_type(p, &e, depth + 1);
        if (*p == ']')
            p++;
        if (!e.ok)
        {
            m->ok = 0;
            return p;
        }
        if (n < 1)
            n = 1;
        m->size = e.size * n;
        m->all_sse = e.all_sse;
        m->fp_count = e.fp_count * n;
        m->fp_size = e.fp_size;
        m->ok = 1;
        return p;
    }
    if (*p == '^')
    {
        struct a64_type_meta e;
        memset(&e, 0, sizeof e);
        e.ok = 1;
        p = a64_measure_type(p + 1, &e, depth + 1);
        m->size = 8;
        m->all_sse = 0;
        m->fp_count = 0;
        m->fp_size = 0;
        m->ok = e.ok;
        return p;
    }
    if (*p == 'b')
    {
        p++;
        int n = 0;
        while (*p >= '0' && *p <= '9')
        {
            n = n * 10 + (*p - '0');
            p++;
        }
        m->size = (n + 7) / 8;
        m->all_sse = 0;
        m->fp_count = 0;
        m->fp_size = 0;
        m->ok = 1;
        return p;
    }
    if (*p == '@')
    {
        p++;
        if (*p == '?')
            p++;
        else if (*p == '"')
        {
            p++;
            while (*p && *p != '"')
                p++;
            if (*p)
                p++;
        }
        m->size = 8;
        m->all_sse = 0;
        m->fp_count = 0;
        m->fp_size = 0;
        m->ok = 1;
        return p;
    }
    if (*p == '"')
    {
        p++;
        while (*p && *p != '"')
            p++;
        if (*p)
            p++;
        m->size = 8;
        m->all_sse = 0;
        m->fp_count = 0;
        m->fp_size = 0;
        m->ok = 1;
        return p;
    }
    m->all_sse = 0;
    m->fp_count = 0;
    m->fp_size = 0;
    m->ok = 1;
    switch (*p)
    {
    case 'c': case 'C': case 'B':
        m->size = 1; return p + 1;
    case 's': case 'S':
        m->size = 2; return p + 1;
    case 'i': case 'I':
        m->size = 4; return p + 1;
    case 'l': case 'L': case 'q': case 'Q':
        m->size = 8; return p + 1;
    case 'f':
        m->size = 4; m->all_sse = 1; m->fp_count = 1; m->fp_size = 4;
        return p + 1;
    case 'd':
        m->size = 8; m->all_sse = 1; m->fp_count = 1; m->fp_size = 8;
        return p + 1;
    case 'v':
        m->size = 0; return p + 1;
    default:
        m->size = 8; return p + 1;
    }
}

/* Calls a native x86_64 IMP with arguments marshalled from the arm64
 * registers using the method's own type encoding. */
static int a64_native_imp(struct a64_cpu *c, void *imp)
{
    const char *types = objc_lookup_method_types(
        (void *)(uintptr_t)c->x[0], (void *)(uintptr_t)c->x[1]);
    if (!types)
        return a64_fail(c, "no method types for native IMP", 0);
    const char *ret_start = a64_skip_qualifiers(types);
    char rtc = *ret_start;
    struct a64_type_meta ret;
    memset(&ret, 0, sizeof ret);
    ret.ok = 1;
    int ret_agg = (rtc == '{' || rtc == '(' || rtc == '[');
    if (ret_agg)
    {
        a64_measure_type(ret_start, &ret, 0);
        if (!ret.ok || ret.size <= 0)
            return a64_fail(c, "unsupported aggregate return type", 0);
    }
    int ret_hfa = ret_agg && ret.all_sse && ret.fp_count >= 1 &&
                  ret.fp_count <= 4 && ret.fp_size > 0;
    const char *p = a64_skip_type(ret_start);
    p = a64_skip_number(p);
    p = a64_skip_type(p); /* self */
    p = a64_skip_number(p);
    p = a64_skip_type(p); /* _cmd */
    p = a64_skip_number(p);

    uint64_t gp_args[4] = {0, 0, 0, 0};
    uint64_t sse_args[8] = {0, 0, 0, 0, 0, 0, 0, 0};
    int ngp = 0, nsse = 0;
    int agp = 2, asse = 0;
    unsigned long stack_off = 0;
    unsigned char stack_args[1024];
    size_t stack_len = 0;
    while (*p)
    {
        p = a64_skip_qualifiers(p);
        const char *arg_start = p;
        char t = *p;
        p = a64_skip_type(p);
        p = a64_skip_number(p);
        if (!t || t == 'v')
            break;
        if (t == '{' || t == '(' || t == '[' || t == 'D')
        {
            /* Aggregates up to sixteen bytes map register-for-register.
             * Larger ones are passed by reference on arm64 and by value
             * on the x86 stack, so copy the caller's object into the
             * x86 argument area. */
            struct a64_type_meta am;
            memset(&am, 0, sizeof am);
            am.ok = 1;
            a64_measure_type(arg_start, &am, 0);
            if (!am.ok || am.size <= 0)
                return a64_fail(c, "unsupported aggregate argument", 0);
            int am_hfa = am.all_sse && am.fp_count >= 1 &&
                         am.fp_count <= 4 && am.fp_size > 0;
            if (am_hfa && am.size > 16)
            {
                /* An HFA of three or four doubles travels in d0..d3 on
                 * arm64 and in memory on x86. */
                size_t padded = ((size_t)am.size + 7) & ~(size_t)7;
                if (stack_len + padded > sizeof stack_args)
                    return a64_fail(c, "stack argument area overflow", 0);
                if (asse + am.fp_count > 8)
                    return a64_fail(c,
                                    "aggregate argument on stack "
                                    "unsupported", 0);
                for (int i = 0; i < am.fp_count; i++)
                    ((uint64_t *)(stack_args + stack_len))[i] = c->d[asse++];
                memset(stack_args + stack_len + am.size, 0,
                       padded - (size_t)am.size);
                stack_len += padded;
                continue;
            }
            if (am.size > 16)
            {
                uint64_t ptr;
                if (agp < 8)
                    ptr = c->x[agp++];
                else
                {
                    ptr = a64_load(c, c->sp + stack_off, 8, 0);
                    stack_off += 8;
                }
                if (!ptr)
                    return a64_fail(c, "null aggregate argument", 0);
                size_t padded = ((size_t)am.size + 7) & ~(size_t)7;
                if (stack_len + padded > sizeof stack_args)
                    return a64_fail(c, "stack argument area overflow", 0);
                memcpy(stack_args + stack_len,
                       (const void *)(uintptr_t)ptr, (size_t)am.size);
                memset(stack_args + stack_len + am.size, 0,
                       padded - (size_t)am.size);
                stack_len += padded;
                continue;
            }
            if (!am.all_sse || am.fp_count == 0 || am.fp_size <= 0)
            {
                if (am.fp_count != 0)
                    return a64_fail(c, "mixed aggregate argument", 0);
                int slots = (am.size + 7) / 8;
                for (int i = 0; i < slots; i++)
                {
                    if (agp >= 8)
                        return a64_fail(c,
                                        "aggregate argument on stack "
                                        "unsupported", 0);
                    if (ngp >= 4)
                        return a64_fail(c, "too many integer arguments", 0);
                    gp_args[ngp++] = c->x[agp++];
                }
            }
            else if (am.fp_size == 8)
            {
                for (int i = 0; i < am.fp_count; i++)
                {
                    if (asse >= 8)
                        return a64_fail(c,
                                        "aggregate argument on stack "
                                        "unsupported", 0);
                    if (nsse >= 8)
                        return a64_fail(c, "too many SSE arguments", 0);
                    sse_args[nsse++] = c->d[asse++];
                }
            }
            else
            {
                for (int i = 0; i < am.fp_count; i += 2)
                {
                    if (asse >= 8)
                        return a64_fail(c,
                                        "aggregate argument on stack "
                                        "unsupported", 0);
                    uint64_t lo = c->d[asse++] & 0xffffffffu;
                    uint64_t hi = 0;
                    if (i + 1 < am.fp_count)
                    {
                        if (asse >= 8)
                            return a64_fail(c,
                                            "aggregate argument on stack "
                                            "unsupported", 0);
                        hi = c->d[asse++] & 0xffffffffu;
                    }
                    if (nsse >= 8)
                        return a64_fail(c, "too many SSE arguments", 0);
                    sse_args[nsse++] = lo | (hi << 32);
                }
            }
            continue;
        }
        int is_fp = (t == 'f' || t == 'd');
        uint64_t v;
        if (is_fp)
        {
            if (asse < 8)
                v = c->d[asse++];
            else
            {
                v = a64_load(c, c->sp + stack_off, 8, 0);
                stack_off += 8;
            }
            if (nsse >= 8)
                return a64_fail(c, "too many SSE arguments", 0);
            sse_args[nsse++] = v;
        }
        else
        {
            if (agp < 8)
                v = c->x[agp++];
            else
            {
                v = a64_load(c, c->sp + stack_off, 8, 0);
                stack_off += 8;
            }
            if (ngp >= 4)
                return a64_fail(c, "too many integer arguments", 0);
            gp_args[ngp++] = v;
        }
    }

    uint64_t retbuf[6] = {0, 0, 0, 0, 0, 0};
    if (ret_agg && ret.size > 16)
    {
        if (ngp > 3)
            return a64_fail(c, "too many integer arguments for struct return",
                            0);
        /* HFAs return in v0..v3 even when larger than sixteen bytes; x86
         * uses a hidden buffer for those sizes. */
        uint64_t tmp[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        uint64_t buffer = ret_hfa ? (uint64_t)(uintptr_t)tmp : c->x[8];
        if (!buffer)
            return a64_fail(c, "null struct return buffer", 0);
        if (stack_len)
            iosim_arm64_native_invoke_stack_stret(
                imp, (void *)(uintptr_t)buffer,
                (void *)(uintptr_t)c->x[0], (void *)(uintptr_t)c->x[1],
                gp_args, sse_args, stack_args, stack_len);
        else
            iosim_arm64_native_invoke_stret(imp, (void *)(uintptr_t)buffer,
                                            (void *)(uintptr_t)c->x[0],
                                            (void *)(uintptr_t)c->x[1],
                                            gp_args, sse_args);
        if (ret_hfa)
        {
            for (int i = 0; i < ret.fp_count; i++)
                c->d[i] = ret.fp_size == 8
                              ? tmp[i]
                              : (tmp[i / 2] >> (32 * (i & 1))) & 0xffffffffu;
            for (int i = 0; i < 4; i++)
                c->dhi[i] = 0;
        }
        return 0;
    }
    if (stack_len)
        iosim_arm64_native_invoke_stack(
            imp, (void *)(uintptr_t)c->x[0], (void *)(uintptr_t)c->x[1],
            gp_args, sse_args, stack_args, stack_len, retbuf);
    else
        iosim_arm64_native_invoke(imp, (void *)(uintptr_t)c->x[0],
                                  (void *)(uintptr_t)c->x[1], gp_args,
                                  sse_args, retbuf);
    if (ret_agg)
    {
        if (ret_hfa)
        {
            for (int i = 0; i < ret.fp_count; i++)
            {
                uint64_t word = ret.fp_size == 8 ? (i < 1 ? retbuf[1]
                                                          : retbuf[4])
                                                 : (i < 2 ? retbuf[1]
                                                          : retbuf[4]);
                c->d[i] = ret.fp_size == 8
                              ? word
                              : (word >> (32 * (i & 1))) & 0xffffffffu;
            }
            for (int i = 0; i < 4; i++)
                c->dhi[i] = 0;
        }
        else if (ret.all_sse && ret.fp_size == -1)
        {
            /* Mixed floating-point fields: arm64 uses integer registers. */
            c->x[0] = retbuf[1];
            c->x[1] = retbuf[4];
        }
        else if (ret.all_sse)
        {
            c->d[0] = retbuf[1];
            c->d[1] = retbuf[4];
            c->dhi[0] = 0;
            c->dhi[1] = 0;
        }
        else
        {
            c->x[0] = retbuf[0];
            c->x[1] = retbuf[3];
        }
    }
    else if (rtc == 'f')
    {
        c->d[0] = retbuf[1] & 0xffffffffu;
    }
    else if (rtc == 'd')
    {
        c->d[0] = retbuf[1];
    }
    else
    {
        c->x[0] = retbuf[0];
    }
    return 0;
}

/* A branch left the arm64 images: call the native target and decide where
 * execution resumes. objc_msgSend is special: an arm64 IMP is entered with
 * the original argument registers and the caller's return address, while a
 * native method implementation is called through the type-encoding bridge. */
static int a64_dispatch_native(struct a64_cpu *c, uint64_t target,
                               uint64_t next, int is_bl, uint64_t *pc_out)
{
    uint64_t saved = c->x[30];
    if (is_bl)
        c->x[30] = next;
    uint64_t ret = 0;
    int r = a64_native_call(c, target, &ret);
    if (r < 0)
        return -1;
    if (r == 2)
    {
        /* objc_msgSendSuper2(super, sel, ...): resolve from the superclass
         * of the class the super struct names, then enter the IMP with the
         * receiver in x0 and the original argument registers untouched. */
        void *sel = (void *)(uintptr_t)c->x[1];
        void *sup = (void *)(uintptr_t)c->x[0];
        void *receiver = sup ? *(void **)sup : NULL;
        if (!receiver)
        {
            c->x[0] = 0;
            *pc_out = is_bl ? next : saved;
            return 0;
        }
        void *imp = objc_lookup_super_imp(sup, sel);
        if (!imp)
            return -1;
        c->x[0] = (uint64_t)(uintptr_t)receiver;
        if (in_any_arm64_image(c, (uint64_t)(uintptr_t)imp))
        {
            if (c->trace)
                fprintf(stderr, "arm64 msgSendSuper2 %s -> arm64 imp %p\n",
                        sel ? (const char *)sel : "(null)", imp);
            *pc_out = (uint64_t)(uintptr_t)imp;
            return 0;
        }
        if (c->trace)
            fprintf(stderr, "arm64 msgSendSuper2 %s -> native imp %p\n",
                    sel ? (const char *)sel : "(null)", imp);
        if (a64_native_imp(c, imp) != 0)
            return -1;
        *pc_out = is_bl ? next : saved;
        return 0;
    }
    if (r == 0)
    {
        void *sel = (void *)(uintptr_t)c->x[1];
        void *imp = objc_lookup_imp((void *)(uintptr_t)c->x[0], sel);
        if (!imp)
        {
            fprintf(stderr,
                    "iosim: arm64: objc_msgSend: no IMP for %s "
                    "(receiver %p)\n",
                    sel ? (const char *)sel : "(null)",
                    (void *)(uintptr_t)c->x[0]);
            return -1;
        }
        if (in_any_arm64_image(c, (uint64_t)(uintptr_t)imp))
        {
            if (c->trace)
                fprintf(stderr, "arm64 msgSend %s -> arm64 imp %p\n",
                        sel ? (const char *)sel : "(null)", imp);
            *pc_out = (uint64_t)(uintptr_t)imp;
            return 0;
        }
        if (c->trace)
            fprintf(stderr, "arm64 msgSend %s -> native imp %p\n",
                    sel ? (const char *)sel : "(null)", imp);
        if (a64_native_imp(c, imp) != 0)
            return -1;
        if (c->trace)
            fprintf(stderr, "arm64 msgSend %s native returned 0x%llx\n",
                    sel ? (const char *)sel : "(null)",
                    (unsigned long long)c->x[0]);
        *pc_out = is_bl ? next : saved;
        return 0;
    }
    c->x[0] = ret;
    *pc_out = is_bl ? next : saved;
    return 0;
}

/* Lane access for AdvSIMD operations over a 128-bit register image. */
static uint64_t a64_lane_get(const uint8_t *v, int index, int esize)
{
    uint64_t out = 0;
    memcpy(&out, v + index * (esize / 8), (size_t)(esize / 8));
    return out;
}

static void a64_lane_put(uint8_t *v, int index, int esize, uint64_t val)
{
    memcpy(v + index * (esize / 8), &val, (size_t)(esize / 8));
}

static int64_t a64_lane_signed(uint64_t v, int esize)
{
    switch (esize)
    {
    case 8:
        return (int8_t)v;
    case 16:
        return (int16_t)v;
    case 32:
        return (int32_t)v;
    default:
        return (int64_t)v;
    }
}

/* Runs arm64 code until the top-level return address (0) is used. Returns
 * the final x0 as the process status, or -1 on an interpretation error. */
static int a64_run(struct a64_cpu *c)
{
    for (;;)
    {
        /* Returning to the sentinel ends this interpreter entry, whether
         * the guest returned directly or tail-called a native function. */
        if (c->pc == A64_RETURN_SENTINEL)
            return (int)(int64_t)c->x[0];
        if (c->step_limit && c->steps >= c->step_limit)
        {
            c->step_done = 1;
            return (int)(int64_t)c->x[0];
        }
        c->steps++;
        uint32_t insn;
        memcpy(&insn, (const void *)(uintptr_t)c->pc, sizeof insn);
        if (c->trace)
            fprintf(stderr, "arm64 pc=0x%llx insn=0x%08x\n",
                    (unsigned long long)c->pc, insn);
        uint64_t next = c->pc + 4;

        /* RET */
        if ((insn & 0xfffffc1f) == 0xd65f0000)
        {
            int rn = (insn >> 5) & 31;
            uint64_t target = rd_x(c, rn);
            if (target == A64_RETURN_SENTINEL)
                return (int)(int64_t)c->x[0];
            c->pc = target;
            continue;
        }
        /* B / BL */
        if ((insn & 0x7c000000) == 0x14000000)
        {
            int is_bl = (insn >> 31) & 1;
            int64_t off = (int64_t)(insn & 0x03ffffff);
            if (off & (1 << 25))
                off -= (1 << 26);
            off <<= 2;
            uint64_t target = c->pc + (uint64_t)off;
            if (!in_any_arm64_image(c, target))
            {
                uint64_t pc = 0;
                if (a64_dispatch_native(c, target, next, is_bl, &pc) != 0)
                    return -1;
                c->pc = pc;
                continue;
            }
            if (is_bl)
                c->x[30] = next;
            c->pc = target;
            continue;
        }
        /* B.cond */
        if ((insn & 0xff000010) == 0x54000000)
        {
            unsigned cond = insn & 0xf;
            int64_t off = (int64_t)((insn >> 5) & 0x7ffff);
            if (off & (1 << 18))
                off -= (1 << 19);
            off <<= 2;
            c->pc = a64_cond(c->nzcv, cond) ? c->pc + (uint64_t)off : next;
            continue;
        }
        /* CBZ / CBNZ */
        if ((insn & 0x7e000000) == 0x34000000)
        {
            int sf = (insn >> 31) & 1;
            int nz = (insn >> 24) & 1;
            int rt = insn & 31;
            int64_t off = (int64_t)((insn >> 5) & 0x7ffff);
            if (off & (1 << 18))
                off -= (1 << 19);
            off <<= 2;
            uint64_t v = sf ? c->x[rt] : (uint32_t)c->x[rt];
            int zero = (v == 0);
            c->pc = (zero != nz) ? c->pc + (uint64_t)off : next;
            continue;
        }
        /* TBZ / TBNZ */
        if ((insn & 0x7e000000) == 0x36000000)
        {
            int b5 = (insn >> 31) & 1;
            int op = (insn >> 24) & 1;
            int b40 = (insn >> 19) & 31;
            int rt = insn & 31;
            int bit = (b5 << 5) | b40;
            int64_t off = (int64_t)((insn >> 5) & 0x3fff);
            if (off & (1 << 13))
                off -= (1 << 14);
            off <<= 2;
            int set = (c->x[rt] >> bit) & 1;
            c->pc = (set != op) ? next : c->pc + (uint64_t)off;
            continue;
        }
        /* BR / BLR */
        if ((insn & 0xfffffc1f) == 0xd61f0000 ||
            (insn & 0xfffffc1f) == 0xd63f0000)
        {
            int is_blr = (insn & 0x00200000) != 0;
            int rn = (insn >> 5) & 31;
            uint64_t target = rd_x(c, rn);
            if (target == 0)
            {
                fprintf(stderr, "iosim: arm64: branch to null at 0x%llx\n",
                        (unsigned long long)c->pc);
                return -1;
            }
            if (!in_any_arm64_image(c, target))
            {
                uint64_t pc = 0;
                if (a64_dispatch_native(c, target, next, is_blr, &pc) != 0)
                    return -1;
                c->pc = pc;
                continue;
            }
            if (is_blr)
                c->x[30] = next;
            c->pc = target;
            continue;
        }
        /* MOVZ / MOVN / MOVK */
        if ((insn & 0x7f800000) == 0x52800000 ||
            (insn & 0x7f800000) == 0x12800000 ||
            (insn & 0x7f800000) == 0x72800000)
        {
            int sf = (insn >> 31) & 1;
            unsigned hw = (insn >> 21) & 3;
            uint64_t imm = (insn >> 5) & 0xffff;
            int rd = insn & 31;
            uint64_t v;
            uint64_t m = sf ? ~0ull : 0xffffffffull;
            uint64_t shifted = (imm << (hw * 16)) & m;
            if ((insn & 0x7f800000) == 0x12800000)
                v = (~shifted) & m;
            else if ((insn & 0x7f800000) == 0x72800000)
                v = (c->x[rd] & ~(0xffffull << (hw * 16))) | shifted;
            else
                v = shifted;
            v &= m;
            wr_x(c, rd, v);
            c->pc = next;
            continue;
        }
        /* ADR / ADRP */
        if ((insn & 0x1f000000) == 0x10000000)
        {
            int is_page = (insn & 0x80000000) != 0;
            uint64_t immlo = (insn >> 29) & 3;
            uint64_t immhi = (insn >> 5) & 0x7ffff;
            int64_t imm = (int64_t)((immhi << 2) | immlo);
            if (imm & (1ll << 20))
                imm -= (1ll << 21);
            int rd = insn & 31;
            uint64_t base = c->pc;
            if (is_page)
            {
                imm <<= 12;
                base &= ~0xfffull;
            }
            wr_x(c, rd, base + (uint64_t)imm);
            c->pc = next;
            continue;
        }
        /* ADD / SUB (immediate) */
        if ((insn & 0x1f000000) == 0x11000000)
        {
            int sf = (insn >> 31) & 1;
            int sub = (insn >> 30) & 1;
            int setflags = (insn >> 29) & 1;
            unsigned shift = (insn >> 22) & 1;
            uint64_t imm = (insn >> 10) & 0xfff;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            int bits = sf ? 64 : 32;
            if (shift)
                imm <<= 12;
            uint64_t a = rn == 31 ? c->sp : c->x[rn];
            uint64_t res = sub ? a64_sub_flags(c, a, imm, bits, setflags)
                               : a64_add_flags(c, a, imm, bits, setflags);
            if (setflags)
                wr_x(c, rd, res);
            else if (rd == 31)
                c->sp = res;
            else
                wr_x(c, rd, res);
            c->pc = next;
            continue;
        }
        /* ADD / SUB (shifted or extended register) */
        if ((insn & 0x1f200000) == 0x0b000000 ||
            (insn & 0x1f200000) == 0x0b200000)
        {
            int sf = (insn >> 31) & 1;
            int sub = (insn >> 30) & 1;
            int setflags = (insn >> 29) & 1;
            int extended = (insn & 0x00200000) != 0;
            int bits = sf ? 64 : 32;
            int rm = (insn >> 16) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            uint64_t b = rd_x(c, rm);
            if (extended)
            {
                unsigned option = (insn >> 13) & 7;
                unsigned shift = (insn >> 10) & 7;
                switch (option)
                {
                case 0: b = (uint8_t)b; break;               /* UXTB */
                case 1: b = (uint16_t)b; break;              /* UXTH */
                case 2: b = (uint32_t)b; break;              /* UXTW */
                case 3: b &= ~0ull; break;                   /* UXTX */
                case 4: b = (uint64_t)(int64_t)(int8_t)b; break;
                case 5: b = (uint64_t)(int64_t)(int16_t)b; break;
                case 6: b = (uint64_t)(int64_t)(int32_t)b; break;
                case 7: break;                               /* SXTX */
                }
                b <<= shift;
            }
            else
            {
                unsigned shift_type = (insn >> 22) & 3;
                unsigned amount = (insn >> 10) & 0x3f;
                if (bits == 32)
                {
                    amount &= 31;
                    b = (uint32_t)b;
                }
                if (shift_type == 0)
                    b <<= amount;
                else if (shift_type == 1)
                    b >>= amount;
                else if (shift_type == 2)
                    b = (uint64_t)((int64_t)(b << (64 - bits)) >>
                                   (64 - bits)) >> amount;
            }
            uint64_t a = rn == 31 ? c->sp : c->x[rn];
            uint64_t res = sub ? a64_sub_flags(c, a, b, bits, setflags)
                               : a64_add_flags(c, a, b, bits, setflags);
            if (rd == 31 && !setflags)
                c->sp = res;
            else
                wr_x(c, rd, res);
            c->pc = next;
            continue;
        }
        /* Logical (shifted register) */
        if ((insn & 0x1f000000) == 0x0a000000)
        {
            int sf = (insn >> 31) & 1;
            int bits = sf ? 64 : 32;
            unsigned opc = (insn >> 29) & 3;
            unsigned shift_type = (insn >> 22) & 3;
            unsigned amount = (insn >> 10) & 0x3f;
            int rm = (insn >> 16) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            uint64_t b = rd_x(c, rm);
            uint64_t m = mask_for(bits);
            if (bits == 32)
                amount &= 31;
            if (shift_type == 0)
                b = (b << amount) & m;
            else if (shift_type == 1)
                b = (b & m) >> amount;
            else if (shift_type == 2)
                b = (uint64_t)((int64_t)(b << (64 - bits)) >> (64 - bits)) >>
                    amount;
            else
                b = a64_ror(b, amount, bits);
            if (insn & 0x00200000) /* N: BIC/ORN/EON/BICS invert */
                b = (~b) & m;
            uint64_t a = rd_x(c, rn);
            uint64_t res;
            if (opc == 0)
                res = a & b;
            else if (opc == 1)
                res = a | b;
            else if (opc == 2)
                res = a ^ b;
            else
                res = a & b;
            res &= m;
            if (opc == 3)
            {
                c->nzcv = 0;
                a64_set_nz(c, res, bits);
            }
            wr_x(c, rd, res);
            c->pc = next;
            continue;
        }
        /* UBFM / SBFM (includes LSL/LSR/ASR/UXT/SXT aliases) */
        if ((insn & 0x1f800000) == 0x13000000)
        {
            int ok = 0;
            uint64_t res = a64_bitfield(c, insn, &ok);
            int rd = insn & 31;
            if (!ok)
                return a64_fail(c, "unsupported bitfield move", insn);
            wr_x(c, rd, res);
            c->pc = next;
            continue;
        }
        /* MADD / MSUB / MUL and the long multiplies */
        if ((insn & 0x1f000000) == 0x1b000000)
        {
            int sf = (insn >> 31) & 1;
            int sub = (insn >> 15) & 1;
            int rm = (insn >> 16) & 31;
            int ra = (insn >> 10) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            if (insn & 0x00200000) /* SMADDL / UMADDL / SMSUBL / UMSUBL */
            {
                int is_signed = (insn & 0x00800000) == 0;
                uint64_t a = is_signed
                                 ? (uint64_t)(int64_t)(int32_t)c->x[rn]
                                 : (uint32_t)c->x[rn];
                uint64_t b = is_signed
                                 ? (uint64_t)(int64_t)(int32_t)c->x[rm]
                                 : (uint32_t)c->x[rm];
                uint64_t prod = a * b;
                uint64_t acc = c->x[ra];
                wr_x(c, rd, sub ? acc - prod : acc + prod);
            }
            else
            {
                uint64_t bits = sf ? ~0ull : 0xffffffffull;
                uint64_t prod = (rd_x(c, rn) * rd_x(c, rm)) & bits;
                uint64_t acc = rd_x(c, ra) & bits;
                wr_x(c, rd, sub ? (acc - prod) & bits : (acc + prod) & bits);
            }
            c->pc = next;
            continue;
        }
        /* LDR (literal) */
        if ((insn & 0x3f000000) == 0x18000000)
        {
            unsigned opc = (insn >> 30) & 3;
            int64_t off = (int64_t)((insn >> 5) & 0x7ffff);
            if (off & (1 << 18))
                off -= (1 << 19);
            off <<= 2;
            uint64_t addr = c->pc + (uint64_t)off;
            int rt = insn & 31;
            if (opc == 0)
                wr_w(c, rt, (uint32_t)a64_load(c, addr, 4, 0));
            else if (opc == 1)
                wr_x(c, rt, a64_load(c, addr, 8, 0));
            else if (opc == 2)
                wr_x(c, rt, a64_load(c, addr, 4, 1));
            else
                return a64_fail(c, "SIMD literal load", insn);
            c->pc = next;
            continue;
        }
        /* UDIV / SDIV */
        if ((insn & 0x1fe0fc00) == 0x1ac00800 ||
            (insn & 0x1fe0fc00) == 0x1ac00c00)
        {
            int sf = (insn >> 31) & 1;
            int is_signed = (insn & 0x400) != 0;
            int rm = (insn >> 16) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            if (sf)
            {
                if (is_signed)
                {
                    int64_t a = (int64_t)c->x[rn], b = (int64_t)c->x[rm];
                    wr_x(c, rd, b ? (uint64_t)(a / b) : 0);
                }
                else
                {
                    uint64_t a = c->x[rn], b = c->x[rm];
                    wr_x(c, rd, b ? a / b : 0);
                }
            }
            else
            {
                if (is_signed)
                {
                    int32_t a = (int32_t)c->x[rn], b = (int32_t)c->x[rm];
                    wr_w(c, rd, b ? (uint32_t)(a / b) : 0);
                }
                else
                {
                    uint32_t a = (uint32_t)c->x[rn], b = (uint32_t)c->x[rm];
                    wr_w(c, rd, b ? a / b : 0);
                }
            }
            c->pc = next;
            continue;
        }
        /* CSEL / CSINC / CSINV / CSNEG (CSET) */
        if ((insn & 0x1fe00000) == 0x1a800000)
        {
            int sf = (insn >> 31) & 1;
            int op = (((insn >> 30) & 1) << 1) | ((insn >> 10) & 1);
            int rm = (insn >> 16) & 31;
            unsigned cond = (insn >> 12) & 0xf;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            uint64_t m = sf ? ~0ull : 0xffffffffull;
            uint64_t a = rd_x(c, rn), b = rd_x(c, rm);
            if (a64_cond(c->nzcv, cond))
                wr_x(c, rd, a);
            else if (op == 0)
                wr_x(c, rd, b & m);
            else if (op == 1)
                wr_x(c, rd, (b + 1) & m);
            else if (op == 2)
                wr_x(c, rd, (~b) & m);
            else
                wr_x(c, rd, (0 - b) & m);
            c->pc = next;
            continue;
        }
        /* Logical (immediate): AND / ORR / EOR / ANDS with a bitmask. */
        if ((insn & 0x1f800000) == 0x12000000)
        {
            int sf = (insn >> 31) & 1;
            int bits = sf ? 64 : 32;
            unsigned opc = (insn >> 29) & 3;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            int ok = 0;
            uint64_t imm = a64_bitmask_imm(insn, bits, &ok);
            if (!ok)
                return a64_fail(c, "bad logical immediate", insn);
            uint64_t a = rd_x(c, rn) & mask_for(bits);
            uint64_t res;
            if (opc == 0 || opc == 3)
                res = a & imm;
            else if (opc == 1)
                res = a | imm;
            else
                res = a ^ imm;
            if (opc == 3)
            {
                c->nzcv = 0;
                a64_set_nz(c, res, bits);
            }
            if (sf)
                wr_x(c, rd, res);
            else
                wr_w(c, rd, (uint32_t)res);
            c->pc = next;
            continue;
        }
        /* Atomic memory operations, exclusives and barriers. */
        if (a64_atomic_insn(c, insn))
            continue;
        /* LDR / STR (unsigned offset, integer) */
        if ((insn & 0x3f000000) == 0x39000000)
        {
            unsigned size = (insn >> 30) & 3;
            unsigned opc = (insn >> 22) & 3;
            uint64_t imm = ((insn >> 10) & 0xfff) << size;
            int rn = (insn >> 5) & 31;
            int rt = insn & 31;
            uint64_t addr = rd_sp(c, rn) + imm;
            if (opc == 0)
                a64_store(c, addr, rd_x(c, rt),
                          size == 3 ? 8 : (1 << size));
            else if (size == 3)
            {
                wr_x(c, rt, a64_load(c, addr, 8, 0));
            }
            else if (size == 2)
            {
                uint64_t v = a64_load(c, addr, 4, opc == 2);
                if (opc == 2) /* LDRSW */
                    wr_x(c, rt, v);
                else
                    wr_w(c, rt, (uint32_t)v);
            }
            else
            {
                int sz = 1 << size;
                if (opc == 1) /* LDRB / LDRH */
                    wr_w(c, rt, (uint32_t)a64_load(c, addr, sz, 0));
                else if (opc == 2) /* LDRSB / LDRSH to X */
                    wr_x(c, rt, a64_load(c, addr, sz, 1));
                else /* LDRSB / LDRSH to W */
                    wr_w(c, rt, (uint32_t)a64_load(c, addr, sz, 1));
            }
            c->pc = next;
            continue;
        }
        /* LDR / STR (register offset, integer and FP/SIMD) */
        if ((insn & 0x3b200c00) == 0x38200800)
        {
            unsigned size = (insn >> 30) & 3;
            int is_vector = (insn >> 26) & 1;
            unsigned opc = (insn >> 22) & 3;
            int rm = (insn >> 16) & 31;
            unsigned option = (insn >> 13) & 7;
            int has_shift = (insn >> 12) & 1;
            int rn = (insn >> 5) & 31;
            int rt = insn & 31;
            uint64_t index = rd_x(c, rm);
            switch (option)
            {
            case 0: case 1: case 2: /* UXTB / UXTH / UXTW */
                index = (uint32_t)index;
                break;
            case 4: case 5: case 6: /* SXTB / SXTH / SXTW */
                index = (uint64_t)(int64_t)(int32_t)index;
                break;
            case 7: /* SXTX */
                index = (uint64_t)(int64_t)index;
                break;
            default: /* UXTX / LSL */
                break;
            }
            if (has_shift)
                index <<= size;
            uint64_t addr = rd_sp(c, rn) + index;
            int sz = 1 << size;
            if (is_vector)
            {
                if (opc == 0)
                    a64_store(c, addr, c->d[rt], sz);
                else
                    c->d[rt] = a64_load(c, addr, sz, 0);
            }
            else if (opc == 0)
                a64_store(c, addr, rd_x(c, rt), sz);
            else if (size == 3)
                wr_x(c, rt, a64_load(c, addr, 8, 0));
            else if (size == 2)
            {
                if (opc == 2) /* LDRSW */
                    wr_x(c, rt, a64_load(c, addr, 4, 1));
                else if (opc == 1)
                    wr_w(c, rt, (uint32_t)a64_load(c, addr, 4, 0));
            }
            else if (opc == 1) /* LDRB / LDRH */
                wr_w(c, rt, (uint32_t)a64_load(c, addr, sz, 0));
            else if (opc == 2) /* LDRSB / LDRSH to X */
                wr_x(c, rt, a64_load(c, addr, sz, 1));
            else /* LDRSB / LDRSH to W */
                wr_w(c, rt, (uint32_t)a64_load(c, addr, sz, 1));
            c->pc = next;
            continue;
        }
        /* LDUR/STUR and pre/post-indexed loads/stores (integer) */
        if ((insn & 0x3f200000) == 0x38000000)
        {
            unsigned size = (insn >> 30) & 3;
            unsigned opc = (insn >> 22) & 3;
            int64_t imm9 = (int64_t)((insn >> 12) & 0x1ff);
            if (imm9 & (1 << 8))
                imm9 -= (1 << 9);
            int mode = (insn >> 10) & 3; /* 0 unscaled, 1 post, 3 pre */
            int rn = (insn >> 5) & 31;
            int rt = insn & 31;
            uint64_t base = rd_sp(c, rn);
            uint64_t addr = mode == 1 ? base : base + (uint64_t)imm9;
            if (opc == 0)
                a64_store(c, addr, rd_x(c, rt), 1 << size);
            else if (size == 3)
                wr_x(c, rt, a64_load(c, addr, 8, 0));
            else if (size == 2)
            {
                uint64_t v = a64_load(c, addr, 4, opc == 2);
                if (opc == 2)
                    wr_x(c, rt, v);
                else
                    wr_w(c, rt, (uint32_t)v);
            }
            else
            {
                int sz = 1 << size;
                if (opc == 1)
                    wr_w(c, rt, (uint32_t)a64_load(c, addr, sz, 0));
                else if (opc == 2) /* LDRSB / LDRSH to X */
                    wr_x(c, rt, a64_load(c, addr, sz, 1));
                else /* LDRSB / LDRSH to W */
                    wr_w(c, rt, (uint32_t)a64_load(c, addr, sz, 1));
            }
            if (mode == 1 || mode == 3)
            {
                uint64_t wb = base + (uint64_t)imm9;
                if (rn == 31)
                    c->sp = wb;
                else
                    c->x[rn] = wb;
            }
            c->pc = next;
            continue;
        }
        /* FP LDUR/STUR and pre/post-indexed FP loads and stores. */
        if ((insn & 0x3f200c00) == 0x3c000000)
        {
            unsigned size = (insn >> 30) & 3;
            unsigned opc = (insn >> 22) & 3;
            int64_t imm9 = (int64_t)((insn >> 12) & 0x1ff);
            if (imm9 & (1 << 8))
                imm9 -= (1 << 9);
            int mode = (insn >> 10) & 3;
            int rn = (insn >> 5) & 31;
            int rt = insn & 31;
            uint64_t base = rd_sp(c, rn);
            uint64_t addr = mode == 1 ? base : base + (uint64_t)imm9;
            if (size == 0)
            {
                if (opc == 2)
                {
                    a64_store(c, addr, c->d[rt], 8);
                    a64_store(c, addr + 8, c->dhi[rt], 8);
                }
                else if (opc == 3)
                {
                    c->d[rt] = a64_load(c, addr, 8, 0);
                    c->dhi[rt] = a64_load(c, addr + 8, 8, 0);
                }
                else
                    return a64_fail(c, "unsupported FP register load", insn);
            }
            else if (opc == 0)
            {
                int bytes = 1 << size;
                a64_store(c, addr, c->d[rt], bytes);
            }
            else if (opc == 1)
            {
                int bytes = 1 << size;
                c->d[rt] = a64_load(c, addr, bytes, 0);
                c->dhi[rt] = 0;
            }
            else
                return a64_fail(c, "unsupported FP register load", insn);
            if (mode == 1 || mode == 3)
            {
                uint64_t wb = base + (uint64_t)imm9;
                if (rn == 31)
                    c->sp = wb;
                else
                    c->x[rn] = wb;
            }
            c->pc = next;
            continue;
        }
        /* LDP / STP (SIMD&FP) */
        if ((insn & 0x3e000000) == 0x2c000000)
        {
            unsigned size = (insn >> 30) & 3;
            int is_load = (insn >> 22) & 1;
            int64_t imm7 = (int64_t)((insn >> 15) & 0x7f);
            if (imm7 & (1 << 6))
                imm7 -= (1 << 7);
            int scale = size == 0 ? 4 : (size == 1 ? 8 : 16);
            int mode = (insn >> 23) & 3;
            int rt2 = (insn >> 10) & 31;
            int rn = (insn >> 5) & 31;
            int rt = insn & 31;
            uint64_t base = rd_sp(c, rn);
            int64_t off = imm7 * scale;
            uint64_t addr = mode == 1 ? base : base + (uint64_t)off;
            if (size == 2)
            {
                if (is_load)
                {
                    c->d[rt] = a64_load(c, addr, 8, 0);
                    c->dhi[rt] = a64_load(c, addr + 8, 8, 0);
                    c->d[rt2] = a64_load(c, addr + 16, 8, 0);
                    c->dhi[rt2] = a64_load(c, addr + 24, 8, 0);
                }
                else
                {
                    a64_store(c, addr, c->d[rt], 8);
                    a64_store(c, addr + 8, c->dhi[rt], 8);
                    a64_store(c, addr + 16, c->d[rt2], 8);
                    a64_store(c, addr + 24, c->dhi[rt2], 8);
                }
            }
            else if (is_load)
            {
                c->d[rt] = a64_load(c, addr, scale, 0);
                c->dhi[rt] = 0;
                c->d[rt2] = a64_load(c, addr + (uint64_t)scale, scale, 0);
                c->dhi[rt2] = 0;
            }
            else
            {
                a64_store(c, addr, c->d[rt], scale);
                a64_store(c, addr + (uint64_t)scale, c->d[rt2], scale);
            }
            if (mode == 1 || mode == 3)
            {
                uint64_t wb = base + (uint64_t)off;
                if (rn == 31)
                    c->sp = wb;
                else
                    c->x[rn] = wb;
            }
            c->pc = next;
            continue;
        }
        /* LDP / STP (signed offset, integer) */
        if ((insn & 0x3e000000) == 0x28000000)
        {
            int sf = (insn >> 31) & 1;
            int is_load = (insn >> 22) & 1;
            int64_t imm7 = (int64_t)((insn >> 15) & 0x7f);
            if (imm7 & (1 << 6))
                imm7 -= (1 << 7);
            int scale = sf ? 8 : 4;
            int64_t off = imm7 * scale;
            int mode = (insn >> 23) & 3; /* 2 offset, 3 pre, 1 post */
            int rt2 = (insn >> 10) & 31;
            int rn = (insn >> 5) & 31;
            int rt = insn & 31;
            uint64_t base = rd_sp(c, rn);
            uint64_t addr = mode == 1 ? base : base + (uint64_t)off;
            int size = sf ? 8 : 4;
            if (is_load)
            {
                uint64_t a = a64_load(c, addr, size, 0);
                uint64_t b = a64_load(c, addr + (uint64_t)size, size, 0);
                if (sf)
                {
                    wr_x(c, rt, a);
                    wr_x(c, rt2, b);
                }
                else
                {
                    wr_w(c, rt, (uint32_t)a);
                    wr_w(c, rt2, (uint32_t)b);
                }
            }
            else
            {
                a64_store(c, addr, c->x[rt], size);
                a64_store(c, addr + (uint64_t)size, c->x[rt2], size);
            }
            if (mode == 1 || mode == 3)
            {
                uint64_t wb = base + (uint64_t)off;
                if (rn == 31)
                    c->sp = wb;
                else
                    c->x[rn] = wb;
            }
            c->pc = next;
            continue;
        }
        /* Floating-point two-source arithmetic */
        if ((insn & 0x7f20fc00) == 0x1e202800 ||
            (insn & 0x7f20fc00) == 0x1e203800 ||
            (insn & 0x7f20fc00) == 0x1e200800 ||
            (insn & 0x7f20fc00) == 0x1e201800)
        {
            int is_double = (insn >> 22) & 1;
            int rm = (insn >> 16) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            unsigned op = (insn >> 12) & 0xf;
            if (is_double)
            {
                double a, b, r;
                memcpy(&a, &c->d[rn], 8);
                memcpy(&b, &c->d[rm], 8);
                if (op == 2)
                    r = a + b;
                else if (op == 3)
                    r = a - b;
                else if (op == 0)
                    r = a * b;
                else
                    r = a / b;
                memcpy(&c->d[rd], &r, 8);
                c->dhi[rd] = 0;
            }
            else
            {
                float a, b, r;
                uint32_t bits = (uint32_t)c->d[rn];
                memcpy(&a, &bits, 4);
                bits = (uint32_t)c->d[rm];
                memcpy(&b, &bits, 4);
                if (op == 2)
                    r = a + b;
                else if (op == 3)
                    r = a - b;
                else if (op == 0)
                    r = a * b;
                else
                    r = a / b;
                uint32_t out;
                memcpy(&out, &r, 4);
                c->d[rd] = out;
                c->dhi[rd] = 0;
            }
            c->pc = next;
            continue;
        }
        /* FMOV between FP registers */
        if ((insn & 0x7f20fc00) == 0x1e204000)
        {
            int is_double = (insn >> 22) & 1;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            if (is_double)
                c->d[rd] = c->d[rn];
            else
                c->d[rd] = (uint32_t)c->d[rn];
            c->dhi[rd] = 0;
            c->pc = next;
            continue;
        }
        /* FMOV (immediate): FMOV Sd/Dd, #imm8. The 8-bit immediate expands
         * per VFPExpandImm: one sign bit, one inverted exponent bit, a
         * replicated exponent bit and a fraction. */
        if ((insn & 0xffe01fe0) == 0x1e201000 ||
            (insn & 0xffe01fe0) == 0x1e601000)
        {
            int is_double = (insn >> 22) & 1;
            unsigned imm8 = (unsigned)((insn >> 13) & 0xff);
            int rd = insn & 31;
            unsigned b6 = (imm8 >> 6) & 1;
            unsigned sign = (imm8 >> 7) & 1;
            if (is_double)
            {
                uint64_t exp = (uint64_t)(!b6) << 10;
                uint64_t frac = (uint64_t)(imm8 & 0xf) << 48;
                if (b6)
                    exp |= 0xffu << 2;
                exp |= (imm8 >> 4) & 3;
                c->d[rd] = ((uint64_t)sign << 63) | (exp << 52) | frac;
            }
            else
            {
                uint32_t exp = (uint32_t)(!b6) << 7;
                uint32_t frac = (uint32_t)(imm8 & 0xf) << 19;
                if (b6)
                    exp |= 0x1fu << 2;
                exp |= (imm8 >> 4) & 3;
                c->d[rd] = (uint32_t)((sign << 31) | (exp << 23) | frac);
            }
            c->dhi[rd] = 0;
            c->pc = next;
            continue;
        }
        /* MOVI <Vd>.<T>, #0: the zero idiom for 8B/1D/16B/2D. */
        if ((insn & 0xfffffc00) == 0x0f00e400 ||
            (insn & 0xfffffc00) == 0x2f00e400 ||
            (insn & 0xfffffc00) == 0x4f00e400 ||
            (insn & 0xfffffc00) == 0x6f00e400)
        {
            int rd = insn & 31;
            c->d[rd] = 0;
            c->dhi[rd] = 0;
            c->pc = next;
            continue;
        }
        /* AdvSIMD shifts by immediate: SHL/USHR/SSHR. The encoding shares
         * the modified-immediate group's mask, so it is decoded first. */
        {
            unsigned sm = insn & 0xbf80fc00;
            if ((sm == 0x0f005400 || sm == 0x0f000400 ||
                 sm == 0x2f000400) && ((insn >> 19) & 0xf) != 0)
            {
                unsigned immh = (insn >> 19) & 0xf;
                unsigned immb = (insn >> 16) & 7;
                int Q = (insn >> 30) & 1;
                int rn = (insn >> 5) & 31;
                int rd = insn & 31;
                int h = 31 - __builtin_clz(immh);
                int esize = 8 << h;
                unsigned imm = (immh << 3) | immb;
                int lanes = (Q ? 128 : 64) / esize;
                uint8_t a[16], r[16];
                memcpy(a, &c->d[rn], 8);
                memcpy(a + 8, &c->dhi[rn], 8);
                memset(r, 0, sizeof r);
                uint64_t mask = esize == 64 ? ~0ull
                                            : ((1ull << esize) - 1);
                for (int i = 0; i < lanes; i++)
                {
                    uint64_t v = a64_lane_get(a, i, esize);
                    uint64_t out;
                    if (sm == 0x0f005400)
                        out = v << (imm - (unsigned)esize);
                    else if (sm == 0x0f000400)
                        out = (uint64_t)(a64_lane_signed(v, esize) >>
                                         (2 * esize - (int)imm));
                    else
                        out = v >> (2 * esize - (int)imm);
                    a64_lane_put(r, i, esize, out & mask);
                }
                memcpy(&c->d[rd], r, 8);
                memcpy(&c->dhi[rd], r + 8, 8);
                c->pc = next;
                continue;
            }
        }
        /* AdvSIMD integer add/sub/mul/mla for every element size. */
        {
            unsigned m = insn & 0xbfe0fc00;
            int op = 0; /* 1 add, 2 sub, 3 mul, 4 mla */
            if (m == 0x0e208400 || m == 0x0e608400 ||
                m == 0x0ea08400 || m == 0x0ee08400)
                op = 1;
            else if (m == 0x2e208400 || m == 0x2e608400 ||
                     m == 0x2ea08400 || m == 0x2ee08400)
                op = 2;
            else if (m == 0x0e209c00 || m == 0x0e609c00 ||
                     m == 0x0ea09c00)
                op = 3;
            else if (m == 0x0e209400 || m == 0x0e609400 ||
                     m == 0x0ea09400)
                op = 4;
            if (op)
            {
                int Q = (insn >> 30) & 1;
                int esize = 8 << ((insn >> 22) & 3);
                int rn = (insn >> 5) & 31;
                int rm = (insn >> 16) & 31;
                int rd = insn & 31;
                int lanes = (Q ? 128 : 64) / esize;
                uint8_t a[16], b[16], acc[16], r[16];
                memcpy(a, &c->d[rn], 8);
                memcpy(a + 8, &c->dhi[rn], 8);
                memcpy(b, &c->d[rm], 8);
                memcpy(b + 8, &c->dhi[rm], 8);
                memcpy(acc, &c->d[rd], 8);
                memcpy(acc + 8, &c->dhi[rd], 8);
                memset(r, 0, sizeof r);
                uint64_t mask = esize == 64 ? ~0ull
                                            : ((1ull << esize) - 1);
                for (int i = 0; i < lanes; i++)
                {
                    uint64_t x = a64_lane_get(a, i, esize);
                    uint64_t y = a64_lane_get(b, i, esize);
                    uint64_t v;
                    if (op == 1)
                        v = x + y;
                    else if (op == 2)
                        v = x - y;
                    else if (op == 3)
                        v = x * y;
                    else
                        v = a64_lane_get(acc, i, esize) + x * y;
                    a64_lane_put(r, i, esize, v & mask);
                }
                memcpy(&c->d[rd], r, 8);
                memcpy(&c->dhi[rd], r + 8, 8);
                c->pc = next;
                continue;
            }
        }
        /* AdvSIMD integer max/min, signed and unsigned. */
        {
            unsigned m = insn & 0xbfe0fc00;
            int kind = 0; /* 1 smax, 2 smin, 3 umax, 4 umin */
            if (m == 0x0e206400 || m == 0x0e606400 ||
                m == 0x0ea06400 || m == 0x0ee06400)
                kind = 1;
            else if (m == 0x0e206c00 || m == 0x0e606c00 ||
                     m == 0x0ea06c00 || m == 0x0ee06c00)
                kind = 2;
            else if (m == 0x2e206400 || m == 0x2e606400 ||
                     m == 0x2ea06400 || m == 0x2ee06400)
                kind = 3;
            else if (m == 0x2e206c00 || m == 0x2e606c00 ||
                     m == 0x2ea06c00 || m == 0x2ee06c00)
                kind = 4;
            if (kind)
            {
                int Q = (insn >> 30) & 1;
                int esize = 8 << ((insn >> 22) & 3);
                int rn = (insn >> 5) & 31;
                int rm = (insn >> 16) & 31;
                int rd = insn & 31;
                int lanes = (Q ? 128 : 64) / esize;
                uint8_t a[16], b[16], r[16];
                memcpy(a, &c->d[rn], 8);
                memcpy(a + 8, &c->dhi[rn], 8);
                memcpy(b, &c->d[rm], 8);
                memcpy(b + 8, &c->dhi[rm], 8);
                memset(r, 0, sizeof r);
                for (int i = 0; i < lanes; i++)
                {
                    uint64_t x = a64_lane_get(a, i, esize);
                    uint64_t y = a64_lane_get(b, i, esize);
                    uint64_t v;
                    if (kind == 1)
                        v = a64_lane_signed(x, esize) >=
                                    a64_lane_signed(y, esize) ? x : y;
                    else if (kind == 2)
                        v = a64_lane_signed(x, esize) <=
                                    a64_lane_signed(y, esize) ? x : y;
                    else if (kind == 3)
                        v = x >= y ? x : y;
                    else
                        v = x <= y ? x : y;
                    a64_lane_put(r, i, esize, v);
                }
                memcpy(&c->d[rd], r, 8);
                memcpy(&c->dhi[rd], r + 8, 8);
                c->pc = next;
                continue;
            }
        }
        /* AdvSIMD 4S floating-point max/min/divide. */
        if ((insn & 0xffe0fc00) == 0x4e20f400 ||
            (insn & 0xffe0fc00) == 0x4ea0f400 ||
            (insn & 0xffe0fc00) == 0x6e20fc00)
        {
            int rm = (insn >> 16) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            float a[4], b[4], r[4];
            memcpy(a, &c->d[rn], 8);
            memcpy(a + 2, &c->dhi[rn], 8);
            memcpy(b, &c->d[rm], 8);
            memcpy(b + 2, &c->dhi[rm], 8);
            unsigned m = insn & 0xffe0fc00;
            for (int i = 0; i < 4; i++)
            {
                if (m == 0x4e20f400)
                    r[i] = a[i] > b[i] ? a[i] : b[i];
                else if (m == 0x4ea0f400)
                    r[i] = a[i] < b[i] ? a[i] : b[i];
                else
                    r[i] = a[i] / b[i];
            }
            memcpy(&c->d[rd], r, 8);
            memcpy(&c->dhi[rd], r + 2, 8);
            c->pc = next;
            continue;
        }
        /* AdvSIMD single-source 4S floating point and integer ops. */
        if ((insn & 0xfffffc00) == 0x6ea1f800 ||   /* fsqrt */
            (insn & 0xfffffc00) == 0x4ea0f800 ||   /* fabs */
            (insn & 0xfffffc00) == 0x6ea0f800 ||   /* fneg */
            (insn & 0xfffffc00) == 0x4ea0b800 ||   /* abs */
            (insn & 0xfffffc00) == 0x6ea0b800)     /* neg */
        {
            unsigned m = insn & 0xfffffc00;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            if (m == 0x4ea0b800 || m == 0x6ea0b800)
            {
                int32_t a[4], r[4];
                memcpy(a, &c->d[rn], 8);
                memcpy(a + 2, &c->dhi[rn], 8);
                for (int i = 0; i < 4; i++)
                    r[i] = m == 0x4ea0b800
                               ? (a[i] < 0 ? -a[i] : a[i])
                               : -a[i];
                memcpy(&c->d[rd], r, 8);
                memcpy(&c->dhi[rd], r + 2, 8);
            }
            else
            {
                uint32_t a[4], r[4];
                memcpy(a, &c->d[rn], 8);
                memcpy(a + 2, &c->dhi[rn], 8);
                for (int i = 0; i < 4; i++)
                {
                    if (m == 0x4ea0f800)
                        r[i] = a[i] & 0x7fffffffu;
                    else if (m == 0x6ea0f800)
                        r[i] = a[i] ^ 0x80000000u;
                    else
                    {
                        float f;
                        memcpy(&f, &a[i], 4);
                        f = sqrtf(f);
                        memcpy(&r[i], &f, 4);
                    }
                }
                memcpy(&c->d[rd], r, 8);
                memcpy(&c->dhi[rd], r + 2, 8);
            }
            c->pc = next;
            continue;
        }
        /* AdvSIMD vector conversions between integer and float (4S). */
        if ((insn & 0xfffffc00) == 0x4e21d800 ||
            (insn & 0xfffffc00) == 0x4ea1b800)
        {
            unsigned m = insn & 0xfffffc00;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            int32_t a[4], r[4];
            float f[4];
            memcpy(a, &c->d[rn], 8);
            memcpy(a + 2, &c->dhi[rn], 8);
            memcpy(f, a, sizeof f);
            for (int i = 0; i < 4; i++)
            {
                if (m == 0x4e21d800)
                {
                    float v = (float)a[i];
                    memcpy(&r[i], &v, 4);
                }
                else
                    r[i] = (int32_t)f[i];
            }
            memcpy(&c->d[rd], r, 8);
            memcpy(&c->dhi[rd], r + 2, 8);
            c->pc = next;
            continue;
        }
        /* AdvSIMD vector compares producing all-ones lane masks. */
        {
            unsigned m = insn & 0xbfe0fc00;
            int kind = 0; /* 1 eq, 2 gt, 3 ge, 4 hi, 5 hs */
            if (m == 0x2e208c00 || m == 0x2e608c00 ||
                m == 0x2ea08c00 || m == 0x2ee08c00)
                kind = 1;
            else if (m == 0x0e203400 || m == 0x0e603400 ||
                     m == 0x0ea03400 || m == 0x0ee03400)
                kind = 2;
            else if (m == 0x0e203c00 || m == 0x0e603c00 ||
                     m == 0x0ea03c00 || m == 0x0ee03c00)
                kind = 3;
            else if (m == 0x2e203400 || m == 0x2e603400 ||
                     m == 0x2ea03400 || m == 0x2ee03400)
                kind = 4;
            else if (m == 0x2e203c00 || m == 0x2e603c00 ||
                     m == 0x2ea03c00 || m == 0x2ee03c00)
                kind = 5;
            if (kind)
            {
                int Q = (insn >> 30) & 1;
                int esize = 8 << ((insn >> 22) & 3);
                int rn = (insn >> 5) & 31;
                int rm = (insn >> 16) & 31;
                int rd = insn & 31;
                int lanes = (Q ? 128 : 64) / esize;
                uint8_t a[16], b[16], r[16];
                memcpy(a, &c->d[rn], 8);
                memcpy(a + 8, &c->dhi[rn], 8);
                memcpy(b, &c->d[rm], 8);
                memcpy(b + 8, &c->dhi[rm], 8);
                memset(r, 0, sizeof r);
                uint64_t ones = esize == 64 ? ~0ull
                                            : ((1ull << esize) - 1);
                for (int i = 0; i < lanes; i++)
                {
                    uint64_t x = a64_lane_get(a, i, esize);
                    uint64_t y = a64_lane_get(b, i, esize);
                    int64_t sx = a64_lane_signed(x, esize);
                    int64_t sy = a64_lane_signed(y, esize);
                    int t;
                    if (kind == 1)
                        t = x == y;
                    else if (kind == 2)
                        t = sx > sy;
                    else if (kind == 3)
                        t = sx >= sy;
                    else if (kind == 4)
                        t = x > y;
                    else
                        t = x >= y;
                    a64_lane_put(r, i, esize, t ? ones : 0);
                }
                memcpy(&c->d[rd], r, 8);
                memcpy(&c->dhi[rd], r + 8, 8);
                c->pc = next;
                continue;
            }
        }
        /* AdvSIMD compare-with-zero (CMEQ #0). */
        if ((insn & 0xbfe0fc00) == 0x0e209800 ||
            (insn & 0xbfe0fc00) == 0x0e609800 ||
            (insn & 0xbfe0fc00) == 0x0ea09800 ||
            (insn & 0xbfe0fc00) == 0x0ee09800)
        {
            int Q = (insn >> 30) & 1;
            int esize = 8 << ((insn >> 22) & 3);
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            int lanes = (Q ? 128 : 64) / esize;
            uint8_t a[16], r[16];
            memcpy(a, &c->d[rn], 8);
            memcpy(a + 8, &c->dhi[rn], 8);
            memset(r, 0, sizeof r);
            uint64_t ones = esize == 64 ? ~0ull : ((1ull << esize) - 1);
            for (int i = 0; i < lanes; i++)
                a64_lane_put(r, i, esize,
                             a64_lane_get(a, i, esize) == 0 ? ones : 0);
            memcpy(&c->d[rd], r, 8);
            memcpy(&c->dhi[rd], r + 8, 8);
            c->pc = next;
            continue;
        }
        /* AdvSIMD pairwise add (ADDP). */
        if ((insn & 0xbfe0fc00) == 0x0e20bc00 ||
            (insn & 0xbfe0fc00) == 0x0e60bc00 ||
            (insn & 0xbfe0fc00) == 0x0ea0bc00 ||
            (insn & 0xbfe0fc00) == 0x0ee0bc00)
        {
            int Q = (insn >> 30) & 1;
            int esize = 8 << ((insn >> 22) & 3);
            int rn = (insn >> 5) & 31;
            int rm = (insn >> 16) & 31;
            int rd = insn & 31;
            int lanes = (Q ? 128 : 64) / esize;
            uint8_t a[16], b[16], r[16];
            memcpy(a, &c->d[rn], 8);
            memcpy(a + 8, &c->dhi[rn], 8);
            memcpy(b, &c->d[rm], 8);
            memcpy(b + 8, &c->dhi[rm], 8);
            memset(r, 0, sizeof r);
            uint64_t mask = esize == 64 ? ~0ull : ((1ull << esize) - 1);
            for (int i = 0; i < lanes / 2; i++)
            {
                uint64_t va = a64_lane_get(a, 2 * i, esize) +
                              a64_lane_get(a, 2 * i + 1, esize);
                uint64_t vb = a64_lane_get(b, 2 * i, esize) +
                              a64_lane_get(b, 2 * i + 1, esize);
                a64_lane_put(r, i, esize, va & mask);
                a64_lane_put(r, lanes / 2 + i, esize, vb & mask);
            }
            memcpy(&c->d[rd], r, 8);
            memcpy(&c->dhi[rd], r + 8, 8);
            c->pc = next;
            continue;
        }
        /* AdvSIMD horizontal reductions for 4S vectors. */
        if ((insn & 0xfffffc00) == 0x4eb0a800 ||
            (insn & 0xfffffc00) == 0x4eb1a800 ||
            (insn & 0xfffffc00) == 0x6eb0a800 ||
            (insn & 0xfffffc00) == 0x6eb1a800 ||
            (insn & 0xfffffc00) == 0x6e30f800 ||
            (insn & 0xfffffc00) == 0x6eb0f800)
        {
            unsigned m = insn & 0xfffffc00;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            if (m == 0x4eb0a800 || m == 0x4eb1a800 ||
                m == 0x6eb0a800 || m == 0x6eb1a800)
            {
                int32_t a[4];
                memcpy(a, &c->d[rn], 8);
                memcpy(a + 2, &c->dhi[rn], 8);
                int32_t v = a[0];
                for (int i = 1; i < 4; i++)
                {
                    if (m == 0x4eb0a800)
                        v = a[i] > v ? a[i] : v;
                    else if (m == 0x4eb1a800)
                        v = a[i] < v ? a[i] : v;
                    else if (m == 0x6eb0a800)
                        v = (uint32_t)a[i] > (uint32_t)v ? a[i] : v;
                    else
                        v = (uint32_t)a[i] < (uint32_t)v ? a[i] : v;
                }
                c->d[rd] = (uint32_t)v;
            }
            else
            {
                float a[4], v;
                memcpy(a, &c->d[rn], 8);
                memcpy(a + 2, &c->dhi[rn], 8);
                v = a[0];
                for (int i = 1; i < 4; i++)
                {
                    if (m == 0x6e30f800)
                        v = a[i] > v ? a[i] : v;
                    else
                        v = a[i] < v ? a[i] : v;
                }
                uint32_t bits;
                memcpy(&bits, &v, 4);
                c->d[rd] = bits;
            }
            c->dhi[rd] = 0;
            c->pc = next;
            continue;
        }
        /* AdvSIMD DUP (element) and INS (general). */
        if ((insn & 0xbfe0fc00) == 0x0e000400)
        {
            unsigned imm5 = (insn >> 16) & 31;
            int Q = (insn >> 30) & 1;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            if (!imm5)
                return a64_fail(c, "bad vector element move", insn);
            int lz = __builtin_ctz(imm5);
            int esize = 8 << lz;
            int index = (int)(imm5 >> (lz + 1));
            uint8_t a[16], r[16];
            memcpy(a, &c->d[rn], 8);
            memcpy(a + 8, &c->dhi[rn], 8);
            memset(r, 0, sizeof r);
            int lanes = (Q ? 128 : 64) / esize;
            uint64_t v = a64_lane_get(a, index, esize);
            for (int i = 0; i < lanes; i++)
                a64_lane_put(r, i, esize, v);
            memcpy(&c->d[rd], r, 8);
            memcpy(&c->dhi[rd], r + 8, 8);
            c->pc = next;
            continue;
        }
        if ((insn & 0xffe0fc00) == 0x4e001c00)
        {
            unsigned imm5 = (insn >> 16) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            if (!imm5)
                return a64_fail(c, "bad vector element insert", insn);
            int lz = __builtin_ctz(imm5);
            int esize = 8 << lz;
            int index = (int)(imm5 >> (lz + 1));
            uint8_t r[16];
            memcpy(r, &c->d[rd], 8);
            memcpy(r + 8, &c->dhi[rd], 8);
            uint64_t v = c->x[rn];
            if (esize < 64)
                v &= (1ull << esize) - 1;
            a64_lane_put(r, index, esize, v);
            memcpy(&c->d[rd], r, 8);
            memcpy(&c->dhi[rd], r + 8, 8);
            c->pc = next;
            continue;
        }
        /* AdvSIMD ZIP/UZP/TRN permutations. */
        {
            unsigned m = insn & 0xbfe0fc00;
            int op = 0; /* 1 zip1, 2 zip2, 3 uzp1, 4 uzp2, 5 trn1, 6 trn2 */
            if (m == 0x0e003800 || m == 0x0e403800 ||
                m == 0x0e803800 || m == 0x0ec03800)
                op = 1;
            else if (m == 0x0e007800 || m == 0x0e407800 ||
                     m == 0x0e807800 || m == 0x0ec07800)
                op = 2;
            else if (m == 0x0e001800 || m == 0x0e401800 ||
                     m == 0x0e801800 || m == 0x0ec01800)
                op = 3;
            else if (m == 0x0e005800 || m == 0x0e405800 ||
                     m == 0x0e805800 || m == 0x0ec05800)
                op = 4;
            else if (m == 0x0e002800 || m == 0x0e402800 ||
                     m == 0x0e802800 || m == 0x0ec02800)
                op = 5;
            else if (m == 0x0e006800 || m == 0x0e406800 ||
                     m == 0x0e806800 || m == 0x0ec06800)
                op = 6;
            if (op)
            {
                int Q = (insn >> 30) & 1;
                int esize = 8 << ((insn >> 22) & 3);
                int rn = (insn >> 5) & 31;
                int rm = (insn >> 16) & 31;
                int rd = insn & 31;
                int lanes = (Q ? 128 : 64) / esize;
                int half = lanes / 2;
                uint8_t a[16], b[16], r[16];
                memcpy(a, &c->d[rn], 8);
                memcpy(a + 8, &c->dhi[rn], 8);
                memcpy(b, &c->d[rm], 8);
                memcpy(b + 8, &c->dhi[rm], 8);
                memset(r, 0, sizeof r);
                for (int i = 0; i < half; i++)
                {
                    uint64_t v0, v1;
                    if (op == 1)
                    {
                        v0 = a64_lane_get(a, i, esize);
                        v1 = a64_lane_get(b, i, esize);
                    }
                    else if (op == 2)
                    {
                        v0 = a64_lane_get(a, half + i, esize);
                        v1 = a64_lane_get(b, half + i, esize);
                    }
                    else if (op == 3)
                    {
                        v0 = a64_lane_get(a, 2 * i, esize);
                        v1 = a64_lane_get(b, 2 * i, esize);
                    }
                    else if (op == 4)
                    {
                        v0 = a64_lane_get(a, 2 * i + 1, esize);
                        v1 = a64_lane_get(b, 2 * i + 1, esize);
                    }
                    else if (op == 5)
                    {
                        v0 = a64_lane_get(a, 2 * i, esize);
                        v1 = a64_lane_get(b, 2 * i, esize);
                    }
                    else
                    {
                        v0 = a64_lane_get(a, 2 * i + 1, esize);
                        v1 = a64_lane_get(b, 2 * i + 1, esize);
                    }
                    if (op == 3 || op == 4)
                    {
                        a64_lane_put(r, i, esize, v0);
                        a64_lane_put(r, half + i, esize, v1);
                    }
                    else
                    {
                        a64_lane_put(r, 2 * i, esize, v0);
                        a64_lane_put(r, 2 * i + 1, esize, v1);
                    }
                }
                memcpy(&c->d[rd], r, 8);
                memcpy(&c->dhi[rd], r + 8, 8);
                c->pc = next;
                continue;
            }
        }
        /* AdvSIMD load-one-lane-replicate (LD1R). */
        {
            unsigned m = insn & 0xbfe0fc00;
            if (m == 0x0d40c000 || m == 0x0d40c400 ||
                m == 0x0d40c800 || m == 0x0d40cc00)
            {
                int Q = (insn >> 30) & 1;
                int esize = 8 << ((insn >> 10) & 3);
                int rn = (insn >> 5) & 31;
                int rd = insn & 31;
                uint64_t addr = c->x[rn];
                uint64_t v = a64_load(c, addr, esize / 8, 0);
                int lanes = (Q ? 128 : 64) / esize;
                uint8_t r[16];
                memset(r, 0, sizeof r);
                for (int i = 0; i < lanes; i++)
                    a64_lane_put(r, i, esize, v);
                memcpy(&c->d[rd], r, 8);
                memcpy(&c->dhi[rd], r + 8, 8);
                c->pc = next;
                continue;
            }
        }
        /* AdvSIMD single-structure load/store (LD1/ST1) of one to four
         * consecutive registers, with no offset or a post-index. */
        if ((insn & 0xbf000000) == 0x0c000000 &&
            ((insn >> 21) & 1) == 0)
        {
            unsigned opcode = (insn >> 12) & 0xf;
            int nregs = opcode == 0x7 ? 1 : opcode == 0xa ? 2 :
                        opcode == 0x6 ? 3 : opcode == 0x2 ? 4 : 0;
            if (nregs)
            {
                int load = (insn >> 22) & 1;
                int post = (insn >> 23) & 1;
                int Q = (insn >> 30) & 1;
                int rm = (insn >> 16) & 31;
                int rn = (insn >> 5) & 31;
                int rt = insn & 31;
                int regbytes = Q ? 16 : 8;
                uint64_t addr = c->x[rn];
                for (int i = 0; i < nregs; i++)
                {
                    int r = rt + i;
                    if (r > 31)
                        return a64_fail(c, "bad vector list", insn);
                    if (load)
                    {
                        c->d[r] = a64_load(c,
                                           addr + (uint64_t)i * regbytes,
                                           8, 0);
                        c->dhi[r] = Q
                            ? a64_load(c,
                                       addr + (uint64_t)i * regbytes + 8,
                                       8, 0)
                            : 0;
                    }
                    else
                    {
                        a64_store(c, addr + (uint64_t)i * regbytes,
                                  c->d[r], 8);
                        if (Q)
                            a64_store(c,
                                      addr + (uint64_t)i * regbytes + 8,
                                      c->dhi[r], 8);
                    }
                }
                if (post)
                    c->x[rn] += rm == 31
                                    ? (uint64_t)nregs * (uint64_t)regbytes
                                    : c->x[rm];
                c->pc = next;
                continue;
            }
        }
        /* AdvSIMD modified immediate: MOVI vectors and FMOV vector
         * immediates. */
        if ((insn & 0x9f000400) == 0x0f000400)
        {
            int Q = (insn >> 30) & 1;
            int op = (insn >> 29) & 1;
            unsigned cmode = (insn >> 12) & 0xf;
            unsigned imm8 = (unsigned)((((insn >> 16) & 7) << 5) |
                                       ((insn >> 5) & 31));
            int rd = insn & 31;
            if (!op && cmode != 0xf)
            {
                if (cmode & 1)
                    return a64_fail(c, "unsupported vector immediate", insn);
                int esize, shift;
                if (cmode <= 6)
                {
                    esize = 32;
                    shift = (int)(cmode >> 1) * 8;
                }
                else if (cmode == 8 || cmode == 0xa)
                {
                    esize = 16;
                    shift = cmode == 0xa ? 8 : 0;
                }
                else if (cmode == 0xc)
                {
                    esize = 8;
                    shift = 0;
                }
                else
                {
                    esize = 64;
                    shift = 0;
                }
                uint64_t lane = ((uint64_t)imm8 << shift);
                if (esize < 64)
                    lane &= (1ull << esize) - 1;
                uint64_t lo = 0, hi = 0;
                int lanes = 128 / esize;
                for (int i = 0; i < lanes; i++)
                {
                    if (i < lanes / 2)
                        lo |= lane << (i * esize);
                    else
                        hi |= lane << ((i - lanes / 2) * esize);
                }
                c->d[rd] = lo;
                c->dhi[rd] = Q ? hi : 0;
                c->pc = next;
                continue;
            }
            if (cmode == 0xf)
            {
                unsigned b6 = (imm8 >> 6) & 1;
                unsigned sign = (imm8 >> 7) & 1;
                if (op)
                {
                    uint64_t exp = (uint64_t)(!b6) << 10;
                    uint64_t frac = (uint64_t)(imm8 & 0xf) << 48;
                    if (b6)
                        exp |= 0xffu << 2;
                    exp |= (imm8 >> 4) & 3;
                    uint64_t bits = ((uint64_t)sign << 63) |
                                    (exp << 52) | frac;
                    c->d[rd] = bits;
                    c->dhi[rd] = bits;
                }
                else
                {
                    uint32_t exp = (uint32_t)(!b6) << 7;
                    uint32_t frac = (uint32_t)(imm8 & 0xf) << 19;
                    if (b6)
                        exp |= 0x1fu << 2;
                    exp |= (imm8 >> 4) & 3;
                    uint32_t bits = (sign << 31) | (exp << 23) | frac;
                    uint64_t pair = ((uint64_t)bits << 32) | bits;
                    c->d[rd] = pair;
                    c->dhi[rd] = Q ? pair : 0;
                }
                c->pc = next;
                continue;
            }
            return a64_fail(c, "unsupported vector immediate", insn);
        }
        /* AdvSIMD DUP (element) to scalar: mov b/h/s/d, v[]. */
        if ((insn & 0xffe0fc00) == 0x5e000400)
        {
            unsigned imm5 = (insn >> 16) & 31;
            if (!imm5)
                return a64_fail(c, "unsupported vector element move", insn);
            int lz = __builtin_ctz(imm5);
            int esize = 8 << lz;
            unsigned index = imm5 >> (lz + 1);
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            uint64_t val;
            if (esize == 64)
                val = index ? c->dhi[rn] : c->d[rn];
            else
            {
                unsigned bit = index * (unsigned)esize;
                uint64_t mask = (1ull << esize) - 1;
                if (bit < 64)
                    val = (c->d[rn] >> bit) & mask;
                else
                    val = (c->dhi[rn] >> (bit - 64)) & mask;
            }
            c->d[rd] = val;
            c->dhi[rd] = 0;
            c->pc = next;
            continue;
        }
        /* AdvSIMD ORR: mov.16b and orr.16b/8b. */
        if ((insn & 0xffe0fc00) == 0x4ea01c00 ||
            (insn & 0xffe0fc00) == 0x0ea01c00)
        {
            int Q = (insn >> 30) & 1;
            int rm = (insn >> 16) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            c->d[rd] = c->d[rn] | c->d[rm];
            c->dhi[rd] = Q ? (c->dhi[rn] | c->dhi[rm]) : 0;
            c->pc = next;
            continue;
        }
        /* AdvSIMD ADDV to scalar: addv sXd, vN.4S. */
        if ((insn & 0xfffffc00) == 0x4eb1b800)
        {
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            uint32_t a[4];
            memcpy(a, &c->d[rn], 8);
            memcpy(a + 2, &c->dhi[rn], 8);
            uint32_t sum = a[0] + a[1] + a[2] + a[3];
            c->d[rd] = sum;
            c->dhi[rd] = 0;
            c->pc = next;
            continue;
        }
        /* AdvSIMD integer add/sub/mul/mla (4S). */
        if ((insn & 0xffe0fc00) == 0x4ea08400 ||
            (insn & 0xffe0fc00) == 0x6ea08400 ||
            (insn & 0xffe0fc00) == 0x4ea09c00 ||
            (insn & 0xffe0fc00) == 0x4ea09400)
        {
            unsigned masked = insn & 0xffe0fc00;
            int rm = (insn >> 16) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            uint32_t a[4], b[4], acc[4], r[4];
            memcpy(a, &c->d[rn], 8);
            memcpy(a + 2, &c->dhi[rn], 8);
            memcpy(b, &c->d[rm], 8);
            memcpy(b + 2, &c->dhi[rm], 8);
            memcpy(acc, &c->d[rd], 8);
            memcpy(acc + 2, &c->dhi[rd], 8);
            for (int i = 0; i < 4; i++)
            {
                if (masked == 0x4ea08400)
                    r[i] = a[i] + b[i];
                else if (masked == 0x6ea08400)
                    r[i] = a[i] - b[i];
                else if (masked == 0x4ea09c00)
                    r[i] = a[i] * b[i];
                else
                    r[i] = acc[i] + a[i] * b[i];
            }
            memcpy(&c->d[rd], r, 8);
            memcpy(&c->dhi[rd], r + 2, 8);
            c->pc = next;
            continue;
        }
        /* AdvSIMD bitwise AND/EOR/BIC/ORN (16b and 8b). */
        if ((insn & 0xffe0fc00) == 0x4e201c00 ||
            (insn & 0xffe0fc00) == 0x0e201c00 ||
            (insn & 0xffe0fc00) == 0x6e201c00 ||
            (insn & 0xffe0fc00) == 0x2e201c00 ||
            (insn & 0xffe0fc00) == 0x4e601c00 ||
            (insn & 0xffe0fc00) == 0x0e601c00 ||
            (insn & 0xffe0fc00) == 0x4ee01c00 ||
            (insn & 0xffe0fc00) == 0x2ee01c00)
        {
            unsigned masked = insn & 0xffe0fc00;
            int Q = (insn >> 30) & 1;
            int rm = (insn >> 16) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            uint64_t a = c->d[rn], b = c->d[rm];
            uint64_t ah = c->dhi[rn], bh = c->dhi[rm];
            int invert = masked == 0x4e601c00 ||
                         masked == 0x0e601c00 ||
                         masked == 0x4ee01c00 ||
                         masked == 0x2ee01c00;
            int eor = masked == 0x6e201c00 ||
                      masked == 0x2e201c00 ||
                      masked == 0x4ee01c00 ||
                      masked == 0x2ee01c00;
            if (invert)
            {
                b = ~b;
                bh = ~bh;
            }
            c->d[rd] = eor ? (a ^ b) : (a & b);
            c->dhi[rd] = Q ? (eor ? (ah ^ bh) : (ah & bh)) : 0;
            c->pc = next;
            continue;
        }
        /* AdvSIMD 4S floating-point arithmetic. */
        if ((insn & 0xffe0fc00) == 0x4e20cc00 ||
            (insn & 0xffe0fc00) == 0x4e20d400 ||
            (insn & 0xffe0fc00) == 0x4ea0d400 ||
            (insn & 0xffe0fc00) == 0x6e20dc00)
        {
            unsigned masked = insn & 0xffe0fc00;
            int rm = (insn >> 16) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            float a[4], b[4], acc[4], r[4];
            memcpy(a, &c->d[rn], 8);
            memcpy(a + 2, &c->dhi[rn], 8);
            memcpy(b, &c->d[rm], 8);
            memcpy(b + 2, &c->dhi[rm], 8);
            memcpy(acc, &c->d[rd], 8);
            memcpy(acc + 2, &c->dhi[rd], 8);
            for (int i = 0; i < 4; i++)
            {
                if (masked == 0x4e20cc00)
                    r[i] = acc[i] + a[i] * b[i];
                else if (masked == 0x4e20d400)
                    r[i] = a[i] + b[i];
                else if (masked == 0x4ea0d400)
                    r[i] = a[i] - b[i];
                else
                    r[i] = a[i] * b[i];
            }
            memcpy(&c->d[rd], r, 8);
            memcpy(&c->dhi[rd], r + 2, 8);
            c->pc = next;
            continue;
        }
        /* FMOV between GP and FP registers */
        if ((insn & 0xfffffc00) == 0x9e660000) /* FMOV Xd, Dn */
        {
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            wr_x(c, rd, c->d[rn]);
            c->pc = next;
            continue;
        }
        if ((insn & 0xfffffc00) == 0x9e670000) /* FMOV Dd, Xn */
        {
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            c->d[rd] = c->x[rn];
            c->dhi[rd] = 0;
            c->pc = next;
            continue;
        }
        if ((insn & 0xfffffc00) == 0x1e260000) /* FMOV Wd, Sn */
        {
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            wr_w(c, rd, (uint32_t)c->d[rn]);
            c->pc = next;
            continue;
        }
        if ((insn & 0xfffffc00) == 0x1e270000) /* FMOV Sd, Wn */
        {
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            c->d[rd] = (uint32_t)c->x[rn];
            c->dhi[rd] = 0;
            c->pc = next;
            continue;
        }
        /* FCVT between single and double precision. */
        if ((insn & 0xfffffc00) == 0x1e22c000) /* fcvt Dd, Sn */
        {
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            float f;
            memcpy(&f, &c->d[rn], 4);
            double d = (double)f;
            memcpy(&c->d[rd], &d, 8);
            c->dhi[rd] = 0;
            c->pc = next;
            continue;
        }
        if ((insn & 0xfffffc00) == 0x1e624000) /* fcvt Sd, Dn */
        {
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            double d;
            memcpy(&d, &c->d[rn], 8);
            float f = (float)d;
            memcpy(&c->d[rd], &f, 4);
            c->dhi[rd] = 0;
            c->pc = next;
            continue;
        }
        /* SCVTF / UCVTF (integer to floating) */
        if ((insn & 0xfffffc00) == 0x9e620000 ||
            (insn & 0xfffffc00) == 0x9e630000 ||
            (insn & 0xfffffc00) == 0x1e620000 ||
            (insn & 0xfffffc00) == 0x1e630000 ||
            (insn & 0xfffffc00) == 0x9e220000 ||
            (insn & 0xfffffc00) == 0x9e230000 ||
            (insn & 0xfffffc00) == 0x1e220000 ||
            (insn & 0xfffffc00) == 0x1e230000)
        {
            int is_signed = (insn & 0x00010000) == 0;
            int is_double = (insn >> 22) & 1;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            uint64_t raw = c->x[rn];
            double v;
            if ((insn & 0x80000000) != 0)
                v = is_signed ? (double)(int64_t)raw
                              : (double)(uint64_t)raw;
            else
                v = is_signed ? (double)(int32_t)(uint32_t)raw
                              : (double)(uint32_t)raw;
            if (is_double)
                memcpy(&c->d[rd], &v, 8);
            else
            {
                float f = (float)v;
                uint32_t out;
                memcpy(&out, &f, 4);
                c->d[rd] = out;
            }
            c->dhi[rd] = 0;
            c->pc = next;
            continue;
        }
        /* FCVTZS / FCVTZU (floating to integer, toward zero) */
        if ((insn & 0xfffffc00) == 0x9e780000 ||
            (insn & 0xfffffc00) == 0x9e790000 ||
            (insn & 0xfffffc00) == 0x1e780000 ||
            (insn & 0xfffffc00) == 0x1e790000 ||
            (insn & 0xfffffc00) == 0x9e380000 ||
            (insn & 0xfffffc00) == 0x9e390000 ||
            (insn & 0xfffffc00) == 0x1e380000 ||
            (insn & 0xfffffc00) == 0x1e390000)
        {
            int is_unsigned = (insn & 0x00010000) != 0;
            int is_double = (insn >> 22) & 1;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            double v;
            if (is_double)
                memcpy(&v, &c->d[rn], 8);
            else
            {
                float f;
                uint32_t bits = (uint32_t)c->d[rn];
                memcpy(&f, &bits, 4);
                v = f;
            }
            if ((insn & 0x80000000) != 0)
            {
                if (is_unsigned)
                    wr_x(c, rd, (uint64_t)v);
                else
                    wr_x(c, rd, (uint64_t)(int64_t)v);
            }
            else
            {
                if (is_unsigned)
                    wr_w(c, rd, (uint32_t)v);
                else
                    wr_w(c, rd, (uint32_t)(int32_t)v);
            }
            c->pc = next;
            continue;
        }
        /* CCMP / CCMN: conditional integer compare (register or immediate).
         * When the condition fails the NZCV immediate is installed. */
        if ((insn & 0x3fe00410) == 0x3a400000)
        {
            int sf = (insn >> 31) & 1;
            int bits = sf ? 64 : 32;
            int is_ccmn = ((insn >> 30) & 1) == 0;
            int is_imm = (insn >> 11) & 1;
            int rm = (insn >> 16) & 31;
            int cond = (insn >> 12) & 0xf;
            int rn = (insn >> 5) & 31;
            unsigned imm = insn & 0xf;
            uint64_t a = rd_x(c, rn) & mask_for(bits);
            if (a64_cond(c->nzcv, cond))
            {
                uint64_t b = is_imm ? (uint64_t)rm
                                    : (rd_x(c, rm) & mask_for(bits));
                if (is_ccmn)
                    a64_add_flags(c, a, b, bits, 1);
                else
                    a64_sub_flags(c, a, b, bits, 1);
            }
            else
            {
                c->nzcv = ((imm & 8) ? A64_N : 0) |
                          ((imm & 4) ? A64_Z : 0) |
                          ((imm & 2) ? A64_C : 0) |
                          ((imm & 1) ? A64_V : 0);
            }
            c->pc = next;
            continue;
        }
        /* FCCMP / FCCMPE: conditional floating-point compare. When the
         * condition fails the NZCV immediate is installed instead. */
        if ((insn & 0xff200c00) == 0x1e200400)
        {
            int is_double = (insn >> 22) & 1;
            int rm = (insn >> 16) & 31;
            int cond = (insn >> 12) & 0xf;
            int rn = (insn >> 5) & 31;
            unsigned imm = insn & 0xf;
            if (!a64_cond(c->nzcv, cond))
            {
                c->nzcv = ((imm & 8) ? A64_N : 0) |
                          ((imm & 4) ? A64_Z : 0) |
                          ((imm & 2) ? A64_C : 0) |
                          ((imm & 1) ? A64_V : 0);
            }
            else
            {
                double a, b;
                if (is_double)
                {
                    memcpy(&a, &c->d[rn], 8);
                    memcpy(&b, &c->d[rm], 8);
                }
                else
                {
                    float fa, fb;
                    uint32_t bits = (uint32_t)c->d[rn];
                    memcpy(&fa, &bits, 4);
                    a = fa;
                    bits = (uint32_t)c->d[rm];
                    memcpy(&fb, &bits, 4);
                    b = fb;
                }
                if (a != a || b != b)
                    c->nzcv = A64_C | A64_V;
                else if (a < b)
                    c->nzcv = A64_N;
                else if (a == b)
                    c->nzcv = A64_Z | A64_C;
                else
                    c->nzcv = A64_C;
            }
            c->pc = next;
            continue;
        }
        /* FCMP / FCMPE (bit 3 selects the zero operand) */
        if ((insn & 0xff20fc07) == 0x1e202000)
        {
            int is_double = (insn >> 22) & 1;
            int rn = (insn >> 5) & 31;
            int rm = (insn >> 16) & 31;
            int zero = (insn & 0x8) != 0;
            double a, b;
            if (is_double)
            {
                memcpy(&a, &c->d[rn], 8);
                if (zero)
                    b = 0.0;
                else
                    memcpy(&b, &c->d[rm], 8);
            }
            else
            {
                float fa, fb;
                uint32_t bits = (uint32_t)c->d[rn];
                memcpy(&fa, &bits, 4);
                a = fa;
                if (zero)
                    b = 0.0;
                else
                {
                    bits = (uint32_t)c->d[rm];
                    memcpy(&fb, &bits, 4);
                    b = fb;
                }
            }
            if (a != a || b != b)
                c->nzcv = A64_C | A64_V;
            else if (a < b)
                c->nzcv = A64_N;
            else if (a == b)
                c->nzcv = A64_Z | A64_C;
            else
                c->nzcv = A64_C;
            c->pc = next;
            continue;
        }
        /* FMADD / FMSUB / FNMADD / FNMSUB */
        if ((insn & 0x7f000000) == 0x1f000000)
        {
            int is_double = (insn >> 22) & 1;
            int negate_product = (insn >> 21) & 1;
            int subtract = (insn >> 15) & 1;
            int rm = (insn >> 16) & 31;
            int ra = (insn >> 10) & 31;
            int rn = (insn >> 5) & 31;
            int rd = insn & 31;
            if (is_double)
            {
                double a, b, add, r;
                memcpy(&a, &c->d[rn], 8);
                memcpy(&b, &c->d[rm], 8);
                memcpy(&add, &c->d[ra], 8);
                /* FMADD: a*b+add; FMSUB: add-a*b;
                 * FNMADD: -(a*b+add); FNMSUB: a*b-add. */
                if (!negate_product)
                    r = subtract ? add - a * b : a * b + add;
                else
                    r = subtract ? a * b - add : -(a * b + add);
                memcpy(&c->d[rd], &r, 8);
                c->dhi[rd] = 0;
            }
            else
            {
                float a, b, cf, r;
                uint32_t bits = (uint32_t)c->d[rn];
                memcpy(&a, &bits, 4);
                bits = (uint32_t)c->d[rm];
                memcpy(&b, &bits, 4);
                bits = (uint32_t)c->d[ra];
                memcpy(&cf, &bits, 4);
                if (!negate_product)
                    r = subtract ? cf - a * b : a * b + cf;
                else
                    r = subtract ? a * b - cf : -(a * b + cf);
                uint32_t out;
                memcpy(&out, &r, 4);
                c->d[rd] = out;
                c->dhi[rd] = 0;
            }
            c->pc = next;
            continue;
        }
        /* FP LDR (literal) */
        if ((insn & 0x3f000000) == 0x1c000000)
        {
            unsigned opc = (insn >> 30) & 3;
            int64_t off = (int64_t)((insn >> 5) & 0x7ffff);
            if (off & (1 << 18))
                off -= (1 << 19);
            off <<= 2;
            int rt = insn & 31;
            uint64_t addr = c->pc + (uint64_t)off;
            if (opc == 0 || opc == 1)
            {
                c->d[rt] = a64_load(c, addr, opc == 0 ? 4 : 8, 0);
                c->dhi[rt] = 0;
            }
            else if (opc == 2)
            {
                c->d[rt] = a64_load(c, addr, 8, 0);
                c->dhi[rt] = a64_load(c, addr + 8, 8, 0);
            }
            else
                return a64_fail(c, "unsupported FP literal load", insn);
            c->pc = next;
            continue;
        }
        /* FP LDR / STR (unsigned offset) */
        if ((insn & 0x3f000000) == 0x3d000000)
        {
            unsigned size = (insn >> 30) & 3;
            unsigned opc = (insn >> 22) & 3;
            unsigned scale = (size == 0 && opc >= 2) ? 4 : size;
            uint64_t imm = ((insn >> 10) & 0xfff) << scale;
            int rn = (insn >> 5) & 31;
            int rt = insn & 31;
            uint64_t addr = rd_sp(c, rn) + imm;
            if (size == 0 && opc >= 2)
            {
                /* Q register: sixteen bytes across both halves. */
                if (opc == 2)
                {
                    a64_store(c, addr, c->d[rt], 8);
                    a64_store(c, addr + 8, c->dhi[rt], 8);
                }
                else
                {
                    c->d[rt] = a64_load(c, addr, 8, 0);
                    c->dhi[rt] = a64_load(c, addr + 8, 8, 0);
                }
                c->pc = next;
                continue;
            }
            int bytes = 1 << size;
            if (opc == 0)
                a64_store(c, addr, c->d[rt], bytes);
            else
            {
                c->d[rt] = a64_load(c, addr, bytes, 0);
                c->dhi[rt] = 0;
            }
            c->pc = next;
            continue;
        }
        /* NOP / hints */
        if ((insn & 0xfffff01f) == 0xd503201f)
        {
            c->pc = next;
            continue;
        }
        return a64_fail(c, "unsupported instruction", insn);
    }
}

static int a64_run_blocks(struct a64_cpu *c);

/* Runs an arm64 method reached from a native x86_64 message send. The
 * trampoline in start.S saved rdi/rsi/rdx/rcx/r8/r9 at frame[5..0] and
 * xmm0..7 at frame+0x30; the method's type encoding says which saved
 * register holds each argument. Only scalar arguments and returns are
 * marshalled: aggregates need their own memory class handling. */
static int arm64_x86_msg_hook(void *imp, void *self, void *sel,
                              void *frame, void *result)
{
    if (!g_arm64_img || !frame || !result ||
        !image_contains(g_arm64_img, (uint64_t)(uintptr_t)imp))
        return 0;
    const char *types = objc_lookup_method_types(self, sel);
    if (!types)
    {
        fprintf(stderr,
                "iosim: arm64: native message has no type encoding for %s\n",
                sel ? (const char *)sel : "(null)");
        _exit(1);
    }
    const char *p = a64_skip_qualifiers(types);
    char rtc = *p;
    p = a64_skip_type(p);
    p = a64_skip_number(p);
    p = a64_skip_type(p); /* self */
    p = a64_skip_number(p);
    p = a64_skip_type(p); /* _cmd */
    p = a64_skip_number(p);
    if (rtc == '{' || rtc == '(' || rtc == '[' || rtc == 'D')
    {
        fprintf(stderr,
                "iosim: arm64: native-to-guest message %s returns an "
                "aggregate\n",
                sel ? (const char *)sel : "(null)");
        _exit(1);
    }

    struct a64_cpu cpu;
    memset(&cpu, 0, sizeof cpu);
    cpu.img = g_arm64_img;
    cpu.trace = getenv("IOSIM_ARM64_TRACE") != NULL;
    cpu.x[0] = (uint64_t)(uintptr_t)self;
    cpu.x[1] = (uint64_t)(uintptr_t)sel;
    int arg_gp = 2;
    int arg_fp = 0;
    int frame_gp = 3; /* rdx, then rcx, r8, r9 */
    while (*p)
    {
        p = a64_skip_qualifiers(p);
        char t = *p;
        p = a64_skip_type(p);
        p = a64_skip_number(p);
        if (!t || t == 'v')
            break;
        if (t == '{' || t == '(' || t == '[' || t == 'D')
        {
            fprintf(stderr,
                    "iosim: arm64: native-to-guest message %s has an "
                    "aggregate argument\n",
                    sel ? (const char *)sel : "(null)");
            _exit(1);
        }
        if (t == 'f' || t == 'd')
        {
            if (arg_fp >= 8)
            {
                fprintf(stderr,
                        "iosim: arm64: too many FP arguments for %s\n",
                        sel ? (const char *)sel : "(null)");
                _exit(1);
            }
            cpu.d[arg_fp] = ((uint64_t *)((uint8_t *)frame + 0x30))[2 *
                                                                   arg_fp];
            arg_fp++;
        }
        else
        {
            if (frame_gp < 0)
            {
                fprintf(stderr,
                        "iosim: arm64: too many integer arguments for %s\n",
                        sel ? (const char *)sel : "(null)");
                _exit(1);
            }
            cpu.x[arg_gp++] = ((uint64_t *)frame)[frame_gp--];
        }
    }

    void *stack = mmap(NULL, A64_STACK_SIZE, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (stack == MAP_FAILED)
    {
        fprintf(stderr, "iosim: arm64: cannot allocate callback stack: %s\n",
                strerror(errno));
        _exit(1);
    }
    cpu.sp = ((uint64_t)(uintptr_t)stack + A64_STACK_SIZE) & ~0xfull;
    cpu.x[30] = A64_RETURN_SENTINEL;
    cpu.pc = (uint64_t)(uintptr_t)imp;
    a64_run_blocks(&cpu);
    munmap(stack, A64_STACK_SIZE);

    uint64_t ret = cpu.x[0];
    uint64_t fpr = cpu.d[0];
    if (rtc == 'v')
    {
        ret = 0;
        fpr = 0;
    }
    else if (rtc == 'f')
        fpr &= 0xffffffffu;
    *(uint64_t *)result = ret;
    memcpy((uint8_t *)result + 8, &fpr, sizeof fpr);
    if (cpu.trace)
        fprintf(stderr,
                "arm64 native->guest %s returned 0x%llx (fp 0x%llx)\n",
                sel ? (const char *)sel : "(null)",
                (unsigned long long)ret, (unsigned long long)fpr);
    return 1;
}

/* --- helpers called from translated blocks --------------------------- */

int a64t_cond(struct a64_cpu *c, int cond)
{
    return a64_cond(c->nzcv, (unsigned)cond);
}

/* Executes the flag-setting ADD/SUB forms (immediate or shifted/extended
 * register, including CMP/CMN) with the interpreter's semantics. */
void a64t_addsub_flags(struct a64_cpu *c, uint32_t insn)
{
    int sf = (insn >> 31) & 1;
    int sub = (insn >> 30) & 1;
    int bits = sf ? 64 : 32;
    int rd = insn & 31;
    if ((insn & 0x1f000000) == 0x11000000)
    {
        unsigned shift = (insn >> 22) & 1;
        uint64_t imm = (insn >> 10) & 0xfff;
        int rn = (insn >> 5) & 31;
        if (shift)
            imm <<= 12;
        uint64_t a = rn == 31 ? c->sp : c->x[rn];
        uint64_t res = sub ? a64_sub_flags(c, a, imm, bits, 1)
                           : a64_add_flags(c, a, imm, bits, 1);
        wr_x(c, rd, res);
        return;
    }
    int extended = (insn & 0x00200000) != 0;
    int rm = (insn >> 16) & 31;
    int rn = (insn >> 5) & 31;
    uint64_t b = rd_x(c, rm);
    if (extended)
    {
        unsigned option = (insn >> 13) & 7;
        unsigned shift = (insn >> 10) & 7;
        switch (option)
        {
        case 0: b = (uint8_t)b; break;
        case 1: b = (uint16_t)b; break;
        case 2: b = (uint32_t)b; break;
        case 3: b &= ~0ull; break;
        case 4: b = (uint64_t)(int64_t)(int8_t)b; break;
        case 5: b = (uint64_t)(int64_t)(int16_t)b; break;
        case 6: b = (uint64_t)(int64_t)(int32_t)b; break;
        case 7: break;
        }
        b <<= shift;
    }
    else
    {
        unsigned shift_type = (insn >> 22) & 3;
        unsigned amount = (insn >> 10) & 0x3f;
        if (bits == 32)
        {
            amount &= 31;
            b = (uint32_t)b;
        }
        if (shift_type == 0)
            b <<= amount;
        else if (shift_type == 1)
            b >>= amount;
        else if (shift_type == 2)
            b = (uint64_t)((int64_t)(b << (64 - bits)) >>
                           (64 - bits)) >> amount;
    }
    uint64_t a = rn == 31 ? c->sp : c->x[rn];
    uint64_t res = sub ? a64_sub_flags(c, a, b, bits, 1)
                       : a64_add_flags(c, a, b, bits, 1);
    wr_x(c, rd, res);
}

void a64t_bitfield_insn(struct a64_cpu *c, uint32_t insn)
{
    int ok = 0;
    uint64_t res = a64_bitfield(c, insn, &ok);
    if (!ok)
    {
        a64_fail(c, "unsupported bitfield move", insn);
        return;
    }
    wr_x(c, insn & 31, res);
}

void a64t_madd_insn(struct a64_cpu *c, uint32_t insn)
{
    int sf = (insn >> 31) & 1;
    int sub = (insn >> 15) & 1;
    int rm = (insn >> 16) & 31;
    int ra = (insn >> 10) & 31;
    int rn = (insn >> 5) & 31;
    int rd = insn & 31;
    if (insn & 0x00200000)
    {
        int is_signed = (insn & 0x00800000) == 0;
        uint64_t a = is_signed ? (uint64_t)(int64_t)(int32_t)c->x[rn]
                               : (uint32_t)c->x[rn];
        uint64_t b = is_signed ? (uint64_t)(int64_t)(int32_t)c->x[rm]
                               : (uint32_t)c->x[rm];
        uint64_t prod = a * b;
        uint64_t acc = c->x[ra];
        wr_x(c, rd, sub ? acc - prod : acc + prod);
    }
    else
    {
        uint64_t bits = sf ? ~0ull : 0xffffffffull;
        uint64_t prod = (rd_x(c, rn) * rd_x(c, rm)) & bits;
        uint64_t acc = rd_x(c, ra) & bits;
        wr_x(c, rd, sub ? (acc - prod) & bits : (acc + prod) & bits);
    }
}

void a64t_div_insn(struct a64_cpu *c, uint32_t insn)
{
    int sf = (insn >> 31) & 1;
    int is_signed = (insn & 0x400) != 0;
    int rm = (insn >> 16) & 31;
    int rn = (insn >> 5) & 31;
    int rd = insn & 31;
    if (sf)
    {
        if (is_signed)
        {
            int64_t a = (int64_t)c->x[rn], b = (int64_t)c->x[rm];
            wr_x(c, rd, b ? (uint64_t)(a / b) : 0);
        }
        else
        {
            uint64_t a = c->x[rn], b = c->x[rm];
            wr_x(c, rd, b ? a / b : 0);
        }
    }
    else
    {
        if (is_signed)
        {
            int32_t a = (int32_t)c->x[rn], b = (int32_t)c->x[rm];
            wr_w(c, rd, b ? (uint32_t)(a / b) : 0);
        }
        else
        {
            uint32_t a = (uint32_t)c->x[rn], b = (uint32_t)c->x[rm];
            wr_w(c, rd, b ? a / b : 0);
        }
    }
}

void a64t_csel_insn(struct a64_cpu *c, uint32_t insn)
{
    int sf = (insn >> 31) & 1;
    int op = (((insn >> 30) & 1) << 1) | ((insn >> 10) & 1);
    int rm = (insn >> 16) & 31;
    unsigned cond = (insn >> 12) & 0xf;
    int rn = (insn >> 5) & 31;
    int rd = insn & 31;
    uint64_t m = sf ? ~0ull : 0xffffffffull;
    uint64_t a = rd_x(c, rn), b = rd_x(c, rm);
    if (a64_cond(c->nzcv, cond))
        wr_x(c, rd, a);
    else if (op == 0)
        wr_x(c, rd, b & m);
    else if (op == 1)
        wr_x(c, rd, (b + 1) & m);
    else if (op == 2)
        wr_x(c, rd, (~b) & m);
    else
        wr_x(c, rd, (0 - b) & m);
}

void a64t_fp2_insn(struct a64_cpu *c, uint32_t insn)
{
    int is_double = (insn >> 22) & 1;
    int rm = (insn >> 16) & 31;
    int rn = (insn >> 5) & 31;
    int rd = insn & 31;
    unsigned op = (insn >> 12) & 0xf;
    if (is_double)
    {
        double a, b, r;
        memcpy(&a, &c->d[rn], 8);
        memcpy(&b, &c->d[rm], 8);
        if (op == 2)
            r = a + b;
        else if (op == 3)
            r = a - b;
        else if (op == 0)
            r = a * b;
        else
            r = a / b;
        memcpy(&c->d[rd], &r, 8);
        c->dhi[rd] = 0;
    }
    else
    {
        float a, b, r;
        uint32_t bits = (uint32_t)c->d[rn];
        memcpy(&a, &bits, 4);
        bits = (uint32_t)c->d[rm];
        memcpy(&b, &bits, 4);
        if (op == 2)
            r = a + b;
        else if (op == 3)
            r = a - b;
        else if (op == 0)
            r = a * b;
        else
            r = a / b;
        uint32_t out;
        memcpy(&out, &r, 4);
        c->d[rd] = out;
        c->dhi[rd] = 0;
    }
}

void a64t_fp3_insn(struct a64_cpu *c, uint32_t insn)
{
    int is_double = (insn >> 22) & 1;
    int negate_product = (insn >> 21) & 1;
    int subtract = (insn >> 15) & 1;
    int rm = (insn >> 16) & 31;
    int ra = (insn >> 10) & 31;
    int rn = (insn >> 5) & 31;
    int rd = insn & 31;
    if (is_double)
    {
        double a, b, add, r;
        memcpy(&a, &c->d[rn], 8);
        memcpy(&b, &c->d[rm], 8);
        memcpy(&add, &c->d[ra], 8);
        if (!negate_product)
            r = subtract ? add - a * b : a * b + add;
        else
            r = subtract ? a * b - add : -(a * b + add);
        memcpy(&c->d[rd], &r, 8);
        c->dhi[rd] = 0;
    }
    else
    {
        float a, b, cf, r;
        uint32_t bits = (uint32_t)c->d[rn];
        memcpy(&a, &bits, 4);
        bits = (uint32_t)c->d[rm];
        memcpy(&b, &bits, 4);
        bits = (uint32_t)c->d[ra];
        memcpy(&cf, &bits, 4);
        if (!negate_product)
            r = subtract ? cf - a * b : a * b + cf;
        else
            r = subtract ? a * b - cf : -(a * b + cf);
        uint32_t out;
        memcpy(&out, &r, 4);
        c->d[rd] = out;
        c->dhi[rd] = 0;
    }
}

void a64t_fp1_insn(struct a64_cpu *c, uint32_t insn)
{
    if ((insn & 0xfffffc00) == 0x9e620000 ||
        (insn & 0xfffffc00) == 0x9e630000 ||
        (insn & 0xfffffc00) == 0x1e620000 ||
        (insn & 0xfffffc00) == 0x1e630000)
    {
        int is_signed = (insn & 0x00010000) == 0;
        int is_double = (insn >> 22) & 1;
        int rn = (insn >> 5) & 31;
        int rd = insn & 31;
        uint64_t raw = c->x[rn];
        double v;
        if ((insn & 0x80000000) != 0)
            v = is_signed ? (double)(int64_t)raw : (double)(uint64_t)raw;
        else
            v = is_signed ? (double)(int32_t)(uint32_t)raw
                          : (double)(uint32_t)raw;
        if (is_double)
            memcpy(&c->d[rd], &v, 8);
        else
        {
            float f = (float)v;
            uint32_t out;
            memcpy(&out, &f, 4);
            c->d[rd] = out;
        }
        c->dhi[rd] = 0;
        return;
    }
    int is_unsigned = (insn & 0x00010000) != 0;
    int is_double = (insn >> 22) & 1;
    int rn = (insn >> 5) & 31;
    int rd = insn & 31;
    double v;
    if (is_double)
        memcpy(&v, &c->d[rn], 8);
    else
    {
        float f;
        uint32_t bits = (uint32_t)c->d[rn];
        memcpy(&f, &bits, 4);
        v = f;
    }
    if ((insn & 0x80000000) != 0)
    {
        if (is_unsigned)
            wr_x(c, rd, (uint64_t)v);
        else
            wr_x(c, rd, (uint64_t)(int64_t)v);
    }
    else
    {
        if (is_unsigned)
            wr_w(c, rd, (uint32_t)v);
        else
            wr_w(c, rd, (uint32_t)(int32_t)v);
    }
}

void a64t_fcmp_insn(struct a64_cpu *c, uint32_t insn)
{
    int is_double = (insn >> 22) & 1;
    int rn = (insn >> 5) & 31;
    int rm = (insn >> 16) & 31;
    int zero = (insn & 0x8) != 0;
    double a, b;
    if (is_double)
    {
        memcpy(&a, &c->d[rn], 8);
        if (zero)
            b = 0.0;
        else
            memcpy(&b, &c->d[rm], 8);
    }
    else
    {
        float fa, fb;
        uint32_t bits = (uint32_t)c->d[rn];
        memcpy(&fa, &bits, 4);
        a = fa;
        if (zero)
            b = 0.0;
        else
        {
            bits = (uint32_t)c->d[rm];
            memcpy(&fb, &bits, 4);
            b = fb;
        }
    }
    if (a != a || b != b)
        c->nzcv = A64_C | A64_V;
    else if (a < b)
        c->nzcv = A64_N;
    else if (a == b)
        c->nzcv = A64_Z | A64_C;
    else
        c->nzcv = A64_C;
}

int iosim_arm64_pc_in_image(struct a64_cpu *c, uint64_t pc)
{
    return c && ((c->img && image_contains(c->img, pc)) ||
                 a64_exec_region_contains(pc));
}

/* Runs translated blocks until the guest returns. Blocks edit the machine
 * state in place; addresses with no inline form are interpreted one
 * instruction at a time, which also serves as the correctness fallback. */
static int a64_run_blocks(struct a64_cpu *c)
{
    static int nojit = -1;
    if (nojit < 0)
        nojit = getenv("IOSIM_ARM64_NOJIT") != NULL;
    if (nojit)
        return a64_run(c);
    for (;;)
    {
        if (c->pc == A64_RETURN_SENTINEL)
            return (int)(int64_t)c->x[0];
        if (c->trace)
            fprintf(stderr, "arm64 driver pc=0x%llx\n",
                    (unsigned long long)c->pc);
        if (!in_any_arm64_image(c, c->pc))
        {
            /* A tail branch or call left the guest image and its
             * runtime-generated code pages: run the native target and
             * resume at its return address. */
            uint64_t out = 0;
            if (a64_dispatch_native(c, c->pc, 0, 0, &out) < 0)
                return -1;
            c->pc = out;
            continue;
        }
        a64_block_fn blk = a64_jit_lookup(c, c->pc);
        if (blk)
        {
            blk(c);
            continue;
        }
        c->step_limit = 1;
        c->steps = 0;
        c->step_done = 0;
        int rc = a64_run(c);
        c->step_limit = 0;
        if (!c->step_done)
            return rc;
    }
}

int arm64_run_main(struct iosim_image *img, int argc, char **argv,
                   char **envp, char **apple)
{
    struct a64_cpu cpu;
    memset(&cpu, 0, sizeof cpu);
    cpu.img = img;
    cpu.trace = getenv("IOSIM_ARM64_TRACE") != NULL;
    g_arm64_img = img;
    iosim_arm64_msg_hook = arm64_x86_msg_hook;

    void *stack = mmap(NULL, A64_STACK_SIZE, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (stack == MAP_FAILED)
    {
        fprintf(stderr, "iosim: arm64: cannot allocate guest stack: %s\n",
                strerror(errno));
        return 1;
    }
    cpu.sp = ((uint64_t)(uintptr_t)stack + A64_STACK_SIZE) & ~0xfull;
    cpu.x[0] = (uint64_t)(int64_t)argc;
    cpu.x[1] = (uint64_t)(uintptr_t)argv;
    cpu.x[2] = (uint64_t)(uintptr_t)envp;
    cpu.x[3] = (uint64_t)(uintptr_t)apple;
    cpu.pc = img->entry_addr + (uint64_t)img->slide;

    int rc = a64_run_blocks(&cpu);
    munmap(stack, A64_STACK_SIZE);
    return rc;
}

int iosim_arm64_is_guest_code(void *fn)
{
    uint64_t addr = (uint64_t)(uintptr_t)fn;
    return fn && ((g_arm64_img && image_contains(g_arm64_img, addr)) ||
                  a64_exec_region_contains(addr));
}

int iosim_arm64_pc_is_static(struct a64_cpu *c, uint64_t pc)
{
    return c && c->img && image_contains(c->img, pc);
}

/* General native-to-guest call used by C callbacks (qsort comparators and
 * the like). Arguments are taken from the arm64 register conventions and
 * the scalar results are published in ret. */
void iosim_arm64_call_guest_ret(void *fn, const uint64_t *gp,
                                const uint64_t *fp, uint64_t *ret)
{
    if (!iosim_arm64_is_guest_code(fn))
        return;
    struct a64_cpu cpu;
    memset(&cpu, 0, sizeof cpu);
    cpu.img = g_arm64_img;
    cpu.trace = getenv("IOSIM_ARM64_TRACE") != NULL;
    void *stack = mmap(NULL, A64_STACK_SIZE, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (stack == MAP_FAILED)
    {
        fprintf(stderr,
                "iosim: arm64: cannot allocate callback stack: %s\n",
                strerror(errno));
        return;
    }
    cpu.sp = ((uint64_t)(uintptr_t)stack + A64_STACK_SIZE) & ~0xfull;
    for (int i = 0; i < 8; i++)
    {
        if (gp)
            cpu.x[i] = gp[i];
        if (fp)
            cpu.d[i] = fp[i];
    }
    cpu.x[30] = A64_RETURN_SENTINEL;
    cpu.pc = (uint64_t)(uintptr_t)fn;
    a64_run_blocks(&cpu);
    munmap(stack, A64_STACK_SIZE);
    if (ret)
    {
        ret[0] = cpu.x[0];
        ret[1] = cpu.d[0];
    }
}

int iosim_arm64_call_guest(void *fn, uint64_t a0, uint64_t a1)
{
    if (!iosim_arm64_is_guest_code(fn))
        return 0;
    struct a64_cpu cpu;
    memset(&cpu, 0, sizeof cpu);
    cpu.img = g_arm64_img;
    cpu.trace = getenv("IOSIM_ARM64_TRACE") != NULL;
    void *stack = mmap(NULL, A64_STACK_SIZE, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (stack == MAP_FAILED)
    {
        fprintf(stderr,
                "iosim: arm64: cannot allocate callback stack: %s\n",
                strerror(errno));
        return 1;
    }
    cpu.sp = ((uint64_t)(uintptr_t)stack + A64_STACK_SIZE) & ~0xfull;
    cpu.x[0] = a0;
    cpu.x[1] = a1;
    cpu.x[30] = A64_RETURN_SENTINEL;
    cpu.pc = (uint64_t)(uintptr_t)fn;
    a64_run_blocks(&cpu);
    munmap(stack, A64_STACK_SIZE);
    return 1;
}
