#ifndef IOSIM_ARM64_H
#define IOSIM_ARM64_H

#include "macho.h"

/* Runs an arm64 main entry through the interpreter. argc/argv/envp/apple
 * are passed in the Darwin arm64 registers (x0-x3). Returns main's value. */
int arm64_run_main(struct iosim_image *img, int argc, char **argv,
                   char **envp, char **apple);

/* Calls a guest arm64 function from native code with two pointer
 * arguments (block copy/dispose and byref keep/destroy helpers). Returns 1
 * when fn is arm64 guest code and was run, 0 when the caller should call it
 * directly as native code. */
int iosim_arm64_call_guest(void *fn, uint64_t a0, uint64_t a1);

/* True when fn points into the arm64 image. */
int iosim_arm64_is_guest_code(void *fn);

/* Calls an arm64 guest function from native code with up to eight integer
 * and eight floating-point arguments. ret receives x0 and d0 (low half). */
void iosim_arm64_call_guest_ret(void *fn, const uint64_t *gp,
                                const uint64_t *fp, uint64_t *ret);

#endif
