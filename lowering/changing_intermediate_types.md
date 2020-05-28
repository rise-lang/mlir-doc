[index](../README.md)

### Let's explore what the internal codegen representation of dot_fused looks like 


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

```C++
func @dot_fused(%out: memref<1xf32>, %arg1: memref<1024xf32>, %arg2: memref<1024xf32>) {
  %array0 = rise.in %arg1 : !rise.array<1024, scalar<f32>> //new
  %array1 = rise.in %arg2 : !rise.array<1024, scalar<f32>> //new
  %0 = "rise.codegen.zip"(%array0, %array1) : (!rise.array<1024, scalar<f32>>, !rise.array<1024, scalar<f32>>) -> !rise.array<1024, tuple<scalar<f32>, scalar<f32>>>
  %c0 = constant 0 : index
  %cst = constant 0.000000e+00 : f32  // not sure about this constant, I think we could just generate a !rise.literal here instead
  %1 = "rise.codegen.idx"(%out, %c0) : (memref<1xf32>, index) -> f32 // for this we would need to also cast the out beforehand
  "rise.codegen.assign"(%cst, %1) : (f32, f32) -> () // not sure how to deal with the types here
  %c1024 = constant 1024 : index
  %c1 = constant 1 : index
  scf.for %arg3 = %c0 to %c1024 step %c1 {
    %i = "rise.codegen.idx"(%0, %arg3) : (!rise.array<1024, tuple<scalar<f32>, scalar<f32>>>, index) -> f32
    %acc = "rise.codegen.idx"(%out, %c0) : (memref<1xf32>, index) -> f32
    %fst = "rise.codegen.fst"(%i) : (!rise.tuple<scalar<f32>, scalar<f32>>) -> !rise.scalar<f32>
    %snd = "rise.codegen.snd"(%i) : (!rise.tuple<scalar<f32>, scalar<f32>>) -> !rise.scalar<f32>
    %result = rise.embed(%fst, %snd, %acc) {
      %product = mulf %fst, %snd :f32
      %result = addf %product, %acc : f32
      rise.return %result : f32
    }
    "rise.codegen.assign"(%result, %acc) : (!rise.scalar<f32>, !rise.array<1, scalar<f32>>) -> ()
  }
  rise.out %outArg <- %result
  return
}
```

```
      Not yet from the new intermediate thingy above
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


