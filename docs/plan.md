# Milestone plan (approved 2026-10-23)

References: requirements and decisions in [requirements.md](requirements.md) (R*, S1, D*).

Every milestone ends with test programs that run on this Mac; a milestone is done when its exit check passes. Test programs generate their own stimuli; the runtime only writes each step's outputs to stdout through the `write` syscall, so a test compares the printed output trace with the expected one.

## M0 — Clocked kernel, end to end

- Bootstrap (D7) parses: `process` models with `?`/`!` interfaces, `:=`, `$ init` (delay), arithmetic, comparison, boolean operators, `|` composition, `/` hiding, `where` local declarations, `when`, `default`, `^=`, clock extraction, `event`.
- Clock calculus over the boolean clock algebra (S1 IV–1).
- Dependence graph with implicit dependences (S1 IV–3.2) and explicit `-->`; causality cycles are rejected (S1 I–3).
- Clock forest (D8): each root clock is a presence input of the step function; clocks that fit no tree are rejected.
- An intermediate representation with explicit integer widths and no arm64 assumptions (D1, D4), lowered to arm64 assembly for a step function; a runtime entry that runs the steps and writes outputs with raw syscalls (D1).
- Exit check: sampling, merging, and resettable-counter programs print their expected traces; a program with two independent root clocks runs with both presence patterns; a causality cycle and a clock that fits no tree are each rejected with an error naming the signals.

## M1 — Types and arrays

- D4 integer types, the unsigned extension, and `pointer` with its operations.
- Enumerated types (used by the `automaton` translation, S1 XI–1.6, D3).
- Arrays with constant capacities: element access, gather `T[I]`, `indices`, `T next K : A`, `iterate … of … with … end`.
- D6 placement: large arrays in windows of one startup reservation, with guard gaps.
- Exit check: a prefix sum and a table-driven lexer for SIGNAL tokens, written in SIGNAL, print their expected output.

## M2 — Effects and drivers

- Labels, `procedure`, guarded processes, `automaton` (D3).
- D2 built-in effects: load/store, syscall, raw instruction, each with a resource; the same-resource ordering check.
- Rejection of an unsafe effect called from an `automaton`, `node`, or `function` (S1 XI–1, D3).
- Exit check: a file-copy program and a program that maps a Mach-O file with `mmap` and prints its load commands (R2, linker-shaped), both written only in SIGNAL; an unordered pair of effects on one resource and an effect inside an automaton are each rejected.
- Carried from M1, both resolved by per-iteration snapshots (D11):
  - A gather from the array's own previous iteration (`Z := Z[?][R]` inside `iterate`) reads a copy taken at the start of the iteration, not elements this iteration already overwrote.
  - Two body arrays that each read the other's previous iteration are accepted (S1 IX–13): each is copied at the start of the iteration.

## M3 — Own assembler and Mach-O writer

- The compiler encodes arm64 instructions and writes a dyld-loaded Mach-O executable with an ad-hoc code signature (D1, D7); Apple `as`/`ld` are no longer invoked.
- Exit check: every earlier test passes with the own backend, and its executables run without `codesign`.

## M4 — Self-hosting

- The compiler is rewritten in SIGNAL (D5) and compiled by the bootstrap (stage 1); stage 1 compiles the compiler (stage 2).
- D5's no-recursion rule needs no separate check here: SIGNAL models cannot recurse.
- Exit check: the full test suite passes with stage 2. The Python bootstrap is then retired.
- Done 2026-10-25: the exit check passes. `python3 tests/selfhost.py` printed `stage2 matches stage1`, `stage3 matches stage2`, `run.py: 278 passed, 0 failed` and `diff.py: 278 cases, 0 differ`. `bootstrap/sigc.py` is frozen as stage 0, and `tests/backend.py` is retired (D13). The declared divergences are listed in [tests/README.md](../tests/README.md).

## M5 — Bare-metal AArch64

- The interrupt-controller and timer drivers are SIGNAL code written per D3; the runtime sets up the stack, dispatches interrupts to input signals (D2, D8) and writes step lines to the UART, as it writes them to stdout on macOS (D15). Array capacities are physical memory (D6).
- Output format: ELF (D14).
- Exit check: a timer-interrupt program under `qemu-system-aarch64 -M virt` prints the expected sequence on the UART.
- Done 2026-10-25: the exit check passes. `tests/cases/m5/timer.sig`, compiled by stage 2, prints the boot line and 1 to 10 on the PL011 under QEMU 11.1.2; `python3 tests/selfhost.py` printed `stage2 matches stage1`, `stage3 matches stage2`, `run.py: 305 passed, 0 failed` and `diff.py: 282 cases, 0 differ`.

