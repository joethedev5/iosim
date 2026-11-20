/* Register-preserving entry point for Mach-O thread-local variables.
 *
 * Darwin's TLV contract requires the getter to preserve every register except
 * the result (%rax). The C body may use SSE and call libc, so this stub saves
 * the caller-saved general registers and all sixteen XMM registers around it.
 * The saved %rax slot is only stack padding and is discarded rather than
 * restored, because %rax carries the returned address.
 */
    .text
    .globl iosim_tlv_get_addr
    .type iosim_tlv_get_addr, @function
iosim_tlv_get_addr:
    pushq %rax
    pushq %r11
    pushq %r10
    pushq %r9
    pushq %r8
    pushq %rsi
    pushq %rdx
    pushq %rcx
    pushq %rdi
    subq  $256, %rsp
    movaps %xmm0,   0(%rsp)
    movaps %xmm1,  16(%rsp)
    movaps %xmm2,  32(%rsp)
    movaps %xmm3,  48(%rsp)
    movaps %xmm4,  64(%rsp)
    movaps %xmm5,  80(%rsp)
    movaps %xmm6,  96(%rsp)
    movaps %xmm7, 112(%rsp)
    movaps %xmm8, 128(%rsp)
    movaps %xmm9, 144(%rsp)
    movaps %xmm10, 160(%rsp)
    movaps %xmm11, 176(%rsp)
    movaps %xmm12, 192(%rsp)
    movaps %xmm13, 208(%rsp)
    movaps %xmm14, 224(%rsp)
    movaps %xmm15, 240(%rsp)
    movq  256(%rsp), %rdi
    call  iosim_tlv_get_addr_slow
    movaps   0(%rsp), %xmm0
    movaps  16(%rsp), %xmm1
    movaps  32(%rsp), %xmm2
    movaps  48(%rsp), %xmm3
    movaps  64(%rsp), %xmm4
    movaps  80(%rsp), %xmm5
    movaps  96(%rsp), %xmm6
    movaps 112(%rsp), %xmm7
    movaps 128(%rsp), %xmm8
    movaps 144(%rsp), %xmm9
    movaps 160(%rsp), %xmm10
    movaps 176(%rsp), %xmm11
    movaps 192(%rsp), %xmm12
    movaps 208(%rsp), %xmm13
    movaps 224(%rsp), %xmm14
    movaps 240(%rsp), %xmm15
    addq  $256, %rsp
    popq  %rdi
    popq  %rcx
    popq  %rdx
    popq  %rsi
    popq  %r8
    popq  %r9
    popq  %r10
    popq  %r11
    addq  $8, %rsp
    ret
    .size iosim_tlv_get_addr, .-iosim_tlv_get_addr
