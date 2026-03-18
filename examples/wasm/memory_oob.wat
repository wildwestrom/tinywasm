;; EXPECT_PREFIX: error: Trap(MemoryOutOfBounds
;; Test that out-of-bounds linear memory stores trap.
(module
  (memory 1)

  (func (export "main")
    i32.const 65535
    i32.const 1
    i32.store
  )
)
