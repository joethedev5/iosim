/* Block translator for arm64 app images.
 *
 * Each translated block is native x86_64 code that edits the shared
 * a64_cpu state in place. Straight-line scalar instructions are emitted
 * inline; instructions with no inline form end the block and the driver
 * single-steps them with the interpreter, so coverage can grow without
 * ever affecting correctness. Blocks are cached by guest address, which is
 * the lazy per-IMP cache from docs/ARM64-TRANSLATION.md. */
#define _GNU_SOURCE
#include "arm64_jit.h"
#include "macho.h"

#include <fcntl.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#ifndef MAP_ANONYMOUS
#define MAP_ANONYMOUS MAP_ANON
#endif

#define JIT_ARENA_SIZE (4u * 1024u * 1024u)
#define JIT_MAX_BLOCK 16384
struct jit_block {
    uint64_t pc;
    a64_block_fn fn;
};

static struct jit_block *g_blocks;
static int g_nblocks;
static int g_capblocks;
static uint8_t *g_arena;
static size_t g_arena_used;
static int g_disabled;

#define O_X(n) ((int32_t)offsetof(struct a64_cpu, x) + 8 * (int32_t)(n))
#define O_SP ((int32_t)offsetof(struct a64_cpu, sp))
#define O_PC ((int32_t)offsetof(struct a64_cpu, pc))
#define O_NZCV ((int32_t)offsetof(struct a64_cpu, nzcv))
#define O_D(n) ((int32_t)offsetof(struct a64_cpu, d) + 8 * (int32_t)(n))
#define O_DHI(n) \
    ((int32_t)offsetof(struct a64_cpu, dhi) + 8 * (int32_t)(n))

/* Every 64-bit immediate that holds an address is recorded so a block can
 * be saved, reloaded in another process and patched: guest addresses move
 * with the image slide, helper pointers with the loader's layout. Values
 * that are plain constants (masks, floating-point bits) are not fixups. */
#define JIT_FIX_GUEST 0
#define JIT_FIX_HELPER 1
#define JIT_MAX_FIX 512

struct jit_fix {
    uint32_t off;
    uint16_t kind;
    uint16_t index;
};

struct jc {
    uint8_t buf[JIT_MAX_BLOCK];
    size_t len;
    int full;
    int ended;
    int cacheable;
    int nfix;
    struct jit_fix fix[JIT_MAX_FIX];
};

static void je8(struct jc *j, unsigned v)
{
    if (j->len >= sizeof j->buf)
    {
        j->full = 1;
        return;
    }
    j->buf[j->len++] = (uint8_t)v;
}

static void je32(struct jc *j, uint32_t v)
{
    je8(j, v & 0xff);
    je8(j, (v >> 8) & 0xff);
    je8(j, (v >> 16) & 0xff);
    je8(j, (v >> 24) & 0xff);
}

static void je64(struct jc *j, uint64_t v)
{
    je32(j, (uint32_t)v);
    je32(j, (uint32_t)(v >> 32));
}

/* --- fixed sequences -------------------------------------------------- */

static void em_mov_rax_imm(struct jc *j, uint64_t v)
{
    je8(j, 0x48); je8(j, 0xB8); je64(j, v);
}

static void em_mov_rcx_imm(struct jc *j, uint64_t v)
{
    je8(j, 0x48); je8(j, 0xB9); je64(j, v);
}

static void em_mov_rdx_imm(struct jc *j, uint64_t v)
{
    je8(j, 0x48); je8(j, 0xBA); je64(j, v);
}

static void jc_note_fix(struct jc *j, uint32_t off, uint16_t kind,
                        uint16_t index)
{
    if (j->nfix >= JIT_MAX_FIX)
    {
        j->cacheable = 0;
        return;
    }
    j->fix[j->nfix].off = off;
    j->fix[j->nfix].kind = kind;
    j->fix[j->nfix].index = index;
    j->nfix++;
}

/* Address-carrying forms: identical instructions, but recorded so a cached
 * block can be relocated. */
static void em_mov_rax_addr(struct jc *j, uint64_t v)
{
    em_mov_rax_imm(j, v);
    jc_note_fix(j, (uint32_t)(j->len - 8), JIT_FIX_GUEST, 0);
}

static void em_mov_rcx_addr(struct jc *j, uint64_t v)
{
    em_mov_rcx_imm(j, v);
    jc_note_fix(j, (uint32_t)(j->len - 8), JIT_FIX_GUEST, 0);
}

static void em_mov_rdx_addr(struct jc *j, uint64_t v)
{
    em_mov_rdx_imm(j, v);
    jc_note_fix(j, (uint32_t)(j->len - 8), JIT_FIX_GUEST, 0);
}

static void em_mov_rdi_rbx(struct jc *j)
{
    je8(j, 0x48); je8(j, 0x89); je8(j, 0xDF);
}

static void em_mov_esi_imm(struct jc *j, uint32_t v)
{
    je8(j, 0xBE); je32(j, v);
}


/* General-purpose register memory access, all relative to rbx. */
static void em_load_rax(struct jc *j, int32_t off)
{
    je8(j, 0x48); je8(j, 0x8B); je8(j, 0x83); je32(j, (uint32_t)off);
}

static void em_store_rax(struct jc *j, int32_t off)
{
    je8(j, 0x48); je8(j, 0x89); je8(j, 0x83); je32(j, (uint32_t)off);
}

static void em_clear_dhi(struct jc *j, int rd)
{
    em_mov_rax_imm(j, 0);
    em_store_rax(j, O_DHI(rd));
}

static void em_load_eax(struct jc *j, int32_t off)
{
    je8(j, 0x8B); je8(j, 0x83); je32(j, (uint32_t)off);
}

static void em_load_rcx(struct jc *j, int32_t off)
{
    je8(j, 0x48); je8(j, 0x8B); je8(j, 0x8B); je32(j, (uint32_t)off);
}

static void em_store_rcx(struct jc *j, int32_t off)
{
    je8(j, 0x48); je8(j, 0x89); je8(j, 0x8B); je32(j, (uint32_t)off);
}

static void em_load_ecx(struct jc *j, int32_t off)
{
    je8(j, 0x8B); je8(j, 0x8B); je32(j, (uint32_t)off);
}


static void em_store_rdx(struct jc *j, int32_t off)
{
    je8(j, 0x48); je8(j, 0x89); je8(j, 0x93); je32(j, (uint32_t)off);
}


static void em_load_r11(struct jc *j, int32_t off)
{
    je8(j, 0x4C); je8(j, 0x8B); je8(j, 0x9B); je32(j, (uint32_t)off);
}

static void em_store_r11(struct jc *j, int32_t off)
{
    je8(j, 0x4C); je8(j, 0x89); je8(j, 0x9B); je32(j, (uint32_t)off);
}

static void em_add_r11_imm(struct jc *j, uint32_t imm)
{
    je8(j, 0x49); je8(j, 0x81); je8(j, 0xC3); je32(j, imm);
}

/* Arithmetic. */
static void em_add_rax_imm(struct jc *j, int32_t imm)
{
    je8(j, 0x48); je8(j, 0x05); je32(j, (uint32_t)imm);
}

