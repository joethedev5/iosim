/* Struct arguments and returns entirely inside the arm64 image: small
 * aggregates in registers, a large aggregate through the x8 result
 * pointer, and an HFA of floats. Exits 51 when all values arrive. */
typedef struct { int a, b; } Pair;
typedef struct { long a, b, c; } Triple;
typedef struct { float x, y; } Vec2;

static Pair pair_make(int a, int b) { Pair p = {a, b}; return p; }
static int pair_sum(Pair p) { return p.a + p.b; }
static Triple triple_make(long a) { Triple t = {a, a + 1, a + 2}; return t; }
static long triple_sum(Triple t) { return t.a + t.b + t.c; }
static Vec2 vec_make(float x, float y) { Vec2 v = {x, y}; return v; }
static float vec_sum(Vec2 v) { return v.x + v.y; }
extern int printf(const char *fmt, ...);

int main(void)
{
    Pair p = pair_make(20, 30);
    Triple t = triple_make(3);
    Vec2 v = vec_make(1.5f, 2.5f);
    int ps = pair_sum(p);
    long ts = triple_sum(t);
    float vs = vec_sum(v);
    printf("p=%d t=%ld v=%.1f\n", ps, ts, (double)vs);
    return (ps == 50 && ts == 12 && vs == 4.0f) ? 51 : 19;
}
