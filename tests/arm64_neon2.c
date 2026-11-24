/* Second AdvSIMD coverage fixture: widening and narrowing arithmetic,
 * saturating add/sub, table lookup, byte extraction, FP rounding, FP
 * compares, pairwise FP, and interleaved LD2/LD3/LD4 structures. */
#include <arm_neon.h>
extern int printf(const char *fmt, ...);

static void p_s16(const char *tag, int16x8_t v)
{
    int16_t a[8];
    vst1q_s16(a, v);
    printf("%s", tag);
    for (int i = 0; i < 8; i++)
        printf(" %d", a[i]);
    printf("\n");
}

static void p_s32_4(const char *tag, int32x4_t v)
{
    int32_t a[4];
    vst1q_s32(a, v);
    printf("%s", tag);
    for (int i = 0; i < 4; i++)
        printf(" %d", a[i]);
    printf("\n");
}

static void p_u8_16(const char *tag, uint8x16_t v)
{
    uint8_t a[16];
    vst1q_u8(a, v);
    printf("%s", tag);
    for (int i = 0; i < 16; i++)
        printf(" %u", (unsigned)a[i]);
    printf("\n");
}

static void p_u32_4(const char *tag, uint32x4_t v)
{
    uint32_t a[4];
    vst1q_u32(a, v);
    printf("%s", tag);
    for (int i = 0; i < 4; i++)
        printf(" %u", (unsigned)a[i]);
    printf("\n");
}

static void p_f32_4(const char *tag, float32x4_t v)
{
    float a[4];
    vst1q_f32(a, v);
    printf("%s", tag);
    for (int i = 0; i < 4; i++)
        printf(" %.1f", a[i]);
    printf("\n");
}


static int16x8_t asm_saddl(int8x8_t a, int8x8_t b)
{
    int16x8_t r;
    __asm__ volatile("saddl %0.8h, %1.8b, %2.8b"
                     : "=w"(r) : "w"(a), "w"(b));
    return r;
}

static uint16x8_t asm_uaddl(uint8x8_t a, uint8x8_t b)
{
    uint16x8_t r;
    __asm__ volatile("uaddl %0.8h, %1.8b, %2.8b"
                     : "=w"(r) : "w"(a), "w"(b));
    return r;
}

static int16x8_t asm_ssubl(int8x8_t a, int8x8_t b)
{
    int16x8_t r;
    __asm__ volatile("ssubl %0.8h, %1.8b, %2.8b"
                     : "=w"(r) : "w"(a), "w"(b));
    return r;
}

static int16x8_t asm_saddw(int16x8_t a, int8x8_t b)
{
    int16x8_t r;
    __asm__ volatile("saddw %0.8h, %1.8h, %2.8b"
                     : "=w"(r) : "w"(a), "w"(b));
    return r;
}

static int16x8_t asm_ssubw(int16x8_t a, int8x8_t b)
{
    int16x8_t r;
    __asm__ volatile("ssubw %0.8h, %1.8h, %2.8b"
                     : "=w"(r) : "w"(a), "w"(b));
    return r;
}

static void p_u16(const char *tag, uint16x8_t v)
{
    uint16_t a[8];
    vst1q_u16(a, v);
    printf("%s", tag);
    for (int i = 0; i < 8; i++)
        printf(" %u", (unsigned)a[i]);
    printf("\n");
}

