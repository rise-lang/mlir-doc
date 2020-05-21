[index](../README.md)

### Here we show how our lowering approach works on different examples 
note: keep in mind that the rise intermediate codegen representation is internal to the lowering and will never be emitted finally.
note: all results here are before canonicalization, which e.g eleminates duplicate constants and moves them out of loops.

### reduce
```C++
func @reduce(%outArg:memref<1xf32>, %inArg:memref<1024xf32>) {
    %array0 = rise.in %inArg : !rise.array<1024, scalar<f32>>

    %reductionAdd = rise.lambda (%summand0 : !rise.scalar<f32>, %summand1 : !rise.scalar<f32>) -> !rise.scalar<f32> {
        %result = rise.embed(%summand0, %summand1) {
            %result = addf %summand0, %summand1 : f32
            rise.return %result : f32
        }
        rise.return %result : !rise.scalar<f32>
    }
    %initializer = rise.literal #rise.lit<0.0>
    %reduce4Ints = rise.reduceSeq #rise.nat<1024> #rise.scalar<f32> #rise.scalar<f32>
    %result = rise.apply %reduce4Ints, %reductionAdd, %initializer, %array0
    rise.out %outArg <- %result
    return
}
```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
func @reduce(%arg0: memref<1xf32>, %arg1: memref<1024xf32>) {
  %c0 = constant 0 : index
  %cst = constant 0.000000e+00 : f32
  %c0_0 = constant 0 : index
  %c1024 = constant 1024 : index
  %c1 = constant 1 : index
  %0 = "rise.codegen.idx"(%arg0, %c0) : (memref<1xf32>, index) -> f32
  "rise.codegen.assign"(%cst, %0) : (f32, f32) -> ()
  scf.for %arg2 = %c0_0 to %c1024 step %c1 {
    %5 = "rise.codegen.idx"(%arg1, %arg2) : (memref<1024xf32>, index) -> f32
    %8 = "rise.codegen.idx"(%arg0, %c0) : (memref<1xf32>, index) -> f32
    %9 = addf %6, %7 : f32
    "rise.codegen.assign"(%9, %8) : (f32, f32) -> ()
  }
  return
}
```

```
        |       Lowering to Imperative: mlir-opt reduce.mlir -convert-rise-to-imperative        
        |           Dialect Conversion: (rise)              -> (std x scf x linalg) 
        |           rise.fun                                -> @riseFun(): (memref) -> () ... call @riseFun
        |           rise.literal                            -> alloc() : memref ... linalg.fill
        |           rise.map ... rise.apply ... rise.apply  -> scf.for
        |           rise.lambda{rise.add}                   -> rise.bin_op ... rise.assign
        V
```

```C++
  func @reduce(%arg0: memref<1xf32>, %arg1: memref<1024xf32>) {
    %c0 = constant 0 : index
    %cst = constant 0.000000e+00 : f32
    store %cst, %arg0[%c0] : memref<1xf32>
    %c0_0 = constant 0 : index
    %c1024 = constant 1024 : index
    %c1 = constant 1 : index
    scf.for %arg2 = %c0_0 to %c1024 step %c1 {
      %0 = load %arg1[%arg2] : memref<1024xf32>
      %1 = load %arg0[%c0] : memref<1xf32>
      %2 = addf %0, %1 : f32
      store %2, %arg0[%c0] : memref<1xf32>
    }
    return
  }
```

### map_add
```C++
func @map_add(%outArg: memref<4xf32>, %in: memref<4xf32>) {
    %array = rise.in %in : !rise.array<4, scalar<f32>>
    %doubleFun = rise.lambda (%summand : !rise.scalar<f32>) -> !rise.scalar<f32> {
        %result = rise.embed(%summand) {
            %doubled = addf %summand, %summand : f32
            rise.return %doubled : f32
        }
        rise.return %result : !rise.scalar<f32>
    }
    %map = rise.mapSeq {to = "loop"} #rise.nat<4> #rise.scalar<f32> #rise.scalar<f32>
    %doubledArray = rise.apply %map, %doubleFun, %array
    rise.out %outArg <- %doubledArray
    return
}

