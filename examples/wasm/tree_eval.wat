;; EXPECT: ok
;; Lisp-oriented smoke test: recursively evaluate a tiny AST stored in linear memory.
(module
  (memory (export "memory") 1)
  (global $hp (mut i32) (i32.const 16))

  (func $alloc_node (param $tag i32) (param $a i32) (param $b i32) (result i32)
    (local $addr i32)
    global.get $hp
    local.tee $addr
    local.get $tag
    i32.store
    local.get $addr
    local.get $a
    i32.store offset=4
    local.get $addr
    local.get $b
    i32.store offset=8
    global.get $hp
    i32.const 12
    i32.add
    global.set $hp
    local.get $addr
  )

  (func $alloc_const (param $v i32) (result i32)
    i32.const 1
    local.get $v
    i32.const 0
    call $alloc_node
  )

  (func $alloc_add (param $lhs i32) (param $rhs i32) (result i32)
    i32.const 2
    local.get $lhs
    local.get $rhs
    call $alloc_node
  )

  (func $alloc_mul (param $lhs i32) (param $rhs i32) (result i32)
    i32.const 3
    local.get $lhs
    local.get $rhs
    call $alloc_node
  )

  (func $alloc_var (param $sym i32) (result i32)
    i32.const 4
    local.get $sym
    i32.const 0
    call $alloc_node
  )

  (func $alloc_env (param $sym i32) (param $val i32) (param $parent i32) (result i32)
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

  (func $eval (param $node i32) (param $env i32) (result i32)
    (local $tag i32)
    local.get $node
    i32.load
    local.tee $tag
    i32.const 1
    i32.eq
    if (result i32)
      local.get $node
      i32.load offset=4
    else
      local.get $tag
      i32.const 2
      i32.eq
      if (result i32)
        local.get $node
        i32.load offset=4
        local.get $env
        call $eval
        local.get $node
        i32.load offset=8
        local.get $env
        call $eval
        i32.add
      else
        local.get $tag
        i32.const 3
        i32.eq
        if (result i32)
          local.get $node
          i32.load offset=4
          local.get $env
          call $eval
          local.get $node
          i32.load offset=8
          local.get $env
          call $eval
          i32.mul
        else
          local.get $tag
          i32.const 4
          i32.eq
          if (result i32)
            local.get $env
            local.get $node
            i32.load offset=4
            call $lookup
          else
            i32.const -1
          end
        end
      end
    end
  )

  (func (export "main")
    (local $x i32) (local $y i32) (local $two i32)
    (local $mul i32) (local $add i32)
    (local $env1 i32) (local $env2 i32)

    i32.const 1
    call $alloc_var
    local.set $x

    i32.const 2
    call $alloc_var
    local.set $y

    i32.const 2
    call $alloc_const
    local.set $two

    local.get $two
    local.get $y
    call $alloc_mul
    local.set $mul

    local.get $x
    local.get $mul
    call $alloc_add
    local.set $add

    i32.const 1
    i32.const 4
    i32.const 0
    call $alloc_env
    local.set $env1

    i32.const 2
    i32.const 5
    local.get $env1
    call $alloc_env
    local.set $env1

    i32.const 1
    i32.const 7
    local.get $env1
    call $alloc_env
    local.set $env2

    local.get $add
    local.get $env1
    call $eval
    i32.const 14
    i32.ne
    if unreachable end

    local.get $add
    local.get $env2
    call $eval
    i32.const 17
    i32.ne
    if unreachable end

    global.get $hp
    i32.const 112
    i32.ne
    if unreachable end
  )
)
