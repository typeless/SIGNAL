import os
import random
import subprocess
import struct
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "bootstrap"))
import sigc

SEED = 0
CASES_PER_FORM = 300
EDGE_PROBABILITY = 0.2
OBJECT_TEXT_SECTION = 32 + 72 + 32
CASES = ROOT / "tests" / "cases"
LC_SEGMENT_64 = 0x19
DATA_BYTES_PER_LINE = 64
FIXUP_SUFFIXES = {sigc.PCREL: "", sigc.PAGE: "@PAGE", sigc.PAGEOFF: "@PAGEOFF"}
CONDITION_NAMES = ("eq", "ne", "hs", "lo", "mi", "pl", "vs", "vc", "hi", "ls", "ge", "lt", "gt", "le", "al", "nv")


def register(kind, number):
    if number == 31:
        return {"x": "xzr", "w": "wzr", "xsp": "sp", "wsp": "wsp"}[kind]
    return f"{kind[0]}{number}"


def relative(offset):
    if isinstance(offset, str):
        return offset
    return f".+{offset}" if offset >= 0 else f".-{-offset}"


SYNTAX = {
    "ret": lambda o: "ret",
    "svc 0x80": lambda o: "svc #0x80",
    "word": lambda o: f".inst {o[2]:#x}",
    "eor x one": lambda o: f"eor {register('xsp', o[0])}, {register('x', o[1])}, #1",
    "msub x": lambda o: f"msub {register('x', o[0])}, {register('x', o[1])}, {register('x', o[2])}, {register('x', o[3])}",
    "b": lambda o: f"b {relative(o[2])}",
    "bl": lambda o: f"bl {relative(o[2])}",
    "b.cond": lambda o: f"b.{CONDITION_NAMES[o[3]]} {relative(o[2])}",
    "adrp": lambda o: f"adrp {register('x', o[0])}, #{o[2]}",
}
for mnemonic, width in (("movz", "x"), ("movz", "w"), ("movk", "x"), ("movk", "w")):
    SYNTAX[f"{mnemonic} {width}"] = lambda o, mnemonic=mnemonic, width=width: f"{mnemonic} {register(width, o[0])}, #{o[2]}, lsl #{16 * o[3]}"
for mnemonic, width, destination in (("add", "x", "xsp"), ("add", "w", "wsp"), ("sub", "x", "xsp"), ("sub", "w", "wsp"), ("subs", "x", "x"), ("subs", "w", "w")):
    SYNTAX[f"{mnemonic} {width} imm"] = lambda o, mnemonic=mnemonic, width=width, destination=destination: f"{mnemonic} {register(destination, o[0])}, {register(width + 'sp', o[1])}, #{o[2]}"
for mnemonic, width in (("add", "x"), ("adds", "x"), ("sub", "x"), ("subs", "x"), ("and", "x"), ("and", "w"), ("orr", "x"), ("orr", "w"), ("eor", "x"), ("orn", "x"), ("lslv", "x"), ("lsrv", "x"), ("sdiv", "x"), ("udiv", "x"), ("mul", "x"), ("umulh", "x")):
    SYNTAX[f"{mnemonic} {width}"] = lambda o, mnemonic=mnemonic, width=width: f"{mnemonic} {register(width, o[0])}, {register(width, o[1])}, {register(width, o[2])}"
for mnemonic, width in (("csel", "x"), ("csinc", "w"), ("csneg", "x")):
    SYNTAX[f"{mnemonic} {width}"] = lambda o, mnemonic=mnemonic, width=width: f"{mnemonic} {register(width, o[0])}, {register(width, o[1])}, {register(width, o[2])}, {CONDITION_NAMES[o[3]]}"
for mnemonic, width in (("cbz", "w"), ("cbz", "x"), ("cbnz", "x")):
    SYNTAX[f"{mnemonic} {width}"] = lambda o, mnemonic=mnemonic, width=width: f"{mnemonic} {register(width, o[0])}, {relative(o[2])}"
for mnemonic, width, shift in (("ldr", "x", 3), ("ldr", "w", 2), ("ldrsw", "x", 2), ("ldrh", "w", 1), ("ldrsh", "x", 1), ("ldrb", "w", 0), ("str", "x", 3), ("str", "w", 2), ("strh", "w", 1), ("strb", "w", 0)):
    SYNTAX[f"{mnemonic} {width}"] = lambda o, mnemonic=mnemonic, width=width: f"{mnemonic} {register(width, o[0])}, [{register('xsp', o[1])}, #{o[2]}]"
    SYNTAX[f"{mnemonic} {width} reg"] = lambda o, mnemonic=mnemonic, width=width, shift=shift: f"{mnemonic} {register(width, o[0])}, [{register('xsp', o[1])}, {register('x', o[2])}" + (f", lsl #{shift}]" if shift else "]")
