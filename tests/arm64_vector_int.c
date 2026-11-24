/* An arm64 integer loop that clang vectorizes to MLA/ADD/ADDV over 4S
 * lanes. Built for x86_64 as well; both must exit with status 168
 * (the sum 424 masked by the process status). */
int scale(int *out, const int *in, int n)
{
    for (int i = 0; i < n; i++)
        out[i] = in[i] * 3 + 1;
    return n;
}

int in[16] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
int pad[128];
int out[16];

int main(void)
{
    scale(out, in, 16);
    int s = 0;
    for (int i = 0; i < 16; i++)
        s += out[i];
    return s; /* 3 * 136 + 16 = 424 */
}