static void em_sub_rax_imm(struct jc *j, int32_t imm)
{
    je8(j, 0x48); je8(j, 0x2D); je32(j, (uint32_t)imm);
}

static void em_add_eax_imm(struct jc *j, int32_t imm)
{
    je8(j, 0x05); je32(j, (uint32_t)imm);
}

static void em_sub_eax_imm(struct jc *j, int32_t imm)
{
    je8(j, 0x2D); je32(j, (uint32_t)imm);
}

static void em_add_rax_rcx(struct jc *j) { je8(j,0x48);je8(j,0x01);je8(j,0xC8); }
static void em_sub_rax_rcx(struct jc *j) { je8(j,0x48);je8(j,0x29);je8(j,0xC8); }
static void em_and_rax_rcx(struct jc *j) { je8(j,0x48);je8(j,0x21);je8(j,0xC8); }
static void em_or_rax_rcx(struct jc *j)  { je8(j,0x48);je8(j,0x09);je8(j,0xC8); }
static void em_xor_rax_rcx(struct jc *j) { je8(j,0x48);je8(j,0x31);je8(j,0xC8); }
static void em_add_eax_ecx(struct jc *j) { je8(j,0x01);je8(j,0xC8); }
static void em_sub_eax_ecx(struct jc *j) { je8(j,0x29);je8(j,0xC8); }
static void em_and_eax_ecx(struct jc *j) { je8(j,0x21);je8(j,0xC8); }
static void em_or_eax_ecx(struct jc *j)  { je8(j,0x09);je8(j,0xC8); }
static void em_xor_eax_ecx(struct jc *j) { je8(j,0x31);je8(j,0xC8); }

static void em_mov_eax_eax(struct jc *j) { je8(j,0x89);je8(j,0xC0); }
static void em_not_rax(struct jc *j) { je8(j,0x48);je8(j,0xF7);je8(j,0xD0); }
static void em_not_eax(struct jc *j) { je8(j,0xF7);je8(j,0xD0); }

static void em_shl_rax(struct jc *j, unsigned n) { je8(j,0x48);je8(j,0xC1);je8(j,0xE0);je8(j,n); }
static void em_shr_rax(struct jc *j, unsigned n) { je8(j,0x48);je8(j,0xC1);je8(j,0xE8);je8(j,n); }
static void em_sar_rax(struct jc *j, unsigned n) { je8(j,0x48);je8(j,0xC1);je8(j,0xF8);je8(j,n); }
static void em_ror_rax(struct jc *j, unsigned n) { je8(j,0x48);je8(j,0xC1);je8(j,0xC8);je8(j,n); }
static void em_shl_eax(struct jc *j, unsigned n) { je8(j,0xC1);je8(j,0xE0);je8(j,n); }
static void em_shr_eax(struct jc *j, unsigned n) { je8(j,0xC1);je8(j,0xE8);je8(j,n); }
static void em_sar_eax(struct jc *j, unsigned n) { je8(j,0xC1);je8(j,0xF8);je8(j,n); }
static void em_ror_eax(struct jc *j, unsigned n) { je8(j,0xC1);je8(j,0xC8);je8(j,n); }

static void em_mov_rdx_rax(struct jc *j) { je8(j,0x48);je8(j,0x89);je8(j,0xC2); }
static void em_mov_rax_rdx(struct jc *j) { je8(j,0x48);je8(j,0x89);je8(j,0xD0); }
static void em_mov_rcx_rax(struct jc *j) { je8(j,0x48);je8(j,0x89);je8(j,0xC1); }

static void em_test_rax(struct jc *j) { je8(j,0x48);je8(j,0x85);je8(j,0xC0); }
static void em_test_eax(struct jc *j) { je8(j,0x85);je8(j,0xC0); }
static void em_cmovz_rdx_rcx(struct jc *j) { je8(j,0x48);je8(j,0x0F);je8(j,0x44);je8(j,0xD1); }
static void em_cmovnz_rdx_rcx(struct jc *j) { je8(j,0x48);je8(j,0x0F);je8(j,0x45);je8(j,0xD1); }
static void em_cmovc_rdx_rcx(struct jc *j) { je8(j,0x48);je8(j,0x0F);je8(j,0x42);je8(j,0xD1); }
static void em_cmovnc_rdx_rcx(struct jc *j) { je8(j,0x48);je8(j,0x0F);je8(j,0x43);je8(j,0xD1); }
static void em_bt_rax(struct jc *j, unsigned bit) { je8(j,0x48);je8(j,0x0F);je8(j,0xBA);je8(j,0xE0);je8(j,bit); }

/* Extensions on rax. */
static void em_movzx_eax_al(struct jc *j) { je8(j,0x0F);je8(j,0xB6);je8(j,0xC0); }
static void em_movzx_eax_ax(struct jc *j) { je8(j,0x0F);je8(j,0xB7);je8(j,0xC0); }
static void em_movsx_rax_al(struct jc *j) { je8(j,0x48);je8(j,0x0F);je8(j,0xBE);je8(j,0xC0); }
static void em_movsx_rax_ax(struct jc *j) { je8(j,0x48);je8(j,0x0F);je8(j,0xBF);je8(j,0xC0); }
static void em_movsxd_rax_eax(struct jc *j) { je8(j,0x48);je8(j,0x63);je8(j,0xC0); }

/* Guest memory access: address in rax, value in rcx. */
static void em_load_mem_rcx(struct jc *j, int bytes, int is_signed)
{
    if (bytes == 8)
    {
        je8(j, 0x48); je8(j, 0x8B); je8(j, 0x08);
    }
    else if (bytes == 4)
    {
        if (is_signed) { je8(j,0x48);je8(j,0x63);je8(j,0x08); }
        else { je8(j, 0x8B); je8(j, 0x08); }
    }
    else if (bytes == 2)
    {
        if (is_signed) { je8(j,0x48);je8(j,0x0F);je8(j,0xBF);je8(j,0x08); }
        else { je8(j,0x0F);je8(j,0xB7);je8(j,0x08); }
    }
    else
    {
        if (is_signed) { je8(j,0x48);je8(j,0x0F);je8(j,0xBE);je8(j,0x08); }
        else { je8(j,0x0F);je8(j,0xB6);je8(j,0x08); }
    }
}

static void em_store_mem_rcx(struct jc *j, int bytes)
{
    if (bytes == 8)
    {
        je8(j, 0x48); je8(j, 0x89); je8(j, 0x08);
    }
    else if (bytes == 4)
    {
        je8(j, 0x89); je8(j, 0x08);
    }
    else if (bytes == 2)
    {
        je8(j, 0x66); je8(j, 0x89); je8(j, 0x08);
    }
    else
    {
        je8(j, 0x88); je8(j, 0x08);
    }
}

/* Same with a disp8 offset from rax. */
static void em_load_mem_rcx_off(struct jc *j, int bytes, int is_signed,
                                int disp)
{
    if (bytes == 8) { je8(j,0x48);je8(j,0x8B);je8(j,0x48);je8(j,disp); }
    else if (bytes == 4)
    {
        if (is_signed) { je8(j,0x48);je8(j,0x63);je8(j,0x48);je8(j,disp); }
        else { je8(j,0x8B);je8(j,0x48);je8(j,disp); }
    }
    else if (bytes == 2)
    {
        if (is_signed) { je8(j,0x48);je8(j,0x0F);je8(j,0xBF);je8(j,0x48);je8(j,disp); }
        else { je8(j,0x0F);je8(j,0xB7);je8(j,0x48);je8(j,disp); }
    }
    else
    {
        if (is_signed) { je8(j,0x48);je8(j,0x0F);je8(j,0xBE);je8(j,0x48);je8(j,disp); }
        else { je8(j,0x0F);je8(j,0xB6);je8(j,0x48);je8(j,disp); }
    }
}

