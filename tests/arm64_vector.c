/* An arm64 loop that clang vectorizes: the NEON path uses 128-bit
 * registers, vector immediates, ORR, FMLA and element extraction. Built
 * for x86_64 as well, where it must produce the same exit status. */
int scale(float *out, const float *in, int n)
{
    for (int i = 0; i < n; i++)
        out[i] = in[i] * 2.0f + 1.0f;
    return n;
}

float in[16] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
float pad[128];
float out[16];

int main(void)
{
    scale(out, in, 16);
    float s = 0;
    for (int i = 0; i < 16; i++)
        s += out[i];
    return (int)s; /* sum(2x + 1) = 288 */
}
