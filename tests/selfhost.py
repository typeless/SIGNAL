import filecmp
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STAGE0 = ROOT / "bootstrap" / "sigc.py"
SOURCE = ROOT / "compiler" / "sigc.sig"
BUILD = ROOT / "build" / "m4"
STAGES = [BUILD / "stage1", BUILD / "stage2", BUILD / "stage3"]


def build_stage(compiler, output):
    output.unlink(missing_ok=True)
    started = time.monotonic()
    finished = subprocess.run([*compiler, str(SOURCE), "-o", str(output)], env={"PATH": ""})
    print(f"{output.name}: exit {finished.returncode}, {time.monotonic() - started:.1f} s")
    return finished.returncode == 0


def main():
    BUILD.mkdir(parents=True, exist_ok=True)
    compilers = [[sys.executable, str(STAGE0)], [str(STAGES[0])], [str(STAGES[1])]]
    for compiler, output in zip(compilers, STAGES):
        if not build_stage(compiler, output):
            return 1
    failures = 0
    for earlier, later in zip(STAGES, STAGES[1:]):
        identical = filecmp.cmp(earlier, later, shallow=False)
        print(f"{later.name} {'matches' if identical else 'differs from'} {earlier.name}")
        failures += not identical
    for script, arguments in (("run.py", ["--compiler", str(STAGES[1])]), ("diff.py", ["image", str(STAGE0), str(STAGES[1])])):
        finished = subprocess.run([sys.executable, str(ROOT / "tests" / script), *arguments], capture_output=True, text=True)
        print(f"{script}: {finished.stdout.strip().splitlines()[-1] if finished.stdout.strip() else finished.stderr.strip()}")
        if finished.returncode != 0:
            print(finished.stdout, end="")
            failures += 1
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
