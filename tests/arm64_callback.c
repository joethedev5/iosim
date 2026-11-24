/* Native qsort/bsearch call an arm64 comparator: the imported C functions
 * run as x86_64 shims and the comparator is called back through the arm64
 * callback bridge. The string comparator also calls strcmp, so the bridge
 * is re-entered from inside a bridged call. */
extern void qsort(void *base, unsigned long n, unsigned long size,
                  int (*cmp)(const void *, const void *));
extern void *bsearch(const void *key, const void *base, unsigned long n,
                     unsigned long size,
                     int (*cmp)(const void *, const void *));
extern int strcmp(const char *a, const char *b);
extern int printf(const char *fmt, ...);

static int icmp(const void *a, const void *b)
{
    int x = *(const int *)a, y = *(const int *)b;
    return (x > y) - (x < y);
}

static int scmp(const void *a, const void *b)
{
    return strcmp(*(const char *const *)a, *(const char *const *)b);
}

int main(void)
{
    int v[5] = {4, 1, 5, 2, 3};
    qsort(v, 5, sizeof v[0], icmp);
    printf("%d %d %d %d %d\n", v[0], v[1], v[2], v[3], v[4]);
    const char *w[4] = {"pear", "apple", "fig", "banana"};
    qsort(w, 4, sizeof w[0], scmp);
    printf("%s %s %s %s\n", w[0], w[1], w[2], w[3]);
    const char *key = "fig";
    const char **found = bsearch(&key, w, 4, sizeof w[0], scmp);
    int ok = v[0] == 1 && v[4] == 5 &&
             strcmp(w[0], "apple") == 0 && strcmp(w[3], "pear") == 0 &&
             found && strcmp(*found, "fig") == 0;
    return ok ? 33 : 9;
}
