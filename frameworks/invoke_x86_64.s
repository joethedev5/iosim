    .text
    .globl _iosim_dynamic_invoke
/* void iosim_dynamic_invoke(void *imp, void *self, void *sel,
 *                           void *gp, void *sse, void *retbuf)
 *
 * Calls imp with self and sel, the four remaining integer argument
 * registers from gp[0..3] (rdx, rcx, r8, r9) and xmm0..xmm7 from sse[0..7].
 * retbuf receives rax at offset 0 and the 16 bytes of xmm0 at offset 8.
 * Only register arguments are supported; struct and stack arguments are
 * rejected by the caller.
 */
_iosim_dynamic_invoke:
    pushq %rbx
    movq %r9, %rbx              /* retbuf */
    movq %rcx, %r10             /* gp */
    movq %r8, %r11              /* sse */
    movq %rdi, %rax             /* imp */
    movq %rsi, %rdi             /* self */
    movq %rdx, %rsi             /* sel */
    movq 0(%r10), %rdx
    movq 8(%r10), %rcx
    movq 16(%r10), %r8
    movq 24(%r10), %r9
    movdqu 0(%r11), %xmm0
    movdqu 16(%r11), %xmm1
    movdqu 32(%r11), %xmm2
    movdqu 48(%r11), %xmm3
    movdqu 64(%r11), %xmm4
    movdqu 80(%r11), %xmm5
    movdqu 96(%r11), %xmm6
    movdqu 112(%r11), %xmm7
    callq *%rax
    movq %rax, 0(%rbx)
    movdqu %xmm0, 8(%rbx)
    popq %rbx
    ret
