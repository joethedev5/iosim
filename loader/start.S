    .text
    .globl iosim_jump_to_entry
    .type iosim_jump_to_entry, @function
/* void iosim_jump_to_entry(void *entry, uint64_t argc, char **argv,
 *                          char **envp, char **apple, void *stack_top)
 *
 * Enter Mach-O code exactly the way the Darwin kernel enters dyld:
 * argc/argv/envp/apple are available both in registers (for simple
 * binaries linked with -e _main) and on the initial process stack
 * (for Apple's crt1 start routine).
 */
iosim_jump_to_entry:
    movq %rdi, %rax          /* entry */
    movq %rsi, %rdi          /* argc (also on stack) */
    movq %rdx, %rsi          /* argv (also on stack) */
    movq %rcx, %rdx          /* envp (also on stack) */
    movq %r8,  %rcx          /* apple (also on stack) */
    movq %r9,  %rsp          /* Darwin initial stack */
    xorq %rbp, %rbp
    jmpq *%rax
    .size iosim_jump_to_entry, .-iosim_jump_to_entry

    .section .note.GNU-stack, "", @progbits

    .text
    .globl objc_msgSend
    .type objc_msgSend, @function
/* id objc_msgSend(id self, SEL _cmd, ...)
 *
 * Save all argument registers (including SSE), ask the C runtime for the
 * IMP, restore the arguments, and tail-jump to the method. This preserves
 * the caller's return address and the exact Darwin message-send ABI.
 */
objc_msgSend:
    subq $0x80, %rsp
    movdqu %xmm0, 0x00(%rsp)
    movdqu %xmm1, 0x10(%rsp)
    movdqu %xmm2, 0x20(%rsp)
    movdqu %xmm3, 0x30(%rsp)
    movdqu %xmm4, 0x40(%rsp)
    movdqu %xmm5, 0x50(%rsp)
    movdqu %xmm6, 0x60(%rsp)
    movdqu %xmm7, 0x70(%rsp)
    pushq %rdi
    pushq %rsi
    pushq %rdx
    pushq %rcx
    pushq %r8
    pushq %r9
    subq $8, %rsp
    callq objc_lookup_imp
    addq $8, %rsp
    popq %r9
    popq %r8
    popq %rcx
    popq %rdx
    popq %rsi
    popq %rdi
    movdqu 0x00(%rsp), %xmm0
    movdqu 0x10(%rsp), %xmm1
    movdqu 0x20(%rsp), %xmm2
    movdqu 0x30(%rsp), %xmm3
    movdqu 0x40(%rsp), %xmm4
    movdqu 0x50(%rsp), %xmm5
    movdqu 0x60(%rsp), %xmm6
    movdqu 0x70(%rsp), %xmm7
    addq $0x80, %rsp
    jmpq *%rax
    .size objc_msgSend, .-objc_msgSend

    .text
    .globl objc_msgSendSuper2
    .type objc_msgSendSuper2, @function
/* id objc_msgSendSuper2(struct objc_super *super, SEL _cmd, ...)
 *
 * Save the argument registers, resolve the IMP starting at the superclass,
 * replace the objc_super pointer with its receiver, and tail-jump. */
objc_msgSendSuper2:
    subq $0x80, %rsp
    movdqu %xmm0, 0x00(%rsp)
    movdqu %xmm1, 0x10(%rsp)
    movdqu %xmm2, 0x20(%rsp)
    movdqu %xmm3, 0x30(%rsp)
    movdqu %xmm4, 0x40(%rsp)
    movdqu %xmm5, 0x50(%rsp)
    movdqu %xmm6, 0x60(%rsp)
    movdqu %xmm7, 0x70(%rsp)
    pushq %rdi
    pushq %rsi
    pushq %rdx
    pushq %rcx
    pushq %r8
    pushq %r9
    subq $8, %rsp
    callq objc_lookup_super_imp
    addq $8, %rsp
    popq %r9
    popq %r8
    popq %rcx
    popq %rdx
    popq %rsi
    popq %r10
    movq (%r10), %rdi
    movdqu 0x00(%rsp), %xmm0
    movdqu 0x10(%rsp), %xmm1
    movdqu 0x20(%rsp), %xmm2
    movdqu 0x30(%rsp), %xmm3
    movdqu 0x40(%rsp), %xmm4
    movdqu 0x50(%rsp), %xmm5
    movdqu 0x60(%rsp), %xmm6
    movdqu 0x70(%rsp), %xmm7
    addq $0x80, %rsp
    jmpq *%rax
    .size objc_msgSendSuper2, .-objc_msgSendSuper2

    .text
    .globl objc_msgSend_stret
    .type objc_msgSend_stret, @function
/* void objc_msgSend_stret(void *stretAddr, id self, SEL _cmd, ...)
 *
 * x86_64 struct-return convention: the hidden return buffer is the first
 * argument, so the lookup uses rsi/rdx and the IMP receives the original
 * register set. */
objc_msgSend_stret:
    subq $0x80, %rsp
    movdqu %xmm0, 0x00(%rsp)
    movdqu %xmm1, 0x10(%rsp)
    movdqu %xmm2, 0x20(%rsp)
    movdqu %xmm3, 0x30(%rsp)
    movdqu %xmm4, 0x40(%rsp)
    movdqu %xmm5, 0x50(%rsp)
    movdqu %xmm6, 0x60(%rsp)
    movdqu %xmm7, 0x70(%rsp)
    pushq %rdi
    pushq %rsi
    pushq %rdx
    pushq %rcx
    pushq %r8
    pushq %r9
    subq $8, %rsp
    movq %rsi, %rdi
    movq %rdx, %rsi
    callq objc_lookup_imp
    addq $8, %rsp
    popq %r9
    popq %r8
    popq %rcx
    popq %rdx
    popq %rsi
    popq %rdi
    movdqu 0x00(%rsp), %xmm0
    movdqu 0x10(%rsp), %xmm1
    movdqu 0x20(%rsp), %xmm2
    movdqu 0x30(%rsp), %xmm3
    movdqu 0x40(%rsp), %xmm4
    movdqu 0x50(%rsp), %xmm5
    movdqu 0x60(%rsp), %xmm6
    movdqu 0x70(%rsp), %xmm7
    addq $0x80, %rsp
    jmpq *%rax
    .size objc_msgSend_stret, .-objc_msgSend_stret
