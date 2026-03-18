#!/usr/bin/env python3
import subprocess, sys, os, struct

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
            name = os.path.basename(path)
            if result == "ok":
                passed += 1
                print(f"ok      {name}")
            else:
                failed += 1
                print(f"FAIL    {name}: {result}")
            qemu.stdout.readline()  # next "ready"

        print(f"\n{passed} passed, {failed} failed")
        return failed == 0
    finally:
        qemu.kill()
        qemu.wait()

if __name__ == "__main__":
    ok = run_tests(sys.argv[1], sys.argv[2:])
    sys.exit(0 if ok else 1)
