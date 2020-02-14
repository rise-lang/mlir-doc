func @main() {


    %array = alloc() : memref<4xf32>
    %init = alloc() : memref<1xf32>

    %filler = constant 5.0 : f32
    %zero = constant 0.0 : f32
    linalg.fill(%array, %filler) : memref<4xf32>, f32
    linalg.fill(%init, %zero) : memref<1xf32>, f32 

    affine.for %i = 0 to 4 {
       %elem = affine.load %array[%i] : memref<4xf32>
       %acc = affine.load %init[0] : memref<1xf32>
       %res = addf %acc, %elem : f32
       affine.store %res, %init[0] : memref<1xf32>
    }
    call @print_memref_0d_f32(%init) : (memref<1xf32>) -> ()
    return
}

func @print_memref_0d_f32(memref<1xf32>)
