;; EXPECT: ok
;; Test linear memory loads, stores, sign extension, offsets, and memory.size.
(module
  (memory (export "memory") 1)

  (func (export "main")
    memory.size
    i32.const 1
    i32.ne
    if unreachable end

    i32.const 0
    i32.const -123456789
    i32.store
    i32.const 0
    i32.load
    i32.const -123456789
    i32.ne
    if unreachable end

    i32.const 16
    i32.const 255
    i32.store8
    i32.const 16
    i32.load8_u
    i32.const 255
    i32.ne
    if unreachable end
    i32.const 16
    i32.load8_s
    i32.const -1
    i32.ne
    if unreachable end

    i32.const 20
    i32.const -256
    i32.store16
    i32.const 20
    i32.load16_u
    i32.const 65280
    i32.ne
    if unreachable end
    i32.const 20
    i32.load16_s
    i32.const -256
    i32.ne
    if unreachable end

    i32.const 28
    i32.const 77
    i32.store offset=4
    i32.const 28
    i32.load offset=4
    i32.const 77
    i32.ne
    if unreachable end
  )
)
