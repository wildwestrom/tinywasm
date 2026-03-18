pub(crate) trait TinywasmIntExt
where
    Self: Sized,
{
    fn checked_wrapping_rem(self, rhs: Self) -> Result<Self>;
    fn wasm_checked_div(self, rhs: Self) -> Result<Self>;
}

pub(super) fn trap_0() -> Error {
    Error::Trap(crate::Trap::DivisionByZero)
}

use crate::{Error, Result};

pub(crate) trait WasmIntOps {
    fn wasm_shl(self, rhs: Self) -> Self;
    fn wasm_shr(self, rhs: Self) -> Self;
    fn wasm_rotl(self, rhs: Self) -> Self;
    fn wasm_rotr(self, rhs: Self) -> Self;
}

macro_rules! impl_wrapping_self_sh {
    ($($t:ty)*) => ($(
        impl WasmIntOps for $t {
            #[inline]
            fn wasm_shl(self, rhs: Self) -> Self {
                self.wrapping_shl(rhs as u32)
            }

            #[inline]
            fn wasm_shr(self, rhs: Self) -> Self {
                self.wrapping_shr(rhs as u32)
            }

            #[inline]
            fn wasm_rotl(self, rhs: Self) -> Self {
                self.rotate_left(rhs as u32)
            }

            #[inline]
            fn wasm_rotr(self, rhs: Self) -> Self {
                self.rotate_right(rhs as u32)
            }
        }
    )*)
}

impl_wrapping_self_sh! { i32 i64 u32 u64 }

macro_rules! impl_checked_wrapping_rem {
    ($($t:ty)*) => ($(
        impl TinywasmIntExt for $t {
            #[inline]
            fn checked_wrapping_rem(self, rhs: Self) -> Result<Self> {
                if rhs == 0 {
                    Err(Error::Trap(crate::Trap::DivisionByZero))
                } else {
                    Ok(self.wrapping_rem(rhs))
                }
            }

            #[inline]
            fn wasm_checked_div(self, rhs: Self) -> Result<Self> {
                if rhs == 0 {
                    Err(Error::Trap(crate::Trap::DivisionByZero))
                } else {
                    self.checked_div(rhs).ok_or_else(|| Error::Trap(crate::Trap::IntegerOverflow))
                }
            }
        }
    )*)
}

impl_checked_wrapping_rem! { i32 i64 u32 u64 }
