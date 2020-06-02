[index](../README.md)

### Let's explore what the internal codegen representation of mm looks like 


### mm_fused
```C++
func @mm_fused(%outArg:memref<2048x2048xf32>, %inA:memref<2048x2048xf32>, %inB:memref<2048x2048xf32>) {
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
}}

```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```C++
func @mm_fused(%arg0: memref<2048x2048xf32>, %arg1: memref<2048x2048xf32>, %arg2: memref<2048x2048xf32>) {
  %0 = "rise.in"(%arg1) : (memref<2048x2048xf32>) -> !rise.array<2048, array<2048, scalar<f32>>>
  %1 = "rise.in"(%arg2) : (memref<2048x2048xf32>) -> !rise.array<2048, array<2048, scalar<f32>>>
  %2 = "rise.codegen.cast"(%arg0) : (memref<2048x2048xf32>) -> !rise.array<2048, array<2048, scalar<f32>>>
  %c0 = constant 0 : index
  %c0_0 = constant 0 : index
  %c2048 = constant 2048 : index
  %c1 = constant 1 : index
  scf.for %arg3 = %c0_0 to %c2048 step %c1 {
    %3 = "rise.codegen.idx"(%0, %arg3) : (!rise.array<2048, array<2048, scalar<f32>>>, index) -> !rise.array<2048, scalar<f32>>
    %4 = "rise.codegen.idx"(%2, %arg3) : (!rise.array<2048, array<2048, scalar<f32>>>, index) -> !rise.array<2048, scalar<f32>>
    %c0_1 = constant 0 : index
    %c0_2 = constant 0 : index
    %c2048_3 = constant 2048 : index
    %c1_4 = constant 1 : index
    scf.for %arg4 = %c0_2 to %c2048_3 step %c1_4 {
      %5 = "rise.codegen.idx"(%1, %arg4) : (!rise.array<2048, array<2048, scalar<f32>>>, index) -> !rise.array<2048, scalar<f32>>
      %6 = "rise.codegen.idx"(%4, %arg4) : (!rise.array<2048, scalar<f32>>, index) -> !rise.scalar<f32>
      %7 = "rise.codegen.zip"(%3, %5) : (!rise.array<2048, scalar<f32>>, !rise.array<2048, scalar<f32>>) -> !rise.array<2048, tuple<scalar<f32>, scalar<f32>>>
      %c0_5 = constant 0 : index
      %8 = "rise.embed"() ( {
        %cst = constant 0.000000e+00 : f32
        "rise.return"(%cst) : (f32) -> ()
      }) : () -> !rise.scalar<f32>
      "rise.codegen.assign"(%8, %6) : (!rise.scalar<f32>, !rise.scalar<f32>) -> ()
      %c0_6 = constant 0 : index
      %c2048_7 = constant 2048 : index
      %c1_8 = constant 1 : index
      scf.for %arg5 = %c0_6 to %c2048_7 step %c1_8 {
        %9 = "rise.codegen.idx"(%7, %arg5) : (!rise.array<2048, tuple<scalar<f32>, scalar<f32>>>, index) -> !rise.tuple<scalar<f32>, scalar<f32>>
        %10 = "rise.codegen.fst"(%9) : (!rise.tuple<scalar<f32>, scalar<f32>>) -> f32
        %11 = "rise.codegen.snd"(%9) : (!rise.tuple<scalar<f32>, scalar<f32>>) -> f32
        %12 = "rise.embed"(%10, %11, %6) ( {
        ^bb0(%arg6: f32, %arg7: f32, %arg8: f32):  // no predecessors
          %13 = mulf %arg6, %arg7 : f32
          %14 = addf %13, %arg8 : f32
          "rise.return"(%14) : (f32) -> ()
        }) : (f32, f32, !rise.scalar<f32>) -> !rise.scalar<f32>
        "rise.codegen.assign"(%12, %6) : (!rise.scalar<f32>, !rise.scalar<f32>) -> ()
      }
    }
  }
  return
}}
```

