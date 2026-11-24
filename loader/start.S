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
    subq $0x28, %rsp           /* receiver + forwarded-result buffer */
    leaq (%rsp), %rdx          /* &receiver: forwarding may replace it */
    leaq 0x28(%rsp), %rcx      /* saved argument registers */
    leaq 8(%rsp), %r8          /* result of a forwarded message */
    callq objc_msgSend_lookup
    movq (%rsp), %r10
    cmpq $-1, %rax             /* sentinel: -forwardInvocation: ran */
    je 2f
    /* Messaging nil is a no-op that returns zero, exactly as on Darwin.
     * The C lookup reports that case with a null IMP. */
    testq %rax, %rax
    jz 1f
    addq $0x28, %rsp
    popq %r9
    popq %r8
    popq %rcx
    popq %rdx
    popq %rsi
    popq %rdi
    movq %r10, %rdi            /* receiver after forwardingTarget: */
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
2:  /* forwarded: return the invocation's return value */
    movq 8(%rsp), %rax
    movdqu 16(%rsp), %xmm0
    addq $0xD8, %rsp
    pxor %xmm1, %xmm1
    ret
1:  /* nil receiver: discard the saved argument area and return zero */
    addq $0xD8, %rsp
    pxor %xmm0, %xmm0
    pxor %xmm1, %xmm1
    xorl %eax, %eax
    ret
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
    testq %rax, %rax
    jz 1f
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
1:  addq $0xB0, %rsp
    pxor %xmm0, %xmm0
    pxor %xmm1, %xmm1
    xorl %eax, %eax
    ret
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
    testq %rax, %rax
    jz 1f
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
1:  addq $0xB0, %rsp
    xorl %eax, %eax
    ret
    .size objc_msgSend_stret, .-objc_msgSend_stret

    .text
    .globl iosim_arm64_native_invoke
    .type iosim_arm64_native_invoke, @function
/* void iosim_arm64_native_invoke(void *imp, void *self, void *sel,
 *                                void *gp, void *sse, void *retbuf)
 *
 * The arm64 bridge's call gate: calls a native x86_64 method with self and
 * sel, four further integer registers from gp[0..3] and xmm0..xmm7 from
 * sse[0..7]. retbuf receives rax at 0, xmm0 at 8, rdx at 24 and xmm1 at
 * 32, which covers scalar and small-aggregate results. */
iosim_arm64_native_invoke:
    pushq %rbx
    movq %r9, %rbx
    movq %rcx, %r10
    movq %r8, %r11
    movq %rdi, %rax
    movq %rsi, %rdi
    movq %rdx, %rsi
    movq 0(%r10), %rdx
    movq 8(%r10), %rcx
    movq 16(%r10), %r8
    movq 24(%r10), %r9
    movq 0(%r11), %xmm0
    movq 8(%r11), %xmm1
    movq 16(%r11), %xmm2
    movq 24(%r11), %xmm3
    movq 32(%r11), %xmm4
    movq 40(%r11), %xmm5
    movq 48(%r11), %xmm6
    movq 56(%r11), %xmm7
    callq *%rax
    movq %rax, 0(%rbx)
    movdqu %xmm0, 8(%rbx)
    movq %rdx, 24(%rbx)
    movdqu %xmm1, 32(%rbx)
    popq %rbx
    ret
    .size iosim_arm64_native_invoke, .-iosim_arm64_native_invoke

    .text
    .globl iosim_arm64_native_invoke_stret
    .type iosim_arm64_native_invoke_stret, @function
/* void iosim_arm64_native_invoke_stret(void *imp, void *ret, void *self,
 *                                      void *sel, void *gp, void *sse)
 *
 * x86_64 large-aggregate convention: the hidden return buffer is the first
 * argument, self and sel follow, then three further integer registers from
 * gp[0..2] and xmm0..xmm7 from sse[0..7]. */