static void em_store_mem_rcx_off(struct jc *j, int bytes, int disp)
{
    if (bytes == 8) { je8(j,0x48);je8(j,0x89);je8(j,0x48);je8(j,disp); }
    else if (bytes == 4) { je8(j,0x89);je8(j,0x48);je8(j,disp); }
    else if (bytes == 2) { je8(j,0x66);je8(j,0x89);je8(j,0x48);je8(j,disp); }
    else { je8(j,0x88);je8(j,0x48);je8(j,disp); }
}

/* --- block plumbing --------------------------------------------------- */

static void em_prologue(struct jc *j)
{
    je8(j, 0x53);             /* push rbx */
    je8(j, 0x48); je8(j, 0x89); je8(j, 0xFB); /* mov rbx, rdi */
}

static void em_epilogue(struct jc *j)
{
    je8(j, 0x5B);             /* pop rbx */
    je8(j, 0xC3);             /* ret */
}

static void em_end_pc_rdx(struct jc *j)
{
    em_store_rdx(j, O_PC);
    em_epilogue(j);
    j->ended = 1;
}

static void em_end_pc_const(struct jc *j, uint64_t pc)
{
    em_mov_rdx_addr(j, pc);
    em_end_pc_rdx(j);
}

static void em_end_pc_rax(struct jc *j)
{
    em_store_rax(j, O_PC);
    em_epilogue(j);
    j->ended = 1;
}

/* Helpers called from translated code, in the order their pointers are
 * cached. Append only: the index is part of the on-disk block format. */
static void *const jit_helpers[] = {
    (void *)a64t_cond,
    (void *)a64t_addsub_flags,
    (void *)a64t_bitfield_insn,
    (void *)a64t_madd_insn,
    (void *)a64t_div_insn,
    (void *)a64t_csel_insn,
    (void *)a64t_fp2_insn,
    (void *)a64t_fp3_insn,
    (void *)a64t_fp1_insn,
    (void *)a64t_fcmp_insn,
};

#define JIT_NHELPERS ((int)(sizeof jit_helpers / sizeof jit_helpers[0]))

static int jit_helper_index(void *fn)
{
    for (int i = 0; i < JIT_NHELPERS; i++)
        if (jit_helpers[i] == fn)
            return i;
    return -1;
}

static void em_call(struct jc *j, void *fn)
{
    /* Absolute indirect call: helper functions and the code arena can be
     * more than 2 GB apart, which a rel32 call cannot reach. Known
     * helpers are recorded so a cached block can rebind them later. */
    je8(j, 0x48); je8(j, 0xB8); je64(j, (uint64_t)(uintptr_t)fn);
    int helper = jit_helper_index(fn);
    if (helper >= 0)
        jc_note_fix(j, (uint32_t)(j->len - 8), JIT_FIX_HELPER,
                    (uint16_t)helper);
    else
        j->cacheable = 0;
    je8(j, 0xFF); je8(j, 0xD0);
}

static void em_call_insn(struct jc *j, void *fn, uint32_t insn)
{
    em_mov_rdi_rbx(j);
    em_mov_esi_imm(j, insn);
    em_call(j, fn);
}

static void em_gpr_load(struct jc *j, int r, int is64)
{
    if (r == 31)
    {
        if (is64) { je8(j,0x48);je8(j,0x31);je8(j,0xC0); } /* xor rax,rax */
        else { je8(j,0x31);je8(j,0xC0); }                   /* xor eax,eax */
    }
    else if (is64)
        em_load_rax(j, O_X(r));
    else
        em_load_eax(j, O_X(r));
}

static void em_gpr_load_rcx(struct jc *j, int r, int is64)
{
    if (r == 31)
    {
        if (is64) { je8(j,0x48);je8(j,0x31);je8(j,0xC9); }
        else { je8(j,0x31);je8(j,0xC9); }
    }
    else if (is64)
        em_load_rcx(j, O_X(r));
    else
        em_load_ecx(j, O_X(r));
}

static void em_gpr_store(struct jc *j, int r, int is64)
{
    if (is64)
        em_store_rax(j, O_X(r));
    else
    {
        /* Values in eax are already zero-extended; clear the high half by
         * storing the full 64-bit register. */
        em_store_rax(j, O_X(r));
    }
}

static void em_base_load(struct jc *j, int r)
{
    if (r == 31)
        em_load_rax(j, O_SP);
    else
        em_load_rax(j, O_X(r));
}

static void em_base_store(struct jc *j, int r)
{
    if (r == 31)
        em_store_rax(j, O_SP);
    else
        em_store_rax(j, O_X(r));
}

static void em_gpr_store_rcx_w(struct jc *j, int rt);
static void em_store_gpr_rcx(struct jc *j, int rt);

/* --- instruction translation ----------------------------------------- */

/* Returns 1 when the instruction was emitted and the block continues, 2
 * when it was emitted and ends the block, 0 when it has no inline form. */
