[index](../README.md)
# Lowering a simple 2D map

##### initial rise_mlir code
```C++
func @print_memref_f32(memref<*xf32>)
func @rise_fun(memref<4x4xf32>)
func @mapMapId() {

    rise.fun "rise_fun" (%outArg:memref<4x4xf32>) {
        %array2D = rise.literal #rise.lit<array<4.4, !rise.float, [[5,5,5,5], [5,5,5,5], [5,5,5,5], [5,5,5,5]]>>
        %doubleFun = rise.lambda (%summand) : !rise.fun<data<float> -> data<float>> {
            %addFun = rise.add #rise.float
            %doubled = rise.apply %addFun, %summand, %summand //: !rise.fun<data<float> -> fun<data<float> -> data<float>>>, %summand, %summand
            rise.return %doubled : !rise.data<float>
        }
        %map1 = rise.map #rise.nat<4> #rise.array<4, !rise.float> #rise.array<4, !rise.float>

        %mapInnerLambda = rise.lambda (%arraySlice) : !rise.fun<data<array<4, float>> -> data<array<4, float>>> {
           %map2 = rise.map #rise.nat<4> #rise.float #rise.float
           %res = rise.apply %map2, %doubleFun, %arraySlice
           rise.return %res : !rise.data<array<4, float>>
        }
        %res = rise.apply %map1, %mapInnerLambda, %array2D

        rise.return %res: !rise.data<array<4, array<4, float>>>
    }

    //prepare output Array
    %outputArray = alloc() : memref<4x4xf32>
    call @rise_fun(%outputArray) : (memref<4x4xf32>) -> ()

    %print_me = memref_cast %outputArray : memref<4x4xf32> to memref<*xf32>
    call @print_memref_f32(%print_me): (memref<*xf32>) -> ()
    return
}
```

            |       Lowering (almost) to imperative, but leaving intermediate ops inside
            |           Dialect Conversion: (rise)              -> (std x loop x linalg) 
            |           rise.fun                                -> @riseFun(): () -> (memref) ... call @riseFun
            |           rise.literal                            -> alloc() : memref ... linalg.fill
            |           rise.map ... rise.apply ... rise.apply  -> loop.for
            |           
            V
```C++
module {
  func @rise_fun(%arg0: memref<4x4xf32>) {
    %0 = alloc() : memref<4x4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4x4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %1 = "rise.idx"(%0, %arg1) : (memref<4x4xf32>, index) -> memref<4xf32>
      %2 = "rise.idx"(%arg0, %arg1) : (memref<4x4xf32>, index) -> memref<4xf32>
      %c0_0 = constant 0 : index
      %c4_1 = constant 4 : index
      %c1_2 = constant 1 : index
      loop.for %arg2 = %c0_0 to %c4_1 step %c1_2 {
        %3 = "rise.idx"(%1, %arg2) : (memref<4xf32>, index) -> memref<f32>
        %4 = "rise.idx"(%2, %arg2) : (memref<4xf32>, index) -> memref<f32>
        %5 = "rise.bin_op"(%3, %3) : (memref<f32>, memref<f32>) -> f32
        "rise.assign"(%5, %4) : (f32, memref<f32>) -> ()
      }
    }
    return
  }
  func @print_memref_f32(memref<*xf32>)
  func @mapMapId() {
    %0 = alloc() : memref<4x4xf32>
    call @rise_fun(%0) : (memref<4x4xf32>) -> ()
    %1 = memref_cast %0 : memref<4x4xf32> to memref<*xf32>
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
module {
  func @rise_fun(%arg0: memref<4x4xf32>) {
    %0 = alloc() : memref<4x4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4x4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %c0_0 = constant 0 : index
      %c4_1 = constant 4 : index
      %c1_2 = constant 1 : index
      loop.for %arg2 = %c0_0 to %c4_1 step %c1_2 {
        %1 = load %0[%arg2, %arg1] : memref<4x4xf32>
        %2 = load %0[%arg2, %arg1] : memref<4x4xf32>
        %3 = addf %1, %2 : f32
        store %3, %arg0[%arg2, %arg1] : memref<4x4xf32>
      }
    }
    return
  }
  func @print_memref_f32(memref<*xf32>)
  func @mapMapId() {
    %0 = alloc() : memref<4x4xf32>
    call @rise_fun(%0) : (memref<4x4xf32>) -> ()
    %1 = memref_cast %0 : memref<4x4xf32> to memref<*xf32>
    call @print_memref_f32(%1) : (memref<*xf32>) -> ()
    return
  }
}
```

            |       Lowering to LLVM IR
            |           -convert-linalg-to-loops
            |           -convert-loop-to-std
            |           -convert-std-to-llvm
            V

```Bash
mlir-opt map_map_add.mlir -convert-rise-to-imperative -convert-linalg-to-loops -convert-loop-to-std -convert-std-to-llvm | mlir-cpu-runner -e mapMapId -entry-point-result=void -shared-libs=libmlir_runner_utils.so
Unranked Memref rank = 2 descriptor@ = 0x7ffdd42828e0
Memref base@ = 0x561ea2598830 rank = 2 offset = 0 sizes = [4, 4] strides = [4, 1] data = 
[[10,   10,   10,   10], 
 [10,   10,   10,   10], 
 [10,   10,   10,   10], 
 [10,   10,   10,   10]]
```