```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
func @map_add(%arg0: memref<4xf32>, %arg1: memref<4xf32>) {
  %c0 = constant 0 : index
  %c0_0 = constant 0 : index
  %c4 = constant 4 : index
  %c1 = constant 1 : index
  scf.for %arg2 = %c0_0 to %c4 step %c1 {
    %3 = "rise.codegen.idx"(%arg1, %arg2) : (memref<4xf32>, index) -> memref<f32>
    %4 = "rise.codegen.idx"(%arg0, %arg2) : (memref<4xf32>, index) -> memref<f32>
    %5 = "std.addf"(%3, %3) : (memref<f32>, memref<f32>) -> f32
    "rise.codegen.assign"(%5, %4) : (f32, memref<f32>) -> ()
  }
  return
}
```

```
        |       Lowering to Imperative: mlir-opt map_add.mlir -convert-rise-to-imperative        
        |           Dialect Conversion: (rise)              -> (std x scf x linalg) 
        |           rise.fun                                -> @riseFun(): (memref) -> () ... call @riseFun
        |           rise.literal                            -> alloc() : memref ... linalg.fill
        |           rise.map ... rise.apply ... rise.apply  -> scf.for
        |           rise.lambda{rise.add}                   -> rise.bin_op ... rise.assign
        V
```

```C++
func @map_add(%arg0: memref<4xf32>, %arg1: memref<4xf32>) {
   %c0 = constant 0 : index
   %c0_0 = constant 0 : index
   %c4 = constant 4 : index
   %c1 = constant 1 : index
   scf.for %arg2 = %c0_0 to %c4 step %c1 {
     %0 = load %arg1[%arg2] : memref<4xf32>
     %1 = load %arg1[%arg2] : memref<4xf32>
     %2 = addf %0, %1 : f32
     store %2, %arg0[%arg2] : memref<4xf32>
   }
  return
}
```

