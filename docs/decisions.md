# Decisions

Surface-compare verdicts, keyed by date. Each entry records the candidates, the pick and the residual; the design that cites it is in the commit body of the change that landed it.

## 2026-10-27 — M9 canonical form (K1)

- Candidates: (A) reduced ordered binary decision diagrams over root and condition variables; (B) polynomials over Z/3Z as in S1 IV–1.3.
- Pick: A. B is not canonical without a normal-form rewrite, and `m4/clocks_default_wide17` expands to 2^17 monomials where A holds 18 nodes.
- Residual: one equivalence obligation, old tree fit against diagram fit, discharged by the old-against-new differential run over m0–m8 (M9a exit).

## 2026-10-27 — Diagram placement (F1)

- Candidates: (i) APPLY and CHECKS as states of the clock pass over node columns; (ii) a separate pass after CK with its own index and bound.
- Pick: (i). A separate pass repeats the row reader and the definition queue, and its only input is CK's own columns.
- Residual: `CK_BOUND` gains `BD_JOBS × JOB_CAP`; exceeded jobs are a capacity error.

## 2026-10-27 — Affine intrinsics (F3/F8)

- Candidates: (a) parse-end rewrites in the `count`/`cell`/`var` template shape, hidden `'`-named signals; (b) library models instantiated through M8's static parameters.
- Pick: (a). (b) needs a hidden event input a model cannot declare and a `^=` across the instance boundary that the call lowering does not carry.
- Finding: a hidden event with no definition is rejected at lowering (`signal … is never defined`); the hidden clock `clk_i'k` is therefore a hidden input row, which makes it a presence column of the input file.
- Residual: `affine_sample` presence law, discharged by the `m9c` property (ticks `t ≡ phi + 1 (mod d)`).

## 2026-10-27 — M10 encodings (D20)

Surface-compare verdicts over the M10 design, read at c47d8c5.

- Multidimensional arrays: flat block with a nested type chain and a derived stride, over a stored stride column (two constructors, sigc.sig 1966–1968 and 4170–4172, would have to agree), nested arrays with padding, and a shape table. Residual: both spellings of a multidimensional type intern to one id (property).
- Nested `iterate`: one product loop with derived indices, over a loop-level stack, which would re-encode the single-loop-id rule at two schedule sites (6172, 6208) and the emitter. Residual: nested-loop traces against a reference, including inner restarts.
- Construction: nested element stores inside one definition, over a chain of hidden signals (the schedule chains storage only through copies and delays, 6983, so the chain would allocate a block per element), a multi-row definition and per-element scalars. Residual: `(I:S)[I] = S`, `[E1..En][j] = Ej`; a write-after-read edge for element and store readers inside loops.
- Tuples: split before lowering, over tuple-typed rows (a row has one clock, so bundles would be split anyway, and about 32 type dispatch sites would gain an arm). Residual: tuple roundtrip and hidden-name injectivity (properties). Amended 2026-10-28 (M10c): the split runs on the token stream before parsing, so the parser and every later pass stay tuple-free; the cost is a copy of the token columns on every compile, about 25 MiB of self-compile RSS.

## 2026-10-30 — M11 string representation (D21)

- Candidates: (A) a scalar kind `TK_STRING` with its own 256-byte slot and per-ISA templates for copy, select, equality, order, delay and `when`; (B) a kind `TK_STRING` whose type row describes a `[256] ubyte` block, reusing the M10 array rows through one block predicate per table.
- Pick: (B). (A) re-implements copy, `default`, `==`, lag and `when` aliasing on arm64 and Thumb-2, ten template equivalences with existing rows; (B) adds one lexicographic compare row and one block select row per ISA. Inside (B), a kind of its own over `TK_ARRAY` with a flag, which would be valid only for one element type and size and would need `and not` at about 30 array-only sites.
- Residual: the canonical form (zero tail, length at byte 255) kept by every producer, discharged by the `m11` roundtrip and order properties against Python `bytes`.

## 2026-11-02 — M12a reals (D22)

