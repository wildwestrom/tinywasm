;; EXPECT: error: Trap(DivisionByZero)
;; Test that remainder by zero traps.
(module
  (func (export "main")
    i32.const 123
    i32.const 0
    i32.rem_u
    drop
  )
)