### mm
```C++
func @mm(%outArg:memref<4x4xf32>, %inA:memref<4x4xf32>, %inB:memref<4x4xf32>) {
    %A = rise.in %inA : !rise.array<4, array<4, scalar<f32>>>
    %B = rise.in %inB : !rise.array<4, array<4, scalar<f32>>>

    %f1 = rise.lambda (%arow : !rise.array<4, scalar<f32>>) -> !rise.array<4, scalar<f32>> {
        %f2 = rise.lambda (%bcol : !rise.array<4, scalar<f32>>) -> !rise.array<4, scalar<f32>> {

            //Zipping
            %zipFun = rise.zip #rise.nat<4> #rise.scalar<f32> #rise.scalar<f32>
            %zippedArrays = rise.apply %zipFun, %arow, %bcol

            //Multiply
            %f = rise.lambda (%floatTuple : !rise.tuple<scalar<f32>, scalar<f32>>) -> !rise.scalar<f32> {
                %fstFun = rise.fst #rise.scalar<f32> #rise.scalar<f32>
                %sndFun = rise.snd #rise.scalar<f32> #rise.scalar<f32>

                %fst = rise.apply %fstFun, %floatTuple
                %snd = rise.apply %sndFun, %floatTuple
                %result = rise.embed(%fst, %snd) {
                    %result = mulf %fst, %snd : f32
                    rise.return %result : f32
                }

                rise.return %result : !rise.scalar<f32>
            }
            %map = rise.mapPar #rise.nat<4> #rise.tuple<scalar<f32>, scalar<f32>> #rise.scalar<f32>
            %multipliedArray = rise.apply %map, %f, %zippedArrays

            //Reduction
            %reductionAdd = rise.lambda (%summand0 : !rise.scalar<f32>, %summand1 : !rise.scalar<f32>) -> !rise.scalar<f32> {
                %result = rise.embed(%summand0, %summand1) {
                       %result = addf %summand0, %summand1 : f32
                       rise.return %result : f32
                }
                rise.return %result : !rise.scalar<f32>
            }
            %initializer = rise.literal #rise.lit<0.0>
            %reduce10Ints = rise.reduceSeq #rise.nat<4> #rise.scalar<f32> #rise.scalar<f32>
            %result = rise.apply %reduce10Ints, %reductionAdd, %initializer, %multipliedArray

            rise.return %result : !rise.scalar<f32>
        }
        %m2 = rise.mapPar #rise.nat<4> #rise.array<4, scalar<f32>> #rise.array<4, scalar<f32>>
        %result = rise.apply %m2, %f2, %B
        rise.return %result : !rise.array<4, array<4, scalar<f32>>>
    }
    %m1 = rise.mapPar #rise.nat<4> #rise.array<4, scalar<f32>> #rise.array<4, scalar<f32>>
    %result = rise.apply %m1, %f1, %A
    rise.out %outArg <- %result
    return
```

```
        |       Lowering to Intermediate (this is for debugging purposes and not the result of the lowering pass)
        |           rise.codegen.*
        V
```