int main(void)
{
    static const float rnd_in[4] = {1.5f, 2.5f, -1.5f, -2.5f};
    static const float x_in[4] = {1.0f, -2.0f, 3.0f, -4.0f};
    static const float y_in[4] = {1.0f, -1.0f, 2.0f, -5.0f};
    int8_t as8[8] = {1, 2, 3, 4, 5, 6, 7, 8};
    int8_t bs8[8] = {10, 20, 30, 40, 50, 60, 70, 80};
    int8x8_t a8 = vld1_s8(as8);
    int8x8_t b8 = vld1_s8(bs8);

    /* widening, forced through the widening encodings */
    p_s16("waddl", asm_saddl(a8, b8));
    p_u16("wuaddl", asm_uaddl(vreinterpret_u8_s8(a8),
                              vreinterpret_u8_s8(b8)));
    p_s16("waddw", asm_saddw(vdupq_n_s16(5), b8));
    p_s16("wsubl", asm_ssubl(b8, a8));
    p_s16("wsubw", asm_ssubw(vdupq_n_s16(100), a8));
    p_s16("sshll", vmovl_s8(a8));
    p_u16("ushll", vmovl_u8(vreinterpret_u8_s8(a8)));
    p_s16("shll2", vshll_n_s8(a8, 2));

    /* narrowing */
    int16_t wide[8] = {1, 300, -1, 200, -200, 127, 128, -129};
    int16x8_t w = vld1q_s16(wide);
    int8x8_t narrowed = vmovn_s16(w);
    int8x8_t sat = vqmovn_s16(w);
    int8_t n[8], s[8];
    vst1_s8(n, narrowed);
    vst1_s8(s, sat);
    printf("xtn");
    for (int i = 0; i < 8; i++)
        printf(" %d", n[i]);
    printf("\n");
    printf("qxtn");
    for (int i = 0; i < 8; i++)
        printf(" %d", s[i]);
    printf("\n");

    /* saturating add/sub */
    uint8_t hi[16] = {200, 100, 0, 255, 200, 100, 0, 255,
                      200, 100, 0, 255, 200, 100, 0, 255};
    uint8_t low[16] = {100, 100, 1, 1, 100, 100, 1, 1,
                       100, 100, 1, 1, 100, 100, 1, 1};
    p_u8_16("uqadd", vqaddq_u8(vld1q_u8(hi), vld1q_u8(low)));
    p_u8_16("uqsub", vqsubq_u8(vld1q_u8(low), vld1q_u8(hi)));
    int8x16_t shi = vdupq_n_s8(100), slow = vdupq_n_s8(100);
    int8_t sq[16];
    vst1q_s8(sq, vqaddq_s8(shi, slow));
    printf("sqadd");
    for (int i = 0; i < 16; i++)
        printf(" %d", sq[i]);
    printf("\n");
    vst1q_s8(sq, vqsubq_s8(vdupq_n_s8(-100), vdupq_n_s8(100)));
    printf("sqsub");
    for (int i = 0; i < 16; i++)
        printf(" %d", sq[i]);
    printf("\n");

    /* table lookup and extraction */
    uint8_t table[16] = {10, 20, 30, 40, 50, 60, 70, 80,
                         90, 100, 110, 120, 130, 140, 150, 160};
    uint8_t idx[16] = {0, 1, 2, 3, 4, 5, 6, 7,
                       8, 9, 10, 11, 12, 13, 14, 15};
    p_u8_16("tbl", vqtbl1q_u8(vld1q_u8(table), vld1q_u8(idx)));
    uint8_t idx2[16] = {15, 0, 16, 17, 3, 3, 99, 255,
                        1, 2, 4, 5, 6, 7, 8, 9};
    p_u8_16("tbl2", vqtbl1q_u8(vld1q_u8(table), vld1q_u8(idx2)));
    p_u8_16("tbx", vqtbx1q_u8(vdupq_n_u8(7),
                              vld1q_u8(table), vld1q_u8(idx2)));
    uint8_t left[16], right[16];
    for (int i = 0; i < 16; i++)
    {
        left[i] = (uint8_t)(i + 1);
        right[i] = (uint8_t)(100 + i);
    }
    p_u8_16("ext", vextq_u8(vld1q_u8(left), vld1q_u8(right), 3));

    /* FP rounding */
    float32x4_t f = vld1q_f32(rnd_in);
    p_f32_4("rndn", vrndnq_f32(f));
    p_f32_4("rnda", vrndaq_f32(f));
    p_f32_4("rndm", vrndmq_f32(f));
    p_f32_4("rndp", vrndpq_f32(f));
    p_f32_4("rndz", vrndq_f32(f));
    p_f32_4("rndx", vrndxq_f32(f));

    /* FP compares */
    float32x4_t x = vld1q_f32(x_in);
    float32x4_t y = vld1q_f32(y_in);
    p_u32_4("fceq", vceqq_f32(x, y));
    p_u32_4("fcgt", vcgtq_f32(x, y));
    p_u32_4("fcge", vcgeq_f32(x, y));
    p_u32_4("facge", vcageq_f32(x, y));
    p_u32_4("facgt", vcagtq_f32(x, y));

    /* pairwise FP */
    p_f32_4("faddp", vpaddq_f32(x, y));
    p_f32_4("fmaxp", vpmaxq_f32(x, y));
    p_f32_4("fminp", vpminq_f32(x, y));

    /* interleaved structures */
    uint32_t src2[8] = {1, 2, 3, 4, 5, 6, 7, 8};
    uint32x4x2_t d2 = vld2q_u32(src2);
    p_u32_4("ld2a", d2.val[0]);
    p_u32_4("ld2b", d2.val[1]);
    uint8_t src3[24];
    for (int i = 0; i < 24; i++)
        src3[i] = (uint8_t)(i + 1);
    uint8x8x3_t d3 = vld3_u8(src3);
    uint8_t out3[24];
    vst3_u8(out3, d3);
    printf("ld3");
    for (int i = 0; i < 24; i++)
        printf(" %u", (unsigned)out3[i]);
    printf("\n");
    uint8_t src4[64];
    for (int i = 0; i < 64; i++)
        src4[i] = (uint8_t)i;
    uint8x16x4_t d4 = vld4q_u8(src4);
    p_u8_16("ld4a", d4.val[0]);
    p_u8_16("ld4d", d4.val[3]);
    uint8_t back[64];
    vst4q_u8(back, d4);
    printf("st4");
    for (int i = 0; i < 64; i++)
        printf(" %u", (unsigned)back[i]);
    printf("\n");

    return 0;
}
