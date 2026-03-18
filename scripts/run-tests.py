#!/usr/bin/env python3
import os
import struct
import subprocess
import sys


def expected_result(path):
    wat_path = os.path.splitext(path)[0] + ".wat"
    if not os.path.exists(wat_path):
        return ("exact", "ok")

    with open(wat_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith(";; EXPECT:"):
                return ("exact", line.split(":", 1)[1].strip())
            if line.startswith(";; EXPECT_PREFIX:"):
                return ("prefix", line.split(":", 1)[1].strip())

    return ("exact", "ok")

def run_tests(firmware, wasm_files):
    qemu = subprocess.Popen(
        ["qemu-system-riscv64", "-machine", "virt", "-nographic",
         "-monitor", "none", "-serial", "stdio",
         "-bios", "none", "-kernel", firmware],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
    )
    assert qemu.stdin is not None
    assert qemu.stdout is not None
    try:
        # Skip banner, wait for first "ready"
        while True:
            line = qemu.stdout.readline()
            if line.strip() == b"ready":
                break

        passed = failed = 0
        for path in wasm_files:
            data = open(path, "rb").read()
            qemu.stdin.write(struct.pack("<I", len(data)) + data)
            qemu.stdin.flush()
            qemu.stdout.readline()  # "received N bytes, parsing..."
            result = qemu.stdout.readline().strip().decode()
            expected_mode, expected = expected_result(path)
            name = os.path.basename(path)
            matches = result == expected if expected_mode == "exact" else result.startswith(expected)
            if matches:
                passed += 1
                print(f"ok      {name}")
            else:
                failed += 1
                print(f"FAIL    {name}: expected {expected_mode} {expected!r}, got {result!r}")
            qemu.stdout.readline()  # next "ready"

        print(f"\n{passed} passed, {failed} failed")
        return failed == 0
    finally:
        qemu.kill()
        qemu.wait()

if __name__ == "__main__":
    ok = run_tests(sys.argv[1], sys.argv[2:])
    sys.exit(0 if ok else 1)
