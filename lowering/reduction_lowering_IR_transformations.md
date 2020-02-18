[index](../README.md)
# IR transformations for lowering a reduction

##### initial rise_mlir code
```C++
func @main() {
  %array = rise.literal #rise.lit<array<4, !rise.int, [1,2,3,4]>>

  %addFun = rise.add #rise.int
  %initializer = rise.literal #rise.lit<int<0>>
  %reduce4Ints = rise.reduce #rise.nat<4> #rise.int #rise.int
  %result = rise.apply %reduce4Ints, %addFun, %initializer, %array0
  return
}
```
            |       (rise.reduce ... rise.apply) expanded
            |  
            V
```C++
func @main() {
  %array = rise.literal #rise.lit<array<4, !rise.int, [1,2,3,4]>>

  %init = rise.literal #rise.lit<int<0>>

  // reduceSeq: new ... (dt2 = f32, acc = %acc)
  %acc = alloc() : memref<1xf32>

  %X = rise.I_promise_to_translate_you %array

  %Y = rise.I_promise_to_translate_you %init
  linalg.fill(%acc, %Y) : memref<1xf32>, f32

  // reduceSeq: for ... (n = 4, i = %i)
  %lb = constant 0 : index
  %ub = constant 4 : index //half open index, so 4 iterations
  %step = constant 1 : index
  loop.for %i = %lb to %ub step %step {
    // reduceSeq: ... acc.rd:
    %x1 = load %acc[%cst_0] : memref<1xf32>
    // reduceSeq: ... in@i
    %x2 = load %X[%i] : memref<4xf32>
    // reduceSeq: ... f(acc.rd)(in@i)r
    %x3 = addf %x1, %x2 : f32
    // reduceSeq: ... f(acc.rd)(in@i)( acc.wr )
    store %x3, %acc[%cst_0] : memref<1xf32>
  }

  return
}
```
            |
            |
            V
```C++

func @main() {
  %cst_0 = constant 0 : index

  %input = alloc() : memref<4xf32>
  %filler = constant 5.0 : f32
  linalg.fill(%input, %filler) : memref<4xf32>, f32

  %output = alloc() : memref<1xf32>

  // reduceSeq: new ... (dt2 = f32, acc = %acc)
  %acc = alloc() : memref<1xf32>

  // reduceSeq: acc := init (init = constant 0.0)
  %init = constant 0.0 : f32
  linalg.fill(%acc, %init) : memref<1xf32>, f32

  // reduceSeq: for ... (n = 4, i = %i)
  %lb = constant 0 : index
  %ub = constant 4 : index //half open index, so 4 iterations
  %step = constant 1 : index
  loop.for %i = %lb to %ub step %step {
    // reduceSeq: ... acc.rd:
    %x1 = load %acc[%cst_0] : memref<1xf32>
    // reduceSeq: ... in@i
    %x2 = load %input[%i] : memref<4xf32>
    // reduceSeq: ... f(acc.rd)(in@i)r
    %x3 = addf %x1, %x2 : f32
    // reduceSeq: ... f(acc.rd)(in@i)( acc.wr )
    store %x3, %acc[%cst_0] : memref<1xf32>
  }
  // reduceSeq: ... out = acc
  %x4 = load %acc[%cst_0] : memref<1xf32>
  store %x4, %output[%cst_0] : memref<1xf32>
  call @print_memref_0d_f32(%output) : (memref<1xf32>) -> ()
  return
}

func @print_memref_0d_f32(memref<1xf32>)
```

