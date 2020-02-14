func @main() {
  %array = alloc() : memref<4xf32>
  %init = alloc() : memref<1xf32>
  
  %filler = constant 5.0 : f32
  %zero = constant 0.0 : f32
  linalg.fill(%array, %filler) : memref<4xf32>, f32
  linalg.fill(%init, %zero) : memref<1xf32>, f32

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
  call @print_memref_0d_f32(%init) : (memref<1xf32>) -> ()
  return
}

func @print_memref_0d_f32(memref<1xf32>)
