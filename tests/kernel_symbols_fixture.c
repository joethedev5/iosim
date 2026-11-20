/* Kernel-table fixture: a small Mach-O with a 24-byte-entry mach trap table
 * and syscall table, so tools/kernel_symbols.py can be tested without a KDK. */
typedef unsigned long u64;

__attribute__((used)) static void trap_alpha(void)
{
    __asm__ volatile("nop");
}

__attribute__((used)) static void trap_beta(void)
{
    __asm__ volatile("nop");
}

struct mach_trap_row {
    u64 arg_info;
    void *handler;
    void *munge;
};

struct sysent_row {
    void *call;
    void *munge;
    unsigned int return_type;
    short narg;
    short arg_bytes;
};

__attribute__((used)) unsigned int mach_trap_count = 2;

__attribute__((used)) struct mach_trap_row mach_trap_table[2] = {
    {0x202, (void *)trap_alpha, (void *)0},
    {0x101, (void *)trap_beta, (void *)0},
};

__attribute__((used)) unsigned int nsysent = 2;

__attribute__((used)) struct sysent_row sysent[2] = {
    {(void *)trap_alpha, (void *)0, 1, 0, 0},
    {(void *)trap_beta, (void *)0, 0, 2, 8},
};

int main(void)
{
    /* Keep both handlers referenced; the tables themselves are used. */
    if (mach_trap_count > 100)
        trap_alpha();
    if (nsysent > 100)
        trap_beta();
    return 0;
}