- Real constants: (a) converted to bits by the compiler, in its own integer code; (b) converted at program start by the runtime parser into the constant's slot. Pick: (a). (b) still needs the exact largest-finite comparison at compile time to reject constants that round to infinity, gives the constant table a type-dependent meaning, adds an ordering convention for the init phase and a parser on `virt`.
- Decimal conversion: (a) a fixed-capacity bignum, exact comparison for parsing and Steele–White/Dragon4 shortest digits for printing; (b) Ryu for printing and Eisel–Lemire for parsing. Pick: (a). (b)'s parse needs (a) as its fallback, adds a fallback trigger kept by convention and about 5 KB of tables. Digits past the 768th fold into one sticky digit (fast_float `binary_format<double>::max_digits()` is 769).
- FP values: (a) operands stay on the x9/x10 path with the existing loads and stores, and `FMOV` moves bits to and from s/d registers around each FP instruction; (b) new FP load and store forms. Pick: (a); only the FP row templates know FP registers.
- Residual: two decimal-to-binary implementations (the compiler's, the runtime's) and one printer, each discharged by the `m12` differential property against Python's `float`, `repr`, `struct` and `fractions`, with exact midpoints and inputs past the 768th digit fed to both parsers.

## 2026-11-02 — M12b complex numbers (D22)

- Representation: (a) a complex kind carried through the emitter as one 16-byte scalar; (b) a row pass after lowering that turns each complex row into a real-part row in place and appends an imaginary-part row. Pick: (b). Load and store forms stop at 8 bytes, so (a) needs a two-register convention at about 44 template arms and 9 emitter selection sites plus about 10 twin rows; (b) leaves the emitter unchanged and has one structural post-condition, no complex row after the pass. Arrays of complex values follow as two real arrays (not one array of twice the length, which would double every element index in the array loops), and their step-line order is D20's struct-of-arrays order.
- Oracle: `*` and `/` follow CPython 3.14's `_Py_c_prod` and `_Py_c_quot` operation for operation, so the `m12` differential compares `dcomplex` results with Python's `complex` bit for bit rather than within a tolerance. S1 VI–8.1 asks only that a representable quotient not come back as NaN or 0. The CPython 3.14.7 build on this machine fuses the multiply-adds of `_Py_c_quot` and of `_Py_c_prod`'s recalculation (checked with otool), and the generated code fuses the same ones; a CPython build that does not contract would differ in the last bit on about 1% of quotients.
- `arg`/`argd` move to M12c with atan2, the XIII–4 routine they need. `modu` stays in M12b as one template: scaling, `FSQRT` and one correction step.
- An absent complex prints `- -`: with (b) a complex is a flattened pair, and D20 prints one `-` per flattened field.
- Residual: complex rows ≡ Python `complex` per operation and operand class (the `m12` differential, bit for bit except `modu`, within 1 ulp); the print–parse roundtrip; boundary cases for every `_Py_c_quot` branch, zero and NaN divisors, `modu` at the extremes and `=` with NaN or −0.0 components; the per-row column copy in the pass is a convention at one site.

## 2026-11-03 — M12c mathematical functions (D22)

- Design: the design attorney cut array extension of the calls, a real exponent for `**` (S1 VI–8.1 types the exponent as an integer), per-function emission, an error print and a separate checker; the exit program compares in-program.
- Routines: (a) arm64 routines in REAL_RUNTIME, generated in tables.py; (b) a SIGNAL prelude. Pick: (a). (b) needs a `dreal`↔integer bit cast S1 does not have, makes helper names user-visible by convention only, and spends the ROWS capacity and the REALS literal budget (about 40 ms per literal, 200–300 coefficients) on every compile.
- Algorithms: (a) port FreeBSD msun function by function; (b) own Remez coefficients and reductions. Pick: (a), one port↔source term per function against about four unproven terms per function in (b) with no reference. msun's `tanh`, `sinh`, `cosh` and `atan2` measured above 1 ulp from the true value, so `sinh`, `cosh`, `tanh`, `atan` and `atan2` finish in double-double. The tests carry no port↔msun oracle: a Python transliteration would re-implement the algorithm under test.
- Oracle: U4 names Python's `math`, which on macOS is Apple's libm and not correctly rounded. Where it is more than 1 ulp from the true value (`tan`, up to 2.4 ulp), the bound is against the true value (user, 2026-11-03). The `m12` differential arbitrates such `tan` results with a decimal evaluation (Machin's π, exact reduction, Taylor sine and cosine); 20000-row runs per function found no other function where Apple is more than 1 ulp off, so the others are checked against Python alone.
- `virt` stack: 1536 bytes, the deepest runtime chain rounded up to a multiple of 512 and checked when the tables are generated; `rem_pio2`'s 1376-byte frame stays as msun lays it out.
- Residual: each routine within 1 ulp (the `m12` differential and the exit program on both targets), the exact set bit for bit, the `frexp`/`modf` laws, `pow`'s special-case table as cases; conventions: each routine's clobber set (x0–x17, d0–d31, x30), no FMADD where msun writes separate operations, and the row templates' stack adjustments outside the generator's stack check.
