[index](../README.md)
# Lowering of a Matrix Multiplication example
taken from: https://github.com/bondhugula/llvm-project/blob/hop/mlir/docs/HighPerfCodeGen.md 

### naive target MLIR code:
```C++
// C += A * B.
func @matmul(%A: memref<2048x2048xf64>, %B: memref<2048x2048xf64>, %C: memref<2048x2048xf64>) {
  affine.for %arg3 = 0 to 2048 {
    affine.for %arg4 = 0 to 2048 {
      affine.for %arg5 = 0 to 2048 {
        %a = affine.load %A[%arg3, %arg5] : memref<2048x2048xf64>
        %b = affine.load %B[%arg5, %arg4] : memref<2048x2048xf64>
        %ci = affine.load %C[%arg3, %arg4] : memref<2048x2048xf64>
        %p = mulf %a, %b : f64
        %co = addf %ci, %p : f64
        affine.store %co, %C[%arg3, %arg4] : memref<2048x2048xf64>
      }
    }
  }
  return
}
```
