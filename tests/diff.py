import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CASES = ROOT / "tests" / "cases"
DUMP = ROOT / "tests" / "dump.py"
STAGE0 = ROOT / "bootstrap" / "sigc.py"
BUILD = ROOT / "build" / "m4"
PASS_NUMBERS = {"tokens": 1, "program": 2, "flat": 3, "rows": 4, "clocks": 5, "schedule": 6}
DUMP_PASS_LINE = "constant integer DUMP_PASS = 0;"
COMPILE_TIMEOUT_SECONDS = 60


def command(compiler):
    path = Path(compiler).resolve()
    return [sys.executable, str(path)] if path.suffix == ".py" else [str(path)]


def compile_case(compiler, source, output):
    try:
        finished = subprocess.run(
            [*command(compiler), str(source), "-o", str(output)],
            capture_output=True,
            timeout=COMPILE_TIMEOUT_SECONDS,
            env={"PATH": ""},
        )
    except subprocess.TimeoutExpired:
        return "timeout"
    return finished.returncode


def read_output(output):
    return output.read_bytes() if output.exists() else None


def dump_differences(pass_name, compiler, source, scratch):
    expected = subprocess.run(
        [sys.executable, str(DUMP), pass_name, str(source)], capture_output=True, timeout=COMPILE_TIMEOUT_SECONDS
    )
    if expected.returncode != 0:
        return [f"dump.py exit {expected.returncode}: {expected.stderr.decode(errors='replace').strip()}"]
    output = scratch / "dump"
    output.unlink(missing_ok=True)
    status = compile_case(compiler, source, output)
    actual = read_output(output)
    if actual is None:
        return [f"compiler exit {status}, no dump written"]
    if actual != expected.stdout:
        return [f"dumps differ (compiler exit {status})"]
    return []


def image_differences(old, new, source, scratch):
    outputs = []
    for side, compiler in (("old", old), ("new", new)):
        output = scratch / side / "image"
        output.parent.mkdir(exist_ok=True)
        output.unlink(missing_ok=True)
        outputs.append((compile_case(compiler, source, output), read_output(output)))
    (old_status, old_image), (new_status, new_image) = outputs
    if old_status != new_status:
        return [f"exit {old_status} vs {new_status}"]
    if old_image != new_image:
        return ["executables differ"]
    return []


MODES = {"dump": dump_differences, "image": image_differences}


def build_dump_compiler(pass_name, source):
    text = Path(source).read_text()
    if DUMP_PASS_LINE not in text or pass_name not in PASS_NUMBERS:
        return None, f"{source} has no line {DUMP_PASS_LINE!r} or {pass_name} has no pass number"
    BUILD.mkdir(parents=True, exist_ok=True)
    patched = BUILD / f"sigc_{pass_name}.sig"
    patched.write_text(text.replace(DUMP_PASS_LINE, f"constant integer DUMP_PASS = {PASS_NUMBERS[pass_name]};", 1))
    executable = BUILD / f"sigc_{pass_name}"
    status = compile_case(STAGE0, patched, executable)
    if status != 0:
        return None, f"stage 0 exit {status} on {patched}"
    return executable, None


def main():
    if len(sys.argv) != 4 or sys.argv[1] not in MODES:
        print("usage: diff.py dump PASS COMPILER | diff.py image OLD NEW", file=sys.stderr)
        return 2
    mode, first, second = sys.argv[1:]
    if mode == "dump" and Path(second).suffix == ".sig":
        second, failure = build_dump_compiler(first, second)
        if failure:
            print(failure, file=sys.stderr)
            return 2
    sources = sorted(CASES.rglob("*.sig"))
    differing = 0
    with tempfile.TemporaryDirectory() as scratch:
        for source in sources:
            report = MODES[mode](first, second, source, Path(scratch))
            if report:
                differing += 1
                print(f"DIFF {source.relative_to(CASES)}: {'; '.join(report)}")
    print(f"{len(sources)} cases, {differing} differ")
    return 1 if differing else 0


if __name__ == "__main__":
    sys.exit(main())