## M6 — Thumb-2

- Second backend for Cortex-M; capacities are physical (D6).
- Target: QEMU `mps2-an385` (Cortex-M3), selected by a `Machine` pragma; output ELF32 (D16).
- Exit check: the M5 test programs, retargeted, pass under `qemu-system-arm` on a Cortex-M machine, and `tests/differential.py` finds no trace difference between Cortex-M and macOS on its seeds (D16).
- Done 2026-10-26: the exit check passes. `tests/cases/m6/timer.sig`, compiled by stage 2, prints the boot line and the SysTick count on UART0 under QEMU 11.1.2 `mps2-an385`; `python3 tests/differential.py 200` printed `200 seeds passed, 0 failed`; `python3 tests/selfhost.py` printed `stage2 matches stage1`, `stage3 matches stage2`, `run.py: 325 passed, 0 failed` and `diff.py: 282 cases, 0 differ`.

Milestones M7–M12 were approved 2026-10-26; they schedule every S1 construct the compiler did not accept after M6. Every milestone below ends with a case per construct it delivers, plus the exit program named. Each one extends `tests/differential.py`'s generator to the constructs it adds wherever both targets can run them. Each milestone's design gets the usual check-in before it is built; the D clauses it lifts are listed so they can be amended there.

## M7 — Repairs and rewrites into existing constructs

- Repairs (behaviour that contradicts the record today):
  - **Automaton state actions:** `S :: P` compiles but runs in every state. Implement S1 XI–1.6's guard, `when` the automaton's state is `S`, on the state signal D11's translation already keeps.
  - **Hiding:** `P / x` is listed under M0 but neither compiler accepts it. Implement it (VII–3).
  - **Class rules:** the `function` and `node` rules (XI–1.4, XI–1.5) are checked.
