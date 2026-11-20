/* Export the UIApplicationDelegate protocol object as a global symbol.
 * Clang emits protocol metadata in the defining dylib as local symbols, but
 * clients that adopt the protocol reference it through an external symbol.
 * The iosim runtime does not introspect protocol method lists, so a
 * zero-filled protocol_t is sufficient to satisfy the bind. */
    .section __DATA,__objc_data
    .p2align 3
    .globl __OBJC_PROTOCOL_$_UIApplicationDelegate
__OBJC_PROTOCOL_$_UIApplicationDelegate:
    .quad 0
    .quad 0
    .quad 0
    .quad 0
    .quad 0
    .quad 0
    .quad 0
    .quad 0