for mnemonic, width in (("ldr", "x"), ("str", "x"), ("str", "w"), ("strb", "w")):
    SYNTAX[f"{mnemonic} {width} post"] = lambda o, mnemonic=mnemonic, width=width: f"{mnemonic} {register(width, o[0])}, [{register('xsp', o[1])}], #{o[2]}"
SYNTAX["ldrb w pre"] = lambda o: f"ldrb {register('w', o[0])}, [{register('xsp', o[1])}, #{o[2]}]!"


def slot_ranges(form):
    _, _, fields, signed, _ = sigc.FORMS[form]
    ranges = {}
    for slot in sorted({field[0] for field in fields}):
        lowest_bit = min(low for field_slot, low, _, _ in fields if field_slot == slot)
        top = max(low + width for field_slot, low, width, _ in fields if field_slot == slot)
        alignment = 1 << lowest_bit
        if signed and slot == 2:
            ranges[slot] = (alignment, -(1 << (top - 1)), (1 << (top - 1)) - alignment, True)
        else:
            ranges[slot] = (alignment, 0, (1 << top) - alignment, False)
    return ranges


def draw_operands(rng, form):
    operands = [0, 0, 0, 0]
    for slot, (alignment, minimum, maximum, _) in slot_ranges(form).items():
        if rng.random() < EDGE_PROBABILITY:
            value = rng.choice((0, minimum, maximum))
        else:
            value = rng.randrange(minimum, maximum + 1)
        operands[slot] = value // alignment * alignment
    if sigc.FORMS[form][2] == sigc.INDEXED and operands[0] == operands[1]:
        operands[1] = (operands[0] + 1) % 31
    return operands


def check_coverage():
    names = {form[0] for form in sigc.FORMS}
    report = [f"form without syntax: {name}" for name in sorted(names - set(SYNTAX))]
    report += [f"syntax without form: {name}" for name in sorted(set(SYNTAX) - names)]
    return report


def check_differential():
    rng = random.Random(SEED)
    cases = [(form, draw_operands(rng, form)) for form in range(len(sigc.FORMS)) for _ in range(CASES_PER_FORM)]
    lines = [SYNTAX[sigc.FORMS[form][0]](operands) for form, operands in cases]
    with tempfile.TemporaryDirectory() as directory:
        source = Path(directory) / "forms.s"
        image = Path(directory) / "forms.o"
        source.write_text("    .p2align 2\n" + "".join(f"    {line}\n" for line in lines))
        assembled = subprocess.run(["as", "-arch", "arm64", str(source), "-o", str(image)], capture_output=True, text=True)
        if assembled.returncode != 0:
            return [f"as failed (exit {assembled.returncode}):", assembled.stderr.rstrip()]
        obj = image.read_bytes()
    _, size, offset = struct.unpack_from("<QQI", obj, OBJECT_TEXT_SECTION)
    words = struct.unpack_from(f"<{size // 4}I", obj, offset)
    if len(words) != len(cases):
        return [f"as produced {len(words)} words for {len(cases)} cases"]
    report = []
    for (form, operands), line, expected in zip(cases, lines, words):
        try:
            actual = f"{sigc.pack(form, operands):08x}"
        except sigc.CompileError as error:
            actual = f"CompileError({error})"
        if actual != f"{expected:08x}":
            report.append(f"{sigc.FORMS[form][0]} {operands}: pack {actual}, as {expected:08x} for '{line}'")
    return report


def check_ranges():
    report = []
    for form, (name, *_) in enumerate(sigc.FORMS):
        for slot, (alignment, minimum, maximum, signed) in slot_ranges(form).items():
            rejected = [maximum + alignment, minimum - alignment if signed else -1] + ([1] if alignment > 1 else [])
            for value, accepted in [(value, True) for value in {0, minimum, maximum}] + [(value, False) for value in rejected]:
                operands = [0, 0, 0, 0]
                operands[slot] = value
                try:
                    sigc.pack(form, operands)
                    packed = True
                except sigc.CompileError:
                    packed = False
                if packed != accepted:
                    report.append(f"{name} slot {slot} value {value}: expected {'acceptance' if accepted else 'CompileError'}")
    return report


def check_compare_branch_example():
    word = sigc.pack(sigc.CBZ_W, [1, 0, -(1 << 20), 0])
    return [] if word == 0x34800001 else [f"pack(CBZ_W, [1, 0, -(1 << 20), 0]) = {word:08x}, expected 34800001"]


