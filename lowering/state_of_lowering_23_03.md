[index](../README.md)


### We can translate:
- map add
- map map add 
- map map map add
- map map map map (...?) add
- zip map fst/snd (projection)
- zip map add 
- reduce
- dot
- mm

- We can now take inputs to our functions from outside.
- casting an outside input to our type system is accomplished with rise.in

    Example: map add
```C++
    rise.fun "rise_fun" (%outArg:memref<4xf32>, %in:memref<4xf32>) {
        %array = rise.in %in : !rise.data<array<4, float>>
        %doubleFun = rise.lambda (%summand) : !rise.fun<data<float> -> data<float>> {
            %addFun = rise.add #rise.float
            %doubled = rise.apply %addFun, %summand, %summand
            rise.return %doubled : !rise.data<float>
        }
        %map4IntsToInts = rise.map #rise.nat<4> #rise.float #rise.float
        %doubledArray = rise.apply %map4IntsToInts, %doubleFun, %array

        rise.return %doubledArray : !rise.data<array<4, float>>
    }
```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
  func @rise_fun(%arg0: memref<4xf32>, %arg1: memref<4xf32>) {
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg2 = %c0 to %c4 step %c1 {
      %0 = "rise.codegen.idx"(%arg1, %arg2) : (memref<4xf32>, index) -> memref<f32>
      %1 = "rise.codegen.idx"(%arg0, %arg2) : (memref<4xf32>, index) -> memref<f32>
      %2 = "rise.codegen.bin_op"(%0, %0) {op = "add"} : (memref<f32>, memref<f32>) -> f32
      "rise.codegen.assign"(%2, %1) : (f32, memref<f32>) -> ()
    }
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
   
```C++
  func @rise_fun(%arg0: memref<4xf32>, %arg1: memref<4xf32>) {
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg2 = %c0 to %c4 step %c1 {
      %0 = load %arg1[%arg2] : memref<4xf32>
      %1 = load %arg1[%arg2] : memref<4xf32>
      %2 = addf %0, %1 : f32
      store %2, %arg0[%arg2] : memref<4xf32>
    }
    return
  }
```

    Example: map map add

```C++
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
```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
  func @rise_fun(%arg0: memref<4x4xf32>) {
    %0 = alloc() : memref<4x4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4x4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %1 = "rise.codegen.idx"(%0, %arg1) : (memref<4x4xf32>, index) -> memref<4xf32>
      %2 = "rise.codegen.idx"(%arg0, %arg1) : (memref<4x4xf32>, index) -> memref<4xf32>
      %c0_0 = constant 0 : index
      %c4_1 = constant 4 : index
      %c1_2 = constant 1 : index
      loop.for %arg2 = %c0_0 to %c4_1 step %c1_2 {
        %3 = "rise.codegen.idx"(%1, %arg2) : (memref<4xf32>, index) -> memref<f32>
        %4 = "rise.codegen.idx"(%2, %arg2) : (memref<4xf32>, index) -> memref<f32>
        %5 = "rise.codegen.bin_op"(%3, %3) {op = "add"} : (memref<f32>, memref<f32>) -> f32
        "rise.codegen.assign"(%5, %4) : (f32, memref<f32>) -> ()
      }
    }
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
   
```C++
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
```

    Example: map map map add

```C++
    rise.fun "rise_fun" (%outArg:memref<4x4x4xf32>) {
        %array3D = rise.literal #rise.lit<array<4.4.4, !rise.float, [[[5,5,5,5], [5,5,5,5], [5,5,5,5], [5,5,5,5]], [[5,5,5,5], [5,5,5,5], [5,5,5,5], [5,5,5,5]], [[5,5,5,5], [5,5,5,5], [5,5,5,5], [5,5,5,5]], [[5,5,5,5], [5,5,5,5], [5,5,5,5], [5,5,5,5]]]>>
        %doubleFun = rise.lambda (%summand) : !rise.fun<data<float> -> data<float>> {
            %addFun = rise.add #rise.float
            %doubled = rise.apply %addFun, %summand, %summand //: !rise.fun<data<float> -> fun<data<float> -> data<float>>>, %summand, %summand
            rise.return %doubled : !rise.data<float>
        }
        %map1 = rise.map #rise.nat<4> #rise.array<4, !rise.array<4, !rise.float>> #rise.array<4, !rise.array<4, !rise.float>>
        %mapInnerLambda_1 = rise.lambda (%arraySlice_1) : !rise.fun<data<array<4, array<4, float>>> -> data<array<4, array<4, float>>>> {
            %map2 = rise.map #rise.nat<4> #rise.array<4, !rise.float> #rise.array<4, !rise.float>
            %mapInnerLambda_2 = rise.lambda (%arraySlice_2) : !rise.fun<data<array<4, float>> -> data<array<4, float>>> {
                %map3 = rise.map #rise.nat<4> #rise.float #rise.float
                %res = rise.apply %map3, %doubleFun, %arraySlice_2
                rise.return %res : !rise.data<array<4, float>>
            }
           %res = rise.apply %map2, %mapInnerLambda_2, %arraySlice_1
           rise.return %res : !rise.data<array<4, array<4, float>>>
        }
        %res = rise.apply %map1, %mapInnerLambda_1, %array3D
        rise.return %res: !rise.data<array<4, array<4, array<4, float>>>>
    }
```
    
```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
  func @rise_fun(%arg0: memref<4x4x4xf32>) {
    %0 = alloc() : memref<4x4x4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4x4x4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %1 = "rise.codegen.idx"(%0, %arg1) : (memref<4x4x4xf32>, index) -> memref<4x4xf32>
      %2 = "rise.codegen.idx"(%arg0, %arg1) : (memref<4x4x4xf32>, index) -> memref<4x4xf32>
      %c0_0 = constant 0 : index
      %c4_1 = constant 4 : index
      %c1_2 = constant 1 : index
      loop.for %arg2 = %c0_0 to %c4_1 step %c1_2 {
        %3 = "rise.codegen.idx"(%1, %arg2) : (memref<4x4xf32>, index) -> memref<4xf32>
        %4 = "rise.codegen.idx"(%2, %arg2) : (memref<4x4xf32>, index) -> memref<4xf32>
        %c0_3 = constant 0 : index
        %c4_4 = constant 4 : index
        %c1_5 = constant 1 : index
        loop.for %arg3 = %c0_3 to %c4_4 step %c1_5 {
          %5 = "rise.codegen.idx"(%3, %arg3) : (memref<4xf32>, index) -> memref<f32>
          %6 = "rise.codegen.idx"(%4, %arg3) : (memref<4xf32>, index) -> memref<f32>
          %7 = "rise.codegen.bin_op"(%5, %5) {op = "add"} : (memref<f32>, memref<f32>) -> f32
          "rise.codegen.assign"(%7, %6) : (f32, memref<f32>) -> ()
        }
      }
    }
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
   
```C++
  func @rise_fun(%arg0: memref<4x4x4xf32>) {
    %0 = alloc() : memref<4x4x4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4x4x4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %c0_0 = constant 0 : index
      %c4_1 = constant 4 : index
      %c1_2 = constant 1 : index
      loop.for %arg2 = %c0_0 to %c4_1 step %c1_2 {
        %c0_3 = constant 0 : index
        %c4_4 = constant 4 : index
        %c1_5 = constant 1 : index
        loop.for %arg3 = %c0_3 to %c4_4 step %c1_5 {
          %1 = load %0[%arg3, %arg2, %arg1] : memref<4x4x4xf32>
          %2 = load %0[%arg3, %arg2, %arg1] : memref<4x4x4xf32>
          %3 = addf %1, %2 : f32
          store %3, %arg0[%arg3, %arg2, %arg1] : memref<4x4x4xf32>
        }
      }
    }
    return
  }
