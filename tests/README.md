# Tests

Run all cases with `python3 tests/run.py`, or a subset with `python3 tests/run.py <name-fragment>...`.

Each case in `tests/cases/` is a SIGNAL source `name.sig` with one of:

- `name.out` — the expected output trace. The compiled program runs its steps indefinitely and prints one line per step: the values of the model's outputs in interface order, separated by one space, with `-` for an absent output. Unsigned types and `pointer` print as unsigned decimal. A program whose model has no outputs prints no step lines; its output is whatever its effects write. The harness reads as many lines as the file has, then stops the program.
- `name.err` — a fragment the compiler's error output must contain; the compiler must reject the program.

A trace case may also have `name.in`, a regular file the harness opens as the program's standard input (fd 0) and feeds as is; it may be binary, for a program that reads or maps fd 0 through its own effects. When a program's clocks form more than one tree (D8), or its model has input signals, each step reads one line: `k` characters, `1` for a present root clock and `0` for an absent one, then, for each input in interface order whose root is present and whose type is not `event`, one space and its value. Roots are ordered by their earliest-declared signal, interface signals before locals. A value is an optional `-` and 1 to 20 decimal digits whose magnitude is below 2^64, stored in the input's type with wrapping (D4); a `boolean` value is `0` or `1`, an enumerated value is its ordinal. End of input at the start of a line ends the program with exit status 0. Any other line, including one without its trailing newline, ends it with status 2 and `presence input malformed at step N` on standard error.

A trace case may also have `name.exit`: its first line is the exit status the program must end with, and the rest is a fragment its standard error must contain. The harness then runs the program to exit and compares every line of output with `name.out`.

The compiler is run with an empty PATH, so it can invoke no external tool.

`tests/backend.py` holds the backend checks, run with `python3 tests/backend.py [encoder|programs|executables]...` (all parts by default): `encoder` checks the instruction encoder against Apple `as` (a differential property with fixed seed 0 and 300 cases per form, plus field-range checks), `programs` checks every trace case's encoded `__text` and `__data` against `as` and `ld`, and `executables` compiles `m0/counter.sig` with an empty PATH and checks that `codesign --verify --strict` accepts it, that it prints its first step, and that the compiler leaves no other file beside it. It is the only script that invokes `as`, `ld`, `xcrun` or `codesign`, and it is retired with the bootstrap.
