;; Test local.get, local.set, local.tee
(module
  (func (export "main")
    (local $a i32) (local $b i32) (local $c i32)
    i32.const 10
    local.set $a
    i32.const 20
    local.set $b
    ;; tee: stores and leaves value on stack
    i32.const 30
    local.tee $c
    drop
    ;; a + b + c should be 60
    local.get $a
    local.get $b
    i32.add
    local.get $c
    i32.add
    i32.const 60
    i32.ne
    if unreachable end
  )
)
