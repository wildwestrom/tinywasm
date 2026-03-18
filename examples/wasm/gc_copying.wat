;; EXPECT: ok
;; Garbage-collector smoke test: Cheney semispace copying collector over pair cells.
;; Covers root rewriting, forwarding pointers, shared structure, cycles, reclamation,
;; and a second collection after additional allocations.
(module
  (memory (export "memory") 1)

  (global $from_start (mut i32) (i32.const 256))
  (global $to_start (mut i32) (i32.const 1536))
  (global $alloc (mut i32) (i32.const 256))

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

  (func $is_ptr (param $v i32) (result i32)
    local.get $v
    i32.eqz
    if (result i32)
      i32.const 0
    else
      local.get $v
      i32.const 1
      i32.and
      i32.eqz
    end
  )

  (func $in_from_space (param $ptr i32) (result i32)
    local.get $ptr
    global.get $from_start
    i32.lt_u
    if (result i32)
      i32.const 0
    else
      local.get $ptr
      global.get $from_start
      i32.const 512
      i32.add
      i32.lt_u
    end
  )

  (func $alloc_cons (param $car i32) (param $cdr i32) (result i32)
    (local $addr i32)
    global.get $alloc
    i32.const 16
    i32.add
    global.get $from_start
    i32.const 512
    i32.add
    i32.gt_u
    if unreachable end

    global.get $alloc
    local.tee $addr
    i32.const 0
    i32.store

    local.get $addr
    local.get $car
    i32.store offset=4

    local.get $addr
    local.get $cdr
    i32.store offset=8

    local.get $addr
    i32.const 0
    i32.store offset=12

    global.get $alloc
    i32.const 16
    i32.add
    global.set $alloc

    local.get $addr
  )

  (func $car (param $cell i32) (result i32)
    local.get $cell
    i32.load offset=4
  )

  (func $cdr (param $cell i32) (result i32)
    local.get $cell
    i32.load offset=8
  )

  (func $set_cdr (param $cell i32) (param $value i32)
    local.get $cell
    local.get $value
    i32.store offset=8
  )

  (func $copy (param $ptr i32) (result i32)
    (local $new i32)
    local.get $ptr
    call $is_ptr
    i32.eqz
    if (result i32)
      local.get $ptr
    else
      local.get $ptr
      call $in_from_space
      i32.eqz
      if (result i32)
        local.get $ptr
      else
        local.get $ptr
        i32.load
        i32.const 1
        i32.eq
        if (result i32)
          local.get $ptr
          i32.load offset=4
        else
          global.get $alloc
          local.tee $new
          i32.const 16
          i32.add
          global.get $to_start
          i32.const 512
          i32.add
          i32.gt_u
          if unreachable end

          local.get $new
          i32.const 0
          i32.store

          local.get $new
          local.get $ptr
          i32.load offset=4
          i32.store offset=4

          local.get $new
          local.get $ptr
          i32.load offset=8
          i32.store offset=8

          local.get $new
          i32.const 0
          i32.store offset=12

          global.get $alloc
          i32.const 16
          i32.add
          global.set $alloc

          local.get $ptr
          i32.const 1
          i32.store

          local.get $ptr
          local.get $new
          i32.store offset=4

          local.get $new
        end
      end
    end
  )

  (func $collect (param $root_count i32)
    (local $i i32)
    (local $slot i32)
    (local $scan i32)
    (local $value i32)
    (local $tmp i32)

    global.get $to_start
    global.set $alloc

    block $roots_done
      loop $roots
        local.get $i
        local.get $root_count
        i32.ge_u
        br_if $roots_done

        local.get $i
        i32.const 2
        i32.shl
        local.tee $slot
        i32.load
        call $copy
        local.set $value

        local.get $slot
        local.get $value
        i32.store

        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $roots
      end
    end

    global.get $to_start
    local.set $scan

    block $scan_done
      loop $scan_loop
        local.get $scan
        global.get $alloc
        i32.ge_u
        br_if $scan_done

        local.get $scan
        i32.load offset=4
        call $copy
        local.set $tmp
        local.get $scan
        local.get $tmp
        i32.store offset=4

        local.get $scan
        i32.load offset=8
        call $copy
        local.set $tmp
        local.get $scan
        local.get $tmp
        i32.store offset=8

        local.get $scan
        i32.const 16
        i32.add
        local.set $scan
        br $scan_loop
      end
    end

    global.get $from_start
    local.set $tmp
    global.get $to_start
    global.set $from_start
    local.get $tmp
    global.set $to_start
  )

  (func (export "main")
    (local $leaf i32)
    (local $shared i32)
    (local $root i32)
    (local $cycle i32)
    (local $garbage1 i32)
    (local $garbage2 i32)
    (local $new1 i32)
    (local $new2 i32)
    (local $r0 i32)
    (local $r1 i32)
    (local $root2 i32)
    (local $shared2 i32)
    (local $leaf2 i32)

    i32.const 10
    call $tag_int
    i32.const 0
    call $alloc_cons
    local.set $leaf

    i32.const 20
    call $tag_int
    local.get $leaf
    call $alloc_cons
    local.set $shared

    local.get $shared
    local.get $leaf
    call $alloc_cons
    local.set $root

    i32.const 30
    call $tag_int
    i32.const 0
    call $alloc_cons
    local.set $cycle

    local.get $cycle
    local.get $cycle
    call $set_cdr

    i32.const 99
    call $tag_int
    i32.const 0
    call $alloc_cons
    local.set $garbage1

    local.get $garbage1
    i32.const 77
    call $tag_int
    call $alloc_cons
    local.set $garbage2

    i32.const 0
    local.get $root
    i32.store
    i32.const 4
    local.get $cycle
    i32.store
    i32.const 8
    i32.const 123
    call $tag_int
    i32.store

    i32.const 3
    call $collect

    i32.const 0
    i32.load
    local.set $r0
    i32.const 4
    i32.load
    local.set $r1

    local.get $r0
    global.get $from_start
    i32.lt_u
    if unreachable end

    local.get $r0
    global.get $from_start
    i32.const 512
    i32.add
    i32.ge_u
    if unreachable end

    local.get $r1
    global.get $from_start
    i32.lt_u
    if unreachable end

    i32.const 8
    i32.load
    call $untag_int
    i32.const 123
    i32.ne
    if unreachable end

    local.get $r0
    call $car
    local.set $shared2
    local.get $r0
    call $cdr
    local.set $leaf2

    local.get $shared2
    call $car
    call $untag_int
    i32.const 20
    i32.ne
    if unreachable end

    local.get $leaf2
    call $car
    call $untag_int
    i32.const 10
    i32.ne
    if unreachable end

    local.get $shared2
    call $cdr
    local.get $leaf2
    i32.ne
    if unreachable end

    local.get $r1
    call $car
    call $untag_int
    i32.const 30
    i32.ne
    if unreachable end

    local.get $r1
    call $cdr
    local.get $r1
    i32.ne
    if unreachable end

    global.get $from_start
    i32.const 1536
    i32.ne
    if unreachable end

    global.get $to_start
    i32.const 256
    i32.ne
    if unreachable end

    global.get $alloc
    i32.const 1600
    i32.ne
    if unreachable end

    i32.const 7
    call $tag_int
    local.get $r0
    call $alloc_cons
    local.set $new1

    i32.const 8
    call $tag_int
    local.get $new1
    call $alloc_cons
    local.set $new2

    i32.const 0
    local.get $new2
    i32.store
    i32.const 4
    local.get $r1
    i32.store
    i32.const 8
    i32.const 0
    i32.store

    i32.const 1
    call $tag_int
    i32.const 0
    call $alloc_cons
    drop

    i32.const 2
    call $tag_int
    i32.const 0
    call $alloc_cons
    drop

    i32.const 2
    call $collect

    i32.const 0
    i32.load
    local.set $r0
    i32.const 4
    i32.load
    local.set $r1

    local.get $r0
    call $cdr
    local.set $new1

    local.get $new1
    call $car
    call $untag_int
    i32.const 7
    i32.ne
    if unreachable end

    local.get $r0
    call $car
    call $untag_int
    i32.const 8
    i32.ne
    if unreachable end

    local.get $new1
    call $cdr
    local.set $root2

    local.get $root2
    call $car
    local.set $shared2

    local.get $root2
    call $cdr
    local.set $leaf2

    local.get $shared2
    call $car
    call $untag_int
    i32.const 20
    i32.ne
    if unreachable end

    local.get $shared2
    call $cdr
    local.get $leaf2
    i32.ne
    if unreachable end

    local.get $leaf2
    call $car
    call $untag_int
    i32.const 10
    i32.ne
    if unreachable end

    local.get $r1
    call $cdr
    local.get $r1
    i32.ne
    if unreachable end

    global.get $from_start
    i32.const 256
    i32.ne
    if unreachable end

    global.get $to_start
    i32.const 1536
    i32.ne
    if unreachable end

    global.get $alloc
    i32.const 352
    i32.ne
    if unreachable end
  )
)
