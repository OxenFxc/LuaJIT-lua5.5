# Lua 5.5 vs. Current LuaJIT Comparison Report

This report compares the current LuaJIT codebase (based on Lua 5.1 kernel with significant extensions) against the Lua 5.5.1 (work-in-progress) source code.

## 1. Syntax and Keywords

| Feature | Lua 5.5 Target | Current LuaJIT | Status |
| :--- | :--- | :--- | :--- |
| **`global` Keyword** | Reserved keyword (`TK_GLOBAL`). Used for global variable declarations. | Contextual keyword. The parser detects `global` as a name and handles it dynamically. | **Compatible**. LuaJIT's approach avoids breaking legacy code using `global` as a variable name. |
| **`continue` Keyword** | **Not supported**. | **Supported**. LuaJIT has `continue` for loops. | **Divergence**. LuaJIT has extra functionality. |
| **Attributes (`<const>`, `<close>`)** | Supported. Used for constants and deterministic finalization. | **Supported**. Parsed and handled (emits `BC_TBC` for to-be-closed variables). | **Parity**. |
| **Labels & `goto`** | Supported. | Supported. | **Parity**. |
| **Bitwise Operators** | Supported (`&`, `|`, `~`, `<<`, `>>`, `//`). | Supported. | **Parity**. |

## 2. Variable Scoping and Environment

| Feature | Lua 5.5 Target | Current LuaJIT | Status |
| :--- | :--- | :--- | :--- |
| **`_ENV` Support** | Native. `LClosure` structure has **no** `env` field. All globals are accesses to `_ENV` upvalue. | **Hybrid**. `GCfunc` structure **retains** `env` field (for 5.1 C API compatibility). Parser implements `_ENV` semantics by creating `_ENV` as upvalue 0. | **Functional Parity**. Lua code behaves identically, though internal C structures differ. |
| **`setfenv`/`getfenv`** | Removed/Deprecated in favor of `_ENV`. | Available (for 5.1 compatibility), but `_ENV` logic is preferred. | **Compatible**. LuaJIT supports both models. |

## 3. Garbage Collection

| Feature | Lua 5.5 Target | Current LuaJIT | Status |
| :--- | :--- | :--- | :--- |
| **Algorithm** | **Generational** (Minor/Major collections) + Incremental. | **Incremental** Mark-and-Sweep. | **Major Gap**. LuaJIT lacks Generational GC. Porting this requires deep VM changes (write barriers). |
| **Table Finalizers** | Supported (`__gc` on tables). | **Supported**. LuaJIT implements `__gc` for tables. | **Parity**. |
| **Ephemeron Tables** | Supported. | Supported (Weak keys/values). | **Parity**. |

## 4. Standard Libraries

### Math Library
| Feature | Lua 5.5 Target | Current LuaJIT | Action Required |
| :--- | :--- | :--- | :--- |
| **`math.maxinteger` / `mininteger`** | Present. | **Missing**. | **Add** these fields to `math` table in `src/lib_math.c`. |
| **`math.randomseed`** | Returns the two seeds used. | Returns nothing (or 0). | **Update** to return seeds if strict parity is needed. |
| **`math.random`** | Uses `xoshiro256**` algorithm. | Uses Tausworthe PRNG. | Algorithm differs; usually acceptable unless deterministic seed compat is required. |
| **`math.type`**, **`tointeger`**, **`ult`** | Present. | **Present**. | None. |

### Table Library
| Feature | Lua 5.5 Target | Current LuaJIT | Action Required |
| :--- | :--- | :--- | :--- |
| **`table.create`** | Present. Pre-allocates array/hash size. | **`table.new`**. Same functionality, different name. | **Alias** `table.create` to `table.new` for compatibility. |
| **`table.pack` / `unpack`** | Present. | **Present**. | None. |
| **`table.move`** | Present. | **Present**. | None. |

### String Library
| Feature | Lua 5.5 Target | Current LuaJIT | Action Required |
| :--- | :--- | :--- | :--- |
| **`string.pack` / `unpack`** | Present. | **Present**. | None. |
| **UTF-8 Support** | `utf8` library present. | Partial internal support. LuaJIT often relies on external `lua-utf8` or has minimal internal helpers. | Verify `utf8` library availability. |

## 5. Summary & Recommendations

The current LuaJIT codebase is remarkably close to Lua 5.5 feature parity regarding **syntax** and **semantics**.

**Immediate Actions for Porting:**
1.  **Math Constants:** Add `math.maxinteger` and `math.mininteger` to `src/lib_math.c`.
2.  **Table Alias:** Expose `table.new` as `table.create` in `src/lib_table.c`.
3.  **Random:** Consider updating `math.randomseed` return values if 5.4/5.5 compliance is strict.

**Long-term Considerations:**
*   **Generational GC:** This is the significant missing piece. If the goal is strict 5.5 *internal* parity, this is a massive undertaking. If the goal is running Lua 5.5 code, the current Incremental GC is sufficient and functionally correct.
*   **Struct Layouts:** `GCfunc` retaining `env` is a design choice for backward compatibility. Changing this breaks the JIT and binary compatibility.
