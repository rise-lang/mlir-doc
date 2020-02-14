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