static int jit_emit_one(struct jc *j, uint32_t insn, uint64_t pc)
{
    uint64_t next = pc + 4;

    /* RET */
    if ((insn & 0xfffffc1f) == 0xd65f0000)
    {
        int rn = (insn >> 5) & 31;
        em_gpr_load(j, rn, 1);
        em_end_pc_rax(j);
        return 2;
    }
    /* B / BL */
    if ((insn & 0x7c000000) == 0x14000000)
    {
        int64_t off = (int64_t)(insn & 0x03ffffff);
        if (off & (1 << 25))
            off -= (1 << 26);
        off <<= 2;
        uint64_t target = pc + (uint64_t)off;
        int is_bl = (insn & 0x80000000) != 0;
        if (is_bl)
        {
            em_mov_rax_addr(j, next);
            em_store_rax(j, O_X(30));
        }
        em_end_pc_const(j, target);
        return 2;
    }
    /* B.cond */
    if ((insn & 0xff000010) == 0x54000000)
    {
        int cond = insn & 0xf;
        int64_t off = (int64_t)((insn >> 5) & 0x7ffff);
        if (off & (1 << 18))
            off -= (1 << 19);
        off <<= 2;
        uint64_t target = pc + (uint64_t)off;
        em_mov_rdi_rbx(j);
        em_mov_esi_imm(j, (uint32_t)cond);
        em_call(j, (void *)a64t_cond);
        em_test_eax(j);
        em_mov_rdx_addr(j, target);
        em_mov_rcx_addr(j, next);
        em_cmovz_rdx_rcx(j);   /* condition false -> next */
        em_end_pc_rdx(j);
        return 2;
    }
    /* CBZ / CBNZ */
    if ((insn & 0x7e000000) == 0x34000000)
    {
        int sf = (insn >> 31) & 1;
        int nz = (insn >> 24) & 1;
        int rt = insn & 31;
        int64_t off = (int64_t)((insn >> 5) & 0x7ffff);
        if (off & (1 << 18))
            off -= (1 << 19);
        off <<= 2;
        uint64_t target = pc + (uint64_t)off;
        em_gpr_load(j, rt, sf);
        if (sf)
            em_test_rax(j);
        else
            em_test_eax(j);
        em_mov_rdx_addr(j, target);
        em_mov_rcx_addr(j, next);
        if (nz)
            em_cmovz_rdx_rcx(j);  /* CBNZ: zero -> next */
        else
            em_cmovnz_rdx_rcx(j); /* CBZ: nonzero -> next */
        em_end_pc_rdx(j);
        return 2;
    }
    /* TBZ / TBNZ */
    if ((insn & 0x7e000000) == 0x36000000)
    {
        int b5 = (insn >> 31) & 1;
        int op = (insn >> 24) & 1;
        int b40 = (insn >> 19) & 31;
        int rt = insn & 31;
        int bit = (b5 << 5) | b40;
        int64_t off = (int64_t)((insn >> 5) & 0x3fff);
        if (off & (1 << 13))
            off -= (1 << 14);
        off <<= 2;
        uint64_t target = pc + (uint64_t)off;
        em_gpr_load(j, rt, 1);
        em_bt_rax(j, (unsigned)bit);
        em_mov_rdx_addr(j, target);
        em_mov_rcx_addr(j, next);
        if (op)
            em_cmovnc_rdx_rcx(j); /* TBNZ: bit clear -> next */
        else
            em_cmovc_rdx_rcx(j);  /* TBZ: bit set -> next */
        em_end_pc_rdx(j);
        return 2;
    }
    /* BR / BLR */
    if ((insn & 0xfffffc1f) == 0xd61f0000 ||
        (insn & 0xfffffc1f) == 0xd63f0000)
    {
        int rn = (insn >> 5) & 31;
        int is_blr = (insn & 0x00200000) != 0;
        em_gpr_load(j, rn, 1);
        if (is_blr)
        {
            em_mov_rdx_rax(j);
            em_mov_rax_addr(j, next);
            em_store_rax(j, O_X(30));
            em_mov_rax_rdx(j);
        }
        em_end_pc_rax(j);
        return 2;
    }
    /* MOVZ / MOVN / MOVK */
    if ((insn & 0x7f800000) == 0x52800000 ||
        (insn & 0x7f800000) == 0x12800000 ||
        (insn & 0x7f800000) == 0x72800000)
    {
        int sf = (insn >> 31) & 1;
        uint64_t m = sf ? ~0ull : 0xffffffffull;
        int hw = (insn >> 21) & 3;
        uint64_t imm = (uint64_t)((insn >> 5) & 0xffff) << (hw * 16);
        int rd = insn & 31;
        if (rd != 31)
        {
            if ((insn & 0x7f800000) == 0x72800000)
            {
                em_gpr_load_rcx(j, rd, sf);
                em_mov_rax_imm(j, ~(0xffffull << (hw * 16)));
                em_and_rax_rcx(j);
                em_mov_rcx_imm(j, imm & m);
                em_or_rax_rcx(j);
            }
            else if ((insn & 0x7f800000) == 0x12800000)
                em_mov_rax_imm(j, (~imm) & m);
            else
                em_mov_rax_imm(j, imm & m);
            em_gpr_store(j, rd, sf);
        }
        return 1;
    }
    /* ADR / ADRP */
    if ((insn & 0x1f000000) == 0x10000000)
    {
        int is_page = (insn & 0x80000000) != 0;
        uint64_t immlo = (insn >> 29) & 3;
        uint64_t immhi = (insn >> 5) & 0x7ffff;
        int64_t imm = (int64_t)((immhi << 2) | immlo);
        if (imm & (1ll << 20))
            imm -= (1ll << 21);
        uint64_t base = pc;
        if (is_page)
        {
            imm <<= 12;
            base &= ~0xfffull;
        }
        int rd = insn & 31;
        if (rd != 31)
        {
            em_mov_rax_addr(j, base + (uint64_t)imm);
            em_gpr_store(j, rd, 1);
        }
        return 1;
    }
    /* ADD / SUB (immediate) */
    if ((insn & 0x1f000000) == 0x11000000)
    {
        int sf = (insn >> 31) & 1;
        int sub = (insn >> 30) & 1;
        int setflags = (insn >> 29) & 1;
        unsigned shift = (insn >> 22) & 1;
        uint64_t imm = (insn >> 10) & 0xfff;
        int rn = (insn >> 5) & 31;
        int rd = insn & 31;
        if (setflags)
        {
            em_call_insn(j, (void *)a64t_addsub_flags, insn);
            return 1;
        }
        if (shift)
            imm <<= 12;
        if (rn == 31)
            em_load_rax(j, O_SP);
        else
            em_gpr_load(j, rn, sf);
        if (sub)
        {
            if (sf) em_sub_rax_imm(j, (int32_t)imm);
            else em_sub_eax_imm(j, (int32_t)imm);
        }
        else
        {
            if (sf) em_add_rax_imm(j, (int32_t)imm);
            else em_add_eax_imm(j, (int32_t)imm);
        }
        if (rd == 31)
            em_base_store(j, 31);
        else
            em_gpr_store(j, rd, sf);
        return 1;
    }
    /* ADD / SUB (shifted or extended register) */
    if ((insn & 0x1f200000) == 0x0b000000 ||
        (insn & 0x1f200000) == 0x0b200000)
    {
        int sf = (insn >> 31) & 1;
        int sub = (insn >> 30) & 1;
        int setflags = (insn >> 29) & 1;
        int extended = (insn & 0x00200000) != 0;
        int rm = (insn >> 16) & 31;
        int rn = (insn >> 5) & 31;
        int rd = insn & 31;
        if (setflags)
        {
            em_call_insn(j, (void *)a64t_addsub_flags, insn);
            return 1;
        }
        em_gpr_load(j, rm, sf);
        if (extended)
        {
            unsigned option = (insn >> 13) & 7;
            unsigned shift = (insn >> 10) & 7;
            switch (option)
            {
            case 0: em_movzx_eax_al(j); break;
            case 1: em_movzx_eax_ax(j); break;
            case 2: em_mov_eax_eax(j); break;
            case 3: break;
            case 4: em_movsx_rax_al(j); break;
            case 5: em_movsx_rax_ax(j); break;
            case 6: em_movsxd_rax_eax(j); break;
            case 7: break;
            }
            if (shift)
                em_shl_rax(j, shift);
        }
        else
        {
            unsigned st = (insn >> 22) & 3;
            unsigned amount = (insn >> 10) & 0x3f;
            if (!sf)
                amount &= 31;
            if (st == 0) { if (sf) em_shl_rax(j, amount); else em_shl_eax(j, amount); }
            else if (st == 1) { if (sf) em_shr_rax(j, amount); else em_shr_eax(j, amount); }
            else if (st == 2) { if (sf) em_sar_rax(j, amount); else em_sar_eax(j, amount); }
            else { if (sf) em_ror_rax(j, amount); else em_ror_eax(j, amount); }
        }
        em_mov_rcx_rax(j);
        if (rn == 31)
            em_load_rax(j, O_SP);
        else
            em_gpr_load(j, rn, sf);
        if (sub) { if (sf) em_sub_rax_rcx(j); else em_sub_eax_ecx(j); }
        else { if (sf) em_add_rax_rcx(j); else em_add_eax_ecx(j); }
        if (rd == 31)
            em_base_store(j, 31);
        else
            em_gpr_store(j, rd, sf);
        return 1;
    }
    /* Logical (shifted register), flags form falls back to the
     * interpreter. */
    if ((insn & 0x1f000000) == 0x0a000000)
    {
        int sf = (insn >> 31) & 1;
        unsigned opc = (insn >> 29) & 3;
        unsigned shift_type = (insn >> 22) & 3;
        unsigned amount = (insn >> 10) & 0x3f;
        int rm = (insn >> 16) & 31;
        int rn = (insn >> 5) & 31;
        int rd = insn & 31;
        if (opc == 3)
            return 0; /* ANDS / TST set flags */
        if (!sf)
            amount &= 31;
        em_gpr_load(j, rm, sf);
        if (shift_type == 0) { if (sf) em_shl_rax(j, amount); else em_shl_eax(j, amount); }
        else if (shift_type == 1) { if (sf) em_shr_rax(j, amount); else em_shr_eax(j, amount); }
        else if (shift_type == 2) { if (sf) em_sar_rax(j, amount); else em_sar_eax(j, amount); }
        else { if (sf) em_ror_rax(j, amount); else em_ror_eax(j, amount); }
        if (insn & 0x00200000)
        {
            if (sf) em_not_rax(j);
            else em_not_eax(j);
        }
        em_mov_rcx_rax(j);
        em_gpr_load(j, rn, sf);
        if (opc == 0) { if (sf) em_and_rax_rcx(j); else em_and_eax_ecx(j); }
        else if (opc == 1) { if (sf) em_or_rax_rcx(j); else em_or_eax_ecx(j); }
        else { if (sf) em_xor_rax_rcx(j); else em_xor_eax_ecx(j); }
        if (rd != 31)
            em_gpr_store(j, rd, sf);
        return 1;
    }
    /* UBFM / SBFM. BFM needs insert semantics the interpreter rejects, so
     * it stays on the interpreter's failing path. */
    if ((insn & 0x1f800000) == 0x13000000)
    {
        if (((insn >> 29) & 3) == 1)
            return 0;
        em_call_insn(j, (void *)a64t_bitfield_insn, insn);
        return 1;
    }
    /* MADD / MSUB / MUL and the long multiplies */
    if ((insn & 0x1f000000) == 0x1b000000)
    {
        em_call_insn(j, (void *)a64t_madd_insn, insn);
        return 1;
    }
    /* LDR (literal) */
    if ((insn & 0x3f000000) == 0x18000000)
    {
        unsigned opc = (insn >> 30) & 3;
        int64_t off = (int64_t)((insn >> 5) & 0x7ffff);
        if (off & (1 << 18))
            off -= (1 << 19);
        off <<= 2;
        uint64_t addr = pc + (uint64_t)off;
        int rt = insn & 31;
        if (opc == 3)
            return 0;
        em_mov_rax_addr(j, addr);
        if (opc == 0)
        {
            em_load_mem_rcx(j, 4, 0);
            em_gpr_store_rcx_w(j, rt);
        }
        else if (opc == 1)
        {
            em_load_mem_rcx(j, 8, 0);
            em_store_gpr_rcx(j, rt);
        }
        else
        {
            em_load_mem_rcx(j, 4, 1);
            em_store_gpr_rcx(j, rt);
        }
        return 1;
    }
    /* UDIV / SDIV */
    if ((insn & 0x1fe0fc00) == 0x1ac00800 ||
        (insn & 0x1fe0fc00) == 0x1ac00c00)
    {
        em_call_insn(j, (void *)a64t_div_insn, insn);
        return 1;
    }
    /* CSEL / CSINC / CSINV / CSNEG */
    if ((insn & 0x1fe00000) == 0x1a800000)
    {
        em_call_insn(j, (void *)a64t_csel_insn, insn);
        return 1;
    }
    /* LDR / STR (unsigned offset, integer) */
    if ((insn & 0x3f000000) == 0x39000000)
    {
        unsigned size = (insn >> 30) & 3;
        unsigned opc = (insn >> 22) & 3;
        uint64_t imm = ((insn >> 10) & 0xfff) << size;
        int rn = (insn >> 5) & 31;
        int rt = insn & 31;
        int bytes = 1 << size;
        em_base_load(j, rn);
        if (imm)
            em_add_rax_imm(j, (int32_t)imm);
        if (opc == 0)
        {
            em_gpr_load_rcx(j, rt, 1);
            em_store_mem_rcx(j, bytes);
        }
        else if (size == 3)
        {
            em_load_mem_rcx(j, 8, 0);
            em_store_gpr_rcx(j, rt);
        }
        else if (size == 2)
        {
            if (opc == 2)
            {
                em_load_mem_rcx(j, 4, 1);
                em_store_gpr_rcx(j, rt);
            }
            else
            {
                em_load_mem_rcx(j, 4, 0);
                em_gpr_store_rcx_w(j, rt);
            }
        }
        else if (opc == 1)
        {
            em_load_mem_rcx(j, bytes, 0);
            em_gpr_store_rcx_w(j, rt);
        }
        else if (opc == 2)
        {
            em_load_mem_rcx(j, bytes, 1);
            em_store_gpr_rcx(j, rt);
        }
        else
        {
            em_load_mem_rcx(j, bytes, 1);
            em_gpr_store_rcx_w(j, rt);
        }
        return 1;
    }
    /* LDUR / STUR and pre/post-indexed integer loads and stores */
    if ((insn & 0x3f200000) == 0x38000000)
    {
        unsigned size = (insn >> 30) & 3;
        unsigned opc = (insn >> 22) & 3;
        int64_t imm9 = (int64_t)((insn >> 12) & 0x1ff);
        if (imm9 & (1 << 8))
            imm9 -= (1 << 9);
        int mode = (insn >> 10) & 3;
        int rn = (insn >> 5) & 31;
        int rt = insn & 31;
        int bytes = 1 << size;
        em_base_load(j, rn);
        em_mov_rdx_rax(j);              /* rdx = base */
        if (mode != 1 && imm9)
            em_add_rax_imm(j, (int32_t)imm9);
        if (opc == 0)
        {
            em_gpr_load_rcx(j, rt, 1);
            em_store_mem_rcx(j, bytes);
        }
        else if (size == 3)
        {
            em_load_mem_rcx(j, 8, 0);
            em_store_gpr_rcx(j, rt);
        }
        else if (size == 2)
        {
            if (opc == 2)
            {
                em_load_mem_rcx(j, 4, 1);
                em_store_gpr_rcx(j, rt);
            }
            else
            {
                em_load_mem_rcx(j, 4, 0);
                em_gpr_store_rcx_w(j, rt);
            }
        }
        else if (opc == 1)
        {
            em_load_mem_rcx(j, bytes, 0);
            em_gpr_store_rcx_w(j, rt);
        }
        else if (opc == 2)
        {
            em_load_mem_rcx(j, bytes, 1);
            em_store_gpr_rcx(j, rt);
        }
        else
        {
            em_load_mem_rcx(j, bytes, 1);
            em_gpr_store_rcx_w(j, rt);
        }
        if (mode == 1 || mode == 3)
        {
            em_mov_rax_rdx(j);
            if (imm9)
                em_add_rax_imm(j, (int32_t)imm9);
            em_base_store(j, rn);
        }
        return 1;
    }
    /* LDP / STP (signed offset, integer) */
    if ((insn & 0x3e000000) == 0x28000000)
    {
        int sf = (insn >> 31) & 1;
        int is_load = (insn >> 22) & 1;
        int64_t imm7 = (int64_t)((insn >> 15) & 0x7f);
        if (imm7 & (1 << 6))
            imm7 -= (1 << 7);
        int bytes = sf ? 8 : 4;
        int64_t off = imm7 * bytes;
        int mode = (insn >> 23) & 3;
        int rt2 = (insn >> 10) & 31;
        int rn = (insn >> 5) & 31;
        int rt = insn & 31;
        em_base_load(j, rn);
        if (mode == 1 || mode == 3)
        {
            if (rn == 31)
                em_load_r11(j, O_SP);
            else
                em_load_r11(j, O_X(rn));
            if (off)
                em_add_r11_imm(j, (uint32_t)(int32_t)off);
        }
        if (mode != 1 && off)
            em_add_rax_imm(j, (int32_t)off);
        if (is_load)
        {
            em_load_mem_rcx(j, bytes, 0);
            if (sf)
                em_store_gpr_rcx(j, rt);
            else
                em_gpr_store_rcx_w(j, rt);
            em_load_mem_rcx_off(j, bytes, 0, bytes);
            if (sf)
                em_store_gpr_rcx(j, rt2);
            else
                em_gpr_store_rcx_w(j, rt2);
        }
        else
        {
            em_gpr_load_rcx(j, rt, sf);
            em_store_mem_rcx(j, bytes);
            em_gpr_load_rcx(j, rt2, sf);
            em_store_mem_rcx_off(j, bytes, bytes);
        }
        if (mode == 1 || mode == 3)
            em_store_r11(j, rn == 31 ? O_SP : O_X(rn));
        return 1;
    }
    /* NOP / hints */
    if ((insn & 0xfffff01f) == 0xd503201f)
        return 1;
    /* MOVI <Vd>.<T>, #0 */
    if ((insn & 0xfffffc00) == 0x0f00e400 ||
        (insn & 0xfffffc00) == 0x2f00e400 ||
        (insn & 0xfffffc00) == 0x4f00e400 ||
        (insn & 0xfffffc00) == 0x6f00e400)
    {
        int rd = insn & 31;
        em_mov_rax_imm(j, 0);
        em_store_rax(j, O_D(rd));
        em_store_rax(j, O_DHI(rd));
        return 1;
    }
    /* FMOV between FP registers */
    if ((insn & 0x7f20fc00) == 0x1e204000)
    {
        int is_double = (insn >> 22) & 1;
        int rn = (insn >> 5) & 31;
        int rd = insn & 31;
        if (is_double)
            em_load_rax(j, O_D(rn));
        else
            em_load_eax(j, O_D(rn));
        em_store_rax(j, O_D(rd));
        em_clear_dhi(j, rd);
        return 1;
    }
    /* FMOV GP <-> FP */
    if ((insn & 0xfffffc00) == 0x9e660000) /* FMOV Xd, Dn */
    {
        int rn = (insn >> 5) & 31;
        int rd = insn & 31;
        em_load_rax(j, O_D(rn));
        if (rd != 31)
            em_store_rax(j, O_X(rd));
        return 1;
    }
    if ((insn & 0xfffffc00) == 0x9e670000) /* FMOV Dd, Xn */
    {
        int rn = (insn >> 5) & 31;
        int rd = insn & 31;
        em_gpr_load(j, rn, 1);
        em_store_rax(j, O_D(rd));
        em_clear_dhi(j, rd);
        return 1;
    }
    if ((insn & 0xfffffc00) == 0x1e260000) /* FMOV Wd, Sn */
    {
        int rn = (insn >> 5) & 31;
        int rd = insn & 31;
        em_load_eax(j, O_D(rn));
        if (rd != 31)
            em_store_rax(j, O_X(rd));
        return 1;
    }
    if ((insn & 0xfffffc00) == 0x1e270000) /* FMOV Sd, Wn */
    {
        int rn = (insn >> 5) & 31;
        int rd = insn & 31;
        em_gpr_load(j, rn, 0);
        em_store_rax(j, O_D(rd));
        em_clear_dhi(j, rd);
        return 1;
    }
    /* FMOV (immediate) */
    if ((insn & 0xffe01fe0) == 0x1e201000 ||
        (insn & 0xffe01fe0) == 0x1e601000)
    {
        int is_double = (insn >> 22) & 1;
        unsigned imm8 = (unsigned)((insn >> 13) & 0xff);
        int rd = insn & 31;
        unsigned b6 = (imm8 >> 6) & 1;
        unsigned sign = (imm8 >> 7) & 1;
        uint64_t bits;
        if (is_double)
        {
            uint64_t exp = (uint64_t)(!b6) << 10;
            uint64_t frac = (uint64_t)(imm8 & 0xf) << 48;
            if (b6)
                exp |= 0xffu << 2;
            exp |= (imm8 >> 4) & 3;
            bits = ((uint64_t)sign << 63) | (exp << 52) | frac;
        }
        else
        {
            uint32_t exp = (uint32_t)(!b6) << 7;
            uint32_t frac = (uint32_t)(imm8 & 0xf) << 19;
            if (b6)
                exp |= 0x1fu << 2;
            exp |= (imm8 >> 4) & 3;
            bits = (uint32_t)((sign << 31) | (exp << 23) | frac);
        }
        em_mov_rax_imm(j, bits);
        em_store_rax(j, O_D(rd));
        em_store_rax(j, O_DHI(rd));
        return 1;
    }
    /* FP LDR / STR (unsigned offset) */
    if ((insn & 0x3f000000) == 0x3d000000)
    {
        unsigned size = (insn >> 30) & 3;
        unsigned opc = (insn >> 22) & 3;
        if (opc > 1 || size < 2)
            return 0;
        uint64_t imm = ((insn >> 10) & 0xfff) << size;
        int rn = (insn >> 5) & 31;
        int rt = insn & 31;
        int bytes = 1 << size;
        em_base_load(j, rn);
        if (imm)
            em_add_rax_imm(j, (int32_t)imm);
        if (opc == 0)
        {
            em_load_rcx(j, O_D(rt));
            em_store_mem_rcx(j, bytes);
        }
        else
        {
            em_load_mem_rcx(j, bytes, 0);
            em_store_rcx(j, O_D(rt));
            em_mov_rax_imm(j, 0);
            em_store_rax(j, O_DHI(rt));
        }
        return 1;
    }
    /* FP two-source arithmetic */
    if ((insn & 0x7f20fc00) == 0x1e202800 ||
        (insn & 0x7f20fc00) == 0x1e203800 ||
        (insn & 0x7f20fc00) == 0x1e200800 ||
        (insn & 0x7f20fc00) == 0x1e201800)
    {
        em_call_insn(j, (void *)a64t_fp2_insn, insn);
        return 1;
    }
    /* FP fused multiply-add family */
    if ((insn & 0x7f000000) == 0x1f000000)
    {
        em_call_insn(j, (void *)a64t_fp3_insn, insn);
        return 1;
    }
    /* SCVTF / UCVTF / FCVTZS / FCVTZU */
    if ((insn & 0xfffffc00) == 0x9e620000 ||
        (insn & 0xfffffc00) == 0x9e630000 ||
        (insn & 0xfffffc00) == 0x1e620000 ||
        (insn & 0xfffffc00) == 0x1e630000 ||
        (insn & 0xfffffc00) == 0x9e220000 ||
        (insn & 0xfffffc00) == 0x9e230000 ||
        (insn & 0xfffffc00) == 0x1e220000 ||
        (insn & 0xfffffc00) == 0x1e230000 ||
        (insn & 0xfffffc00) == 0x9e780000 ||
        (insn & 0xfffffc00) == 0x9e790000 ||
        (insn & 0xfffffc00) == 0x1e780000 ||
        (insn & 0xfffffc00) == 0x1e790000 ||
        (insn & 0xfffffc00) == 0x9e380000 ||
        (insn & 0xfffffc00) == 0x9e390000 ||
        (insn & 0xfffffc00) == 0x1e380000 ||
        (insn & 0xfffffc00) == 0x1e390000)
    {
        em_call_insn(j, (void *)a64t_fp1_insn, insn);
        return 1;
    }
    /* FCMP / FCMPE */
    if ((insn & 0xff20fc0f) == 0x1e202000)
    {
        em_call_insn(j, (void *)a64t_fcmp_insn, insn);
        return 1;
    }
    return 0;
}

