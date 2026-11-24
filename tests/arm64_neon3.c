/* Third AdvSIMD check: the 2S/2D and other-size forms of the families
 * added in the second batch, plus 8B table lookups. */
#include <arm_neon.h>
extern int printf(const char *fmt, ...);

static int16x8_t asm_saddl_h(int8x8_t a, int8x8_t b)
{
    int16x8_t r;
    __asm__ volatile("saddl %0.8h, %1.8b, %2.8b" : "=w"(r) : "w"(a), "w"(b));
    return r;
}
static int32x4_t asm_saddl_s(int16x4_t a, int16x4_t b)
{
    int32x4_t r;
    __asm__ volatile("saddl %0.4s, %1.4h, %2.4h" : "=w"(r) : "w"(a), "w"(b));
    return r;
}
static int64x2_t asm_saddl_d(int32x2_t a, int32x2_t b)
{
    int64x2_t r;
    __asm__ volatile("saddl %0.2d, %1.2s, %2.2s" : "=w"(r) : "w"(a), "w"(b));
    return r;
}

static void p16(const char *t, int16x8_t v)
{
    int16_t a[8];
    vst1q_s16(a, v);
    printf("%s", t);
    for (int i = 0; i < 8; i++)
        printf(" %d", a[i]);
    printf("\n");
}
static void p32(const char *t, int32x4_t v)
{
    int32_t a[4];
    vst1q_s32(a, v);
    printf("%s", t);
    for (int i = 0; i < 4; i++)
        printf(" %d", a[i]);
    printf("\n");
}
static void p64(const char *t, int64x2_t v)
{
    int64_t a[2];
    vst1q_s64(a, v);
    printf("%s %d %d %d %d\n", t, (int)(a[0] >> 32), (int)a[0],
           (int)(a[1] >> 32), (int)a[1]);
}
static void p16_4(const char *t, int16x4_t v)
{
    int16_t a[4];
    vst1_s16(a, v);
    printf("%s %d %d %d %d\n", t, a[0], a[1], a[2], a[3]);
}
static void p32_2(const char *t, int32x2_t v)
{
    int32_t a[2];
    vst1_s32(a, v);
    printf("%s %d %d\n", t, a[0], a[1]);
}
static void pf2(const char *t, float32x2_t v)
{
    float a[2];
    vst1_f32(a, v);
    printf("%s %.1f %.1f\n", t, a[0], a[1]);
}
static void pf4(const char *t, float32x4_t v)
{
    float a[4];
    vst1q_f32(a, v);
    printf("%s %.1f %.1f %.1f %.1f\n", t, a[0], a[1], a[2], a[3]);
}
static void pd2(const char *t, float64x2_t v)
{
    double a[2];
    vst1q_f64(a, v);
    printf("%s %.1f %.1f\n", t, a[0], a[1]);
}
static void pu32_4(const char *t, uint32x4_t v)
{
    uint32_t a[4];
    vst1q_u32(a, v);
    printf("%s %u %u %u %u\n", t, (unsigned)a[0], (unsigned)a[1],
           (unsigned)a[2], (unsigned)a[3]);
}
static void pu8_8(const char *t, uint8x8_t v)
{
    uint8_t a[8];
    vst1_u8(a, v);
    printf("%s", t);
    for (int i = 0; i < 8; i++)
        printf(" %u", (unsigned)a[i]);
    printf("\n");
}
static void pu16_8(const char *t, uint16x8_t v)
{
    uint16_t a[8];
    vst1q_u16(a, v);
    printf("%s", t);
    for (int i = 0; i < 8; i++)
        printf(" %u", (unsigned)a[i]);
    printf("\n");
}
static void pu32_2(const char *t, uint32x2_t v)
{
    uint32_t a[2];
    vst1_u32(a, v);
    printf("%s %u %u\n", t, (unsigned)a[0], (unsigned)a[1]);
}
static void p64u(const char *t, uint64x2_t v)
{
    uint64_t a[2];
    vst1q_u64(a, v);
    printf("%s %u %u %u %u\n", t, (unsigned)(a[0] >> 32), (unsigned)a[0],
           (unsigned)(a[1] >> 32), (unsigned)a[1]);
}
static void pd2u(const char *t, uint64x2_t v)
{
    uint64_t a[2];
    vst1q_u64(a, v);
    printf("%s %llx %llx\n", t, (unsigned long long)a[0],
           (unsigned long long)a[1]);
}

