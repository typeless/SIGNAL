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
    types: sigc.Types
    table_types: list
    table_values: list


def lowered(text):
    program = flat(text)
    rows, loops = sigc.lower(program)
    return Lowered(rows, loops, program.types, program.table_types, program.table_values)


def clocks(text):
    program = flat(text)
    rows, loops = sigc.lower(program)
    result = sigc.clock_calculus(rows, program, loops)
    result.parent = [sigc.find(result, clock) for clock in range(len(result.parent))]
    return result


@dataclass
class Scheduled:
    order: list
    loop_orders: list
    snapshots: list
    snapshotted: set


def scheduled(text):
    program = flat(text)
    rows, loops = sigc.lower(program)
    order, loop_orders = sigc.schedule(program, rows, sigc.clock_calculus(rows, program, loops), loops)
    return Scheduled(order, loop_orders, loops.snapshots, rows.snapshotted)


@dataclass
class Emitted:
    form: list
    op0: list
    op1: list
    op2: list
    op3: list
    target_section: list
    target_offset: list
    data_offsets: list
    data_alignments: list
    data: bytes


def emitted(text):
    program = flat(text)
    rows, loops = sigc.lower(program)
    clocks_found = sigc.clock_calculus(rows, program, loops)
    order, loop_orders = sigc.schedule(program, rows, clocks_found, loops)
    alignments = []
    data_item = sigc.data_item

    def recording_data_item(code, alignment, content):
        alignments.append(alignment)
        return data_item(code, alignment, content)

    sigc.data_item = recording_data_item
    try:
        code = sigc.emit_code(program, rows, clocks_found, loops, order, loop_orders)
    finally:
        sigc.data_item = data_item
    targets = [(-1, 0) if target < 0 else (code.label_section[target], code.label_offset[target]) for target in code.target]
    data_offsets = [offset for section, offset in zip(code.label_section, code.label_offset) if section == sigc.DATA]
    return Emitted(
        code.form, code.op0, code.op1, code.op2, code.op3, [section for section, _ in targets],
        [offset for _, offset in targets], data_offsets, alignments, bytes(code.data),
    )


PASSES = {
    "tokens": sigc.lex, "program": parse, "flat": flat, "rows": lowered, "clocks": clocks, "schedule": scheduled,
    "code": emitted,
}


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
    except UnicodeDecodeError as error:
        print(f"sigc: error: {error}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
