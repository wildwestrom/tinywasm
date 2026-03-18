;; EXPECT: ok
;; Lisp-oriented smoke test: compare zero-terminated byte strings in linear memory.
(module
  (memory (export "memory") 1)

  (func $streq (param $a i32) (param $b i32) (result i32)
    (local $ca i32) (local $cb i32)
    block $done
      loop $loop
        local.get $a
        i32.load8_u
        local.tee $ca
        local.get $b
        i32.load8_u
        local.tee $cb
        i32.ne
        if
          i32.const 0
          return
        end

        local.get $ca
        i32.eqz
        if
          i32.const 1
          return
        end

        local.get $a
        i32.const 1
        i32.add
        local.set $a

        local.get $b
        i32.const 1
        i32.add
        local.set $b

        br $loop
      end
    end

    i32.const 0
  )

  (func (export "main")
    ;; "lambda"
    i32.const 0 i32.const 108 i32.store8
    i32.const 1 i32.const 97  i32.store8
    i32.const 2 i32.const 109 i32.store8
    i32.const 3 i32.const 98  i32.store8
    i32.const 4 i32.const 100 i32.store8
    i32.const 5 i32.const 97  i32.store8
    i32.const 6 i32.const 0   i32.store8

    ;; "lambda"
    i32.const 16 i32.const 108 i32.store8
    i32.const 17 i32.const 97  i32.store8
    i32.const 18 i32.const 109 i32.store8
    i32.const 19 i32.const 98  i32.store8
    i32.const 20 i32.const 100 i32.store8
    i32.const 21 i32.const 97  i32.store8
    i32.const 22 i32.const 0   i32.store8

    ;; "let"
    i32.const 32 i32.const 108 i32.store8
    i32.const 33 i32.const 101 i32.store8
    i32.const 34 i32.const 116 i32.store8
    i32.const 35 i32.const 0   i32.store8

    ;; "lam"
    i32.const 48 i32.const 108 i32.store8
    i32.const 49 i32.const 97  i32.store8
    i32.const 50 i32.const 109 i32.store8
    i32.const 51 i32.const 0   i32.store8

    ;; ""
    i32.const 64 i32.const 0   i32.store8
    i32.const 80 i32.const 0   i32.store8

    i32.const 0
    i32.const 16
    call $streq
    i32.eqz
    if unreachable end

    i32.const 0
    i32.const 32
    call $streq
    if unreachable end

    i32.const 0
    i32.const 48
    call $streq
    if unreachable end

    i32.const 64
    i32.const 80
    call $streq
    i32.eqz
    if unreachable end
  )
)