int main(void)
{
    int8_t b1[8] = {1, 2, 3, 4, 5, 6, 7, 8};
    int8_t b2[8] = {10, 20, 30, 40, 50, 60, 70, 80};
    int16_t h1[4] = {1, 2, 3, 4};
    int16_t h2[4] = {10, 20, 30, 40};
    int32_t s1[2] = {1, 2};
    int32_t s2[2] = {5, 6};

    p16("h_saddl", asm_saddl_h(vld1_s8(b1), vld1_s8(b2)));
    p32("s_saddl", asm_saddl_s(vld1_s16(h1), vld1_s16(h2)));
    p64("d_saddl", asm_saddl_d(vld1_s32(s1), vld1_s32(s2)));

    static const int32_t narrow4[4] = {70000, -1, 2, 3};
    p16_4("narrow_4h", vmovn_s32(vld1q_s32(narrow4)));
    static const int64_t narrow2[2] = {0x7fffffffffffffffLL, -5LL};
    p32_2("narrow_2s", vqmovn_s64(vld1q_s64(narrow2)));

    p16("sat16", vqaddq_s16(vdupq_n_s16(30000), vdupq_n_s16(30000)));
    p64("sat64", vqaddq_s64(vdupq_n_s64(0x7fffffffffffffffLL),
                            vdupq_n_s64(1)));
    pu16_8("sat16u", vqsubq_u16(vdupq_n_u16(0), vdupq_n_u16(1)));

    uint8_t table8[8] = {10, 20, 30, 40, 50, 60, 70, 80};
    uint8_t table16[16] = {10, 20, 30, 40, 50, 60, 70, 80,
                           90, 100, 110, 120, 130, 140, 150, 160};
    uint8_t idx8[8] = {0, 1, 2, 3, 4, 5, 6, 7};
    pu8_8("tbl8", vqtbl1_u8(vld1q_u8(table16), vld1_u8(idx8)));
    uint8_t idx9[8] = {7, 0, 8, 99, 3, 3, 1, 2};
    pu8_8("tbl8b", vqtbl1_u8(vld1q_u8(table16), vld1_u8(idx9)));
    pu8_8("ext8", vext_u8(vld1_u8(table8), vld1_u8(idx8), 5));

    static const float rn2[2] = {1.5f, -2.5f};
    static const double ra2[2] = {2.5, -2.5};
    static const double rp2[2] = {2.1, -2.9};
    pf2("rndn2s", vrndn_f32(vld1_f32(rn2)));
    pd2("rnda2d", vrndaq_f64(vld1q_f64(ra2)));
    pd2("rndp2d", vrndpq_f64(vld1q_f64(rp2)));

    static const double c1[2] = {1.5, 2.5};
    static const double c2[2] = {1.5, 3.5};
    static const float g1[2] = {1.0f, -2.0f};
    static const float g2[2] = {0.0f, -3.0f};
    static const double a1[2] = {-4.0, 1.0};
    static const double a2[2] = {3.0, 2.0};
    uint64x2_t ceq = vceqq_f64(vld1q_f64(c1), vld1q_f64(c2));
    pd2u("fceq2d", ceq);
    pu32_2("fcmge2s", vcge_f32(vld1_f32(g1), vld1_f32(g2)));
    uint64x2_t acgt = vcagtq_f64(vld1q_f64(a1), vld1q_f64(a2));
    pd2u("facgt2d", acgt);

    static const double p1[2] = {1.0, 2.0};
    static const double p2[2] = {3.0, 4.0};
    static const float q1[2] = {1.0f, -2.0f};
    static const float q2[2] = {3.0f, 0.5f};
    pd2("faddp2d", vpaddq_f64(vld1q_f64(p1), vld1q_f64(p2)));
    pf2("fminp2s", vpmin_f32(vld1_f32(q1), vld1_f32(q2)));

    uint16_t hsrc[8] = {0, 1, 2, 3, 4, 5, 6, 7};
    uint16x4x2_t hd2 = vld2_u16(hsrc);
    pu32_2("ld2h_a", vreinterpret_u32_u16(hd2.val[0]));
    double dsrc[4] = {1.0, 2.0, 3.0, 4.0};
    float64x2x2_t dd2 = vld2q_f64(dsrc);
    pd2("ld2d_a", dd2.val[0]);
    pd2("ld2d_b", dd2.val[1]);
    uint8_t bsrc[32];
    for (int i = 0; i < 32; i++)
        bsrc[i] = (uint8_t)(i + 1);
    uint8x8x4_t bd4 = vld4_u8(bsrc);
    pu8_8("ld4b_d", bd4.val[3]);

    return 0;
}
