# Tests

Run all cases with `python3 tests/run.py`, or a subset with `python3 tests/run.py <name-fragment>...`.

Each case in `tests/cases/` is a SIGNAL source `name.sig` with one of:

- `name.out` — the expected output trace. The compiled program runs its steps indefinitely and prints one line per step: the values of the model's outputs in interface order, separated by one space, with `-` for an absent output. Unsigned types and `pointer` print as unsigned decimal. A program whose model has no outputs prints no step lines; its output is whatever its effects write. The harness reads as many lines as the file has, then stops the program.
- `name.err` — a fragment the compiler's error output must contain; the compiler must reject the program.

A trace case may also have `name.in`, a regular file the harness opens as the program's standard input (fd 0) and feeds as is; it may be binary, for a program that reads or maps fd 0 through its own effects. When a program's clocks form more than one tree (D8), or its model has input signals, each step reads one line: `k` characters, `1` for a present root clock and `0` for an absent one, then, for each input in interface order whose root is present and whose type is not `event`, one space and its value. Roots are ordered by their earliest-declared signal, interface signals before locals. A value is an optional `-` and 1 to 20 decimal digits whose magnitude is below 2^64, stored in the input's type with wrapping (D4); a `boolean` value is `0` or `1`, an enumerated value is its ordinal. End of input at the start of a line ends the program with exit status 0. Any other line, including one without its trailing newline, ends it with status 2 and `presence input malformed at step N` on standard error.

A trace case may also have `name.exit`: its first line is the exit status the program must end with, and the rest is a fragment its standard error must contain. The harness then runs the program to exit and compares every line of output with `name.out`.

The compiler is run with an empty PATH, so it can invoke no external tool.

`python3 tests/run.py --compiler PATH [<name-fragment>...]` runs the same cases with the native compiler executable at PATH in place of `python3 bootstrap/sigc.py`, with the same empty PATH and timeouts.

`tests/cases/m4/` holds the cases for the extensions the self-hosted compiler (M4, D13) needs: `argc` (the runtime keeps argc in `x25` and argv in `x26`; the case has no arguments, so it prints 1), `load` and `store` inside `iterate` (`load_*`, `store_*`, `syscall_iterate`), the run-time count `X := 0 .. E` (`range_*`), and string constants (`string_*`).

`python3 tests/dump.py PASS SOURCE` prints `sigc.py`'s table after pass PASS for SOURCE: per column, a line `COLUMN COUNT` and then one value per line. A compile error in the pass ends the output with `error LINE COLUMN MESSAGE`. The passes are `tokens` (columns `kinds`, `texts`, `lines`, `columns`) and `program`, the `Program` returned by `parse_program` (its `finish_model` rewrites included), whose `name` prints as a one-value column and whose nested `types` and `models` print as columns `types.kind` … `models.labels`. A value prints as its decimal or its text, `None` as `none` and a boolean as `0` or `1`; a tuple or list prints its items separated by one space, each nested tuple or list inside `[` `]`, so an empty one prints an empty line, or `[]` when nested. A compile error in either pass prints only the error line.

`tests/diff.py` compiles every case in `tests/cases/` and prints one `DIFF` line per differing case, then `N cases, K differ`; it exits 1 when any case differs. A compiler argument is either a `.py` file, run with Python, or a native executable; compilers run with an empty PATH.

- `python3 tests/diff.py dump PASS COMPILER` compares `dump.py PASS SOURCE` with the file `COMPILER SOURCE -o OUT` writes. COMPILER is the SIGNAL compiler built with its `DUMP_PASS` constant set to the pass, which writes the dump to OUT instead of an executable. COMPILER may also be `compiler/sigc.sig`: diff.py then replaces its line `constant integer DUMP_PASS = 0;` with the pass number (`tokens` is 1, `program` is 2) and builds it with `bootstrap/sigc.py` into `build/m4/` before comparing.
- `python3 tests/diff.py image OLD NEW` compiles every case with both compilers and compares exit statuses and executables byte for byte.

`tests/backend.py` holds the backend checks, run with `python3 tests/backend.py [encoder|programs|executables]...` (all parts by default): `encoder` checks the instruction encoder against Apple `as` (a differential property with fixed seed 0 and 300 cases per form, plus field-range checks), `programs` checks every trace case's encoded `__text` and `__data` against `as` and `ld`, and `executables` compiles `m0/counter.sig` with an empty PATH and checks that `codesign --verify --strict` accepts it, that it prints its first step, and that the compiler leaves no other file beside it. It is the only script that invokes `as`, `ld`, `xcrun` or `codesign`, and it is retired with the bootstrap.
