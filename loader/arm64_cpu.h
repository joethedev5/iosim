#ifndef IOSIM_ARM64_CPU_H
#define IOSIM_ARM64_CPU_H

#include <stdint.h>

struct iosim_image;

/* The AArch64 machine state. The interpreter and the block translator share
 * this layout; translated code keeps a pointer to it in a callee-saved
 * register and edits fields in place. */
struct a64_cpu {
    uint64_t x[31];
    uint64_t sp;
    uint64_t pc;
    uint32_t nzcv;
    uint64_t d[32];    /* low 64 bits of each vector register */
    uint64_t dhi[32];  /* high 64 bits of each vector register */
    struct iosim_image *img;
    int trace;
    /* Single-step support for the block driver. Zero means "run until
     * return"; a positive limit stops after that many instructions. */
    int step_limit;
    int steps;
    int step_done;
    /* Exclusive monitor for LDXR/STXR pairs. */
    uint64_t excl_addr;
    int excl_size;
    int excl_valid;
};

/* NZCV bits. */
#define A64_N (1u << 31)
#define A64_Z (1u << 30)
#define A64_C (1u << 29)
#define A64_V (1u << 28)

/* Helpers called from translated code. The cpu pointer arrives in rdi; the
 * remaining arguments follow in the x86_64 registers. The *_insn helpers
 * take the raw guest word and reuse the interpreter's decoding. */
int a64t_cond(struct a64_cpu *c, int cond);
void a64t_addsub_flags(struct a64_cpu *c, uint32_t insn);
void a64t_bitfield_insn(struct a64_cpu *c, uint32_t insn);
void a64t_madd_insn(struct a64_cpu *c, uint32_t insn);
void a64t_div_insn(struct a64_cpu *c, uint32_t insn);
void a64t_csel_insn(struct a64_cpu *c, uint32_t insn);
void a64t_fp2_insn(struct a64_cpu *c, uint32_t insn);
void a64t_fp3_insn(struct a64_cpu *c, uint32_t insn);
void a64t_fp1_insn(struct a64_cpu *c, uint32_t insn);
void a64t_fcmp_insn(struct a64_cpu *c, uint32_t insn);

/* True when pc lies in an executable segment of the current arm64 image. */
int iosim_arm64_pc_in_image(struct a64_cpu *c, uint64_t pc);

#endif
