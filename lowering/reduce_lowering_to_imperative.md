[index](../README.md)
# Lowering of the Reduce primitive

## rise_functional lowering
Functional Code:
```
private val simpleReduction = nFun(n => fun(xsT(n))( xs =>
    xs |> reduceSeq(add)(l(0.0f)))
)
```
            |
            |
            V
Imperative C Code:
```C
void foo(float* output, int n0, float* x0){
  {
    float x37;
    x37 = 0.0f;
    /* reduceSeq */
    for (int i_39 = 0;(i_39 < n0);i_39 = (1 + i_39)) {
      x37 = (x37 + x0[i_39]);
    }
    output[0] = x37;
  }
}
```
desugared:
```
New(f32,λ(x37 : exp[f32, read] x acc[f32]). Seq(Seq(Seq(Assign(f32, Proj2((x37 : exp[f32, read] x acc[f32])), Literal(0.0f)),Comment(reduceSeq)),For(n0,λ(x38 : exp[idx(n0), read]). Assign(f32, Proj2((x37 : exp[f32, read] x acc[f32])), BinOp(+,Proj1((x37 : exp[f32, read] x acc[f32])),Idx(n0,f32,(x38 : exp[idx(n0), read]),(x0 : exp[n0.f32, read])))),false)),Assign(f32, IdxAcc(1,f32,AsIndex(1,Natural(0)),(output : acc[1.f32])), Proj1((x37 : exp[f32, read] x acc[f32])))))#include <stdint.h>
```

## rise_mlir lowering:
##### initial rise_mlir code
```C++
//Array
%array0 = rise.literal #rise.lit<array<4, !rise.int, [1,2,3,4]>>


//Reduction
%addFun = rise.add #rise.int
%initializer = rise.literal #rise.lit<int<4>>
%reduce4Ints = rise.reduce #rise.nat<4> #rise.int #rise.int
%result = rise.apply %reduce4Ints, %addFun, %initializer, %array0
```

            |
            |   We have multiple options but concentrate on the sequential one for now.
            V

##### mlir loops (sequential):
```C++
func @main() {
  %array = alloc() : memref<4xf32>
  %init = alloc() : memref<1xf32>
  %cst_0 = constant 0 : index

  %lb = constant 0 : index
  %ub = constant 4 : index //half open index, so 4 iterations
  %step = constant 1 : index
  loop.for %i = %lb to %ub step %step {
    %elem = load %array[%i] : memref<4xf32>
    %acc = load %init[%cst_0] : memref<1xf32>
    %res = addf %acc, %elem : f32
    store %res, %init[%cst_0] : memref<1xf32>
  }
  return
}
```
[file](examples/lowering/reduce_loop.mlir)

exectue: `mlir-opt --convert-linalg-to-loops --convert-loop-to-std --convert-std-to-llvm reduce_loop_executable.mlir | mlir-cpu-runner -O3 -e main -entry-point-result=void --shared-libs='/home/martin/development/MLIR/mlir/llvm/cmake-build-debug/lib/libmlir_runner_utils.so'`


- note: the func around it is required for lowering, as a module can only have one block. (the loop is lowered into multiple blocks)
- further lowering insights: calling `rewriter.createOp<...>(...)` is not sufficient for creating ops in the IR. We have to call `rewriter.replaceOp(...)` to out it in the IR. This seems to finalize the rewriting and materialze the new op in the IR. When creating multiple ops call `replace` with the last created op, which ties all newly created ops together. 
- *There has to be a way to create new ops without replacing the old one* I think this just works by replacing the old op with new operations and a new instance of that old op. 

##### mlir loops (using loop.reduce):
```C++
%lb = constant 0 : index
%ub = constant 4 : index //half open index, so 4 iterations
%step = constant 1 : index
%result = loop.parallel (%iv) = (%lb) to (%ub) step (%step) {
    %zero = constant 0.0 : f32
    loop.reduce(%zero) {
      ^bb0(%lhs : f32, %rhs: f32):
        %res = addf %lhs, %rhs : f32
        loop.reduce.return %res : f32
    } : f32
} :f32
```
[file](examples/lowering/reduce_loop_parallel.mlir)

I have trouble lowering loop.parallel. I expect it can obviously only lowered to a parallel primitive. This means it has to be lowered to the gpu dialect(or are there other options? maybe OpenMP, which is out of tree). Lowering to gpu dialect does not work, presumably due to wrong structuring of loops. (only a single loop) 

##### mlir affine+standard implementation
```C++
%array = alloc() : memref<4xf32>
%init = alloc() : memref<1xf32>
affine.for %i = 0 to 4 {
    %elem = affine.load %array[%i] : memref<4xf32>
    %acc = affine.load %init[0] : memref<1xf32>
    %res = addf %acc, %elem : f32
    affine.store %res, %init[0] : memref<1xf32>
}
```
[file](examples/lowering/reduce_affine.mlir)

execute: ` mlir-opt -convert-linalg-to-loops --convert-loop-to-std --lower-affine --convert-std-to-llvm reduce_affine_executable.mlir | mlir-cpu-runner -O3 -e main -entry-point-result=void --shared-libs='/home/martin/development/phd/repos/mlir/llvm/cmake-build-debug/lib/libmlir_runner_utils.so' ` 

yields correct result
