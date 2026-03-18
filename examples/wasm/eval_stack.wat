;; EXPECT: ok
;; Lisp-oriented smoke test: explicit evaluator stack in linear memory and bytecode dispatch.
(module
  (memory (export "memory") 1)
  (global $sp (mut i32) (i32.const 512))

  (func $push (param $v i32)
    global.get $sp
    local.get $v
    i32.store
    global.get $sp
    i32.const 4
    i32.add
    global.set $sp
  )

  (func $pop (result i32)
    global.get $sp
    i32.const 512
    i32.eq
    if (result i32)
      i32.const -2147483648
    else
      global.get $sp
      i32.const 4
      i32.sub
      global.set $sp
      global.get $sp
      i32.load
    end
  )

  (func $eval_program (param $pc i32) (result i32)
    (local $op i32) (local $lhs i32) (local $rhs i32)
    block $done
      loop $loop
        local.get $pc
        i32.load8_u
        local.tee $op
        i32.eqz
        br_if $done

        local.get $op
        i32.const 1
        i32.eq
        if
          local.get $pc
          i32.const 1
          i32.add
          i32.load8_u
          call $push

          local.get $pc
          i32.const 2
          i32.add
          local.set $pc
          br $loop
        end

        local.get $op
        i32.const 2
        i32.eq
        if
          call $pop
          local.set $rhs
          call $pop
          local.set $lhs
          local.get $lhs
          local.get $rhs
          i32.add
          call $push

          local.get $pc
          i32.const 1
          i32.add
          local.set $pc
          br $loop
        end

        local.get $op
        i32.const 3
        i32.eq
        if
          call $pop
          local.set $rhs
          call $pop
          local.set $lhs
          local.get $lhs
          local.get $rhs
          i32.mul
          call $push

          local.get $pc
          i32.const 1
          i32.add
          local.set $pc
          br $loop
        end

        local.get $op
        i32.const 4
        i32.eq
        if
          call $pop
          local.set $rhs
          call $pop
          local.set $lhs
          local.get $lhs
          local.get $rhs
          i32.sub
          call $push

          local.get $pc
          i32.const 1
          i32.add
          local.set $pc
          br $loop
        end

        i32.const -1
        return
      end
    end

    call $pop
  )

  (func (export "main")
    call $pop
    i32.const -2147483648
    i32.ne
    if unreachable end

    ;; Program 1: 2 3 * 4 + => 10
    i32.const 0 i32.const 1 i32.store8
    i32.const 1 i32.const 2 i32.store8
    i32.const 2 i32.const 1 i32.store8
    i32.const 3 i32.const 3 i32.store8
    i32.const 4 i32.const 3 i32.store8
    i32.const 5 i32.const 1 i32.store8
    i32.const 6 i32.const 4 i32.store8
    i32.const 7 i32.const 2 i32.store8
    i32.const 8 i32.const 0 i32.store8

    i32.const 0
    call $eval_program
    i32.const 10
    i32.ne
    if unreachable end

    global.get $sp
    i32.const 512
    i32.ne
    if unreachable end

    ;; Program 2: 9 4 - 2 * => 10
    i32.const 32 i32.const 1 i32.store8
    i32.const 33 i32.const 9 i32.store8
    i32.const 34 i32.const 1 i32.store8
    i32.const 35 i32.const 4 i32.store8
    i32.const 36 i32.const 4 i32.store8
    i32.const 37 i32.const 1 i32.store8
    i32.const 38 i32.const 2 i32.store8
    i32.const 39 i32.const 3 i32.store8
    i32.const 40 i32.const 0 i32.store8

    i32.const 32
    call $eval_program
    i32.const 10
    i32.ne
    if unreachable end

    global.get $sp
    i32.const 512
    i32.ne
    if unreachable end
  )
)