### 4D_map_add
```C++
func @4D_map_add(%outArg:memref<4x4x4x4xf32>, %inArg:memref<4x4x4x4xf32>) {
    %array3D = rise.in %inArg : !rise.array<4, array<4, array<4, array<4, scalar<f32>>>>>
    %doubleFun = rise.lambda (%summand : !rise.scalar<f32>) -> !rise.scalar<f32> {
        %addFun = rise.add #rise.scalar<f32>
        %doubled = rise.apply %addFun, %summand, %summand //: !rise.fun<data<scalar<f32>> -> fun<data<scalar<f32>> -> data<scalar<f32>>>>, %summand, %summand
        rise.return %doubled : !rise.scalar<f32>
    }
    %map1 = rise.mapSeq #rise.nat<4> #rise.array<4, array<4, array<4, scalar<f32>>>> #rise.array<4, array<4, array<4, scalar<f32>>>>
    %mapInnerLambda_1 = rise.lambda (%arraySlice_1 : !rise.array<4, array<4, array<4, scalar<f32>>>>) -> !rise.array<4, array<4, array<4, scalar<f32>>>> {
        %map2 = rise.mapSeq #rise.nat<4> #rise.array<4, array<4, scalar<f32>>> #rise.array<4, array<4, scalar<f32>>>
        %mapInnerLambda_2 = rise.lambda (%arraySlice_2 : !rise.array<4, array<4, scalar<f32>>>) -> !rise.array<4, array<4, scalar<f32>>> {
            %map3 = rise.mapSeq #rise.nat<4> #rise.array<4, scalar<f32>> #rise.array<4, scalar<f32>>
                %mapInnerLambda_3 = rise.lambda (%arraySlice_3 : !rise.array<4, scalar<f32>>) -> !rise.array<4, scalar<f32>> {
                    %map4 = rise.mapSeq #rise.nat<4> #rise.scalar<f32> #rise.scalar<f32>
                    %res = rise.apply %map4, %doubleFun, %arraySlice_3
                    rise.return %res : !rise.array<4, scalar<f32>>
                }
            %res = rise.apply %map3, %mapInnerLambda_3, %arraySlice_2
            rise.return %res : !rise.array<4, array<4, scalar<f32>>>
        }
       %res = rise.apply %map2, %mapInnerLambda_2, %arraySlice_1
       rise.return %res : !rise.array<4, array<4, array<4, scalar<f32>>>>
    }
    %res = rise.apply %map1, %mapInnerLambda_1, %array3D
    rise.out %outArg <- %res
    return
}

```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
func @4D_map_add(%arg0: memref<4x4x4x4xf32>, %arg1: memref<4x4x4x4xf32>) {
  %c0 = constant 0 : index
  %c0_0 = constant 0 : index
  %c4 = constant 4 : index
  %c1 = constant 1 : index
  scf.for %arg2 = %c0_0 to %c4 step %c1 {
    %4 = "rise.codegen.idx"(%arg1, %arg2) : (memref<4x4x4x4xf32>, index) -> memref<4x4x4xf32>
    %5 = "rise.codegen.idx"(%arg0, %arg2) : (memref<4x4x4x4xf32>, index) -> memref<4x4x4xf32>
    %c0_1 = constant 0 : index
    %c0_2 = constant 0 : index
    %c4_3 = constant 4 : index
    %c1_4 = constant 1 : index
    scf.for %arg3 = %c0_2 to %c4_3 step %c1_4 {
      %6 = "rise.codegen.idx"(%4, %arg3) : (memref<4x4x4xf32>, index) -> memref<4x4xf32>
      %7 = "rise.codegen.idx"(%5, %arg3) : (memref<4x4x4xf32>, index) -> memref<4x4xf32>
      %c0_5 = constant 0 : index
      %c0_6 = constant 0 : index
      %c4_7 = constant 4 : index
      %c1_8 = constant 1 : index
      scf.for %arg4 = %c0_6 to %c4_7 step %c1_8 {
        %8 = "rise.codegen.idx"(%6, %arg4) : (memref<4x4xf32>, index) -> memref<4xf32>
        %9 = "rise.codegen.idx"(%7, %arg4) : (memref<4x4xf32>, index) -> memref<4xf32>
        %c0_9 = constant 0 : index
        %c0_10 = constant 0 : index
        %c4_11 = constant 4 : index
        %c1_12 = constant 1 : index
        scf.for %arg5 = %c0_10 to %c4_11 step %c1_12 {
          %10 = "rise.codegen.idx"(%8, %arg5) : (memref<4xf32>, index) -> memref<f32>
          %11 = "rise.codegen.idx"(%9, %arg5) : (memref<4xf32>, index) -> memref<f32>
          %12 = "rise.codegen.bin_op"(%10, %10) {op = "add"} : (memref<f32>, memref<f32>) -> f32
          "rise.codegen.assign"(%12, %11) : (f32, memref<f32>) -> ()
        }
      }
    }
  }
  return
}
```

```
        |       Lowering to Imperative: mlir-opt 4D_map_add.mlir -convert-rise-to-imperative        
        |           Dialect Conversion: (rise)              -> (std x scf x linalg) 
        |           rise.fun                                -> @riseFun(): (memref) -> () ... call @riseFun
        |           rise.literal                            -> alloc() : memref ... linalg.fill
        |           rise.map ... rise.apply ... rise.apply  -> scf.for
        |           rise.lambda{rise.add}                   -> rise.bin_op ... rise.assign
        V
```

```C++
  func @4D_map_add(%arg0: memref<4x4x4x4xf32>, %arg1: memref<4x4x4x4xf32>) {
    %c0 = constant 0 : index
    %c0_0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    scf.for %arg2 = %c0_0 to %c4 step %c1 {
      %c0_1 = constant 0 : index
      %c0_2 = constant 0 : index
      %c4_3 = constant 4 : index
      %c1_4 = constant 1 : index
      scf.for %arg3 = %c0_2 to %c4_3 step %c1_4 {
        %c0_5 = constant 0 : index
        %c0_6 = constant 0 : index
        %c4_7 = constant 4 : index
        %c1_8 = constant 1 : index
        scf.for %arg4 = %c0_6 to %c4_7 step %c1_8 {
          %c0_9 = constant 0 : index
          %c0_10 = constant 0 : index
          %c4_11 = constant 4 : index
          %c1_12 = constant 1 : index
          scf.for %arg5 = %c0_10 to %c4_11 step %c1_12 {
            %0 = load %arg1[%arg5, %arg4, %arg3, %arg2] : memref<4x4x4x4xf32>
            %1 = load %arg1[%arg5, %arg4, %arg3, %arg2] : memref<4x4x4x4xf32>
            %2 = addf %0, %1 : f32
            store %2, %arg0[%arg5, %arg4, %arg3, %arg2] : memref<4x4x4x4xf32>
          }
        }
      }
    }
    return
  }