```C++
func @rise_fun(%arg0: memref<4x4xf32>, %arg1: memref<4x4xf32>, %arg2: memref<4x4xf32>) {
  %0 = "rise.in"(%arg1) : (memref<4x4xf32>) -> !rise.array<4, array<4, scalar<f32>>>
  %1 = "rise.in"(%arg2) : (memref<4x4xf32>) -> !rise.array<4, array<4, scalar<f32>>>
  %2 = "rise.codegen.cast"(%arg0) : (memref<4x4xf32>) -> !rise.array<4, array<4, scalar<f32>>>
  %c0 = constant 0 : index
  %c4 = constant 4 : index
  %c1 = constant 1 : index
  scf.for %arg3 = %c0 to %c4 step %c1 {
    %3 = "rise.codegen.idx"(%0, %arg3) : (!rise.array<4, array<4, scalar<f32>>>, index) -> !rise.array<4, scalar<f32>>
    %4 = "rise.codegen.idx"(%2, %arg3) : (!rise.array<4, array<4, scalar<f32>>>, index) -> !rise.array<4, scalar<f32>>
    %c0_0 = constant 0 : index
    %c4_1 = constant 4 : index
    %c1_2 = constant 1 : index
    scf.for %arg4 = %c0_0 to %c4_1 step %c1_2 {
      %5 = "rise.codegen.idx"(%1, %arg4) : (!rise.array<4, array<4, scalar<f32>>>, index) -> !rise.array<4, scalar<f32>>
      %6 = "rise.codegen.idx"(%4, %arg4) : (!rise.array<4, scalar<f32>>, index) -> !rise.scalar<f32>
      %7 = "rise.embed"() ( {
        %10 = alloc() : memref<4xf32>
        "rise.return"(%10) : (memref<4xf32>) -> ()
      }) : () -> !rise.array<4, scalar<f32>>
      %8 = "rise.codegen.zip"(%3, %5) : (!rise.array<4, scalar<f32>>, !rise.array<4, scalar<f32>>) -> !rise.array<4, tuple<scalar<f32>, scalar<f32>>>
      %c0_3 = constant 0 : index
      %c4_4 = constant 4 : index
      %c1_5 = constant 1 : index
      scf.for %arg5 = %c0_3 to %c4_4 step %c1_5 {
        %10 = "rise.codegen.idx"(%8, %arg5) : (!rise.array<4, tuple<scalar<f32>, scalar<f32>>>, index) -> !rise.tuple<scalar<f32>, scalar<f32>>
        %11 = "rise.codegen.idx"(%7, %arg5) : (!rise.array<4, scalar<f32>>, index) -> !rise.scalar<f32>
        %12 = "rise.codegen.fst"(%10) : (!rise.tuple<scalar<f32>, scalar<f32>>) -> f32
        %13 = "rise.codegen.snd"(%10) : (!rise.tuple<scalar<f32>, scalar<f32>>) -> f32
        %14 = "rise.embed"(%12, %13) ( {
        ^bb0(%arg6: f32, %arg7: f32):  // no predecessors
          %15 = mulf %arg6, %arg7 : f32
          "rise.return"(%15) : (f32) -> ()
        }) : (f32, f32) -> !rise.scalar<f32>
        "rise.codegen.assign"(%14, %11) : (!rise.scalar<f32>, !rise.scalar<f32>) -> ()
      }
      %c0_6 = constant 0 : index
      %9 = "rise.embed"() ( {
        %cst = constant 0.000000e+00 : f32
        "rise.return"(%cst) : (f32) -> ()
      }) : () -> !rise.scalar<f32>
      "rise.codegen.assign"(%9, %6) : (!rise.scalar<f32>, !rise.scalar<f32>) -> ()
      %c0_7 = constant 0 : index
      %c4_8 = constant 4 : index
      %c1_9 = constant 1 : index
      scf.for %arg5 = %c0_7 to %c4_8 step %c1_9 {
        %10 = "rise.codegen.idx"(%7, %arg5) : (!rise.array<4, scalar<f32>>, index) -> !rise.scalar<f32>
        %11 = "rise.embed"(%10, %6) ( {
        ^bb0(%arg6: f32, %arg7: f32):  // no predecessors
          %12 = addf %arg6, %arg7 : f32
          "rise.return"(%12) : (f32) -> ()
        }) : (!rise.scalar<f32>, !rise.scalar<f32>) -> !rise.scalar<f32>
        "rise.codegen.assign"(%11, %6) : (!rise.scalar<f32>, !rise.scalar<f32>) -> ()
      }
    }
  }
  return
}
```

