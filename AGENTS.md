# AGENTS.md

This file provides guidance to LLM-based agents when working with code in this repository.

## What this is

This is a fork of **TinyWasm**, a minimal `no_std`-compatible WebAssembly runtime written in Rust. The focus of this fork is a bare-metal RISC-V firmware (`crates/firmware`) that receives WASM modules over UART, interprets them with a minimal subset of the tinywasm runtime, and prints `ok` or `error: ...`. The goal is to support only a small, structured, imperative subset of WASM — no i64, no SIMD, no threads.

## Commands

All firmware commands must be run from within `crates/firmware/` (or via `just`) because the custom target and `build-std` config live in `crates/firmware/.cargo/config.toml`, which cargo ignores when invoked from the workspace root.

```sh
just build-firmware    # cargo build in crates/firmware/
just run-firmware      # boots firmware in QEMU interactively (Ctrl-A X to exit)
just build-tests       # compile examples/wasm/*.wat → .wasm via wasm-tools
just test-firmware     # build + run smoke tests via QEMU (passes all .wasm to firmware)
```

## Architecture

### Workspace crates

- **`crates/tinywasm`** — core runtime: parse, instantiate, execute WASM modules
- **`crates/types`** — shared type definitions and the custom bytecode format (instruction enums, not raw opcodes)
- **`crates/parser`** — converts binary WASM to tinywasm's internal bytecode using `wasmparser`
- **`crates/firmware`** — bare-metal RISC-V firmware (the main focus of this fork)

### Firmware internals (`crates/firmware/src/`)

- **`main.rs`** — assembly bootstrap (`_start`), heap init, UART protocol loop. Receives modules as `[u32_le_len][wasm_bytes]`, calls `main` or `_start` export, prints `ok`/`error`.
- **`host.rs`** — registers WASM host imports under the `env` module: `uart_putc`, `uart_getc`, `uart_write`, `uart_read`. Memory access via `FuncContext::exported_memory("memory")` — WASM modules must export their memory by name.
- **`uart.rs`** — NS16550A driver at `0x10000000` (QEMU virt UART0).
- **`sync.rs`** — bare-metal `__sync_fetch_and_*` intrinsics needed by `spinning_top` (used inside `linked_list_allocator`). The target has no A-extension atomics, so these are volatile read/write — safe only because this is single-hart with no interrupts.

### Target & linker

- Custom target: `riscv64im-unknown-none-elf.json` — RV64IM, `+forced-atomics`, `panic=abort`, static relocation
- `linker.ld` — 128 MB RAM from `0x80000000`, 64 KB stack at top, rest is heap
- `crates/firmware/.cargo/config.toml` — sets target, linker args (`-Tlinker.ld`, `-Lcrates/firmware`), and `build-std = ["core", "alloc"]`

### WASM bytecode format

TinyWasm uses a custom bytecode format (instruction enums, not raw WASM opcodes) produced by the parser. Key properties:
- Label instructions carry relative offsets for fast branching
- `End` is split into `End` and `EndBlock`
- All stack values are held as `u64` internally; type context inferred from usage
- Pre-processed bytecode can be serialized/deserialized via the `archive` feature (postcard/serde)

### Smoke tests (`examples/wasm/`)

`.wat` source files are compiled with `wasm-tools parse`. Tests assert correctness by trapping (`unreachable`) on wrong results — the firmware reports `ok` if the module returns without error. Each test that uses `uart_write` must export its memory as `"memory"`.

Current tests: `add`, `locals`, `if_else`, `loop`, `fib`, `hello`.

## QEMU invocation

```sh
qemu-system-riscv64 -machine virt -nographic -monitor none -serial stdio -bios none -kernel <elf>
```

`-monitor none` is required — without it, `-nographic` muxes the QEMU monitor onto stdio, starving the serial port of I/O when stdout is a pipe.