def print_assembly(code):
    text_labels = [[] for _ in range(len(code.form) + 1)]
    data_labels = {0: [], len(code.data): []}
    for label, (section, offset) in enumerate(zip(code.label_section, code.label_offset)):
        if section == sigc.TEXT:
            text_labels[offset].append(label)
        elif section == sigc.DATA:
            data_labels.setdefault(offset, []).append(label)
    lines = ["    .section __TEXT,__text,regular,pure_instructions", "    .globl _start", "    .p2align 2", "_start:"]
    for index, form in enumerate(code.form):
        lines += [f"_l{label}:" for label in text_labels[index]]
        name = sigc.FORMS[form][0]
        operands = [code.op0[index], code.op1[index], code.op2[index], code.op3[index]]
        target = code.target[index]
        if target >= 0:
            operands[2] = f"_l{target}{FIXUP_SUFFIXES[sigc.FORMS[form][4]]}"
        lines.append(f"    {SYNTAX[name](operands)}")
    lines += [f"_l{label}:" for label in text_labels[len(code.form)]]
    lines += ["    .section __DATA,__data", "    .p2align 3"]
    boundaries = sorted(data_labels)
    for start, end in zip(boundaries, boundaries[1:] + [len(code.data)]):
        lines += [f"_l{label}:" for label in data_labels[start]]
        for chunk in range(start, end, DATA_BYTES_PER_LINE):
            lines.append("    .byte " + ", ".join(str(byte) for byte in code.data[chunk:min(end, chunk + DATA_BYTES_PER_LINE)]))
    return "\n".join(lines) + "\n"


def linked_sections(image):
    sections = {}
    _, _, _, _, command_count, _, _, _ = struct.unpack_from("<IiiIIIII", image, 0)
    command = 32
    for _ in range(command_count):
        kind, size = struct.unpack_from("<II", image, command)
        if kind == LC_SEGMENT_64:
            section_count = struct.unpack_from("<I", image, command + 64)[0]
            for section in range(section_count):
                header = command + 72 + 80 * section
                name = image[header:header + 16].rstrip(b"\0").decode()
                address, size_bytes, offset = struct.unpack_from("<QQI", image, header + 32)
                sections[name] = (address, size_bytes, offset)
        command += size
    return sections


def first_difference(expected, actual):
    return next((index for index, (left, right) in enumerate(zip(expected, actual)) if left != right), min(len(expected), len(actual)))


def check_programs():
    sdk = subprocess.run(["xcrun", "--show-sdk-path"], capture_output=True, text=True, check=True).stdout.strip()
    report = []
    with tempfile.TemporaryDirectory() as directory:
        for source in sorted(CASES.rglob("*.sig")):
            if not source.with_suffix(".out").exists():
                continue
            name = source.relative_to(CASES)
            code, _ = sigc.compile_source(source.read_text())
            assembly = Path(directory) / "program.s"
            image_path = Path(directory) / "program.o"
            executable = Path(directory) / "program"
            assembly.write_text(print_assembly(code))
            for step in (
                ["as", "-arch", "arm64", str(assembly), "-o", str(image_path)],
                ["ld", "-arch", "arm64", "-e", "_start", "-syslibroot", sdk, "-lSystem", str(image_path), "-o", str(executable)],
            ):
                finished = subprocess.run(step, capture_output=True, text=True)
                if finished.returncode != 0:
                    report.append(f"{name}: {step[0]} failed (exit {finished.returncode}): {finished.stderr.strip()}")
                    break
            else:
                image = executable.read_bytes()
                sections = linked_sections(image)
                text_address, text_size, text_offset = sections["__text"]
                data_address, data_size, data_offset = sections["__data"]
                linked_text = image[text_offset:text_offset + text_size]
                linked_data = image[data_offset:data_offset + data_size]
                encoded = sigc.encode(code, text_address, data_address)
                if encoded != linked_text:
                    word = first_difference(encoded, linked_text) // 4
                    form = sigc.FORMS[code.form[word]][0] if word < len(code.form) else "end"
                    report.append(f"{name}: __text differs from ld at word {word} ({form}): {encoded[4 * word:4 * word + 4].hex()} vs {linked_text[4 * word:4 * word + 4].hex()}, {len(encoded)} vs {len(linked_text)} bytes")
                if bytes(code.data) != linked_data:
                    report.append(f"{name}: __data differs from ld at byte {first_difference(code.data, linked_data)}, {len(code.data)} vs {len(linked_data)} bytes")
    return report


