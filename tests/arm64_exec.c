/* An arm64 executable with no framework dependencies: the interpreter must
 * run a real frame, a loop and a call, then return the result. The volatile
 * inputs keep the compiler from folding the loop away. */
volatile int arm64_seed = 40;
volatile int arm64_count = 4;

static int sum(int n)
{
    int s = 0;
    for (int i = 0; i < n; i++)
        s += i;
    return s;
}

int main(void)
{
    return arm64_seed + sum(arm64_count);
}
