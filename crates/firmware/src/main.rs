#![no_std]
#![no_main]

extern crate alloc;

mod host;
mod sync;
mod uart;

use core::arch::global_asm;
use linked_list_allocator::LockedHeap;

#[global_allocator]
static ALLOCATOR: LockedHeap = LockedHeap::empty();

unsafe extern "C" {
    static __bss_start: u8;
    static __bss_end: u8;
    static __heap_start: u8;
    static __heap_end: u8;
    static __stack_top: u8;
}

global_asm!(
    r#"
.section .text.init, "ax"
.global _start
_start:
    la sp, __stack_top
    # Zero BSS
    la t0, __bss_start
    la t1, __bss_end
1:
    bgeu t0, t1, 2f
    sd zero, 0(t0)
    addi t0, t0, 8
    j 1b
2:
    call main
3:
    j 3b
"#
);

#[unsafe(no_mangle)]
extern "C" fn main() -> ! {
    // Initialize the heap allocator
    unsafe {
        let heap_start = &raw const __heap_start as usize;
        let heap_end = &raw const __heap_end as usize;
        let heap_size = heap_end - heap_start;
        ALLOCATOR.lock().init(heap_start as *mut u8, heap_size);
    }

    println!("tinywasm firmware v0.1.0");
    println!("RISC-V WASM interpreter over UART");

    loop {
        println!("ready");

        // Read 4-byte LE u32 length
        let mut len_buf = [0u8; 4];
        uart::read_exact(&mut len_buf);
        let len = u32::from_le_bytes(len_buf) as usize;

        if len == 0 || len > 4 * 1024 * 1024 {
            println!("error: invalid module size: {}", len);
            continue;
        }

        // Read the WASM module bytes
        let mut wasm_buf = alloc::vec![0u8; len];
        uart::read_exact(&mut wasm_buf);

        println!("received {} bytes, parsing...", len);

        // Parse and execute
        match run_module(&wasm_buf) {
            Ok(()) => println!("ok"),
            Err(e) => println!("error: {:?}", e),
        }
    }
}

fn run_module(wasm: &[u8]) -> tinywasm::Result<()> {
    let module = tinywasm::Module::parse_bytes(wasm)?;
    // We're gonna try to trim down the interpreter to a really minimal subset
    let mut store = tinywasm::Store::with_config(tinywasm::StackConfig {
        value_stack_32_init_size: None,
        value_stack_64_init_size: Some(0),
        value_stack_128_init_size: Some(0),
        value_stack_ref_init_size: None,
        block_stack_init_size: None,
    });
    // let mut store = tinywasm::Store::default();
    let imports = host::register_imports();

    let instance = module.instantiate(&mut store, Some(imports))?;

    // Try to call exported "main" or "_start"
    if let Ok(func) = instance.exported_func_untyped(&store, "main") {
        let result = func.call(&mut store, &[])?;
        if !result.is_empty() {
            println!("result: {:?}", result);
        }
    } else if let Ok(func) = instance.exported_func_untyped(&store, "_start") {
        func.call(&mut store, &[])?;
    }

    Ok(())
}

#[panic_handler]
fn panic(info: &core::panic::PanicInfo) -> ! {
    println!("PANIC: {}", info);
    loop {}
}