```


    Example: zip map fst (projection)

```C++
    rise.fun "rise_fun" (%outArg:memref<4xf32>) {
        %array0 = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>
        %array1 = rise.literal #rise.lit<array<4, !rise.float, [10,10,10,10]>>

        %zipFun = rise.zip #rise.nat<4> #rise.float #rise.float
        %zipped = rise.apply %zipFun, %array0, %array1

        %projectToFirst = rise.lambda (%floatTuple) : !rise.fun<data<tuple<float, float>> -> data<float>> {
            %fstFun = rise.fst #rise.float #rise.float
            // or rise.snd... 
            %fst = rise.apply %fstFun, %floatTuple
            rise.return %fst : !rise.data<float>
        }

        %mapFun = rise.map #rise.nat<4> #rise.tuple<float, float> #rise.float
        %fstArray = rise.apply %mapFun, %projectToFirst, %zipped

        rise.return %fstArray : !rise.data<array<4, float>>
    }
```
    
```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```C++
  func @rise_fun(%arg0: memref<4xf32>) {
    %0 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4xf32>, f32
    %1 = alloc() : memref<4xf32>
    %cst_0 = constant 1.000000e+01 : f32
    linalg.fill(%1, %cst_0) : memref<4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %2 = load %0[%arg1] : memref<4xf32>
        // with snd the difference is:
        // %2 = load %1[%arg1] : memref<4xf32>
      store %2, %arg0[%arg1] : memref<4xf32>
    }
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

```
  func @rise_fun(%arg0: memref<4xf32>) {
    %0 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4xf32>, f32
    %1 = alloc() : memref<4xf32>
    %cst_0 = constant 1.000000e+01 : f32
    linalg.fill(%1, %cst_0) : memref<4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %2 = load %0[%arg1] : memref<4xf32>
      store %2, %arg0[%arg1] : memref<4xf32>
    }
    return
  }
