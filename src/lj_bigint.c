#define lj_bigint_c
#define LUA_CORE

#include <string.h>

#include "lj_obj.h"
#include "lj_gc.h"
#include "lj_str.h"
#include "lj_err.h"
#include "lj_state.h"
#include "lj_bigint.h"
#include "lj_bc.h"

#define BIGINT_BASE ((uint64_t)1 << BIGINT_BASE_BITS)

GCbigint *lj_bigint_new(lua_State *L, uint32_t len)
{
  GCSize size = sizeof(GCbigint) + len * sizeof(uint32_t);
  GCobj *o = (GCobj *)lj_mem_newgco(L, size);
  GCbigint *b = &o->big;
  b->gct = ~LJ_TBIGINT;
  b->len = len;
  b->sign = 1;
  memset(bigdata(b), 0, len * sizeof(uint32_t));
  return b;
}

void lj_bigint_free(global_State *g, GCobj *o)
{
  GCbigint *b = &o->big;
  lj_mem_free(g, b, sizeof(GCbigint) + b->len * sizeof(uint32_t));
}

static void big_normalize(GCbigint *b)
{
  uint32_t *buff = bigdata(b);
  while (b->len > 0 && buff[b->len - 1] == 0) {
    b->len--;
  }
  if (b->len == 0) b->sign = 1;
}

static void big_copy(GCbigint *dst, const GCbigint *src)
{
  dst->sign = src->sign;
  dst->len = src->len;
  if (src->len > 0)
    memcpy(bigdata(dst), bigdata(src), src->len * sizeof(uint32_t));
}

GCbigint *lj_bigint_fromint64(lua_State *L, int64_t val)
{
  GCbigint *b = lj_bigint_new(L, 2);
  uint32_t *buff = bigdata(b);
  if (val < 0) {
    b->sign = -1;
    if (val == INT64_MIN) {
        buff[0] = 0;
        buff[1] = 0x80000000;
        b->len = 2;
        return b;
    }
    val = -val;
  } else {
    b->sign = 1;
  }
  buff[0] = (uint32_t)(val & 0xFFFFFFFF);
  buff[1] = (uint32_t)(val >> 32);
  big_normalize(b);
  return b;
}

GCbigint *lj_bigint_fromuint64(lua_State *L, uint64_t val)
{
  GCbigint *b = lj_bigint_new(L, 2);
  uint32_t *buff = bigdata(b);
  b->sign = 1;
  buff[0] = (uint32_t)(val & 0xFFFFFFFF);
  buff[1] = (uint32_t)(val >> 32);
  big_normalize(b);
  fprintf(stderr, "lj_bigint_fromnumber done actual\n");
  return b;
}

GCbigint *lj_bigint_fromnumber(lua_State *L, double n)
{
  if (n != n) return NULL; /* NaN */
  /* Check for Infinity */
  uint64_t u;
  memcpy(&u, &n, 8);
  if ((u & 0x7ff0000000000000ULL) == 0x7ff0000000000000ULL) return NULL;

  if (n == 0.0) return lj_bigint_new(L, 0);

  int sign = 1;
  if (n < 0) { sign = -1; n = -n; }

  /* Check if it fits in uint64 (approx < 1.84e19) */
  if (n < 18446744073709551616.0) { /* 2^64 */
     GCbigint *b = lj_bigint_fromuint64(L, (uint64_t)n);
     b->sign = sign;
     return b;
  }

  int exp = (int)((u >> 52) & 0x7ff) - 1023;
  /* exp >= 64 is guaranteed here */

  uint64_t mant = (u & 0xfffffffffffff) | 0x10000000000000ULL;

  int shift = exp - 52;
  uint32_t word_idx = shift / 32;
  uint32_t bit_ofs = shift % 32;

  uint32_t len = word_idx + 3;

  GCbigint *b = lj_bigint_new(L, len);
  b->sign = sign;
  uint32_t *d = bigdata(b);

  uint32_t v0 = (uint32_t)mant;
  uint32_t v1 = (uint32_t)(mant >> 32);

  if (bit_ofs == 0) {
      d[word_idx] = v0;
      d[word_idx+1] = v1;
  } else {
      d[word_idx] = (v0 << bit_ofs);
      d[word_idx+1] = (v0 >> (32 - bit_ofs)) | (v1 << bit_ofs);
      d[word_idx+2] = (v1 >> (32 - bit_ofs));
  }

  big_normalize(b);
  return b;
}