/* Stores the 32-bit value in ecx to x[rt] as a zero-extended 64-bit
 * value. */
static void em_gpr_store_rcx_w(struct jc *j, int rt)
{
    if (rt == 31)
        return;
    /* 32-bit writes clear the upper half of the guest register. */
    je8(j, 0x89); je8(j, 0xC9); /* mov ecx, ecx */
    em_store_gpr_rcx(j, rt);
}

static void em_store_gpr_rcx(struct jc *j, int rt)
{
    if (rt != 31)
        em_store_rcx(j, O_X(rt));
}

/* --- persistent cache -------------------------------------------------- */

/* With IOSIM_ARM64_CACHE_DIR set, translated image blocks are appended to
 * <dir>/<image uuid>.blocks. A later launch of the same image loads them,
 * patches the guest addresses for the new slide and the helper pointers
 * for this process, and skips translation entirely. Runtime-generated
 * pages are never persisted. Bump the version whenever the emitter, the
 * a64_cpu layout or the helper table changes. */
#define A64_CACHE_VERSION 1u

struct cache_header {
    char magic[8];
    uint32_t version;
    uint32_t reserved;
    uint8_t uuid[16];
    int64_t slide;
};

struct cache_record {
    uint64_t pc;
    uint32_t len;
    uint16_t nfix;
    uint16_t pad;
    int64_t slide;
};

