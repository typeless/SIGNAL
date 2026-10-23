# Requirements and decisions

## R — Requirements (user, 2026-10-23)

> I'd like to implement the SIGNAL programming language (like Polychrony)

- **R1** The target is CPU machine instructions (mac mini native).
- **R2** Can be used for developing RTOS/device drivers and user-space programs like a dynamic linker (heavy OS primitive interfacing) without relying on external C.
- **R3** Can use whatever programming language (with fast-iteration, low dependencies).
- **R4** Eventually self-hosted.

## S — Specification

- **S1** Language reference: *SIGNAL V4 – INRIA version: Reference Manual (revised working version)*, Besnard, Gautier, Le Guernic, 2020-04-01, HAL [hal-02928452v1](https://hal.science/hal-02928452/document). Where this document extends the spec, the extension is named as such.

## D — Decisions (each approved by the user, 2026-10-23)

- **D1 Targets.** First target is macOS arm64 user space. Bare metal is AArch64 under QEMU `virt`, sharing the arm64 backend. Thumb-2 (Cortex-M) is required but deferred to a later phase.
  - Measured on this Mac: static Mach-O executables are killed at launch (exit 137) even when ad-hoc signed; dyld-loaded executables issuing raw `svc #0x80` syscalls run. Generated programs are therefore dyld-loaded and code-signed.
- **D2 Effects.** Load/store at an address, syscall, and raw instruction are built-in `external` models of class `unsafe` (S1 XI–1), each naming a resource. Order between effects is stated with `-->` (S1 XI–6.2). The compiler rejects two effects on the same resource with no order between them (extension). No inline imperative escape hatch. Interrupts are input signals.
- **D3 Automata.** `automaton` models stay deterministic (S1 XI–1.6) and never call unsafe effects. A driver is a `process` shell around a pure automaton: the shell reads via unsafe procedures, feeds values to the automaton, and performs writes ordered by `-->`. Hand-written state variables with guarded processes inside a `process` remain allowed.
- **D4 Integer types.** `short`/`integer`/`long` are 16/32/64 bits on every target; overflow wraps. Extension: unsigned `ubyte`/`ushort`/`uinteger`/`ulong` (8/16/32/64); bitwise `and`/`or`/`xor`/`not` and shifts on unsigned types only; value-preserving widening implicit, same-width signed↔unsigned explicit. `pointer` (S1 V–2) is the only target-width type, with ± offset, compare, and explicit conversion to/from `ulong`/`uinteger`.
- **D5 Self-hosting.** Table-driven (APL style), no recursion: column tables for syntax trees, table-driven parsing with explicit stacks, bounded `iterate` for fixpoints, built on S1 chapter IX. No recursive functions, tagged unions, or arenas.
- **D6 Memory.** Array capacities are declared constants. On macOS user space, large arrays live in fixed windows carved at compile time from one address-space reservation made at startup, each followed by an unmapped guard gap; arrays never move. Measured: 16 KiB pages; one 2^46-byte reservation succeeds, 2^47 fails; pages cost memory only when written.
- **D7 Bootstrap.** Python 3.14, standard library only, written table-driven so passes port to SIGNAL by transliteration. It covers only the SIGNAL subset the self-hosted compiler is written in. It emits arm64 assembly and uses Apple `as`/`ld` until the compiler writes Mach-O itself.
- **D8 Clock structure.** A program's clocks may form a forest of clock trees rather than a single tree. Each root clock becomes a presence input to the step function, supplied by the caller (for example, an interrupt dispatcher knows which interrupt fired). Clocks that fit no tree are rejected. This is broader than endochrony (S1 III–8.2), which the spec defines but does not require.
