FIRMWARE := "target/riscv64im-unknown-none-elf/firmware/tinywasm-firmware"

default:
    @just --list

# Build the RISC-V firmware
build-firmware:
    cd crates/firmware && cargo build --profile firmware

# Run firmware interactively in QEMU (Ctrl-A X to exit)
run-firmware: build-firmware
    qemu-system-riscv64 -machine virt -nographic -monitor none -serial stdio -bios none -kernel {{FIRMWARE}}

# Compile WAT smoke tests to wasm
build-tests:
    for f in examples/wasm/*.wat; do wasm-tools parse "$f" -o "${f%.wat}.wasm"; done

# Run smoke tests on firmware via QEMU
test-firmware: build-firmware build-tests
    python3 scripts/run-tests.py {{FIRMWARE}} \
        examples/wasm/add.wasm \
        examples/wasm/arith_wrap.wasm \
        examples/wasm/arith_div_zero.wasm \
        examples/wasm/arith_rem_zero.wasm \
        examples/wasm/arith_overflow.wasm \
        examples/wasm/locals.wasm \
        examples/wasm/if_else.wasm \
        examples/wasm/loop.wasm \
        examples/wasm/fib.wasm \
        examples/wasm/hello.wasm

# Check the binary size
check-bin-size:
	du -h target/riscv64im-unknown-none-elf/firmware/tinywasm-firmware