```

```
        |          
        |   -canonicalize
        V
```

```C++
  func @4D_map_add(%arg0: memref<4x4x4x4xf32>, %arg1: memref<4x4x4x4xf32>) {
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    scf.for %arg2 = %c0 to %c4 step %c1 {
      scf.for %arg3 = %c0 to %c4 step %c1 {
        scf.for %arg4 = %c0 to %c4 step %c1 {
          scf.for %arg5 = %c0 to %c4 step %c1 {
            %0 = load %arg1[%arg5, %arg4, %arg3, %arg2] : memref<4x4x4x4xf32>
            %1 = load %arg1[%arg5, %arg4, %arg3, %arg2] : memref<4x4x4x4xf32>
            %2 = addf %0, %1 : f32
            store %2, %arg0[%arg5, %arg4, %arg3, %arg2] : memref<4x4x4x4xf32>
          }
        }
      }
    }
    return
  }
```

### fst (projection)
```C++
func @fst(%outArg:memref<4xf32>, %inArg0:memref<4xf32>, %inArg1:memref<4xf32>) {
    %array0 = rise.in %inArg0 : !rise.array<4, scalar<f32>>
    %array1 = rise.in %inArg1 : !rise.array<4, scalar<f32>>

    %zipFun = rise.zip #rise.nat<4> #rise.scalar<f32> #rise.scalar<f32>
    %zipped = rise.apply %zipFun, %array0, %array1

    %projectToFirst = rise.lambda (%floatTuple : !rise.tuple<scalar<f32>, scalar<f32>>) -> !rise.scalar<f32> {
        %fstFun = rise.fst #rise.scalar<f32> #rise.scalar<f32>
        %fst = rise.apply %fstFun, %floatTuple
        rise.return %fst : !rise.scalar<f32>
    }

    %mapFun = rise.mapSeq #rise.nat<4> #rise.tuple<scalar<f32>, scalar<f32>> #rise.scalar<f32>
    %fstArray = rise.apply %mapFun, %projectToFirst, %zipped
    rise.out %outArg <- %fstArray
    return
}

```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
func @fst(%arg0: memref<4xf32>, %arg1: memref<4xf32>, %arg2: memref<4xf32>) {
  %0 = "rise.codegen.zip"(%arg1, %arg2) : (memref<4xf32>, memref<4xf32>) -> memref<4xf32>
  %c0 = constant 0 : index
  %c0_0 = constant 0 : index
  %c4 = constant 4 : index
  %c1 = constant 1 : index
  scf.for %arg3 = %c0_0 to %c4 step %c1 {
    %6 = "rise.codegen.idx"(%0, %arg3) : (memref<4xf32>, index) -> memref<f32>
    %7 = "rise.codegen.idx"(%arg0, %arg3) : (memref<4xf32>, index) -> memref<f32>
    %8 = "rise.codegen.fst"(%6) : (memref<f32>) -> f32
    "rise.codegen.assign"(%8, %7) : (f32, memref<f32>) -> ()
  }
  return
}
```

```
        |       Lowering to Imperative: mlir-opt fst.mlir -convert-rise-to-imperative        
        |           Dialect Conversion: (rise)              -> (std x scf x linalg) 
        |           rise.fun                                -> @riseFun(): (memref) -> () ... call @riseFun
        |           rise.literal                            -> alloc() : memref ... linalg.fill
        |           rise.map ... rise.apply ... rise.apply  -> scf.for
        |           rise.lambda{rise.add}                   -> rise.bin_op ... rise.assign
        V
```

