/* Floating-point coverage for the arm64 interpreter: literal loads, FMUL,
 * FMADD and FCVTZS. The volatile inputs keep the arithmetic real. */
volatile double arm64_a = 3.0;
volatile double arm64_b = 4.0;

static double hypot2(double a, double b)
{
    return a * a + b * b;
}

int main(void)
{
    double x = hypot2(arm64_a, arm64_b);
    return (int)x;
}
