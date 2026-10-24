import sys
from dataclasses import fields
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "bootstrap"))
import sigc

PASSES = {"tokens": sigc.lex}


def dump_columns(record):
    for column in fields(record):
        values = getattr(record, column.name)
        print(column.name, len(values))
        for value in values:
            print(value)


def main():
    if len(sys.argv) != 3 or sys.argv[1] not in PASSES:
        print(f"usage: dump.py PASS SOURCE; passes are {' '.join(PASSES)}", file=sys.stderr)
        return 2
    pass_name, source = sys.argv[1:]
    try:
        dump_columns(PASSES[pass_name](Path(source).read_text()))
    except sigc.CompileError as error:
        print(f"error {error.line} {error.column} {error}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