```C++
  func @fst(%arg0: memref<4xf32>, %arg1: memref<4xf32>, %arg2: memref<4xf32>) {
    %c0 = constant 0 : index
    %c0_0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    scf.for %arg3 = %c0_0 to %c4 step %c1 {
      %0 = load %arg1[%arg3] : memref<4xf32>
      store %0, %arg0[%arg3] : memref<4xf32>
    }
    return
  }
```

### vector addition
```C++
func @vec_add(%outArg:memref<4xf32>, %inArg0:memref<4xf32>, %inArg1:memref<4xf32>) {
    %array0 = rise.in %inArg0 : !rise.array<4, scalar<f32>>
    %array1 = rise.in %inArg1 : !rise.array<4, scalar<f32>>

    %zipFun = rise.zip #rise.nat<4> #rise.scalar<f32> #rise.scalar<f32>
    %zipped = rise.apply %zipFun, %array0, %array1

    %tupleAddFun = rise.lambda (%floatTuple : !rise.tuple<scalar<f32>, scalar<f32>>) -> !rise.scalar<f32> {
        %fstFun = rise.fst #rise.scalar<f32> #rise.scalar<f32>
        %sndFun = rise.snd #rise.scalar<f32> #rise.scalar<f32>

        %fst = rise.apply %fstFun, %floatTuple
        %snd = rise.apply %sndFun, %floatTuple
        %result = rise.embed(%fst, %snd) {
            %result = addf %fst, %snd : f32
            rise.return %result : f32
        }
        rise.return %result : !rise.scalar<f32>
    }

    %mapFun = rise.mapSeq #rise.nat<4> #rise.tuple<scalar<f32>, scalar<f32>> #rise.scalar<f32>
    %sumArray = rise.apply %mapFun, %tupleAddFun, %zipped
    rise.out %outArg <- %sumArray
    return
}

```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
func @vec_add(%arg0: memref<4xf32>, %arg1: memref<4xf32>, %arg2: memref<4xf32>) {
  %0 = "rise.codegen.zip"(%arg1, %arg2) : (memref<4xf32>, memref<4xf32>) -> memref<4xf32>
  %c0 = constant 0 : index
  %c0_0 = constant 0 : index
  %c4 = constant 4 : index
  %c1 = constant 1 : index
  scf.for %arg3 = %c0_0 to %c4 step %c1 {
    %6 = "rise.codegen.idx"(%0, %arg3) : (memref<4xf32>, index) -> memref<f32>
    %7 = "rise.codegen.idx"(%arg0, %arg3) : (memref<4xf32>, index) -> memref<f32>
    %8 = "rise.codegen.fst"(%6) : (memref<f32>) -> f32
    %9 = "rise.codegen.snd"(%6) : (memref<f32>) -> f32
    %10 = addf %8, %9 : f32
    "rise.codegen.assign"(%10, %7) : (f32, memref<f32>) -> ()
  }
  return
}
```

```
        |       Lowering to Imperative: mlir-opt vec_add.mlir -convert-rise-to-imperative        
        |           Dialect Conversion: (rise)              -> (std x scf x linalg) 
        |           rise.fun                                -> @riseFun(): (memref) -> () ... call @riseFun
        |           rise.literal                            -> alloc() : memref ... linalg.fill
        |           rise.map ... rise.apply ... rise.apply  -> scf.for
        |           rise.lambda{rise.add}                   -> rise.bin_op ... rise.assign
        V
```

```C++
  func @vec_add(%arg0: memref<4xf32>, %arg1: memref<4xf32>, %arg2: memref<4xf32>) {
    %c0 = constant 0 : index
    %c0_0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    scf.for %arg3 = %c0_0 to %c4 step %c1 {
      %0 = load %arg1[%arg3] : memref<4xf32>
      %1 = load %arg2[%arg3] : memref<4xf32>
      %2 = addf %0, %1 : f32
      store %2, %arg0[%arg3] : memref<4xf32>
    }
    return
  }