iosim_arm64_native_invoke_stret:
    pushq %rbx
    movq %r9, %rbx
    movq %r8, %r10
    movq %rdi, %rax
    movq %rsi, %rdi
    movq %rdx, %rsi
    movq %rcx, %rdx
    movq 0(%r10), %rcx
    movq 8(%r10), %r8
    movq 16(%r10), %r9
    movq 0(%rbx), %xmm0
    movq 8(%rbx), %xmm1
    movq 16(%rbx), %xmm2
    movq 24(%rbx), %xmm3
    movq 32(%rbx), %xmm4
    movq 40(%rbx), %xmm5
    movq 48(%rbx), %xmm6
    movq 56(%rbx), %xmm7
    callq *%rax
    popq %rbx
    ret
    .size iosim_arm64_native_invoke_stret, .-iosim_arm64_native_invoke_stret

    .text
    .globl iosim_arm64_native_invoke_stack
    .type iosim_arm64_native_invoke_stack, @function
/* void iosim_arm64_native_invoke_stack(void *imp, void *self, void *sel,
 *                                      void *gp, void *sse, void *args,
 *                                      uint64_t args_size, void *retbuf)
 *
 * Calls a native method that takes memory-class aggregates by value. args
 * holds the x86 stack argument area in call order; it is copied below the
 * aligned stack pointer before the call. */
iosim_arm64_native_invoke_stack:
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    movq 56(%rsp), %r14
    movq 48(%rsp), %r13
    movq %r9, %r12
    movq %rdi, %rbx
    movq %rcx, %r10
    movq %r8, %r11
    movq %rsi, %rax
    movq %rdx, %r9
    movq %r13, %r15
    addq $15, %r15
    andq $-16, %r15
    subq %r15, %rsp
    movq %rsp, %rdi
    movq %r12, %rsi
    movq %r13, %rcx
    rep movsb
    movq %rax, %rdi
    movq %r9, %rsi
    movq 0(%r10), %rdx
    movq 8(%r10), %rcx
    movq 16(%r10), %r8
    movq 24(%r10), %r9
    movq 0(%r11), %xmm0
    movq 8(%r11), %xmm1
    movq 16(%r11), %xmm2
    movq 24(%r11), %xmm3
    movq 32(%r11), %xmm4
    movq 40(%r11), %xmm5
    movq 48(%r11), %xmm6
    movq 56(%r11), %xmm7
    callq *%rbx
    movq %rax, 0(%r14)
    movdqu %xmm0, 8(%r14)
    movq %rdx, 24(%r14)
    movdqu %xmm1, 32(%r14)
    addq %r15, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    ret
    .size iosim_arm64_native_invoke_stack, .-iosim_arm64_native_invoke_stack

    .text
    .globl iosim_arm64_native_invoke_stack_stret
    .type iosim_arm64_native_invoke_stack_stret, @function
/* void iosim_arm64_native_invoke_stack_stret(void *imp, void *ret,
 *                                            void *self, void *sel,
 *                                            void *gp, void *sse,
 *                                            void *args, uint64_t args_size)
 *
 * Memory-class return and stack arguments together: the hidden result
 * pointer leads the x86 argument registers, leaving three GP slots. */
iosim_arm64_native_invoke_stack_stret:
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    movq 48(%rsp), %r12
    movq 56(%rsp), %r13
    movq %rdi, %rbx
    movq %r8, %r10
    movq %r9, %r11
    movq %rsi, %r14
    movq %rdx, %rax
    movq %rcx, %r9
    movq %r13, %r15
    addq $15, %r15
    andq $-16, %r15
    subq %r15, %rsp
    movq %rsp, %rdi
    movq %r12, %rsi
    movq %r13, %rcx
    rep movsb
    movq %r14, %rdi
    movq %rax, %rsi
    movq %r9, %rdx
    movq 0(%r10), %rcx
    movq 8(%r10), %r8
    movq 16(%r10), %r9
    movq 0(%r11), %xmm0
    movq 8(%r11), %xmm1
    movq 16(%r11), %xmm2
    movq 24(%r11), %xmm3
    movq 32(%r11), %xmm4
    movq 40(%r11), %xmm5
    movq 48(%r11), %xmm6
    movq 56(%r11), %xmm7
    callq *%rbx
    addq %r15, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    ret
    .size iosim_arm64_native_invoke_stack_stret, .-iosim_arm64_native_invoke_stack_stret
