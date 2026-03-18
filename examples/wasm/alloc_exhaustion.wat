;; EXPECT: ok
;; Lisp-oriented smoke test: bump allocator detects linear-memory exhaustion without trapping.
(module
  (memory (export "memory") 1)
  (global $hp (mut i32) (i32.const 65520))

  (func $alloc_pair (param $a i32) (param $b i32) (result i32)
    (local $addr i32)
    global.get $hp
    i32.const 8
    i32.add
    memory.size
    i32.const 16
    i32.shl
    i32.gt_u
    if (result i32)
      i32.const 0
    else
      global.get $hp
      local.tee $addr
      local.get $a
      i32.store
      local.get $addr
      local.get $b
      i32.store offset=4
      global.get $hp
      i32.const 8
      i32.add
      global.set $hp
      local.get $addr
    end
  )

  (func (export "main")
    (local $p1 i32) (local $p2 i32) (local $p3 i32)

    i32.const 1
    i32.const 2
    call $alloc_pair
    local.set $p1

    i32.const 3
    i32.const 4
    call $alloc_pair
    local.set $p2

    i32.const 5
    i32.const 6
    call $alloc_pair
    local.set $p3

    local.get $p1
    i32.const 65520
    i32.ne
    if unreachable end

    local.get $p2
    i32.const 65528
    i32.ne
    if unreachable end

    local.get $p3
    if unreachable end

    local.get $p1
    i32.load
    i32.const 1
    i32.ne
    if unreachable end

    local.get $p1
    i32.load offset=4
    i32.const 2
    i32.ne
    if unreachable end

    local.get $p2
    i32.load
    i32.const 3
    i32.ne
    if unreachable end

    local.get $p2
    i32.load offset=4
    i32.const 4
    i32.ne
    if unreachable end

    global.get $hp
    i32.const 65536
    i32.ne
    if unreachable end
  )
)