```

### dot_fused
```C++
func @dot_fused(%outArg:memref<1xf32>, %inArg0:memref<1024xf32>, %inArg1:memref<1024xf32>)  {
    //Arrays
    %array0 = rise.in %inArg0 : !rise.array<1024, scalar<f32>>
    %array1 = rise.in %inArg1 : !rise.array<1024, scalar<f32>>

    //Zipping
    %zipFun = rise.zip #rise.nat<1024> #rise.scalar<f32> #rise.scalar<f32>
    %zippedArrays = rise.apply %zipFun, %array0, %array1

    //Reduction
    %reductionLambda = rise.lambda (%tuple : !rise.tuple<scalar<f32>, scalar<f32>>, %acc : !rise.scalar<f32>) -> !rise.scalar<f32> {

        %fstFun = rise.fst #rise.scalar<f32> #rise.scalar<f32>
        %sndFun = rise.snd #rise.scalar<f32> #rise.scalar<f32>

        %fst = rise.apply %fstFun, %tuple
        %snd = rise.apply %sndFun, %tuple

        %result = rise.embed(%fst, %snd, %acc) {
               %product = mulf %fst, %snd :f32
               %result = addf %product, %acc : f32
               rise.return %result : f32
        }

        rise.return %result : !rise.scalar<f32>
    }

    %initializer = rise.literal #rise.lit<0.0>
    %reduceFun = rise.reduceSeq #rise.nat<1024> #rise.tuple<scalar<f32>, scalar<f32>> #rise.scalar<f32>
    %result = rise.apply %reduceFun, %reductionLambda, %initializer, %zippedArrays
    rise.out %outArg <- %result
    return
}

```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
func @dot_fused(%arg0: memref<1xf32>, %arg1: memref<1024xf32>, %arg2: memref<1024xf32>) {
  %0 = "rise.codegen.zip"(%arg1, %arg2) : (memref<1024xf32>, memref<1024xf32>) -> memref<4xf32>
  %c0 = constant 0 : index
  %cst = constant 0.000000e+00 : f32
  %1 = "rise.codegen.idx"(%arg0, %c0) : (memref<1xf32>, index) -> f32
  "rise.codegen.assign"(%cst, %1) : (f32, f32) -> ()
  %c0_0 = constant 0 : index
  %c1024 = constant 1024 : index
  %c1 = constant 1 : index
  scf.for %arg3 = %c0_0 to %c1024 step %c1 {
    %8 = "rise.codegen.idx"(%0, %arg3) : (memref<4xf32>, index) -> f32
    %9 = "rise.codegen.idx"(%arg0, %c0) : (memref<1xf32>, index) -> f32
    %10 = "rise.codegen.fst"(%8) : (f32) -> f32
    %11 = "rise.codegen.snd"(%8) : (f32) -> f32
    %12 = mulf %10, %11 : f32
    %13 = addf %12, %9 : f32
    "rise.codegen.assign"(%13, %9) : (f32, f32) -> ()
  }
  return
}
```

```
        |       Lowering to Imperative: mlir-opt dot_fused.mlir -convert-rise-to-imperative        
        |           Dialect Conversion: (rise)              -> (std x scf x linalg) 
        |           rise.fun                                -> @riseFun(): (memref) -> () ... call @riseFun
        |           rise.literal                            -> alloc() : memref ... linalg.fill
        |           rise.map ... rise.apply ... rise.apply  -> scf.for
        |           rise.lambda{rise.add}                   -> rise.bin_op ... rise.assign
        V
```

```C++
  func @dot_fused(%arg0: memref<1xf32>, %arg1: memref<1024xf32>, %arg2: memref<1024xf32>) {
    %cst = constant 0.000000e+00 : f32
    %c0 = constant 0 : index
    %c1024 = constant 1024 : index
    %c1 = constant 1 : index
    store %cst, %arg0[%c0] : memref<1xf32>
    scf.for %arg3 = %c0 to %c1024 step %c1 {
      %0 = load %arg1[%arg3] : memref<1024xf32>
      %1 = load %arg2[%arg3] : memref<1024xf32>
      %2 = load %arg0[%c0] : memref<1xf32>
      %3 = mulf %0, %1 : f32
      %4 = addf %3, %2 : f32
      store %4, %arg0[%c0] : memref<1xf32>
    }
    return
  }
```