```


    Example: zip map add (vector addition)

```C++
    rise.fun "rise_fun" (%outArg:memref<4xf32>) {
        %array0 = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>
        %array1 = rise.literal #rise.lit<array<4, !rise.float, [10,10,10,10]>>

        %zipFun = rise.zip #rise.nat<4> #rise.float #rise.float
        %zipped = rise.apply %zipFun, %array0, %array1

        %tupleAddFun = rise.lambda (%floatTuple) : !rise.fun<data<tuple<float, float>> -> data<float>> {
            %fstFun = rise.fst #rise.float #rise.float
            %sndFun = rise.snd #rise.float #rise.float

            %fst = rise.apply %fstFun, %floatTuple
            %snd = rise.apply %sndFun, %floatTuple

            %addFun = rise.add #rise.float
            %result = rise.apply %addFun, %snd, %fst

            rise.return %result : !rise.data<float>
        }

        %mapFun = rise.map #rise.nat<4> #rise.tuple<float, float> #rise.float
        %sumArray = rise.apply %mapFun, %tupleAddFun, %zipped

        rise.return %sumArray : !rise.data<array<4, float>>
    }
```
    
```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```C++
  func @rise_fun(%arg0: memref<4xf32>) {
    %0 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4xf32>, f32
    %1 = alloc() : memref<4xf32>
    %cst_0 = constant 1.000000e+01 : f32
    linalg.fill(%1, %cst_0) : memref<4xf32>, f32
    %2 = "rise.zip_interm"(%0, %1) : (memref<4xf32>, memref<4xf32>) -> memref<4xf32>
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %3 = "rise.idx"(%2, %arg1) : (memref<4xf32>, index) -> memref<f32>
      %4 = "rise.idx"(%arg0, %arg1) : (memref<4xf32>, index) -> memref<f32>
      %5 = "rise.snd_interm"(%3) : (memref<f32>) -> f32
      %6 = "rise.fst_interm"(%3) : (memref<f32>) -> f32
      %7 = "rise.bin_op"(%5, %6) : (f32, f32) -> f32
      "rise.assign"(%7, %4) : (f32, memref<f32>) -> ()
    }
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
   
```C++
  func @rise_fun(%arg0: memref<4xf32>) {
    %0 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4xf32>, f32
    %1 = alloc() : memref<4xf32>
    %cst_0 = constant 1.000000e+01 : f32
    linalg.fill(%1, %cst_0) : memref<4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %2 = load %1[%arg1] : memref<4xf32>
      %3 = load %0[%arg1] : memref<4xf32>
      %4 = addf %2, %3 : f32
      store %4, %arg0[%arg1] : memref<4xf32>
    }
    return
  }
```

Example: reduce add

```C++
    rise.fun "rise_fun" (%outArg:memref<1xf32>) {
        %array0 = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>

        %reductionAdd = rise.lambda (%summand0, %summand1) : !rise.fun<data<float> -> fun<data<float> -> data<float>>> {
            %addFun = rise.add #rise.float
            %doubled = rise.apply %addFun, %summand0, %summand1
            rise.return %doubled : !rise.data<float>
        }
        %initializer = rise.literal #rise.lit<float<0>>
        %reduce4Ints = rise.reduce #rise.nat<4> #rise.float #rise.float
        %result = rise.apply %reduce4Ints, %reductionAdd, %initializer, %array0

        rise.return %result : !rise.data<float>
    }
