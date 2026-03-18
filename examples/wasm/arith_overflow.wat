;; EXPECT: error: Trap(IntegerOverflow)
;; Test the one i32 signed division overflow case: INT_MIN / -1.
(module
  (func (export "main")
    i32.const -2147483648
    i32.const -1
    i32.div_s
    drop
  )
)