static GCbigint *to_bigint(lua_State *L, cTValue *v)
{
  if (tvisbigint(v)) {
    return bigintV(v);
  } else if (tvisint(v)) {
    return lj_bigint_fromint64(L, intV(v));
  } else if (tvisnum(v)) {
    return lj_bigint_fromnumber(L, numV(v));
  }
  /* Handle cdata int64? Should have been handled by caller converting or via generic arithmetic */
  return NULL;
}

static int cmp_abs(const GCbigint *a, const GCbigint *b)
{
  if (a->len != b->len) return a->len < b->len ? -1 : 1;
  uint32_t *da = bigdata(a);
  uint32_t *db = bigdata(b);
  int i;
  for (i = (int)a->len - 1; i >= 0; i--) {
    if (da[i] != db[i]) return da[i] < db[i] ? -1 : 1;
  }
  return 0;
}

/* dst = |a| + |b| */
static void add_abs(GCbigint *dst, const GCbigint *a, const GCbigint *b)
{
  uint32_t len = a->len > b->len ? a->len : b->len;
  uint64_t carry = 0;
  uint32_t *dd = bigdata(dst);
  const uint32_t *da = bigdata(a);
  const uint32_t *db = bigdata(b);
  uint32_t i;

  for (i = 0; i < len || carry; i++) {
    uint64_t sum = carry;
    if (i < a->len) sum += da[i];
    if (i < b->len) sum += db[i];
    dd[i] = (uint32_t)sum;
    carry = sum >> 32;
  }
  dst->len = i;
  /* Should not need normalization if a,b normalized and non-zero */
  big_normalize(dst);
}

/* dst = |a| - |b|. Assumes |a| >= |b| */
static void sub_abs(GCbigint *dst, const GCbigint *a, const GCbigint *b)
{
  int64_t borrow = 0;
  uint32_t *dd = bigdata(dst);
  const uint32_t *da = bigdata(a);
  const uint32_t *db = bigdata(b);
  uint32_t i;

  for (i = 0; i < a->len; i++) {
    int64_t diff = (int64_t)da[i] - borrow;
    if (i < b->len) diff -= db[i];

    if (diff < 0) {
      diff += BIGINT_BASE;
      borrow = 1;
    } else {
      borrow = 0;
    }
    dd[i] = (uint32_t)diff;
  }
  dst->len = a->len;
  big_normalize(dst);
}

GCbigint *lj_bigint_add(lua_State *L, GCbigint *b1, GCbigint *b2)
{
  uint32_t max_len = (b1->len > b2->len ? b1->len : b2->len) + 2; /* +2 safe margin */
  GCbigint *r = lj_bigint_new(L, max_len);

  if (b1->sign == b2->sign) {
    add_abs(r, b1, b2);
    r->sign = b1->sign;
  } else {
    int cmp = cmp_abs(b1, b2);
    if (cmp >= 0) {
      sub_abs(r, b1, b2);
      r->sign = b1->sign;
    } else {
      sub_abs(r, b2, b1);
      r->sign = b2->sign;
    }
  }
  return r;
}

GCbigint *lj_bigint_sub(lua_State *L, GCbigint *b1, GCbigint *b2)
{
  uint32_t max_len = (b1->len > b2->len ? b1->len : b2->len) + 2;
  GCbigint *r = lj_bigint_new(L, max_len);

  if (b1->sign != b2->sign) {
    add_abs(r, b1, b2);
    r->sign = b1->sign;
  } else {
    int cmp = cmp_abs(b1, b2);
    if (cmp >= 0) {
      sub_abs(r, b1, b2);
      r->sign = b1->sign;
    } else {
      sub_abs(r, b2, b1);
      r->sign = -b1->sign;
    }
  }
  return r;
}

GCbigint *lj_bigint_mul(lua_State *L, GCbigint *b1, GCbigint *b2)
{
  if (b1->len == 0 || b2->len == 0) {
    return lj_bigint_new(L, 0);
  }
  uint32_t len = b1->len + b2->len;
  GCbigint *r = lj_bigint_new(L, len);
  uint32_t *d1 = bigdata(b1);
  uint32_t *d2 = bigdata(b2);
  uint32_t *dr = bigdata(r);
  uint32_t i, j;

  for (i = 0; i < b1->len; i++) {
    uint64_t carry = 0;
    for (j = 0; j < b2->len; j++) {
      uint64_t tmp = (uint64_t)d1[i] * d2[j] + dr[i + j] + carry;
      dr[i + j] = (uint32_t)tmp;
      carry = tmp >> 32;
    }
    dr[i + b2->len] = (uint32_t)carry;
  }

  r->sign = b1->sign * b2->sign;
  big_normalize(r);
  return r;
}

