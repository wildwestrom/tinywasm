use core::fmt::Debug;

use crate::{ConstInstruction, ExternAddr, FuncAddr};

/// A WebAssembly value.
///
/// See <https://webassembly.github.io/spec/core/syntax/types.html#value-types>
#[derive(Clone, Copy, PartialEq)]
pub enum WasmValue {
    // Num types
    /// A 32-bit integer.
    I32(i32),
    /// A 64-bit integer.
    I64(i64),

    RefExtern(ExternRef),
    RefFunc(FuncRef),
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub struct ExternRef(Option<ExternAddr>);

#[derive(Clone, Copy, PartialEq, Eq)]
pub struct FuncRef(Option<FuncAddr>);

impl Debug for ExternRef {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self.0 {
            Some(addr) => write!(f, "extern({addr:?})"),
            None => write!(f, "extern(null)"),
        }
    }
}

impl Debug for FuncRef {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self.0 {
            Some(addr) => write!(f, "func({addr:?})"),
            None => write!(f, "func(null)"),
        }
    }
}

impl FuncRef {
    /// Create a new `FuncRef` from a `FuncAddr`.
    /// Should only be used by the runtime.
    #[doc(hidden)]
    #[inline]
    pub const fn new(addr: Option<FuncAddr>) -> Self {
        Self(addr)
    }

    /// Create a null `FuncRef`.
    #[inline]
    pub const fn null() -> Self {
        Self(None)
    }

    /// Check if the `FuncRef` is null.
    #[inline]
    pub const fn is_null(&self) -> bool {
        self.0.is_none()
    }

    /// Get the `FuncAddr` from the `FuncRef`.
    #[inline]
    pub const fn addr(&self) -> Option<FuncAddr> {
        self.0
    }
}

impl ExternRef {
    /// Create a new `ExternRef` from an `ExternAddr`.
    /// Should only be used by the runtime.
    #[doc(hidden)]
    #[inline]
    pub const fn new(addr: Option<ExternAddr>) -> Self {
        Self(addr)
    }

    /// Create a null `ExternRef`.
    #[inline]
    pub const fn null() -> Self {
        Self(None)
    }

    /// Check if the `ExternRef` is null.
    #[inline]
    pub const fn is_null(&self) -> bool {
        self.0.is_none()
    }

    /// Get the `ExternAddr` from the `ExternRef`.
    #[inline]
    pub const fn addr(&self) -> Option<ExternAddr> {
        self.0
    }
}

impl WasmValue {
    #[doc(hidden)]
    #[inline]
    pub fn const_instr(&self) -> ConstInstruction {
        match self {
            Self::I32(i) => ConstInstruction::I32Const(*i),
            Self::I64(i) => ConstInstruction::I64Const(*i),
            Self::RefFunc(i) => ConstInstruction::RefFunc(i.addr()),
            Self::RefExtern(_) => unimplemented!("no const_instr for RefExtern"),
        }
    }

    /// Get the default value for a given type.
    #[inline]
    pub fn default_for(ty: ValType) -> Self {
        match ty {
            ValType::I32 => Self::I32(0),
            ValType::I64 => Self::I64(0),
            ValType::RefFunc => Self::RefFunc(FuncRef::null()),
            ValType::RefExtern => Self::RefExtern(ExternRef::null()),
        }
    }

    /// Check if two values are equal, ignoring differences in NaN values.
    #[inline]
    pub fn eq_loose(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::I32(a), Self::I32(b)) => a == b,
            (Self::I64(a), Self::I64(b)) => a == b,
            (Self::RefExtern(addr), Self::RefExtern(addr2)) => addr == addr2,
            (Self::RefFunc(addr), Self::RefFunc(addr2)) => addr == addr2,
            _ => false,
        }
    }

    #[doc(hidden)]
    pub fn as_i32(&self) -> Option<i32> {
        match self {
            Self::I32(i) => Some(*i),
            _ => None,
        }
    }

    #[doc(hidden)]
    pub fn as_i64(&self) -> Option<i64> {
        match self {
            Self::I64(i) => Some(*i),
            _ => None,
        }
    }

    #[doc(hidden)]
    pub fn as_ref_extern(&self) -> Option<ExternRef> {
        match self {
            Self::RefExtern(ref_extern) => Some(*ref_extern),
            _ => None,
        }
    }

    #[doc(hidden)]
    pub fn as_ref_func(&self) -> Option<FuncRef> {
        match self {
            Self::RefFunc(ref_func) => Some(*ref_func),
            _ => None,
        }
    }
}

#[cold]
fn cold() {}

impl Debug for WasmValue {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::I32(i) => write!(f, "i32({i})"),
            Self::I64(i) => write!(f, "i64({i})"),
            Self::RefExtern(i) => write!(f, "ref({i:?})"),
            Self::RefFunc(i) => write!(f, "func({i:?})"),
        }
    }
}

impl WasmValue {
    /// Get the type of a [`WasmValue`]
    #[inline]
    pub fn val_type(&self) -> ValType {
        match self {
            Self::I32(_) => ValType::I32,
            Self::I64(_) => ValType::I64,
            Self::RefExtern(_) => ValType::RefExtern,
            Self::RefFunc(_) => ValType::RefFunc,
        }
    }
}

/// Type of a WebAssembly value.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(feature = "archive", derive(serde::Serialize, serde::Deserialize))]
pub enum ValType {
    /// A 32-bit integer.
    I32,
    /// A 64-bit integer.
    I64,
    /// A reference to a function.
    RefFunc,
    /// A reference to an external value.
    RefExtern,
}

impl ValType {
    #[inline]
    pub fn default_value(&self) -> WasmValue {
        WasmValue::default_for(*self)
    }
}

macro_rules! impl_conversion_for_wasmvalue {
    ($($t:ty => $variant:ident),*) => {
        $(
            // Implementing From<$t> for WasmValue
            impl From<$t> for WasmValue {
                #[inline]
                fn from(i: $t) -> Self {
                    Self::$variant(i)
                }
            }

            // Implementing TryFrom<WasmValue> for $t
            impl TryFrom<WasmValue> for $t {
                type Error = ();

                #[inline]
                fn try_from(value: WasmValue) -> Result<Self, Self::Error> {
                    if let WasmValue::$variant(i) = value {
                        Ok(i)
                    } else {
                        cold();
                        Err(())
                    }
                }
            }
        )*
    }
}

impl_conversion_for_wasmvalue! { i32 => I32, i64 => I64, ExternRef => RefExtern, FuncRef => RefFunc }
