use tinywasm::{Extern, FuncContext, Imports};

use crate::uart;

pub fn register_imports() -> Imports {
    let mut imports = Imports::new();

    let uart_putc = Extern::typed_func(|_ctx: FuncContext<'_>, c: i32| -> tinywasm::Result<()> {
        uart::putc(c as u8);
        Ok(())
    });

    let uart_getc = Extern::typed_func(|_ctx: FuncContext<'_>, ()| -> tinywasm::Result<i32> {
        Ok(uart::getc() as i32)
    });

    let uart_write =
        Extern::typed_func(|ctx: FuncContext<'_>, (ptr, len): (i32, i32)| -> tinywasm::Result<()> {
            let mem = ctx.exported_memory("memory")?;
            let data = mem.load(ptr as usize, len as usize)?;
            uart::write_all(data);
            Ok(())
        });

    let uart_read =
        Extern::typed_func(|mut ctx: FuncContext<'_>, (ptr, len): (i32, i32)| -> tinywasm::Result<i32> {
            let len = len as usize;
            let mut buf = alloc::vec![0u8; len];
            uart::read_exact(&mut buf);
            let mut mem = ctx.exported_memory_mut("memory")?;
            mem.store(ptr as usize, len, &buf)?;
            Ok(len as i32)
        });

    imports.define("env", "uart_putc", uart_putc).unwrap();
    imports.define("env", "uart_getc", uart_getc).unwrap();
    imports.define("env", "uart_write", uart_write).unwrap();
    imports.define("env", "uart_read", uart_read).unwrap();

    imports
}
