# Tests

Run all cases with `python3 tests/run.py`, or a subset with `python3 tests/run.py <name-fragment>...`.

Each case in `tests/cases/` is a SIGNAL source `name.sig` with one of:

- `name.out` — the expected output trace. The compiled program runs its steps indefinitely and prints one line per step: the values of the model's outputs in interface order, separated by one space, with `-` for an absent output. The harness reads as many lines as the file has, then stops the program.
- `name.err` — a fragment the compiler's error output must contain; the compiler must reject the program.

A trace case may also have `name.in`, which the harness feeds to the program's standard input. When a program's clocks form more than one tree (D8), each step reads one line of `k` characters, `1` for a present root clock and `0` for an absent one. Roots are ordered by their earliest-declared signal, interface signals before locals. A short line reads the missing roots as absent; end of input, including a missing trailing newline, ends the program.
