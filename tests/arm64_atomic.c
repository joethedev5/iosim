/* arm64 atomic memory operations. With the default simulator target clang
 * emits the LSE read-modify-write and CAS forms, ordered loads/stores and
 * RCpc acquire loads; a baseline build (armv8-a) uses LL/SC exclusives.
 * Exits 107 when every operation observes the expected value. */
static long l;
static int i;
static unsigned char b;
static unsigned short h;

static int check(int ok)
{
    return ok ? 0 : 1;
}

#if defined(__aarch64__)
static long excl_var;
static int exclusives(void)
{
    long old, newv;
    unsigned int fail;
    do
    {
        __asm__ volatile("ldxr %0, [%1]"
                         : "=r"(old) : "r"(&excl_var) : "memory");
        newv = old + 1;
        __asm__ volatile("stxr %w0, %1, [%2]"
                         : "=&r"(fail) : "r"(newv), "r"(&excl_var)
                         : "memory");
    } while (fail);
    long old2;
    do
    {
        __asm__ volatile("ldaxr %0, [%1]"
                         : "=r"(old2) : "r"(&excl_var) : "memory");
        newv = old2 + 2;
        __asm__ volatile("stlxr %w0, %1, [%2]"
                         : "=&r"(fail) : "r"(newv), "r"(&excl_var)
                         : "memory");
    } while (fail);
    return excl_var == 3;
}
#endif

int main(void)
{
    int bad = 0;
    bad += check(__atomic_fetch_add(&l, 5, __ATOMIC_SEQ_CST) == 0);
    bad += check(__atomic_fetch_add(&l, 7, __ATOMIC_SEQ_CST) == 5);
    bad += check(l == 12);
    bad += check(__atomic_fetch_sub(&i, 3, __ATOMIC_SEQ_CST) == 0);
    bad += check(i == -3);
    bad += check(__atomic_fetch_and(&l, 6, __ATOMIC_SEQ_CST) == 12);
    bad += check(l == 4);
    bad += check(__atomic_fetch_or(&i, 10, __ATOMIC_SEQ_CST) == -3);
    bad += check(i == -1);
    bad += check(__atomic_fetch_xor(&l, 15, __ATOMIC_SEQ_CST) == 4);
    bad += check(l == 11);
    bad += check(__atomic_exchange_n(&i, 42, __ATOMIC_SEQ_CST) == -1);
    bad += check(i == 42);
    bad += check(__atomic_fetch_add(&b, 200, __ATOMIC_SEQ_CST) == 0);
    bad += check(b == 200);
    bad += check(__atomic_fetch_add(&b, 100, __ATOMIC_SEQ_CST) == 200);
    bad += check(b == 44);
    bad += check(__atomic_fetch_add(&h, 40000, __ATOMIC_SEQ_CST) == 0);
    bad += check(h == 40000);
    bad += check(__atomic_fetch_sub(&h, 10000, __ATOMIC_SEQ_CST) == 40000);
    bad += check(h == 30000);

    long expect = 11;
    bad += check(__atomic_compare_exchange_n(&l, &expect, 21, 0,
                                             __ATOMIC_SEQ_CST,
                                             __ATOMIC_SEQ_CST) == 1);
    bad += check(l == 21 && expect == 11);
    expect = 99;
    bad += check(__atomic_compare_exchange_n(&l, &expect, 33, 0,
                                             __ATOMIC_SEQ_CST,
                                             __ATOMIC_SEQ_CST) == 0);
    bad += check(l == 21 && expect == 21);

    __atomic_store_n(&l, 77, __ATOMIC_RELEASE);
    bad += check(__atomic_load_n(&l, __ATOMIC_ACQUIRE) == 77);

    b = 0;
    bad += check(__atomic_test_and_set(&b, __ATOMIC_SEQ_CST) == 0);
    bad += check(b == 1);
    bad += check(__atomic_test_and_set(&b, __ATOMIC_SEQ_CST) == 1);
    __atomic_clear(&b, __ATOMIC_SEQ_CST);
    bad += check(b == 0);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
#if defined(__aarch64__)
    bad += check(exclusives());
#endif
    return bad == 0 ? 107 : 100 + bad;
}