def check_executable():
    source = CASES / "m0" / "counter.sig"
    expected_first_line = source.with_suffix(".out").read_text().splitlines()[0]
    with tempfile.TemporaryDirectory() as directory:
        executable = Path(directory) / "counter"
        compiled = subprocess.run(
            [sys.executable, str(ROOT / "bootstrap" / "sigc.py"), str(source), "-o", str(executable)],
            capture_output=True,
            text=True,
            env={"PATH": ""},
        )
        if compiled.returncode != 0:
            return [f"compile failed (exit {compiled.returncode}): {compiled.stderr.strip()}"]
        report = []
        verified = subprocess.run(["/usr/bin/codesign", "--verify", "--strict", str(executable)], capture_output=True, text=True)
        if verified.returncode != 0:
            report.append(f"codesign --verify --strict exit {verified.returncode}: {verified.stderr.strip()}")
        process, first_line = first_output_line(executable)
        stop(process)
        if first_line != expected_first_line:
            report.append(f"first line {first_line!r} (exit {process.returncode}), expected {expected_first_line!r}")
        leftovers = sorted(path.name for path in Path(directory).iterdir() if path != executable)
        if leftovers:
            report.append(f"files beside the executable: {' '.join(leftovers)}")
    return report


def first_output_line(executable):
    process = subprocess.Popen([str(executable)], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE)
    first_line = process.stdout.readline().decode(errors="replace").rstrip("\n")
    return process, first_line


def stop(process):
    process.kill()
    process.wait()
    process.stdout.close()


def check_recompile_over_running():
    source = CASES / "m0" / "counter.sig"
    expected_first_line = source.with_suffix(".out").read_text().splitlines()[0]
    command = [sys.executable, str(ROOT / "bootstrap" / "sigc.py"), str(source), "-o"]
    with tempfile.TemporaryDirectory() as directory:
        executable = Path(directory) / "counter"
        subprocess.run(command + [str(executable)], capture_output=True, check=True, env={"PATH": ""})
        running, _ = first_output_line(executable)
        try:
            recompiled = subprocess.run(command + [str(executable)], capture_output=True, text=True, env={"PATH": ""})
            if recompiled.returncode != 0:
                return [f"recompile failed (exit {recompiled.returncode}): {recompiled.stderr.strip()}"]
            relaunched, first_line = first_output_line(executable)
            stop(relaunched)
        finally:
            stop(running)
        report = []
        if first_line != expected_first_line:
            report.append(f"relaunch printed {first_line!r} (exit {relaunched.returncode}), expected {expected_first_line!r}")
        leftovers = sorted(path.name for path in Path(directory).iterdir() if path != executable)
        if leftovers:
            report.append(f"files beside the executable: {' '.join(leftovers)}")
    return report


def check_planted_staging_link():
    source = CASES / "m0" / "counter.sig"
    code, _ = sigc.compile_source(source.read_text())
    with tempfile.TemporaryDirectory() as directory:
        victim = Path(directory) / "victim"
        victim.write_text("untouched")
        executable = Path(directory) / "counter"
        (Path(directory) / f".counter.{os.getpid()}").symlink_to(victim)
        try:
            sigc.write_executable(code, executable)
        except OSError:
            pass
        if victim.read_text(errors="replace") != "untouched":
            return ["write_executable wrote through a link planted at its staging name"]
    return []


PARTS = {
    "encoder": (
        ("encoder coverage", check_coverage),
        ("encoder differential", check_differential),
        ("encoder ranges", check_ranges),
        ("encoder compare-branch example", check_compare_branch_example),
    ),
    "programs": (
        ("programs against ld", check_programs),
    ),
    "executables": (
        ("executable compiled with an empty PATH", check_executable),
        ("recompile over a running executable", check_recompile_over_running),
        ("planted link at the staging name", check_planted_staging_link),
    ),
}


def main():
    selected = sys.argv[1:] or list(PARTS)
    unknown = [part for part in selected if part not in PARTS]
    if unknown:
        print(f"unknown part: {' '.join(unknown)}; parts are {' '.join(PARTS)}")
        return 1
    checks = [check for part in selected for check in PARTS[part]]
    failures = 0
    for name, check in checks:
        try:
            report = check()
        except Exception as error:
            report = [f"{type(error).__name__}: {error}"]
        if report:
            failures += 1
            print(f"FAIL {name}")
            for line in report:
                print(f"  {line}")
        else:
            print(f"PASS {name}")
    print(f"{len(checks) - failures} passed, {failures} failed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
