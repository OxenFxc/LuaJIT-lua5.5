#ifndef _LJ_BIGINT_H
#define _LJ_BIGINT_H

#include "lj_obj.h"

#define BIGINT_BASE_BITS 32

/* Access flexible array member. */
#define bigdata(b) ((uint32_t *)((b) + 1))

LJ_FUNC GCbigint *lj_bigint_new(lua_State *L, uint32_t len);
LJ_FUNC void lj_bigint_free(global_State *g, GCobj *o);
LJ_FUNC GCbigint *lj_bigint_fromint64(lua_State *L, int64_t val);
LJ_FUNC GCbigint *lj_bigint_fromuint64(lua_State *L, uint64_t val);
LJ_FUNC GCbigint *lj_bigint_fromnumber(lua_State *L, double val);
LJ_FUNC GCbigint *lj_bigint_add(lua_State *L, GCbigint *b1, GCbigint *b2);
LJ_FUNC GCbigint *lj_bigint_sub(lua_State *L, GCbigint *b1, GCbigint *b2);
LJ_FUNC GCbigint *lj_bigint_mul(lua_State *L, GCbigint *b1, GCbigint *b2);
LJ_FUNC int lj_bigint_arith(lua_State *L, TValue *ra, cTValue *rb, cTValue *rc, MMS mm);
LJ_FUNC int lj_bigint_compare(lua_State *L, cTValue *o1, cTValue *o2);
LJ_FUNC int lj_bigint_rawcompare(GCbigint *a, GCbigint *b);
LJ_FUNC GCstr *lj_bigint_tostring(lua_State *L, GCbigint *b);

#endif
