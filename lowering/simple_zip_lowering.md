[index](../README.md)
# Lowering a simple 2D map

##### initial rise_mlir code
```C++
func @print_memref_f32(memref<*xf32>)
func @rise_fun(memref<4xf32>)
func @array_times_2() {

    rise.fun "rise_fun" (%outArg:memref<4xf32>) {
        %array0 = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>
        %array1 = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>

        %zipFun = rise.zip #rise.nat<4> #rise.float #rise.float
        %zipped = rise.apply %zipFun, %array0, %array1

        %projectToFirst = rise.lambda (%floatTuple) : !rise.fun<data<tuple<float, float>> -> data<float>> {
            %fstFun = rise.fst #rise.float #rise.float
            %fst = rise.apply %fstFun, %floatTuple
            rise.return %fst : !rise.data<float>
        }

        %mapFun = rise.map #rise.nat<4> #rise.tuple<float, float> #rise.float
        %fstArray = rise.apply %mapFun, %projectToFirst, %zipped

        rise.return %fstArray : !rise.data<array<4, float>>
    }

    //prepare output Array
    %outputArray = alloc() : memref<4xf32>
    call @rise_fun(%outputArray) : (memref<4xf32>) -> ()

    %print_me = memref_cast %outputArray : memref<4xf32> to memref<*xf32>
    call @print_memref_f32(%print_me): (memref<*xf32>) -> ()
    return
}
```

Mockup
            |       Lowering (almost) to imperative, but leaving intermediate ops inside
            |           Dialect Conversion: (rise)              -> (std x loop x linalg) 
            |           rise.fun                                -> @riseFun(): () -> (memref) ... call @riseFun
            |           rise.literal                            -> alloc() : memref ... linalg.fill
            |           rise.map ... rise.apply ... rise.apply  -> loop.for
            |           
            V
```C++
module {
  func @rise_fun(%arg0: memref<4xf32>) {
    %0 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4xf32>, f32
    %1 = alloc() : memref<4xf32>
    %cst_0 = constant 5.000000e+00 : f32
    linalg.fill(%1, %cst_0) : memref<4xf32>, f32
    %2 = "rise.zip_interm"(%0, %1) : (memref<4xf32>, memref<4xf32>) -> memref<4xf32>
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %3 = "rise.idx"(%2, %arg1) : (memref<4xf32>, index) -> memref<f32>
      %4 = "rise.idx"(%arg0, %arg1) : (memref<4xf32>, index) -> memref<f32>
      %5 = "rise.fst_interm"(%3) : (memref<f32>) -> f32
      "rise.assign"(%5, %4) : (f32, memref<f32>) -> ()
    }
    return
  }
  func @print_memref_f32(memref<*xf32>)
  func @array_times_2() {
    %0 = alloc() : memref<4xf32>
    call @rise_fun(%0) : (memref<4xf32>) -> ()
    %1 = memref_cast %0 : memref<4xf32> to memref<*xf32>
    call @print_memref_f32(%1) : (memref<*xf32>) -> ()
    return
  }
}
```


            |       Lowering to Imperative: mlir-opt reduce.mlir -convert-rise-to-imperative        
            |           Dialect Conversion: (rise)              -> (std x loop x linalg) 
            |           rise.fun                                -> @riseFun(): () -> (memref) ... call @riseFun
            |           rise.literal                            -> alloc() : memref ... linalg.fill
            |           rise.map ... rise.apply ... rise.apply  -> loop.for
            |           rise.lambda{rise.add} //cheated for now -> load... addf ... store 
            V
```C++

```

            |       Lowering to LLVM IR
            |           -convert-linalg-to-loops
            |           -convert-loop-to-std
            |           -convert-std-to-llvm
            V

```Bash
```

