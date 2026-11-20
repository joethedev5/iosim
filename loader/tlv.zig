// Zig version of the Mach-O thread-local variable getter, selectable with
// -DIOSIM_USE_ZIG_ASM=ON. The ABI contract is Darwin's: the caller passes the
// thunk in %rax and expects every other register preserved, because the C
// slow path may use SSE and call libc. The saved %rax slot is stack padding
// and is discarded so %rax carries the returned address.

extern fn iosim_tlv_get_addr_slow(thunk: *anyopaque) ?*anyopaque;

export fn iosim_tlv_get_addr() callconv(.naked) void {
    asm volatile (
        \\ pushq %rax
        \\ pushq %r11
        \\ pushq %r10
        \\ pushq %r9
        \\ pushq %r8
        \\ pushq %rsi
        \\ pushq %rdx
        \\ pushq %rcx
        \\ pushq %rdi
        \\ subq  $256, %rsp
        \\ movaps %xmm0,   0(%rsp)
        \\ movaps %xmm1,  16(%rsp)
        \\ movaps %xmm2,  32(%rsp)
        \\ movaps %xmm3,  48(%rsp)
        \\ movaps %xmm4,  64(%rsp)
        \\ movaps %xmm5,  80(%rsp)
        \\ movaps %xmm6,  96(%rsp)
        \\ movaps %xmm7, 112(%rsp)
        \\ movaps %xmm8, 128(%rsp)
        \\ movaps %xmm9, 144(%rsp)
        \\ movaps %xmm10, 160(%rsp)
        \\ movaps %xmm11, 176(%rsp)
        \\ movaps %xmm12, 192(%rsp)
        \\ movaps %xmm13, 208(%rsp)
        \\ movaps %xmm14, 224(%rsp)
        \\ movaps %xmm15, 240(%rsp)
        \\ movq  256(%rsp), %rdi
        \\ call  iosim_tlv_get_addr_slow
        \\ movaps   0(%rsp), %xmm0
        \\ movaps  16(%rsp), %xmm1
        \\ movaps  32(%rsp), %xmm2
        \\ movaps  48(%rsp), %xmm3
        \\ movaps  64(%rsp), %xmm4
        \\ movaps  80(%rsp), %xmm5
        \\ movaps  96(%rsp), %xmm6
        \\ movaps 112(%rsp), %xmm7
        \\ movaps 128(%rsp), %xmm8
        \\ movaps 144(%rsp), %xmm9
        \\ movaps 160(%rsp), %xmm10
        \\ movaps 176(%rsp), %xmm11
        \\ movaps 192(%rsp), %xmm12
        \\ movaps 208(%rsp), %xmm13
        \\ movaps 224(%rsp), %xmm14
        \\ movaps 240(%rsp), %xmm15
        \\ addq  $256, %rsp
        \\ popq  %rdi
        \\ popq  %rcx
        \\ popq  %rdx
        \\ popq  %rsi
        \\ popq  %r8
        \\ popq  %r9
        \\ popq  %r10
        \\ popq  %r11
        \\ addq  $8, %rsp
        \\ ret
        :
        :
        : .{ .rax = true, .rcx = true, .rdx = true, .rsi = true, .rdi = true,
             .r8 = true, .r9 = true, .r10 = true, .r11 = true,
             .xmm0 = true, .xmm1 = true, .xmm2 = true, .xmm3 = true,
             .xmm4 = true, .xmm5 = true, .xmm6 = true, .xmm7 = true,
             .xmm8 = true, .xmm9 = true, .xmm10 = true, .xmm11 = true,
             .xmm12 = true, .xmm13 = true, .xmm14 = true, .xmm15 = true,
             .memory = true }
    );
}
