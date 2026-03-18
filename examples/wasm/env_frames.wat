;; EXPECT: ok
;; Lisp-oriented smoke test: lexical environment frames with parent links and shadowing.
(module
  (memory (export "memory") 1)
  (global $hp (mut i32) (i32.const 16))

  (func $bind (param $sym i32) (param $val i32) (param $parent i32) (result i32)
    (local $addr i32)
    global.get $hp
    local.tee $addr
    local.get $sym
    i32.store
    local.get $addr
    local.get $val
    i32.store offset=4
    local.get $addr
    local.get $parent
    i32.store offset=8
    global.get $hp
    i32.const 12
    i32.add
    global.set $hp
    local.get $addr
  )

  (func $lookup (param $env i32) (param $sym i32) (result i32)
    block $done
      loop $loop
        local.get $env
        i32.eqz
        if
          i32.const -2147483648
          return
        end

        local.get $env
        i32.load
        local.get $sym
        i32.eq
        if
          local.get $env
          i32.load offset=4
          return
        end

        local.get $env
        i32.load offset=8
        local.set $env
        br $loop
      end
    end

    i32.const -2147483648
  )

  (func (export "main")
    (local $e1 i32) (local $e2 i32) (local $e3 i32)

    i32.const 1
    i32.const 10
    i32.const 0
    call $bind
    local.set $e1

    i32.const 2
    i32.const 20
    local.get $e1
    call $bind
    local.set $e2

    i32.const 1
    i32.const 99
    local.get $e2
    call $bind
    local.set $e3

    local.get $e3
    i32.const 1
    call $lookup
    i32.const 99
    i32.ne
    if unreachable end

    local.get $e3
    i32.const 2
    call $lookup
    i32.const 20
    i32.ne
    if unreachable end

    local.get $e2
    i32.const 1
    call $lookup
    i32.const 10
    i32.ne
    if unreachable end

    local.get $e1
    i32.const 2
    call $lookup
    i32.const -2147483648
    i32.ne
    if unreachable end

    global.get $hp
    i32.const 52
    i32.ne
    if unreachable end
  )
)
