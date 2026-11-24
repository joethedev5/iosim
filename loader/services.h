#ifndef IOSIM_SERVICES_H
#define IOSIM_SERVICES_H

#include <stdint.h>

/* Called by the UIKit run loop: runs due main-queue blocks and returns how
 * many ran. */
int iosim_dispatch_drain_main(void);

/* Symbol table for the libdispatch, Mach, bootstrap, XPC and launchd
 * surface. Returns NULL when the name is not a service symbol. */
void *iosim_services_lookup(const char *name);

/* Reverse lookup used by the arm64 call gate: a guest can import a service
 * function directly, and its address must be recognized as a plain native
 * call. */
int iosim_services_lookup_addr(void *addr, const char **name);

/* Native framework code invoking a block directly (UIView animation steps
 * and completions). An arm64 block runs through the native-to-guest bridge;
 * an x86 block is called directly. */
void iosim_block_call(void *block);
void iosim_block_call1(void *block, uint64_t arg);
void iosim_block_call2(void *block, uint64_t a, uint64_t b);
void iosim_block_call3(void *block, uint64_t a, uint64_t b, uint64_t c);
void iosim_block_call4(void *block, uint64_t a, uint64_t b, uint64_t c,
                       uint64_t d);
uint64_t iosim_block_call_ret(void *block);
uint64_t iosim_block_call_ret1(void *block, uint64_t arg);
uint64_t iosim_block_call_ret2(void *block, uint64_t a, uint64_t b);
uint64_t iosim_block_call_ret3(void *block, uint64_t a, uint64_t b,
                               uint64_t c);

/* Exported data symbols (Mach-O binds these by address). */
extern uint32_t bootstrap_port_value;
extern uint32_t mach_task_self_value;
extern char dispatch_main_q_storage[];
extern char xpc_type_dictionary_storage[];
extern char xpc_type_string_storage[];
extern char xpc_type_int64_storage[];
extern char xpc_type_bool_storage[];
extern char xpc_type_data_storage[];
extern char xpc_type_array_storage[];
extern char xpc_type_error_storage[];
extern char xpc_type_connection_storage[];

#endif
