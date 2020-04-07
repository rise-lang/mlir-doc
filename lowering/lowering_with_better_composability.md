[index](../README.md)

    Example: reduce
```C++
rise.fun "rise_fun" (%outArg:memref<1xf32>, %inArg:memref<4xf32>) {
    %array0 = rise.in %inArg : !rise.array<4, scalar<f32>>

    %reductionAdd = rise.lambda (%summand0, %summand1) : !rise.fun<scalar<f32> -> fun<scalar<f32> -> scalar<f32>>> {
        %summand0_unwrapped = rise.unwrap %summand0
        %summand1_unwrapped = rise.unwrap %summand1
        %result = addf %summand0_unwrapped, %summand1_unwrapped : f32
        %result_wrapped = rise.wrap %result
        rise.return %result_wrapped : !rise.scalar<f32>
    }
    %initializer = rise.literal #rise.lit<0.0>
    %reduce4Ints = rise.reduceSeq #rise.nat<4> #rise.scalar<f32> #rise.scalar<f32>
    %result = rise.apply %reduce4Ints, %reductionAdd, %initializer, %array0

    rise.return %result : !rise.scalar<f32>
} 
```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
func @rise_fun(%arg0: memref<1xf32>, %arg1: memref<4xf32>) {
    %cst = constant 0.000000e+00 : f32
    %0 = alloc() : memref<1xf32>
    linalg.fill(%0, %cst) : memref<1xf32>, f32
    %c0 = constant 0 : index
    %c0_0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg2 = %c0_0 to %c4 step %c1 {
          %3 = "rise.codegen.idx"(%arg1, %arg2) : (memref<4xf32>, index) -> memref<f32>
          %4 = "rise.codegen.idx"(%0, %c0) : (memref<1xf32>, index) -> memref<1xf32>
          %5 = "rise.unwrap"(%4) : (memref<1xf32>) -> f32
          %6 = "rise.unwrap"(%3) : (memref<f32>) -> f32
          %7 = addf %5, %6 : f32
          %8 = "rise.wrap"(%7) : (f32) -> !rise.scalar<f32>
          "rise.codegen.assign"(%8, %4) : (!rise.scalar<f32>, memref<1xf32>) -> ()
    }
    %1 = "rise.codegen.idx"(%arg0, %c0) : (memref<1xf32>, index) -> memref<1xf32>
    %2 = "rise.codegen.idx"(%0, %c0) : (memref<1xf32>, index) -> memref<1xf32>
    "rise.codegen.assign"(%2, %1) : (memref<1xf32>, memref<1xf32>) -> ()
    return
}  
```

```
        |       Lowering to Imperative: mlir-opt map_add.mlir -convert-rise-to-imperative        
        |           Dialect Conversion: (rise)              -> (std x loop x linalg) 
        |           rise.fun                                -> @riseFun(): (memref) -> () ... call @riseFun
        |           rise.literal                            -> alloc() : memref ... linalg.fill
        |           rise.map ... rise.apply ... rise.apply  -> loop.for
        |           rise.lambda{rise.add}                   -> rise.bin_op ... rise.assign
        V
```

Almost finished
