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
