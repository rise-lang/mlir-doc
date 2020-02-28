module {
  func @riseFun() -> memref<1xf32> {
    %0 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4xf32>, f32
    %cst_0 = constant 0.000000e+00 : f32
    %1 = alloc() : memref<1xf32>
    linalg.fill(%1, %cst_0) : memref<1xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg0 = %c0 to %c4 step %c1 {
      %2 = load %1[%c0] : memref<1xf32>
      %3 = load %0[%arg0] : memref<4xf32>
      %4 = addf %2, %3 : f32
      store %4, %1[%c0] : memref<1xf32>
    }
    return %1 : memref<1xf32>
  }
  func @print_memref_f32(memref<*xf32>)
  func @simple_reduction() {
    %0 = call @riseFun() : () -> memref<1xf32>
    %1 = memref_cast %0 : memref<1xf32> to memref<*xf32>
    call @print_memref_f32(%1) : (memref<*xf32>) -> ()
    return
  }
}
