/* AdvSIMD coverage for the interpreter: arithmetic, min/max, shifts,
 * compares, conversions, pairwise adds, reductions and permutations.
 * Results are stored to arrays with vst1q and printed for comparison. */
#include <arm_neon.h>

extern int printf(const char *fmt, ...);

static float fa[4] = {1.5f, -2.5f, 3.0f, -4.0f};
static float fb[4] = {2.0f, 2.0f, -1.0f, 0.5f};
static int ia[4] = {3, -1, 7, 2};
static int ib[4] = {2, 5, -3, 4};
static short ha[8] = {1, -2, 3, -4, 5, -6, 7, -8};
static short hb[8] = {10, 20, 30, 40, 50, 60, 70, 80};
static signed char ba[16] = {1, 2, 3, 4, 5, 6, 7, 8,
                             -1, -2, -3, -4, -5, -6, -7, -8};
static signed char bb[16] = {1, 1, 1, 1, 1, 1, 1, 1,
                             2, 2, 2, 2, 2, 2, 2, 2};
static float f2[8] = {1, 2, 3, 4, 5, 6, 7, 8};
static float out_f2[8];
static float out_f[4];
static int out_i[4];
static short out_h[8];
static signed char out_b[16];

int main(void)
{
    float32x4_t a = vld1q_f32(fa), b = vld1q_f32(fb);
    vst1q_f32(out_f, vmaxq_f32(a, b));
    printf("fmax %.1f %.1f %.1f %.1f\n", out_f[0], out_f[1], out_f[2],
           out_f[3]);
    vst1q_f32(out_f, vminq_f32(a, b));
    printf("fmin %.1f %.1f %.1f %.1f\n", out_f[0], out_f[1], out_f[2],
           out_f[3]);
    vst1q_f32(out_f, vdivq_f32(a, b));
    printf("fdiv %.1f %.1f %.1f %.1f\n", out_f[0], out_f[1], out_f[2],
           out_f[3]);
    vst1q_f32(out_f, vabsq_f32(a));
    printf("fabs %.1f %.1f %.1f %.1f\n", out_f[0], out_f[1], out_f[2],
           out_f[3]);
    vst1q_f32(out_f, vsqrtq_f32(vabsq_f32(a)));
    printf("fsqrt %.1f %.1f %.1f %.1f\n", out_f[0], out_f[1], out_f[2],
           out_f[3]);

    int32x4_t x = vld1q_s32(ia), y = vld1q_s32(ib);
    vst1q_s32(out_i, vaddq_s32(x, y));
    printf("iadd %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vsubq_s32(x, y));
    printf("isub %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vmulq_s32(x, y));
    printf("imul %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vmaxq_s32(x, y));
    printf("imax %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vminq_s32(x, y));
    printf("imin %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vabsq_s32(x));
    printf("iabs %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vshlq_n_s32(x, 3));
    printf("shl %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vshrq_n_s32(x, 2));
    printf("sshr %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_u32((uint32_t *)out_i, vshrq_n_u32(vreinterpretq_u32_s32(x), 2));
    printf("ushr %u %u %u %u\n", (unsigned)out_i[0], (unsigned)out_i[1],
           (unsigned)out_i[2], (unsigned)out_i[3]);

    int16x8_t hx = vld1q_s16(ha), hy = vld1q_s16(hb);
    vst1q_s16(out_h, vaddq_s16(hx, hy));
    printf("hadd %d %d %d %d %d %d %d %d\n", out_h[0], out_h[1], out_h[2],
           out_h[3], out_h[4], out_h[5], out_h[6], out_h[7]);
    vst1q_s16(out_h, vmaxq_s16(hx, hy));
    printf("hmax %d %d %d %d %d %d %d %d\n", out_h[0], out_h[1], out_h[2],
           out_h[3], out_h[4], out_h[5], out_h[6], out_h[7]);

    int8x16_t bx = vld1q_s8(ba), by = vld1q_s8(bb);
    vst1q_s8(out_b, vaddq_s8(bx, by));
    printf("badd %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
           out_b[0], out_b[1], out_b[2], out_b[3], out_b[4], out_b[5],
           out_b[6], out_b[7], out_b[8], out_b[9], out_b[10], out_b[11],
           out_b[12], out_b[13], out_b[14], out_b[15]);

    vst1q_s32(out_i, (int32x4_t)vceqq_s32(x, y));
    printf("ceq %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, (int32x4_t)vcgtq_s32(x, y));
    printf("cgt %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, (int32x4_t)vcgeq_s32(x, y));
    printf("cge %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, (int32x4_t)vceqq_s32(x, vdupq_n_s32(0)));
    printf("ceq0 %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);

    vst1q_s32(out_i, vpaddq_s32(x, y));
    printf("addp %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    printf("smaxv %d sminv %d umaxv %u uminv %u\n", vmaxvq_s32(x),
           vminvq_s32(x), vmaxvq_u32(vreinterpretq_u32_s32(x)),
           vminvq_u32(vreinterpretq_u32_s32(x)));
    printf("fmaxv %.1f fminv %.1f\n", vmaxvq_f32(a), vminvq_f32(a));

    vst1q_f32(out_f, vcvtq_f32_s32(x));
    printf("scvtf %.1f %.1f %.1f %.1f\n", out_f[0], out_f[1], out_f[2],
           out_f[3]);
    vst1q_s32(out_i, vcvtq_s32_f32(a));
    printf("fcvt %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);

    vst1q_s32(out_i, vzip1q_s32(x, y));
    printf("zip1 %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vzip2q_s32(x, y));
    printf("zip2 %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vuzp1q_s32(x, y));
    printf("uzp1 %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vtrn1q_s32(x, y));
    printf("trn1 %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vdupq_laneq_s32(x, 2));
    printf("dup %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);
    vst1q_s32(out_i, vsetq_lane_s32(9, x, 2));
    printf("ins %d %d %d %d\n", out_i[0], out_i[1], out_i[2], out_i[3]);

    float32x4x2_t pair = vld1q_f32_x2(f2);
    vst1q_f32_x2(out_f2, pair);
    printf("ld1 %.1f %.1f %.1f %.1f %.1f %.1f %.1f %.1f\n", out_f2[0],
           out_f2[1], out_f2[2], out_f2[3], out_f2[4], out_f2[5],
           out_f2[6], out_f2[7]);
    return 0;
}
