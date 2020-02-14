

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

func @main() {
  %A = alloc() : memref<2048x2048xf64>
  %B = alloc() : memref<2048x2048xf64>
  %C = alloc() : memref<2048x2048xf64>

  %cf1 = constant 1.00000e+00 : f64

  linalg.fill(%A, %cf1) : memref<2048x2048xf64>, f64
  linalg.fill(%B, %cf1) : memref<2048x2048xf64>, f64
  linalg.fill(%C, %cf1) : memref<2048x2048xf64>, f64

  call @matmul(%A, %B, %C) : (memref<2048x2048xf64>, memref<2048x2048xf64>, memref<2048x2048xf64>) -> ()
  return 
}

