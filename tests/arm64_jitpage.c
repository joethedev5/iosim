/* Runtime-generated arm64 code: main maps executable pages, copies an
 * arm64 function into them and calls through the pointers. The loader
 * records PROT_EXEC mappings as guest code, so branches into the pages
 * enter the interpreter and the block translator. One page is mapped
 * read-write and made executable afterwards with mprotect; the first
 * page is rewritten and re-protected to prove cached translations are
 * dropped. Exits 96 when every call returns the expected value. */
typedef unsigned long size_t;
extern void *mmap(void *addr, size_t len, int prot, int flags, int fd,
                  long off);
extern int mprotect(void *addr, size_t len, int prot);
extern int printf(const char *fmt, ...);

/* int jit_mix(int a, int b)
 * {
 *     int s = a + b;
 *     if (s > 100)
 *         s -= 100;
 *     return s * 3 + 1;
 * }
 * clang -target arm64-apple-ios18.0-simulator -ffreestanding -O1 */
static const unsigned int code[] = {
    0x0b000028u, /* add  w8, w1, w0         */
    0x71019109u, /* subs w9, w8, #0x64      */
    0x1a88c128u, /* csel w8, w9, w8, gt     */
    0x0b080508u, /* add  w8, w8, w8, lsl #1 */
    0x11000500u, /* add  w0, w8, #0x1       */
    0xd65f03c0u, /* ret                     */
};

static void copy_code(unsigned char *b)
{
    for (size_t i = 0; i < sizeof code; i++)
        b[i] = ((const unsigned char *)code)[i];
}

int main(void)
{
    /* PROT_READ|PROT_WRITE|PROT_EXEC, MAP_PRIVATE|MAP_ANON. */
    void *p = mmap(0, 4096, 7, 0x1002, -1, 0);
    if (p == (void *)-1)
        return 11;
    printf("page=%llx\n", (unsigned long long)(unsigned long)p);
    copy_code(p);
    int (*fn)(int, int) = (int (*)(int, int))p;
    int r = fn(70, 50);
    int r2 = fn(7, 35);

    /* A read-write mapping becomes guest code when mprotect grants
     * PROT_EXEC. */
    void *q = mmap(0, 4096, 3, 0x1002, -1, 0);
    if (q == (void *)-1)
        return 13;
    copy_code(q);
    if (mprotect(q, 4096, 7) != 0)
        return 14;
    int (*fn2)(int, int) = (int (*)(int, int))q;
    int r3 = fn2(70, 50);

    /* Rewrite the returned constant while the page is writable again,
     * then re-protect it: the cached translation must be dropped. */
    if (mprotect(p, 4096, 3) != 0)
        return 15;
    unsigned char *pb = (unsigned char *)p;
    unsigned int patched = 0x11000900u; /* add w0, w8, #2 */
    for (int i = 0; i < 4; i++)
        pb[16 + i] = ((const unsigned char *)&patched)[i];
    if (mprotect(p, 4096, 7) != 0)
        return 16;
    int r4 = fn(70, 50);

    printf("jit=%d,%d mprotect=%d reprotect=%d\n", r, r2, r3, r4);
    return (r == 61 && r2 == 127 && r3 == 61 && r4 == 62) ? 96 : 12;
}
