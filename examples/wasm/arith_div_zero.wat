;; EXPECT: error: Trap(DivisionByZero)
;; Test that signed division by zero traps.
(module
  (func (export "main")
    i32.const 1
    i32.const 0
    i32.div_s
    drop
  )
)
