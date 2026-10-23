import os
import selectors
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CASES = ROOT / "tests" / "cases"
BUILD = ROOT / "build" / "tests"
COMPILER = ROOT / "bootstrap" / "sigc.py"
COMPILE_TIMEOUT_SECONDS = 60
RUN_TIMEOUT_SECONDS = 5


def compile_case(source, executable):
    return subprocess.run(
        [sys.executable, str(COMPILER), str(source), "-o", str(executable)],
        capture_output=True,
        text=True,
        timeout=COMPILE_TIMEOUT_SECONDS,
    )


def read_trace(executable, line_count):
    process = subprocess.Popen([str(executable)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    deadline = time.monotonic() + RUN_TIMEOUT_SECONDS
    received = b""
    timed_out = False
    while received.count(b"\n") < line_count:
        remaining = deadline - time.monotonic()
        if remaining <= 0 or not selector.select(remaining):
            timed_out = True
            break
        chunk = os.read(process.stdout.fileno(), 65536)
        if not chunk:
            break
        received += chunk
    process.kill()
    process.wait()
    selector.close()
    lines = received.decode(errors="replace").split("\n")[:line_count]
    return lines, timed_out, process.returncode


def run_trace_case(source, expected_path):
    expected = expected_path.read_text().splitlines()
    executable = BUILD / source.relative_to(CASES).with_suffix("")
    executable.parent.mkdir(parents=True, exist_ok=True)
    compiled = compile_case(source, executable)
    if compiled.returncode != 0:
        return [f"compile failed (exit {compiled.returncode}):", compiled.stderr.rstrip()]
    actual, timed_out, returncode = read_trace(executable, len(expected))
    if actual == expected:
        return []
    report = [f"trace mismatch (exit {returncode}{', timed out' if timed_out else ''}):"]
    for step, (want, got) in enumerate(zip(expected, actual + [None] * len(expected))):
        if want != got:
            report.append(f"  step {step}: expected {want!r}, got {got!r}")
    return report


def run_error_case(source, expected_path):
    expected = expected_path.read_text().strip()
    compiled = compile_case(source, BUILD / "rejected")
    if compiled.returncode == 0:
        return [f"expected rejection containing {expected!r}, but compilation succeeded"]
    if expected not in compiled.stderr:
        return [f"expected rejection containing {expected!r}, got:", compiled.stderr.rstrip()]
    return []


def main():
    BUILD.mkdir(parents=True, exist_ok=True)
    selected = sys.argv[1:]
    sources = sorted(CASES.rglob("*.sig"))
    if selected:
        sources = [s for s in sources if any(name in str(s.relative_to(CASES)) for name in selected)]
    failures = 0
    for source in sources:
        name = source.relative_to(CASES)
        trace_path = source.with_suffix(".out")
        error_path = source.with_suffix(".err")
        if trace_path.exists():
            report = run_trace_case(source, trace_path)
        elif error_path.exists():
            report = run_error_case(source, error_path)
        else:
            report = ["no .out or .err file"]
        if report:
            failures += 1
            print(f"FAIL {name}")
            for line in report:
                print(f"  {line}")
        else:
            print(f"PASS {name}")
    print(f"{len(sources) - failures} passed, {failures} failed")
    return 1 if failures or not sources else 0


if __name__ == "__main__":
    sys.exit(main())
