/// NS16550A UART driver for QEMU virt machine
const UART_BASE: usize = 0x10000000;

const THR: usize = 0; // Transmit Holding Register
const RBR: usize = 0; // Receive Buffer Register
const LSR: usize = 5; // Line Status Register

const LSR_DR: u8 = 1 << 0;   // Data Ready
const LSR_THRE: u8 = 1 << 5; // Transmit Holding Register Empty

unsafe fn read_reg(offset: usize) -> u8 {
    unsafe { core::ptr::read_volatile((UART_BASE + offset) as *const u8) }
}

unsafe fn write_reg(offset: usize, val: u8) {
    unsafe { core::ptr::write_volatile((UART_BASE + offset) as *mut u8, val) }
}

pub fn putc(c: u8) {
    // Spin until the transmit holding register is empty
    unsafe {
        while read_reg(LSR) & LSR_THRE == 0 {}
        write_reg(THR, c);
    }
}

pub fn getc() -> u8 {
    // Spin until data is ready
    unsafe {
        while read_reg(LSR) & LSR_DR == 0 {}
        read_reg(RBR)
    }
}

pub fn write_all(data: &[u8]) {
    for &b in data {
        putc(b);
    }
}

pub fn read_exact(buf: &mut [u8]) {
    for b in buf.iter_mut() {
        *b = getc();
    }
}

pub struct Uart;

impl core::fmt::Write for Uart {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        write_all(s.as_bytes());
        Ok(())
    }
}

#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => {{
        use core::fmt::Write;
        let _ = write!($crate::uart::Uart, $($arg)*);
    }};
}

#[macro_export]
macro_rules! println {
    () => { $crate::print!("\n") };
    ($($arg:tt)*) => {{
        use core::fmt::Write;
        let _ = writeln!($crate::uart::Uart, $($arg)*);
    }};
}