int lj_bigint_arith(lua_State *L, TValue *ra, cTValue *rb, cTValue *rc, MMS mm)
{
  ptrdiff_t ra_offset = savestack(L, ra);
  /* rb_offset not needed as we assume rb is used only for b1 creation immediately */
  ptrdiff_t rc_offset = savestack(L, rc);
  GCbigint *b1 = to_bigint(L, rb);
  GCbigint *b2;
  GCbigint *r = NULL;

  if (!b1) return 0;

  /* Always push b1 to anchor it */
  setbigintV(L, L->top++, b1);

  b2 = to_bigint(L, restorestack(L, rc_offset));
  if (!b2) {
      L->top--;
      return 0;
  }
  /* Always push b2 to anchor it */
  setbigintV(L, L->top++, b2);

  switch (mm) {
    case MM_add: r = lj_bigint_add(L, b1, b2); break;
    case MM_sub: r = lj_bigint_sub(L, b1, b2); break;
    case MM_mul: r = lj_bigint_mul(L, b1, b2); break;
    default:
        /* Clean up stack */
        L->top -= 2;
        return 0;
  }

  ra = restorestack(L, ra_offset);
  setbigintV(L, ra, r);

  /* Clean up stack */
  L->top -= 2;

  return 1;
}

int lj_bigint_compare(lua_State *L, cTValue *o1, cTValue *o2)
{
  GCbigint *b1 = to_bigint(L, o1);
  GCbigint *b2 = to_bigint(L, o2);
  if (!b1 || !b2) {
      if (!b1 && !tvisbigint(o1)) return -2; /* Not comparable here */
      if (!b2 && !tvisbigint(o2)) return -2;
      /* If one is bigint and other cannot be converted, they are not equal? */
      /* Or should we error? Standard comparison behavior... */
      return -2;
  }

  /* Stack anchor logic omitted for comparison as we don't allocate during cmp_abs */
  /* But to_bigint DOES allocate. */
  if (!tvisbigint(o1)) setbigintV(L, L->top++, b1);
  if (!tvisbigint(o2)) setbigintV(L, L->top++, b2);

  int cmp;
  if (b1->sign != b2->sign) {
      cmp = b1->sign < b2->sign ? -1 : 1;
  } else {
      cmp = cmp_abs(b1, b2);
      if (b1->sign < 0) cmp = -cmp;
  }

  if (!tvisbigint(o2)) L->top--;
  if (!tvisbigint(o1)) L->top--;

  return cmp;
}

int lj_bigint_rawcompare(GCbigint *b1, GCbigint *b2)
{
  if (b1->sign != b2->sign) {
      return b1->sign < b2->sign ? -1 : 1;
  } else {
      int cmp = cmp_abs(b1, b2);
      if (b1->sign < 0) cmp = -cmp;
      return cmp;
  }
}

GCstr *lj_bigint_tostring(lua_State *L, GCbigint *b)
{
  if (b->len == 0) return lj_str_newz(L, "0");

  int estimated = b->len * 10 + 2;
  char *buff = (char *)lj_mem_new(L, estimated);
  int pos = estimated - 1;
  buff[pos] = '\0';

  GCbigint *temp = lj_bigint_new(L, b->len);
  setbigintV(L, L->top++, temp); /* Anchor */
  big_copy(temp, b);

  uint32_t *d = bigdata(temp);

  while (temp->len > 0) {
    uint64_t rem = 0;
    int i;
    for (i = temp->len - 1; i >= 0; i--) {
      uint64_t cur = d[i] + (rem << 32);
      d[i] = (uint32_t)(cur / 10);
      rem = cur % 10;
    }
    big_normalize(temp);
    buff[--pos] = (char)('0' + rem);
  }

  if (b->sign < 0) buff[--pos] = '-';

  GCstr *s = lj_str_newz(L, buff + pos);
  L->top--; /* Pop temp */
  lj_mem_free(G(L), buff, estimated);
  return s;
}
