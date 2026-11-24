/* Thread-local variables in an arm64 image. Each variable has a thunk in
 * __DATA,__thread_vars; the loader patches the thunk's per-image metadata
 * and the first access lazily allocates the block from __thread_data and
 * __thread_bss. The initializers, a zero-filled slot and a double all
 * have to survive. */
extern int printf(const char *fmt, ...);

static _Thread_local int counter = 5;
static _Thread_local char text[8] = "tlv";
static _Thread_local long zeros[4];
static _Thread_local double ratio = 1.5;

int main(void)
{
    counter += 37;
    text[0] = 'T';
    zeros[2] = 9;
    ratio *= 2.0;
    printf("tlv %d %s %ld %.1f\n", counter, text, zeros[2], ratio);
    return 0;
}
