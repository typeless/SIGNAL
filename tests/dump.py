import sys
from dataclasses import dataclass, fields, is_dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "bootstrap"))
import sigc


def parse(text):
    return sigc.Parser(sigc.lex(text)).parse_program()


def flat(text):
    return sigc.instantiate(parse(text))


@dataclass
class Lowered:
    rows: sigc.Rows
    loops: sigc.Loops


def lowered(text):
    return Lowered(*sigc.lower(flat(text)))


PASSES = {"tokens": sigc.lex, "program": parse, "flat": flat, "rows": lowered}


def render(value, nested):
    if value is None:
        return "none"
    if isinstance(value, bool):
        return str(int(value))
    if isinstance(value, set):
        value = sorted(value)
    if isinstance(value, (tuple, list)):
        items = " ".join(render(item, True) for item in value)
        return f"[{items}]" if nested else items
    return str(value)


def dump_columns(record, prefix=""):
    for column in fields(record):
        values = getattr(record, column.name)
        if is_dataclass(values):
            dump_columns(values, f"{prefix}{column.name}.")
            continue
        if isinstance(values, str):
            values = [values]
        if isinstance(values, set):
            values = sorted(values)
        print(f"{prefix}{column.name}", len(values))
        for value in values:
            print(render(value, False))


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