### mm_fused
```C++
func @rise_fun(%outArg:memref<2048x2048xf32>, %inA:memref<2048x2048xf32>, %inB:memref<2048x2048xf32>) {
    %A = rise.in %inA : !rise.array<2048, array<2048, scalar<f32>>>
    %B = rise.in %inB : !rise.array<2048, array<2048, scalar<f32>>>

    %m1fun = rise.lambda (%arow : !rise.array<2048, scalar<f32>>) -> !rise.array<2048, scalar<f32>> {
        %m2fun = rise.lambda (%bcol : !rise.array<2048, scalar<f32>>) -> !rise.array<2048, scalar<f32>> {

            //Zipping
            %zipFun = rise.zip #rise.nat<2048> #rise.scalar<f32> #rise.scalar<f32>
            %zippedArrays = rise.apply %zipFun, %arow, %bcol

            //Reduction
            %reductionLambda = rise.lambda (%tuple : !rise.tuple<scalar<f32>, scalar<f32>>, %acc : !rise.scalar<f32>) -> !rise.scalar<f32> {

                %fstFun = rise.fst #rise.scalar<f32> #rise.scalar<f32>
                %sndFun = rise.snd #rise.scalar<f32> #rise.scalar<f32>

                %fst = rise.apply %fstFun, %tuple
                %snd = rise.apply %sndFun, %tuple

                %result = rise.embed(%fst, %snd, %acc) {
                       %product = mulf %fst, %snd :f32
                       %result = addf %product, %acc : f32
                       rise.return %result : f32
                }
                rise.return %result : !rise.scalar<f32>
            }

            %initializer = rise.literal #rise.lit<0.0>
            %reduceFun = rise.reduceSeq {to = "loop"}  #rise.nat<2048> #rise.tuple<scalar<f32>, scalar<f32>> #rise.scalar<f32>
            %result = rise.apply %reduceFun, %reductionLambda, %initializer, %zippedArrays

            rise.return %result : !rise.scalar<f32>
        }
        %m2 = rise.mapSeq {to = "loop"}  #rise.nat<2048> #rise.array<2048, scalar<f32>> #rise.array<2048, scalar<f32>>
        %result = rise.apply %m2, %m2fun, %B
        rise.return %result : !rise.array<2048, array<2048, scalar<f32>>>
    }
    %m1 = rise.mapSeq {to = "loop"}  #rise.nat<2048> #rise.array<2048, scalar<f32>> #rise.array<2048, scalar<f32>>
    %result = rise.apply %m1, %m1fun, %A
    rise.out %outArg <- %result
    return
}

```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
func @mm_fused(%arg0: memref<2048x2048xf32>, %arg1: memref<2048x2048xf32>, %arg2: memref<2048x2048xf32>) {
  %c0 = constant 0 : index
  %c0_0 = constant 0 : index
  %c2048 = constant 2048 : index
  %c1 = constant 1 : index
  scf.for %arg3 = %c0_0 to %c2048 step %c1 {
    %3 = "rise.codegen.idx"(%arg1, %arg3) : (memref<2048x2048xf32>, index) -> memref<2048xf32>
    %4 = "rise.codegen.idx"(%arg0, %arg3) : (memref<2048x2048xf32>, index) -> memref<2048xf32>
    %c0_1 = constant 0 : index
    %c0_2 = constant 0 : index
    %c2048_3 = constant 2048 : index
    %c1_4 = constant 1 : index
    scf.for %arg4 = %c0_2 to %c2048_3 step %c1_4 {
      %5 = "rise.codegen.idx"(%arg2, %arg4) : (memref<2048x2048xf32>, index) -> memref<2048xf32>
      %6 = "rise.codegen.idx"(%4, %arg4) : (memref<2048xf32>, index) -> memref<2048xf32>
      %7 = "rise.codegen.zip"(%3, %5) : (memref<2048xf32>, memref<2048xf32>) -> memref<4xf32>
      %c0_5 = constant 0 : index
      %cst = constant 0.000000e+00 : f32
      %8 = "rise.codegen.idx"(%6, %c0_5) : (memref<2048xf32>, index) -> f32
      "rise.codegen.assign"(%cst, %8) : (f32, f32) -> ()
      %c0_6 = constant 0 : index
      %c2048_7 = constant 2048 : index
      %c1_8 = constant 1 : index
      scf.for %arg5 = %c0_6 to %c2048_7 step %c1_8 {
        %9 = "rise.codegen.idx"(%7, %arg5) : (memref<4xf32>, index) -> f32
        %10 = "rise.codegen.idx"(%6, %c0_5) : (memref<2048xf32>, index) -> f32
        %11 = "rise.codegen.fst"(%9) : (f32) -> f32
        %12 = "rise.codegen.snd"(%9) : (f32) -> f32
        %13 = mulf %11, %12 : f32
        %14 = addf %13, %10 : f32
        "rise.codegen.assign"(%14, %10) : (f32, f32) -> ()
      }
    }
  }
  return
}
```

```
        |       Lowering to Imperative: mlir-opt mm_fused.mlir -convert-rise-to-imperative        
        |           Dialect Conversion: (rise)              -> (std x scf x linalg) 
        |           rise.fun                                -> @riseFun(): (memref) -> () ... call @riseFun
        |           rise.literal                            -> alloc() : memref ... linalg.fill
        |           rise.map ... rise.apply ... rise.apply  -> scf.for
        |           rise.lambda{rise.add}                   -> rise.bin_op ... rise.assign
        V
