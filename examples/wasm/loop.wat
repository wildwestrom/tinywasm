;; Test loop + br_if: sum 1..=10 == 55
(module
  (func (export "main")
    (local $i i32) (local $sum i32)
    i32.const 1
    local.set $i
    block $break
      loop $cont
        local.get $i
        i32.const 10
        i32.gt_s
        br_if $break
        local.get $sum
        local.get $i
        i32.add
        local.set $sum
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      end
    end
    local.get $sum
    i32.const 55
    i32.ne
    if unreachable end
  )
)