```
    
```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```
  func @rise_fun(%arg0: memref<1xf32>) {
    %0 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4xf32>, f32
    %cst_0 = constant 0.000000e+00 : f32
    %1 = alloc() : memref<1xf32>
    linalg.fill(%1, %cst_0) : memref<1xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %4 = "rise.codegen.idx"(%0, %arg1) : (memref<4xf32>, index) -> memref<f32>
      %5 = "rise.codegen.idx"(%1, %c0) : (memref<1xf32>, index) -> memref<1xf32>
      %6 = "rise.codegen.bin_op"(%5, %4) {op = "add"} : (memref<1xf32>, memref<f32>) -> f32
      "rise.codegen.assign"(%6, %5) : (f32, memref<1xf32>) -> ()
    }
    %2 = "rise.codegen.idx"(%arg0, %c0) : (memref<1xf32>, index) -> memref<1xf32>
    %3 = "rise.codegen.idx"(%1, %c0) : (memref<1xf32>, index) -> memref<1xf32>
    "rise.codegen.assign"(%3, %2) : (memref<1xf32>, memref<1xf32>) -> ()
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
   
```C++
  func @rise_fun(%arg0: memref<1xf32>) {
    %0 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4xf32>, f32
    %cst_0 = constant 0.000000e+00 : f32
    %1 = alloc() : memref<1xf32>
    linalg.fill(%1, %cst_0) : memref<1xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %3 = load %1[%c0] : memref<1xf32>
      %4 = load %0[%arg1] : memref<4xf32>
      %5 = addf %3, %4 : f32
      store %5, %1[%c0] : memref<1xf32>
    }
    %2 = load %1[%c0] : memref<1xf32>
    store %2, %arg0[%c0] : memref<1xf32>
    return
  }
```



Example: dot
```C++
    rise.fun "rise_fun" (%outArg:memref<4xf32>) {

        //Arrays
        %array0 = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>
        %array1 = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>

        //Zipping
        %zipFun = rise.zip #rise.nat<4> #rise.float #rise.float
        %zippedArrays = rise.apply %zipFun, %array0, %array1

        //Multiply

        %tupleMulFun = rise.lambda (%floatTuple) : !rise.fun<data<tuple<float, float>> -> data<float>> {
            %fstFun = rise.fst #rise.float #rise.float
               %sndFun = rise.snd #rise.float #rise.float

               %fst = rise.apply %fstFun, %floatTuple
              %snd = rise.apply %sndFun, %floatTuple

              %mulFun = rise.mult #rise.float
              %result = rise.apply %mulFun, %snd, %fst

             rise.return %result : !rise.data<float>
            }

        %map10TuplesToInts = rise.map #rise.nat<4> #rise.tuple<float, float> #rise.float
        %multipliedArray = rise.apply %map10TuplesToInts, %tupleMulFun, %zippedArrays

        //Reduction
        %reductionAdd = rise.lambda (%summand0, %summand1) : !rise.fun<data<float> -> fun<data<float> -> data<float>>> {
            %addFun = rise.add #rise.float
            %doubled = rise.apply %addFun, %summand0, %summand1
            rise.return %doubled : !rise.data<float>
        }
        %initializer = rise.literal #rise.lit<float<0>>
        %reduce10Ints = rise.reduce #rise.nat<4> #rise.float #rise.float
        %result = rise.apply %reduce10Ints, %reductionAdd, %initializer, %multipliedArray

        rise.return %result : !rise.data<float>
    }
