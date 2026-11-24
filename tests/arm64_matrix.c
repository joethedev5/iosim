/* A 4x4 float matrix multiply that clang unrolls into FMADD chains with
 * unscaled and post-indexed FP loads and stores. Returns the sum of the
 * product matrix, 43. */
float A[16] = {1, 2, 3, 4, 5, 6, 7, 8, 1, 1, 1, 1, 2, 0, 1, 0};
float B[16] = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};
float C[16];

void mm4(float *c, const float *a, const float *b)
{
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++)
        {
            float s = 0;
            for (int k = 0; k < 4; k++)
                s += a[i * 4 + k] * b[k * 4 + j];
            c[i * 4 + j] = s;
        }
}

int main(void)
{
    mm4(C, A, B);
    float s = 0;
    for (int i = 0; i < 16; i++)
        s += C[i];
    return (int)s; /* 43 */
}
