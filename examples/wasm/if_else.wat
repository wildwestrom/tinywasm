;; Test if/else and i32 comparisons
(module
  (func $max (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.gt_s
    if (result i32)
      local.get $a
    else
      local.get $b
    end
  )
  (func (export "main")
    ;; max(3, 7) == 7
    i32.const 3
    i32.const 7
    call $max
    i32.const 7
    i32.ne
    if unreachable end
    ;; max(9, 2) == 9
    i32.const 9
    i32.const 2
    call $max
    i32.const 9
    i32.ne
    if unreachable end
    ;; max(5, 5) == 5
    i32.const 5
    i32.const 5
    call $max
    i32.const 5
    i32.ne
    if unreachable end
  )
)