```
    
```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```
  
```C++
  func @rise_fun(%arg0: memref<1xf32>) {
    %0 = alloc() : memref<4xf32>
    %1 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%1, %cst) : memref<4xf32>, f32
    %2 = alloc() : memref<4xf32>
    %cst_0 = constant 5.000000e+00 : f32
    linalg.fill(%2, %cst_0) : memref<4xf32>, f32
    %3 = "rise.codegen.zip"(%1, %2) : (memref<4xf32>, memref<4xf32>) -> memref<4xf32>
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %7 = "rise.codegen.idx"(%3, %arg1) : (memref<4xf32>, index) -> memref<f32>
      %8 = "rise.codegen.idx"(%0, %arg1) : (memref<4xf32>, index) -> memref<f32>
      %9 = "rise.codegen.snd"(%7) : (memref<f32>) -> f32
      %10 = "rise.codegen.fst"(%7) : (memref<f32>) -> f32
      %11 = "rise.codegen.bin_op"(%9, %10) {op = "mul"} : (f32, f32) -> f32
      "rise.codegen.assign"(%11, %8) : (f32, memref<f32>) -> ()
    }
    %cst_1 = constant 0.000000e+00 : f32
    %4 = alloc() : memref<1xf32>
    linalg.fill(%4, %cst_1) : memref<1xf32>, f32
    %c0_2 = constant 0 : index
    %c4_3 = constant 4 : index
    %c1_4 = constant 1 : index
    loop.for %arg1 = %c0_2 to %c4_3 step %c1_4 {
      %7 = "rise.codegen.idx"(%0, %arg1) : (memref<4xf32>, index) -> memref<f32>
      %8 = "rise.codegen.idx"(%4, %c0_2) : (memref<1xf32>, index) -> memref<1xf32>
      %9 = "rise.codegen.bin_op"(%8, %7) {op = "add"} : (memref<1xf32>, memref<f32>) -> f32
      "rise.codegen.assign"(%9, %8) : (f32, memref<1xf32>) -> ()
    }
    %5 = "rise.codegen.idx"(%arg0, %c0_2) : (memref<1xf32>, index) -> memref<1xf32>
    %6 = "rise.codegen.idx"(%4, %c0_2) : (memref<1xf32>, index) -> memref<1xf32>
    "rise.codegen.assign"(%6, %5) : (memref<1xf32>, memref<1xf32>) -> ()
    return
  }
```

```
        |       Lowering to Imperative
        |           Dialect Conversion: (rise)              -> (std x loop x linalg) 
        |           rise.fun                                -> @riseFun(): (memref) -> () ... call @riseFun
        |           rise.literal                            -> alloc() : memref ... linalg.fill
        |           rise.map ... rise.apply                 -> loop.for
        |           rise.reduce ... rise.apply              -> loop.for
        |           rise.lambda{rise.add}                   -> rise.bin_op {"add"}... rise.assign
        |           rise.labda{rise.mul}                    -> rise.bin_op {"mul} ... rise.assign
        V
```

 
```C++
  func @rise_fun(%arg0: memref<1xf32>) {
    %0 = alloc() : memref<4xf32>
    %1 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%1, %cst) : memref<4xf32>, f32
    %2 = alloc() : memref<4xf32>
    %cst_0 = constant 5.000000e+00 : f32
    linalg.fill(%2, %cst_0) : memref<4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %5 = load %2[%arg1] : memref<4xf32>
      %6 = load %1[%arg1] : memref<4xf32>
      %7 = mulf %5, %6 : f32
      store %7, %0[%arg1] : memref<4xf32>
    }
    %cst_1 = constant 0.000000e+00 : f32
    %3 = alloc() : memref<1xf32>
    linalg.fill(%3, %cst_1) : memref<1xf32>, f32
    %c0_2 = constant 0 : index
    %c4_3 = constant 4 : index
    %c1_4 = constant 1 : index
    loop.for %arg1 = %c0_2 to %c4_3 step %c1_4 {
      %5 = load %3[%c0_2] : memref<1xf32>
      %6 = load %0[%arg1] : memref<4xf32>
      %7 = addf %5, %6 : f32
      store %7, %3[%c0_2] : memref<1xf32>
    }
    %4 = load %3[%c0_2] : memref<1xf32>
    store %4, %arg0[%c0_2] : memref<1xf32>
    return
  }
