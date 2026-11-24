#ifndef IOSIM_ARM64_JIT_H
#define IOSIM_ARM64_JIT_H

#include "arm64_cpu.h"

typedef void (*a64_block_fn)(struct a64_cpu *);

/* Returns a translated block starting at pc, translating it on first use.
 * NULL means the block could not be translated and the driver should
 * single-step the instruction with the interpreter. */
a64_block_fn a64_jit_lookup(struct a64_cpu *c, uint64_t pc);

/* Drops every cached block; the arena stays allocated. */
void a64_jit_invalidate(void);

#endif
