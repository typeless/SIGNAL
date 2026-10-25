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
QEMU_COMMANDS = {
    "m5": ["qemu-system-aarch64", "-M", "virt", "-cpu", "cortex-a72", "-nographic", "-kernel"],
    "m6": ["qemu-system-arm", "-M", "mps2-an385", "-cpu", "cortex-m3", "-nographic", "-no-reboot", "-kernel"],
}


def compile_case(compiler, source, executable):
    return subprocess.run(
        [*compiler, str(source), "-o", str(executable)],
        capture_output=True,
        text=True,
        timeout=COMPILE_TIMEOUT_SECONDS,
        env={"PATH": ""},
    )


def read_trace(command, line_count, input_path):
    stdin = open(input_path, "rb") if input_path.exists() else subprocess.DEVNULL
    process = subprocess.Popen(command, stdin=stdin, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
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
    if stdin is not subprocess.DEVNULL:
        stdin.close()
    lines = received.decode(errors="replace").split("\n")[:line_count]
    return lines, timed_out, process.returncode


def run_to_exit(executable, input_path):
    stdin = open(input_path, "rb") if input_path.exists() else subprocess.DEVNULL
    try:
        finished = subprocess.run([str(executable)], stdin=stdin, capture_output=True, timeout=RUN_TIMEOUT_SECONDS)
    finally:
        if stdin is not subprocess.DEVNULL:
            stdin.close()
    return finished.stdout.decode(errors="replace").splitlines(), finished.returncode, finished.stderr.decode(errors="replace")


def run_trace_case(compiler, source, expected_path):
    expected = expected_path.read_text().splitlines()
    executable = BUILD / source.relative_to(CASES).with_suffix("")
    executable.parent.mkdir(parents=True, exist_ok=True)
    compiled = compile_case(compiler, source, executable)
    if compiled.returncode != 0:
        return [f"compile failed (exit {compiled.returncode}):", compiled.stderr.rstrip()]
    exit_path = source.with_suffix(".exit")
    if exit_path.exists():
        expected_status, _, expected_stderr = exit_path.read_text().partition("\n")
        try:
            actual, returncode, stderr = run_to_exit(executable, source.with_suffix(".in"))
        except subprocess.TimeoutExpired:
            return [f"expected exit {expected_status}, but the program did not exit"]
        report = []
        if returncode != int(expected_status):
            report.append(f"expected exit {expected_status}, got {returncode}")
        if expected_stderr.strip() not in stderr:
            report.append(f"expected stderr containing {expected_stderr.strip()!r}, got {stderr.strip()!r}")
        timed_out = False
    else:
        command = [*QEMU_COMMANDS.get(source.relative_to(CASES).parts[0], []), str(executable)]
        actual, timed_out, returncode = read_trace(command, len(expected), source.with_suffix(".in"))
        report = []
    if actual == expected and not report:
        return []
    report.insert(0, f"trace mismatch (exit {returncode}{', timed out' if timed_out else ''}):")
    for step, (want, got) in enumerate(zip(expected + [None] * len(actual), actual + [None] * len(expected))):
        if want != got:
            report.append(f"  step {step}: expected {want!r}, got {got!r}")
    return report


def run_error_case(compiler, source, expected_path):
    expected = expected_path.read_text().strip()
    compiled = compile_case(compiler, source, BUILD / "rejected")
    if compiled.returncode == 0:
        return [f"expected rejection containing {expected!r}, but compilation succeeded"]
    if expected not in compiled.stderr:
        return [f"expected rejection containing {expected!r}, got:", compiled.stderr.rstrip()]
    return []


def main():
    BUILD.mkdir(parents=True, exist_ok=True)
    selected = sys.argv[1:]
    compiler = [sys.executable, str(COMPILER)]
    if "--compiler" in selected:
        position = selected.index("--compiler")
        if position + 1 == len(selected):
            print("--compiler requires a path")
            return 2
        compiler = [str(Path(selected[position + 1]).resolve())]
        del selected[position:position + 2]
    sources = sorted(CASES.rglob("*.sig"))
    if compiler[-1] == str(COMPILER):
        sources = [s for s in sources if s.relative_to(CASES).parts[0] not in QEMU_COMMANDS]
    if selected:
        sources = [s for s in sources if any(name in str(s.relative_to(CASES)) for name in selected)]
    failures = 0
    for source in sources:
        name = source.relative_to(CASES)
        trace_path = source.with_suffix(".out")
        error_path = source.with_suffix(".err")
        if trace_path.exists():
            report = run_trace_case(compiler, source, trace_path)
        elif error_path.exists():
            report = run_error_case(compiler, source, error_path)
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
