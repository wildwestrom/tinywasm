/// Single-core bare-metal atomic intrinsics.
/// Safe because we're single-hart with no interrupts using atomics.

#[unsafe(no_mangle)]
pub unsafe extern "C" fn __sync_fetch_and_or_1(ptr: *mut u8, val: u8) -> u8 {
    unsafe {
        let old = ptr.read_volatile();
        ptr.write_volatile(old | val);
        old
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn __sync_fetch_and_add_8(ptr: *mut u64, val: u64) -> u64 {
    unsafe {
        let old = ptr.read_volatile();
        ptr.write_volatile(old.wrapping_add(val));
        old
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn __sync_fetch_and_sub_8(ptr: *mut u64, val: u64) -> u64 {
    unsafe {
        let old = ptr.read_volatile();
        ptr.write_volatile(old.wrapping_sub(val));
        old
    }
}