```

```Bash
mlir-opt dot.mlir -convert-rise-to-imperative -convert-linalg-to-loops -convert-loop-to-std -convert-std-to-llvm | mlir-cpu-runner -e simple_dot -entry-point-result=void -shared-libs=libmlir_runner_utils.so
Unranked Memref rank = 1 descriptor@ = 0x7ffd81181870
Memref base@ = 0x55883b438ec0 rank = 1 offset = 0 sizes = [1] strides = [1] data = 
[100]
```

Example: mm

```C++
    rise.fun "rise_fun" (%outArg:memref<4x4xf32>, %inA:memref<4x4xf32>, %inB:memref<4x4xf32>) {
        //Arrays
        %A = rise.in %inA : !rise.data<array<4, array<4, float>>>
        %B = rise.in %inB : !rise.data<array<4, array<4, float>>>

        %m1fun = rise.lambda (%arow) : !rise.fun<data<array<4, float>> -> data<array<4, float>>> {
            %m2fun = rise.lambda (%bcol) : !rise.fun<data<array<4, float>> -> data<array<4, float>>> {

                //Zipping
                %zipFun = rise.zip #rise.nat<4> #rise.float #rise.float
                %zippedArrays = rise.apply %zipFun, %arow, %bcol

                //Multiply
                %tupleMulFun = rise.lambda (%floatTuple) : !rise.fun<data<tuple<float, float>> -> data<float>> {
                    %fstFun = rise.fst #rise.float #rise.float
                       %sndFun = rise.snd #rise.float #rise.float

                       %fst = rise.apply %fstFun, %floatTuple
                      %snd = rise.apply %sndFun, %floatTuple

                      %mulFun = rise.mult #rise.float
                      %result = rise.apply %mulFun, %snd, %fst

                     rise.return %result : !rise.data<float>
                }
                %map10TuplesToInts = rise.map #rise.nat<4> #rise.tuple<float, float> #rise.float
                %multipliedArray = rise.apply %map10TuplesToInts, %tupleMulFun, %zippedArrays

                //Reduction
                %reductionAdd = rise.lambda (%summand0, %summand1) : !rise.fun<data<float> -> fun<data<float> -> data<float>>> {
                    %addFun = rise.add #rise.float
                    %doubled = rise.apply %addFun, %summand0, %summand1
                    rise.return %doubled : !rise.data<float>
                }
                %initializer = rise.literal #rise.lit<float<0>>
                %reduce10Ints = rise.reduce #rise.nat<4> #rise.float #rise.float
                %result = rise.apply %reduce10Ints, %reductionAdd, %initializer, %multipliedArray

                rise.return %result : !rise.data<float>
            }
            %m2 = rise.map #rise.nat<4> #rise.array<4, float> #rise.array<4, float>
            %result = rise.apply %m2, %m2fun, %B
            rise.return %result : !rise.data<array<4, array<4, float>>>
        }
        %m1 = rise.map #rise.nat<4> #rise.array<4, !rise.float> #rise.array<4, !rise.float>
        %result = rise.apply %m1, %m1fun, %A
    }
```
 
```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```
  
```C++
  func @rise_fun(%arg0: memref<4x4xf32>, %arg1: memref<4x4xf32>, %arg2: memref<4x4xf32>) {
    %0 = alloc() : memref<4x4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4x4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg3 = %c0 to %c4 step %c1 {
      %1 = "rise.codegen.idx"(%0, %arg3) : (memref<4x4xf32>, index) -> memref<4xf32>
      %2 = "rise.codegen.idx"(%arg0, %arg3) : (memref<4x4xf32>, index) -> memref<4xf32>
      %3 = alloc() : memref<4x4xf32>
      %cst_0 = constant 5.000000e+00 : f32
      linalg.fill(%3, %cst_0) : memref<4x4xf32>, f32
      %c0_1 = constant 0 : index
      %c4_2 = constant 4 : index
      %c1_3 = constant 1 : index
      loop.for %arg4 = %c0_1 to %c4_2 step %c1_3 {
        %4 = "rise.codegen.idx"(%3, %arg4) : (memref<4x4xf32>, index) -> memref<4xf32>
        %5 = "rise.codegen.idx"(%2, %arg4) : (memref<4xf32>, index) -> memref<4xf32>
        %6 = alloc() : memref<4xf32>
        %7 = "rise.codegen.zip"(%1, %4) : (memref<4xf32>, memref<4xf32>) -> memref<4xf32>
        %c0_4 = constant 0 : index
        %c4_5 = constant 4 : index
        %c1_6 = constant 1 : index
        loop.for %arg5 = %c0_4 to %c4_5 step %c1_6 {
          %11 = "rise.codegen.idx"(%7, %arg5) : (memref<4xf32>, index) -> memref<f32>
          %12 = "rise.codegen.idx"(%6, %arg5) : (memref<4xf32>, index) -> memref<f32>
          %13 = "rise.codegen.snd"(%11) : (memref<f32>) -> f32
          %14 = "rise.codegen.fst"(%11) : (memref<f32>) -> f32
          %15 = "rise.codegen.bin_op"(%13, %14) {op = "mul"} : (f32, f32) -> f32
          "rise.codegen.assign"(%15, %12) : (f32, memref<f32>) -> ()
        }
        %cst_7 = constant 0.000000e+00 : f32
        %8 = alloc() : memref<1xf32>
        linalg.fill(%8, %cst_7) : memref<1xf32>, f32
        %c0_8 = constant 0 : index
        %c4_9 = constant 4 : index
        %c1_10 = constant 1 : index
        loop.for %arg5 = %c0_8 to %c4_9 step %c1_10 {
          %11 = "rise.codegen.idx"(%6, %arg5) : (memref<4xf32>, index) -> memref<f32>
          %12 = "rise.codegen.idx"(%8, %c0_8) : (memref<1xf32>, index) -> memref<1xf32>
          %13 = "rise.codegen.bin_op"(%12, %11) {op = "add"} : (memref<1xf32>, memref<f32>) -> f32
          "rise.codegen.assign"(%13, %12) : (f32, memref<1xf32>) -> ()
        }
        %9 = "rise.codegen.idx"(%5, %c0_8) : (memref<4xf32>, index) -> memref<4xf32>
        %10 = "rise.codegen.idx"(%8, %c0_8) : (memref<1xf32>, index) -> memref<1xf32>
        "rise.codegen.assign"(%10, %9) : (memref<1xf32>, memref<4xf32>) -> ()
      }
    }
    return
  }
