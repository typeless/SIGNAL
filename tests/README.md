# Tests

Run all cases with `python3 tests/run.py`, or a subset with `python3 tests/run.py <name-fragment>...`.

Each case in `tests/cases/` is a SIGNAL source `name.sig` with one of:

- `name.out` — the expected output trace. The compiled program runs its steps indefinitely and prints one line per step: the values of the model's outputs in interface order, separated by one space, with `-` for an absent output. The harness reads as many lines as the file has, then stops the program.
- `name.err` — a fragment the compiler's error output must contain; the compiler must reject the program.

A trace case may also have `name.in`, which the harness feeds to the program's standard input. When a program's clocks form more than one tree (D8), each step reads one line of `k` characters, `1` for a present root clock and `0` for an absent one. Roots are ordered by their earliest-declared signal, interface signals before locals. End of input at the start of a line ends the program with exit status 0. Any other line, including one without its trailing newline, ends it with status 2 and `presence input malformed at step N` on standard error.

A trace case may also have `name.exit`: its first line is the exit status the program must end with, and the rest is a fragment its standard error must contain. The harness then runs the program to exit and compares every line of output with `name.out`.
