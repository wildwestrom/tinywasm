;; EXPECT: ok
;; Test i32 wrapping behavior and boundary arithmetic.
(module
  (func (export "main")
    ;; 0x7fffffff + 1 wraps to 0x80000000.
    i32.const 2147483647
    i32.const 1
    i32.add
    i32.const -2147483648
    i32.ne
    if unreachable end

    ;; 0x80000000 - 1 wraps to 0x7fffffff.
    i32.const -2147483648
    i32.const 1
    i32.sub
    i32.const 2147483647
    i32.ne
    if unreachable end

    ;; 0x40000000 * 4 wraps to 0.
    i32.const 1073741824
    i32.const 4
    i32.mul
    i32.const 0
    i32.ne
    if unreachable end

    ;; Unsigned division sees -1 as 0xffffffff.
    i32.const -1
    i32.const 2
    i32.div_u
    i32.const 2147483647
    i32.ne
    if unreachable end

    ;; Signed remainder keeps the dividend sign at the boundary.
    i32.const -2147483648
    i32.const 3
    i32.rem_s
    i32.const -2
    i32.ne
    if unreachable end
  )
)
