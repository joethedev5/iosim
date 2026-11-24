/* An arm64 main printing through a native libc gate. Darwin arm64 passes
 * the variadic arguments on the stack; the interpreter's printf gate reads
 * them there. */
extern int printf(const char *fmt, ...);

int main(void)
{
    printf("arm64 hello %d %s\n", 42, "ok");
    return 0;
}
