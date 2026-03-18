;; Test direct call + recursion: fib(10) == 55
(module
  (func $fib (param $n i32) (result i32)
    local.get $n
    i32.const 2
    i32.lt_s
    if (result i32)
      local.get $n
    else
      local.get $n
      i32.const 1
      i32.sub
      call $fib
      local.get $n
      i32.const 2
      i32.sub
      call $fib
      i32.add
    end
  )
  (func (export "main")
    i32.const 10
    call $fib
    i32.const 55
    i32.ne
    if unreachable end
  )
)
