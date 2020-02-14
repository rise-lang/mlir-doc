func @main() {
  %input = alloc() : memref<4xf32>
  %output = alloc() : memref<1xf32>
  %acc = alloc() : memref<1xf32>

  %filler = constant 5.0 : f32
  %zero = constant 0.0 : f32
  linalg.fill(%input, %filler) : memref<4xf32>, f32
  linalg.fill(%acc, %zero) : memref<1xf32>, f32

  %cst_0 = constant 0 : index

  %lb = constant 0 : index
  %ub = constant 4 : index //half open index, so 4 iterations
  %step = constant 1 : index
  loop.for %i = %lb to %ub step %step {
    %x1 = load %input[%i] : memref<4xf32>
    %x2 = load %acc[%cst_0] : memref<1xf32>
    %x3 = addf %x2, %x1 : f32
    store %x3, %acc[%cst_0] : memref<1xf32>
  }
  %x4 = load %acc[%cst_0] : memref<1xf32>
  store %x4, %output[%cst_0] : memref<1xf32>
  call @print_memref_0d_f32(%output) : (memref<1xf32>) -> ()
  return
}

func @print_memref_0d_f32(memref<1xf32>)