struct cache_loaded {
    uint64_t pc;
    uint32_t len;
    uint8_t *code;
};

static struct cache_loaded *g_loaded;
static int g_nloaded;
static int g_cap_loaded;
static int g_cache_state; /* 0 = uninitialized, 1 = disabled, 2 = active */
static int g_cache_fd = -1;
/* Block keys are image-relative (guest pc minus the slide) so they match
 * across launches; the slide differs under ASLR. */
static int64_t g_cache_slide;

static uint8_t *jit_arena_alloc(size_t size)
{
    if (!g_arena)
    {
        g_arena = mmap(NULL, JIT_ARENA_SIZE, PROT_READ | PROT_WRITE | PROT_EXEC,
                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        if (g_arena == MAP_FAILED)
        {
            g_arena = NULL;
            g_disabled = 1;
            return NULL;
        }
        g_arena_used = 0;
    }
    if (g_arena_used + size > JIT_ARENA_SIZE)
    {
        g_disabled = 1;
        return NULL;
    }
    uint8_t *dst = g_arena + g_arena_used;
    g_arena_used += size;
    return dst;
}

static int jit_cache_pc_ok(struct iosim_image *img, uint64_t pc)
{
    if ((pc & 3) != 0)
        return 0;
    for (int i = 0; i < img->nsegs; i++)
    {
        struct iosim_segment *s = &img->segs[i];
        if (!(s->initprot & 4))
            continue;
        if (pc >= s->vmaddr && pc < s->vmaddr + s->vmsize)
            return 1;
    }
    return 0;
}

static void jit_cache_store_loaded(uint64_t pc, uint8_t *code, uint32_t len)
{
    if (g_nloaded == g_cap_loaded)
    {
        int cap = g_cap_loaded ? g_cap_loaded * 2 : 64;
        struct cache_loaded *nl =
            realloc(g_loaded, (size_t)cap * sizeof *nl);
        if (!nl)
        {
            free(code);
            return;
        }
        g_loaded = nl;
        g_cap_loaded = cap;
    }
    g_loaded[g_nloaded].pc = pc;
    g_loaded[g_nloaded].len = len;
    g_loaded[g_nloaded].code = code;
    g_nloaded++;
}

static void jit_cache_init(struct a64_cpu *c)
{
    if (g_cache_state)
        return;
    g_cache_state = 1;
    const char *dir = getenv("IOSIM_ARM64_CACHE_DIR");
    if (!dir || !*dir || !c || !c->img || !c->img->has_uuid)
        return;
    char path[3072];
    int n = snprintf(path, sizeof path, "%s/", dir);
    for (int i = 0; i < 16 && n > 0 && n + 2 < (int)sizeof path; i++)
        n += snprintf(path + n, sizeof path - (size_t)n, "%02x",
                      c->img->uuid[i]);
    if (n <= 0 || n >= (int)sizeof path - 8)
        return;
    snprintf(path + n, sizeof path - (size_t)n, ".blocks");
    int fd = open(path, O_RDWR | O_CREAT | O_APPEND, 0644);
    if (fd < 0)
        return;
    struct cache_header h;
    ssize_t got = pread(fd, &h, sizeof h, 0);
    int valid = got == (ssize_t)sizeof h &&
                memcmp(h.magic, "IOSIMA64", 8) == 0 &&
                h.version == A64_CACHE_VERSION &&
                memcmp(h.uuid, c->img->uuid, 16) == 0;
    if (!valid)
    {
        if (ftruncate(fd, 0) != 0)
        {
            close(fd);
            return;
        }
        memset(&h, 0, sizeof h);
        memcpy(h.magic, "IOSIMA64", 8);
        h.version = A64_CACHE_VERSION;
        memcpy(h.uuid, c->img->uuid, 16);
        h.slide = c->img->slide;
        if (write(fd, &h, sizeof h) != (ssize_t)sizeof h)
        {
            close(fd);
            return;
        }
    }
    else
    {
        off_t off = (off_t)sizeof h;
        for (;;)
        {
            struct cache_record r;
            if (pread(fd, &r, sizeof r, off) != (ssize_t)sizeof r)
                break;
            if (r.len == 0 || r.len > JIT_MAX_BLOCK || r.nfix > JIT_MAX_FIX ||
                !jit_cache_pc_ok(c->img, r.pc))
                break;
            uint8_t *code = malloc(r.len);
            if (!code)
                break;
            off_t foff = off + (off_t)sizeof r;
            struct jit_fix *fixes = NULL;
            size_t fixbytes = (size_t)r.nfix * sizeof(struct jit_fix);
            if (fixbytes)
            {
                fixes = malloc(fixbytes);
                if (!fixes || pread(fd, fixes, fixbytes, foff) !=
                                  (ssize_t)fixbytes)
                {
                    free(fixes);
                    free(code);
                    break;
                }
                foff += (off_t)fixbytes;
            }
            if (pread(fd, code, r.len, foff) != (ssize_t)r.len)
            {
                free(fixes);
                free(code);
                break;
            }
            foff += (off_t)r.len;
            int bad = 0;
            for (int i = 0; i < r.nfix; i++)
            {
                struct jit_fix f = fixes[i];
                if ((size_t)f.off + 8 > r.len)
                {
                    bad = 1;
                    break;
                }
                uint64_t v;
                memcpy(&v, code + f.off, 8);
                if (f.kind == JIT_FIX_HELPER)
                {
                    if (f.index >= JIT_NHELPERS)
                    {
                        bad = 1;
                        break;
                    }
                    v = (uint64_t)(uintptr_t)jit_helpers[f.index];
                }
                else
                    v = v - (uint64_t)r.slide + (uint64_t)c->img->slide;
                memcpy(code + f.off, &v, 8);
            }
            free(fixes);
            if (bad)
            {
                free(code);
                break;
            }
            jit_cache_store_loaded(r.pc, code, r.len);
            off = foff;
        }
        /* A crash can leave a partial record; drop it so appends stay
         * parseable. */
        ftruncate(fd, off);
    }
    g_cache_fd = fd;
    g_cache_slide = (int64_t)c->img->slide;
    g_cache_state = 2;
    if (getenv("IOSIM_ARM64_JIT_TRACE"))
        fprintf(stderr, "jit cache %s valid=%d loaded=%d slide=%lld\n", path,
                valid, g_nloaded, (long long)g_cache_slide);
}

static void jit_cache_append(struct jc *j, uint64_t pc, int64_t slide)
{
    if (g_cache_state != 2 || g_cache_fd < 0 || !j->cacheable)
        return;
    size_t fixbytes = (size_t)j->nfix * sizeof(struct jit_fix);
    size_t need = sizeof(struct cache_record) + fixbytes + j->len;
    if (need > (1u << 20))
        return;
    uint8_t *buf = malloc(need);
    if (!buf)
        return;
    struct cache_record r;
    memset(&r, 0, sizeof r);
    r.pc = pc - (uint64_t)slide;
    r.len = (uint32_t)j->len;
    r.nfix = (uint16_t)j->nfix;
    r.slide = slide;
    memcpy(buf, &r, sizeof r);
    memcpy(buf + sizeof r, j->fix, fixbytes);
    memcpy(buf + sizeof r + fixbytes, j->buf, j->len);
    ssize_t w = write(g_cache_fd, buf, need);
    free(buf);
    if (w != (ssize_t)need)
    {
        close(g_cache_fd);
        g_cache_fd = -1;
        g_cache_state = 1;
    }
}

static a64_block_fn jit_cache_lookup(uint64_t pc)
{
    if (g_cache_state != 2)
        return NULL;
    uint64_t key = pc - (uint64_t)g_cache_slide;
    for (int i = 0; i < g_nloaded; i++)
    {
        if (g_loaded[i].pc != key)
            continue;
        size_t size = ((size_t)g_loaded[i].len + 15) & ~(size_t)15;
        uint8_t *dst = jit_arena_alloc(size);
        if (!dst)
            return NULL;
        memcpy(dst, g_loaded[i].code, g_loaded[i].len);
        if (getenv("IOSIM_ARM64_JIT_TRACE"))
            fprintf(stderr, "jit cached 0x%llx\n", (unsigned long long)pc);
        return (a64_block_fn)(void *)dst;
    }
    return NULL;
}

/* --- cache ------------------------------------------------------------ */

static a64_block_fn jit_translate(struct a64_cpu *c, uint64_t pc)
{
    struct jc j;
    memset(&j, 0, sizeof j);
    j.cacheable = 1;
    em_prologue(&j);
    uint64_t p = pc;
    int emitted = 0;
    while (j.len + 256 < sizeof j.buf)
    {
        if (!iosim_arm64_pc_in_image(c, p))
            break;
        uint32_t insn;
        memcpy(&insn, (const void *)(uintptr_t)p, sizeof insn);
        int r = jit_emit_one(&j, insn, p);
        if (r == 0)
            break;
        emitted = 1;
        if (r == 2)
            break;
        p += 4;
    }
    if (j.full || !emitted)
        return NULL;
    if (!j.ended)
        em_end_pc_const(&j, p);
    if (getenv("IOSIM_ARM64_JIT_TRACE"))
        fprintf(stderr, "jit block 0x%llx..0x%llx len=%zu\n",
                (unsigned long long)pc, (unsigned long long)p, j.len);
    if (j.full || j.len > sizeof j.buf)
        return NULL;

    size_t size = (j.len + 15) & ~(size_t)15;
    uint8_t *dst = jit_arena_alloc(size);
    if (!dst)
        return NULL;
    memcpy(dst, j.buf, j.len);
    if (j.cacheable && iosim_arm64_pc_is_static(c, pc) && c->img)
        jit_cache_append(&j, pc, (int64_t)c->img->slide);
    return (a64_block_fn)(void *)dst;
}

a64_block_fn a64_jit_lookup(struct a64_cpu *c, uint64_t pc)
{
    if (g_disabled)
        return NULL;
    for (int i = 0; i < g_nblocks; i++)
        if (g_blocks[i].pc == pc)
            return g_blocks[i].fn;
    jit_cache_init(c);
    a64_block_fn fn = jit_cache_lookup(pc);
    if (!fn)
        fn = jit_translate(c, pc);
    if (!fn)
    {
        /* Negative entry so an untranslatable address is decoded once. */
    }
    if (g_nblocks == g_capblocks)
    {
        int cap = g_capblocks ? g_capblocks * 2 : 64;
        struct jit_block *nb = realloc(g_blocks,
                                       (size_t)cap * sizeof *nb);
        if (!nb)
            return fn;
        g_blocks = nb;
        g_capblocks = cap;
    }
    g_blocks[g_nblocks].pc = pc;
    g_blocks[g_nblocks].fn = fn;
    g_nblocks++;
    return fn;
}

void a64_jit_invalidate(void)
{
    g_nblocks = 0;
    g_arena_used = 0;
}

void a64_jit_invalidate_range(uint64_t lo, uint64_t hi)
{
    int out = 0;
    for (int i = 0; i < g_nblocks; i++)
    {
        if (g_blocks[i].pc >= lo && g_blocks[i].pc < hi)
            continue;
        g_blocks[out++] = g_blocks[i];
    }
    g_nblocks = out;
}
