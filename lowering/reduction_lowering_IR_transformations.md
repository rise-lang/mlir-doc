[index](../README.md)
# IR transformations for lowering a reduction

##### initial rise_mlir code
```C++
rise.interface "foo" {
  %addFun = rise.add #rise.int
  %init = rise.literal #rise.lit<int<0>>
  
  %reduce4Ints = rise.reduce #rise.nat<4> #rise.int #rise.int
  %result = rise.apply %reduce4Ints, %addFun, %init, %array0
  return %result
}

func @main() {
  %res = rise.call "foo" ()
  return
}
```
            |       ...                     
            |       rise.reduce 
            |       rise.apply      expanded to loop.for
            V
```C++
func @foo() {
  %array = rise.literal #rise.lit<array<4, !rise.int, [1,2,3,4]>>
  %init = rise.literal #rise.lit<int<0>>

  %X = rise.I_promise_to_translate_you %array                       //TODO
  %Y = rise.I_promise_to_translate_you %init                        //TODO
  
  // reduceSeq: new ... (dt2 = f32, acc = %acc)
  %acc = alloc() : memref<1xf32>
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
    x3 = addf %x1, %x2                                
    // reduceSeq: ... f(acc.rd)(in@i)( acc.wr )
    store %x3, %acc[%cst_0] : memref<1xf32>
  }

  return
}

func @main() {
  %output = alloc() : memref<1xf32>
  call @foo(%output)
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
  return
}


func @main() {
  %output = alloc() : memref<1xf32>
  call @foo(%output)
}

func @print_memref_-1d_f32(memref<1xf32>)
```

