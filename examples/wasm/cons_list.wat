;; EXPECT: ok
;; Lisp-oriented smoke test: bump-allocate cons cells in linear memory and traverse a list.
(module
  (memory (export "memory") 1)
  (global $hp (mut i32) (i32.const 8))

  (func $alloc_cons (param $car i32) (param $cdr i32) (result i32)
    (local $addr i32)
    global.get $hp
    local.tee $addr
    local.get $car
    i32.store
    local.get $addr
    local.get $cdr
    i32.store offset=4
    global.get $hp
    i32.const 8
    i32.add
    global.set $hp
    local.get $addr
  )

  (func $car (param $cell i32) (result i32)
    local.get $cell
    i32.load
  )

  (func $cdr (param $cell i32) (result i32)
    local.get $cell
    i32.load offset=4
  )

  (func $list_sum (param $list i32) (result i32)
    (local $sum i32)
    block $done
      loop $loop
        local.get $list
        i32.eqz
        br_if $done
        local.get $sum
        local.get $list
        call $car
        i32.add
        local.set $sum
        local.get $list
        call $cdr
        local.set $list
        br $loop
      end
    end
    local.get $sum
  )

  (func $list_len (param $list i32) (result i32)
    (local $len i32)
    block $done
      loop $loop
        local.get $list
        i32.eqz
        br_if $done
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $list
        call $cdr
        local.set $list
        br $loop
      end
    end
    local.get $len
  )

  (func (export "main")
    (local $c1 i32) (local $c2 i32) (local $c3 i32)

    i32.const 30
    i32.const 0
    call $alloc_cons
    local.set $c3

    i32.const 20
    local.get $c3
    call $alloc_cons
    local.set $c2

    i32.const 10
    local.get $c2
    call $alloc_cons
    local.set $c1

    local.get $c1
    i32.const 24
    i32.ne
    if unreachable end

    local.get $c1
    call $car
    i32.const 10
    i32.ne
    if unreachable end

    local.get $c1
    call $cdr
    local.get $c2
    i32.ne
    if unreachable end

    local.get $c2
    call $car
    i32.const 20
    i32.ne
    if unreachable end

    local.get $c3
    call $cdr
    i32.const 0
    i32.ne
    if unreachable end

    local.get $c1
    call $list_sum
    i32.const 60
    i32.ne
    if unreachable end

    local.get $c1
    call $list_len
    i32.const 3
    i32.ne
    if unreachable end

    global.get $hp
    i32.const 32
    i32.ne
    if unreachable end
  )
)
