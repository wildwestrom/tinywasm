;; EXPECT: ok
;; Lisp-oriented smoke test: fixnum tagging, untagging, arithmetic, and simple type predicates.
(module
  (func $tag_int (param $n i32) (result i32)
    local.get $n
    i32.const 1
    i32.shl
    i32.const 1
    i32.or
  )

  (func $untag_int (param $v i32) (result i32)
    local.get $v
    i32.const 1
    i32.shr_s
  )

  (func $is_fixnum (param $v i32) (result i32)
    local.get $v
    i32.const 1
    i32.and
    i32.const 1
    i32.eq
  )

  (func $is_heap_ptr (param $v i32) (result i32)
    local.get $v
    i32.const 7
    i32.and
    i32.eqz
  )

  (func $add_fixnums (param $a i32) (param $b i32) (result i32)
    local.get $a
    call $is_fixnum
    i32.eqz
    if
      i32.const 0
      return
    end

    local.get $b
    call $is_fixnum
    i32.eqz
    if
      i32.const 0
      return
    end

    local.get $a
    call $untag_int
    local.get $b
    call $untag_int
    i32.add
    call $tag_int
  )

  (func (export "main")
    i32.const 21
    call $tag_int
    i32.const 43
    i32.ne
    if unreachable end

    i32.const -3
    call $tag_int
    call $untag_int
    i32.const -3
    i32.ne
    if unreachable end

    i32.const 10
    call $tag_int
    call $is_fixnum
    i32.eqz
    if unreachable end

    i32.const 24
    call $is_heap_ptr
    i32.eqz
    if unreachable end

    i32.const 24
    call $is_fixnum
    if unreachable end

    i32.const 24
    call $is_heap_ptr
    i32.const 1
    i32.ne
    if unreachable end

    i32.const 10
    call $tag_int
    i32.const 32
    call $tag_int
    call $add_fixnums
    call $untag_int
    i32.const 42
    i32.ne
    if unreachable end

    i32.const -5
    call $tag_int
    i32.const 4
    call $tag_int
    call $add_fixnums
    call $untag_int
    i32.const -1
    i32.ne
    if unreachable end

    i32.const 24
    i32.const 7
    call $tag_int
    call $add_fixnums
    i32.eqz
    if
    else
      unreachable
    end
  )
)
