/* CommonCrypto subset needed by Darwin command-line tools: MD5 and SHA-256.
 *
 * Darwin's CC_*_CTX structs are opaque to callers, so these definitions only
 * need to fit inside the guest-allocated sizes (MD5 92 bytes, SHA-256 104
 * bytes) and keep their own state.
 */
#include <stdint.h>
#include <string.h>

struct cc_md5_ctx {
    uint32_t a, b, c, d;
    uint64_t bytes;
    uint8_t buf[64];
};

struct cc_sha256_ctx {
    uint32_t h[8];
    uint64_t bytes;
    uint8_t buf[64];
};

static uint32_t rol32(uint32_t x, int n)
{
    return (x << n) | (x >> (32 - n));
}

static uint32_t ror32(uint32_t x, int n)
{
    return (x >> n) | (x << (32 - n));
}

/* ---------------------------------------------------------------- MD5 */

static const uint32_t md5_k[64] = {
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a,
    0xa8304613, 0xfd469501, 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821, 0xf61e2562, 0xc040b340,
    0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8,
    0x676f02d9, 0x8d2a4c8a, 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, 0x289b7ec6, 0xeaa127fa,
    0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92,
    0xffeff47d, 0x85845dd1, 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
};

static const int md5_s[64] = {
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
};

static void md5_block(struct cc_md5_ctx *ctx, const uint8_t *p)
{
    uint32_t m[16];
    for (int i = 0; i < 16; i++)
        m[i] = (uint32_t)p[i * 4] | ((uint32_t)p[i * 4 + 1] << 8) |
               ((uint32_t)p[i * 4 + 2] << 16) |
               ((uint32_t)p[i * 4 + 3] << 24);
    uint32_t a = ctx->a, b = ctx->b, c = ctx->c, d = ctx->d;
    for (int i = 0; i < 64; i++)
    {
        uint32_t f;
        int g;
        if (i < 16)
        {
            f = (b & c) | (~b & d);
            g = i;
        }
        else if (i < 32)
        {
            f = (d & b) | (~d & c);
            g = (5 * i + 1) & 15;
        }
        else if (i < 48)
        {
            f = b ^ c ^ d;
            g = (3 * i + 5) & 15;
        }
        else
        {
            f = c ^ (b | ~d);
            g = (7 * i) & 15;
        }
        uint32_t tmp = d;
        d = c;
        c = b;
        b = b + rol32(a + f + md5_k[i] + m[g], md5_s[i]);
        a = tmp;
    }
    ctx->a += a;
    ctx->b += b;
    ctx->c += c;
    ctx->d += d;
}

int iosim_CC_MD5_Init(void *vctx)
{
    struct cc_md5_ctx *ctx = vctx;
    ctx->a = 0x67452301;
    ctx->b = 0xefcdab89;
    ctx->c = 0x98badcfe;
    ctx->d = 0x10325476;
    ctx->bytes = 0;
    return 1;
}

int iosim_CC_MD5_Update(void *vctx, const void *data, uint32_t len)
{
    struct cc_md5_ctx *ctx = vctx;
    const uint8_t *p = data;
    ctx->bytes += len;
    size_t used = (size_t)(ctx->bytes - len) % 64;
    if (used)
    {
        size_t take = 64 - used;
        if (take > len)
            take = len;
        memcpy(ctx->buf + used, p, take);
        p += take;
        len -= (uint32_t)take;
        if (used + take == 64)
            md5_block(ctx, ctx->buf);
    }
    while (len >= 64)
    {
        md5_block(ctx, p);
        p += 64;
        len -= 64;
    }
    if (len)
        memcpy(ctx->buf, p, len);
    return 1;
}

int iosim_CC_MD5_Final(uint8_t *digest, void *vctx)
{
    struct cc_md5_ctx *ctx = vctx;
    uint64_t bits = ctx->bytes * 8;
    size_t used = (size_t)ctx->bytes % 64;
    ctx->buf[used++] = 0x80;
    if (used > 56)
    {
        memset(ctx->buf + used, 0, 64 - used);
        md5_block(ctx, ctx->buf);
        used = 0;
    }
    memset(ctx->buf + used, 0, 56 - used);
    for (int i = 0; i < 8; i++)
        ctx->buf[56 + i] = (uint8_t)(bits >> (8 * i));
    md5_block(ctx, ctx->buf);
    uint32_t h[4] = {ctx->a, ctx->b, ctx->c, ctx->d};
    for (int i = 0; i < 4; i++)
    {
        digest[i * 4] = (uint8_t)h[i];
        digest[i * 4 + 1] = (uint8_t)(h[i] >> 8);
        digest[i * 4 + 2] = (uint8_t)(h[i] >> 16);
        digest[i * 4 + 3] = (uint8_t)(h[i] >> 24);
    }
    return 1;
}