```

```C++
  func @mm_fused(%arg0: memref<2048x2048xf32>, %arg1: memref<2048x2048xf32>, %arg2: memref<2048x2048xf32>) {
    %c0 = constant 0 : index
    %c0_0 = constant 0 : index
    %c2048 = constant 2048 : index
    %c1 = constant 1 : index
    scf.for %arg3 = %c0_0 to %c2048 step %c1 {
      %c0_1 = constant 0 : index
      %c0_2 = constant 0 : index
      %c2048_3 = constant 2048 : index
      %c1_4 = constant 1 : index
      scf.for %arg4 = %c0_2 to %c2048_3 step %c1_4 {
        %c0_5 = constant 0 : index
        %cst = constant 0.000000e+00 : f32
        store %cst, %arg0[%arg4, %arg3] : memref<2048x2048xf32>
        %c0_6 = constant 0 : index
        %c2048_7 = constant 2048 : index
        %c1_8 = constant 1 : index
        scf.for %arg5 = %c0_6 to %c2048_7 step %c1_8 {
          %0 = load %arg1[%arg5, %arg3] : memref<2048x2048xf32>
          %1 = load %arg2[%arg5, %arg4] : memref<2048x2048xf32>
          %2 = load %arg0[%arg4, %arg3] : memref<2048x2048xf32>
          %3 = mulf %0, %1 : f32
          %4 = addf %3, %2 : f32
          store %4, %arg0[%arg4, %arg3] : memref<2048x2048xf32>
        }
      }
    }
    return
  }
```

```
        |          
        |   -canonicalize
        V
```

```C++
  func @rise_fun(%arg0: memref<2048x2048xf32>, %arg1: memref<2048x2048xf32>, %arg2: memref<2048x2048xf32>) {
    %cst = constant 0.000000e+00 : f32
    %c0 = constant 0 : index
    %c2048 = constant 2048 : index
    %c1 = constant 1 : index
    scf.for %arg3 = %c0 to %c2048 step %c1 {
      scf.for %arg4 = %c0 to %c2048 step %c1 {
        store %cst, %arg0[%arg4, %arg3] : memref<2048x2048xf32>
        scf.for %arg5 = %c0 to %c2048 step %c1 {
          %0 = load %arg1[%arg5, %arg3] : memref<2048x2048xf32>
          %1 = load %arg2[%arg5, %arg4] : memref<2048x2048xf32>
          %2 = load %arg0[%arg4, %arg3] : memref<2048x2048xf32>
          %3 = mulf %0, %1 : f32
          %4 = addf %3, %2 : f32
          store %4, %arg0[%arg4, %arg3] : memref<2048x2048xf32>
        }
      }
    }
    return
  }
```

