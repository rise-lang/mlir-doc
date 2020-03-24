[index](../README.md)


### We can translate:
- map add
- map map add 
- map map map add
- map map map map (...?) add
- zip map fst/snd (projection)
- zip map add 


Do for the others as well.



    Example: map add
```C++
    rise.fun "rise_fun" (%outArg:memref<4xf32>) {
        %array = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>
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
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %1 = load %0[%arg1] : memref<4xf32>
      %2 = load %0[%arg1] : memref<4xf32>
      %3 = addf %1, %2 : f32
      store %3, %arg0[%arg1] : memref<4xf32>
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
      %2 = load %0[%arg1] : memref<4xf32>
        // with snd the difference is:
        // %2 = load %1[%arg1] : memref<4xf32>
      store %2, %arg0[%arg1] : memref<4xf32>
    }
    return
  }

```


    Example: zip map add (adding two arrays)

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



Questions/Comments for properly implementing reduce:

- as the input and the acc are arrays of size 1 right now. I generate idx ops
  for accessing them. (not done in the paper)
    -> We could try to move from memref<1xf32> to memref<f32>


Current state of reduce:


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
      %2 = "rise.idx"(%0, %arg1) : (memref<4xf32>, index) -> memref<f32>
      %3 = "rise.idx"(%1, %c0) : (memref<1xf32>, index) -> memref<1xf32>
      %4 = "rise.idx"(%1, %c0) : (memref<1xf32>, index) -> memref<f32>
      %5 = "rise.bin_op"(%3, %2) : (memref<1xf32>, memref<f32>) -> f32
      "rise.assign"(%5, %4) : (f32, memref<f32>) -> ()
      %6 = load %1[%c0] : memref<1xf32>
      %7 = load %0[%arg1] : memref<4xf32>
      %8 = addf %6, %7 : f32
      store %8, %1[%c0] : memref<1xf32>
    }
    "rise.assign"(%3, %4) : (memref<1xf32>, memref<f32>) -> ()
    return
  }
```