- Rewrites whose output uses only constructs the compiler already has; the parser gains an operand copier for operators S1 defines with a repeated operand, and FINISH gains a template expander for constructs S1 defines with fresh signals (`cell`, `var`, `after`, `from`, `count`):
  - **Processes:** inner `where` (VII–4; its scoping against D11's one namespace is decided here), empty composition (VII–2), `case … in … else … end` (VII–7).
  - **Equations:** tuple definitions `(X, Y) := (E1, E2)` (VIII–2).
  - **Memory:** `cell`, `after`/`from`/`count` (VI–4.3, VI–4.5); `var` (VI–4.4) where its context clock follows from a sibling operand or the defined signal (IV–2).
  - **Clocks:** `[: E]`, `[/: E]`, `^+`, `^*`, `^-` (VI–5.1–5.2).
  - **Values and arrays:** `T[E] \\ V` (IX–7.2), `E |* N` (IX–5), `array I to N of … end` with definition bodies (IX–13), `==` and `<<=` on scalars (VI–7.2), `left_tt` and `abs` (XIII).
  - **Declarations:** type aliases (V–7), `init` in declarations (V–9), constant names as `$ init` (VI–3.2), arrays of `event` (V–4).
  - **Dependences and pragmas:** dependence sets `{a, b} --> c` (XI–6.2); pragmas on inner models and pragma names other than D15/D16's (XI–7: "A pragma has no semantic effect").
  - **Program and lexer:** a top model of any class (XI–1); Latin-1 letters in names and escapes in strings (II–1).
- Lifts: D10 "Constants are integer literals…" (constant names as initial values only), D11 "state actions are deferred", D13 "without escapes".
- Exit program: the M2 automaton cases with state actions added, and each rewrite's trace equal to the S1 definition written out by hand.

## M8 — Models, parameters and modules

- **Constants and parameters:**
  - constants and `$ init` values defined by any constant expression (V–8, VI–3.2);
  - static parameters on user models, `P{K}(…)` (VI–1.2, XI–5);
  - models as types and parameters (XI–8).
- **Calls and model classes:**
  - calls of models with several outputs (VI–1.2);
  - `action` models (XI–1.2);
  - a label as an expression, and `on L :: P` (VII–5, VII–6);
  - `ref` (XI–4);
  - `safe`, `deterministic`, `unsafe` (XI–6).
- **Automata and operators:** automaton priority, `Automaton_Clock`, `Automaton_SetClock`, `Automaton_SetCurrentStateId` (XI–1.6); `E1 ** E2` on integers (VI–8.1).
- **Modules:** `module … end`, `use`, `private` (XII–1), in the compiled source file (S1: "The way this module is made available is not normalized"; D13's command line stays).
- Lifts: D11 "Static parameters are limited to…", "a called model has at most one output", the D11 automaton deferrals, D11's one program-wide namespace (for modules).
- Exit program: a timer driver written as one parameterised model in a module, instantiated for two CMSDK timers on `mps2-an385`, printing both timers' interrupts. Timer 0 was measured in M6 (Q4); timer 1 is probed at the check-in.

## M9 — Clock algebra in canonical form

- **Canonical form:** a canonical form for clock formulas (S1 IV–1.3 encodes clocks as polynomials over Z/3Z), replacing D8's syntactic equalities.
- **Using it:**
  - clock relations `^<`, `^>`, `^#` (VI–5.3);
  - `^0`;
  - `assert` (VII–8);
  - cycles whose edge clocks are exclusive;
  - conditional dependences `{a --> b} when C` (XI–6.2);
  - `spec` on models with bodies (XI–6.1);
  - `:=:` (VI–6);
  - `min_clock` (XIII–1);
  - the affine intrinsics (XIII–2), using M8's static parameters;
  - the tick-equality check in guarded processes.
- **Shared variables and state variables:** shared variables and partial definitions `::=` with the agreement check (V–10); state variables `statevar`, `X?` (V–11).
- **Open for this milestone's check-in:** whether constants take their context clock (S1 IV–2) instead of D8's constant-root rule.
- Lifts: D8 "Other partitions … wait for a canonical form", "causality cycles … are rejected until that canonical form exists"; D11 "the tick equality is otherwise not checked".
- Exit program: every D8 test still passes or moves to the accepted cases, and a program using each relation prints its expected trace.

## M10 — Arrays and tuples, full

- **Arrays, shapes and access:**
  - multidimensional arrays and multi-index access (V–4, IX–1);
  - arrays as model and top-level inputs and outputs, with a step-line format;
  - whole-value `==`/`<<=`;
  - element endpoints in dependences.
- **Arrays, delays and construction:**
  - `$` on arrays, `window`, generalized delay (VI–3.2–3.4);
  - array enumeration with expressions, `|+`, `E1 .. E2 step E3`, restructuration, element definitions, `<< … >>`, multi-argument `indices` (IX–3–IX–12).
- **Arrays, iteration:**
  - general `iterate` and `next`, sequential enumeration (IX–13–IX–15);
  - `tr`, `*.` (IX–16).
- **Tuples:** `struct` and `bundle` types, field access and definitions (V–5, VIII).
- **Extension:** extension of operators to arrays and tuples (X–1).
- Lifts: D10 "`$` is not supported on arrays", "`iterate` bodies hold monochronous definitions only"; D11 "Model calls … inside `iterate` are rejected", "`with` initializes an array only from…", "A top-level input signal is a scalar"; D13's `0 .. E` subset.
- Exit program: S1's `byte_adder` and matrix product, and a driver whose register block is a `struct` and whose status is a `bundle`.

## M11 — Characters and strings

- `char`, character constants, `string` signals (V–1.5, V–1.6); their representation is chosen at the milestone's check-in.
- `read`, `write`, `writeString` (XIII–6); `read` is rejected on the QEMU targets, which have no input path (D15, D16), as `syscall` is.
- Exit program: a program that reads and writes strings on macOS and writes them on both QEMU targets.

## M12 — Reals and complex numbers

- **Types:** `real`/`dreal` (V–1.3) on arm64 floating point; `complex`/`dcomplex` and `@` (V–1.4).
- **Functions:** `**` with a real base; the XIII mathematical and complex functions in the compiler's own runtime (R2: no libm).
- **Step lines:** decimal printing and parsing of reals.
- **Open for this milestone's check-in:** soft float on Cortex-M3, which has no FPU, or reals rejected there.
- Placed last because no R2 program class (drivers, a dynamic linker) needs reals, and no other milestone depends on them.
- Exit program: each function agrees on every target with Python's `math` module, run offline, within an error bound stated per function at the check-in.

## Not scheduled

- **External model bodies, external types and external constants** (V–2, XI–1, XII): these need calls into separately compiled code. R2's programs do not rely on them, and no requirement asks for them. Open decision.
