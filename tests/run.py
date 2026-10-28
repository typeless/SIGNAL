import concurrent.futures
import os
import re
import selectors
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path
from typing import NamedTuple

ROOT = Path(__file__).resolve().parent.parent
CASES = ROOT / "tests" / "cases"
BUILD = ROOT / "build" / "tests"
COMPILER = ROOT / "bootstrap" / "sigc.py"
COMPILE_TIMEOUT_SECONDS = 180
RUN_TIMEOUT_SECONDS = 5
QEMU_COMMANDS = {
    "virt": ["qemu-system-aarch64", "-M", "virt", "-cpu", "cortex-a72", "-nographic", "-no-reboot", "-kernel"],
    "mps2-an385": ["qemu-system-arm", "-M", "mps2-an385", "-cpu", "cortex-m3", "-nographic", "-no-reboot", "-kernel"],
}
STAGE2_ONLY = {"m5", "m6", "m7", "m8", "m9", "m10"}
DEFAULT_JOBS = 4
PEAK_RSS_TABLE = BUILD / "peak_rss.tsv"


class Compiled(NamedTuple):
    returncode: int
    stdout: str
    stderr: str
    peak_rss_bytes: int


def target_command(source):
    text = source.read_text()
    if 'Machine "mps2-an385"' in text:
        return QEMU_COMMANDS["mps2-an385"]
    if re.search(r"\b(Interrupt|Boot)\s*\{", text):
        return QEMU_COMMANDS["virt"]
    return []


def compile_case(compiler, source, executable, timeout=COMPILE_TIMEOUT_SECONDS):
    command = [*compiler, str(source), "-o", str(executable)]
    with tempfile.TemporaryFile() as stdout, tempfile.TemporaryFile() as stderr:
        process = subprocess.Popen(command, stdout=stdout, stderr=stderr, env={"PATH": ""})
        expired = threading.Event()
        killer = threading.Timer(timeout, lambda: (expired.set(), process.kill()))
        killer.start()
        _, status, usage = os.wait4(process.pid, 0)
        killer.cancel()
        process.returncode = os.waitstatus_to_exitcode(status)
        if expired.is_set():
            raise subprocess.TimeoutExpired(command, timeout)
        stdout.seek(0)
        stderr.seek(0)
        return Compiled(process.returncode, stdout.read().decode(errors="replace"), stderr.read().decode(errors="replace"), usage.ru_maxrss)


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


def run_trace_case(compiled, executable, source, expected_path):
    expected = expected_path.read_text().splitlines()
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
        command = [*target_command(source), str(executable)]
        actual, timed_out, returncode = read_trace(command, len(expected), source.with_suffix(".in"))
        report = []
    if actual == expected and not report:
        return []
    report.insert(0, f"trace mismatch (exit {returncode}{', timed out' if timed_out else ''}):")
    for step, (want, got) in enumerate(zip(expected + [None] * len(actual), actual + [None] * len(expected))):
        if want != got:
            report.append(f"  step {step}: expected {want!r}, got {got!r}")
    return report


def run_error_case(compiled, expected_path):
    expected = expected_path.read_text().strip()
    if compiled.returncode == 0:
        return [f"expected rejection containing {expected!r}, but compilation succeeded"]
    if expected not in compiled.stderr:
        return [f"expected rejection containing {expected!r}, got:", compiled.stderr.rstrip()]
    return []


def jobs_option(arguments):
    if "-j" not in arguments:
        return DEFAULT_JOBS
    position = arguments.index("-j")
    if position + 1 == len(arguments) or not arguments[position + 1].isdigit() or int(arguments[position + 1]) < 1:
        sys.exit("-j requires a positive count")
    jobs = int(arguments[position + 1])
    del arguments[position:position + 2]
    return jobs


def check_case(compiler, source):
    trace_path = source.with_suffix(".out")
    error_path = source.with_suffix(".err")
    if not trace_path.exists() and not error_path.exists():
        return ["no .out or .err file"], 0
    executable = BUILD / source.relative_to(CASES).with_suffix("")
    executable.parent.mkdir(parents=True, exist_ok=True)
    compiled = compile_case(compiler, source, executable)
    if trace_path.exists():
        return run_trace_case(compiled, executable, source, trace_path), compiled.peak_rss_bytes
    return run_error_case(compiled, error_path), compiled.peak_rss_bytes


def main():
    BUILD.mkdir(parents=True, exist_ok=True)
    selected = sys.argv[1:]
    jobs = jobs_option(selected)
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
        sources = [s for s in sources if s.relative_to(CASES).parts[0] not in STAGE2_ONLY]
    if selected:
        sources = [s for s in sources if any(name in str(s.relative_to(CASES)) for name in selected)]
    failures = 0
    peaks = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        for source, (report, peak_rss_bytes) in zip(sources, pool.map(lambda source: check_case(compiler, source), sources)):
            name = source.relative_to(CASES)
            peaks.append((name, peak_rss_bytes))
            if report:
                failures += 1
                print(f"FAIL {name}")
                for line in report:
                    print(f"  {line}")
            else:
                print(f"PASS {name}")
    PEAK_RSS_TABLE.write_text("".join(f"{name}\t{peak_rss_bytes}\n" for name, peak_rss_bytes in peaks))
    if peaks:
        name, peak_rss_bytes = max(peaks, key=lambda peak: peak[1])
        print(f"peak compile RSS {peak_rss_bytes / 2**20:.0f} MiB ({name}); all cases in {PEAK_RSS_TABLE.relative_to(ROOT)}")
    print(f"{len(sources) - failures} passed, {failures} failed")
    return 1 if failures or not sources else 0


if __name__ == "__main__":
    sys.exit(main())