/* -------------------------------------------------------------- SHA-256 */

static const uint32_t sha256_k[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
};

static void sha256_block(struct cc_sha256_ctx *ctx, const uint8_t *p)
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++)
        w[i] = ((uint32_t)p[i * 4] << 24) | ((uint32_t)p[i * 4 + 1] << 16) |
               ((uint32_t)p[i * 4 + 2] << 8) | p[i * 4 + 3];
    for (int i = 16; i < 64; i++)
    {
        uint32_t s0 = ror32(w[i - 15], 7) ^ ror32(w[i - 15], 18) ^
                      (w[i - 15] >> 3);
        uint32_t s1 = ror32(w[i - 2], 17) ^ ror32(w[i - 2], 19) ^
                      (w[i - 2] >> 10);
        w[i] = w[i - 16] + s0 + w[i - 7] + s1;
    }
    uint32_t a = ctx->h[0], b = ctx->h[1], c = ctx->h[2], d = ctx->h[3];
    uint32_t e = ctx->h[4], f = ctx->h[5], g = ctx->h[6], h = ctx->h[7];
    for (int i = 0; i < 64; i++)
    {
        uint32_t s1 = ror32(e, 6) ^ ror32(e, 11) ^ ror32(e, 25);
        uint32_t ch = (e & f) ^ (~e & g);
        uint32_t t1 = h + s1 + ch + sha256_k[i] + w[i];
        uint32_t s0 = ror32(a, 2) ^ ror32(a, 13) ^ ror32(a, 22);
        uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = s0 + maj;
        h = g;
        g = f;
        f = e;
        e = d + t1;
        d = c;
        c = b;
        b = a;
        a = t1 + t2;
    }
    ctx->h[0] += a;
    ctx->h[1] += b;
    ctx->h[2] += c;
    ctx->h[3] += d;
    ctx->h[4] += e;
    ctx->h[5] += f;
    ctx->h[6] += g;
    ctx->h[7] += h;
}

int iosim_CC_SHA256_Init(void *vctx)
{
    struct cc_sha256_ctx *ctx = vctx;
    static const uint32_t init[8] = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    };
    memcpy(ctx->h, init, sizeof(init));
    ctx->bytes = 0;
    return 1;
}

int iosim_CC_SHA256_Update(void *vctx, const void *data, uint32_t len)
{
    struct cc_sha256_ctx *ctx = vctx;
    const uint8_t *p = data;
    ctx->bytes += len;
    size_t used = (size_t)(ctx->bytes - len) % 64;
    if (used)
    {
        size_t take = 64 - used;
        if (take > len)
            take = len;
        memcpy(ctx->buf + used, p, take);
        p += take;
        len -= (uint32_t)take;
        if (used + take == 64)
            sha256_block(ctx, ctx->buf);
    }
    while (len >= 64)
    {
        sha256_block(ctx, p);
        p += 64;
        len -= 64;
    }
    if (len)
        memcpy(ctx->buf, p, len);
    return 1;
}

int iosim_CC_SHA256_Final(uint8_t *digest, void *vctx)
{
    struct cc_sha256_ctx *ctx = vctx;
    uint64_t bits = ctx->bytes * 8;
    size_t used = (size_t)ctx->bytes % 64;
    ctx->buf[used++] = 0x80;
    if (used > 56)
    {
        memset(ctx->buf + used, 0, 64 - used);
        sha256_block(ctx, ctx->buf);
        used = 0;
    }
    memset(ctx->buf + used, 0, 56 - used);
    for (int i = 0; i < 8; i++)
        ctx->buf[56 + i] = (uint8_t)(bits >> (56 - 8 * i));
    sha256_block(ctx, ctx->buf);
    for (int i = 0; i < 8; i++)
    {
        digest[i * 4] = (uint8_t)(ctx->h[i] >> 24);
        digest[i * 4 + 1] = (uint8_t)(ctx->h[i] >> 16);
        digest[i * 4 + 2] = (uint8_t)(ctx->h[i] >> 8);
        digest[i * 4 + 3] = (uint8_t)ctx->h[i];
    }
    return 1;
}
