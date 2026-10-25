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
- Exit check: the M5 test programs, retargeted, pass under `qemu-system-arm` on a Cortex-M machine.

## Not scheduled

S1 features no milestone delivers yet: tuples and multiple-output models beyond what the compiler needs, `action` models, array access with recovery (`T[E] \\ V`), real/complex/string/character types, `window` and generalized delay, choice processes, `array … of` iteration, modules (S1 XII), intrinsic processes (S1 XIII). Whether full S1 coverage is a goal, and when, is an open decision.
