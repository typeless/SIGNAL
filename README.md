# SIGNAL

A compiler for [SIGNAL](https://hal.science/hal-02928452/document), the synchronous dataflow language, that writes native executables without C, an assembler or a linker. The compiler is written in SIGNAL and compiles itself.

Targets:

- macOS arm64 user space (Mach-O, ad-hoc signed)
- bare-metal AArch64 on QEMU `virt` (ELF64), selected by `Interrupt`/`Boot` pragmas
- bare-metal Cortex-M3 on QEMU `mps2-an385` (Thumb-2, ELF32), selected by `Machine "mps2-an385"`

## Layout

- `compiler/sigc.sig` — the self-hosted compiler; `compiler/tables.py` generates its constant tables
- `bootstrap/sigc.py` — the frozen Python stage 0 (standard library only)
- `docs/requirements.md` — requirements and design decisions (D1–D16); `docs/plan.md` — milestones
- `tests/` — test cases and harness; see [tests/README.md](tests/README.md)

## Build and test

Requires Python 3.14 on an Apple silicon Mac; the bare-metal tests also need QEMU (`qemu-system-aarch64`, `qemu-system-arm`).

```bash
python3 tests/selfhost.py
```

This builds the compiler three times into `build/m4/` (stage 1 with the bootstrap, stage 2 with stage 1, stage 3 with stage 2), checks that the stages are identical, and runs the full test suite with stage 2. Then compile a program with:

```bash
build/m4/stage2 program.sig -o program
```

## License

MIT