```

```
        |       Lowering to Imperative
        |           Dialect Conversion: (rise)              -> (std x loop x linalg) 
        |           rise.fun                                -> @riseFun(): (memref) -> () ... call @riseFun
        |           rise.literal                            -> alloc() : memref ... linalg.fill
        |           rise.map ... rise.apply                 -> loop.for
        |           rise.reduce ... rise.apply              -> loop.for
        |           rise.lambda{rise.add}                   -> rise.bin_op {"add"}... rise.assign
        |           rise.labda{rise.mul}                    -> rise.bin_op {"mul} ... rise.assign
        V
```

 
```C++
  func @rise_fun(%arg0: memref<4x4xf32>, %arg1: memref<4x4xf32>, %arg2: memref<4x4xf32>) {
    %0 = alloc() : memref<4x4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4x4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg3 = %c0 to %c4 step %c1 {
      %1 = alloc() : memref<4x4xf32>
      %cst_0 = constant 5.000000e+00 : f32
      linalg.fill(%1, %cst_0) : memref<4x4xf32>, f32
      %c0_1 = constant 0 : index
      %c4_2 = constant 4 : index
      %c1_3 = constant 1 : index
      loop.for %arg4 = %c0_1 to %c4_2 step %c1_3 {
        %2 = alloc() : memref<4xf32>
        %c0_4 = constant 0 : index
        %c4_5 = constant 4 : index
        %c1_6 = constant 1 : index
        loop.for %arg5 = %c0_4 to %c4_5 step %c1_6 {
          %5 = load %1[%arg5, %arg4] : memref<4x4xf32>
          %6 = load %0[%arg5, %arg3] : memref<4x4xf32>
          %7 = mulf %5, %6 : f32
          store %7, %2[%arg5] : memref<4xf32>
        }
        %cst_7 = constant 0.000000e+00 : f32
        %3 = alloc() : memref<1xf32>
        linalg.fill(%3, %cst_7) : memref<1xf32>, f32
        %c0_8 = constant 0 : index
        %c4_9 = constant 4 : index
        %c1_10 = constant 1 : index
        loop.for %arg5 = %c0_8 to %c4_9 step %c1_10 {
          %5 = load %3[%c0_8] : memref<1xf32>
          %6 = load %2[%arg5] : memref<4xf32>
          %7 = addf %5, %6 : f32
          store %7, %3[%c0_8] : memref<1xf32>
        }
        %4 = load %3[%c0_8] : memref<1xf32>
        store %4, %arg0[%arg4, %arg3] : memref<4x4xf32>
      }
    }
    return
  }
```

```Bash
mlir-opt mm.mlir -convert-rise-to-imperative -convert-linalg-to-loops -convert-loop-to-std -convert-std-to-llvm | mlir-cpu-runner -e mm -entry-point-result=void -shared-libs=libmlir_runner_utils.so
Unranked Memref rank = 2 descriptor@ = 0x7ffc9c9c8470
Memref base@ = 0x55754f6608f0 rank = 2 offset = 0 sizes = [4, 4] strides = [4, 1] data = 
[[100,   100,   100,   100], 
 [100,   100,   100,   100], 
 [100,   100,   100,   100], 
 [100,   100,   100,   100]]
```


