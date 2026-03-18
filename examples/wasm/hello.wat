;; Test linear memory + uart_write host import
(module
  (import "env" "uart_write" (func $uart_write (param i32 i32)))
  (memory (export "memory") 1)
  (data (i32.const 0) "hello from wasm\n")
  (func (export "main")
    i32.const 0   ;; ptr
    i32.const 16  ;; len
    call $uart_write
  )
)
