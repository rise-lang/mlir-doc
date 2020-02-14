%array = alloc() : memref<4xf32>
%init = alloc() : memref<1xf32>
affine.for %i = 0 to 4 {
    %elem = affine.load %array[%i] : memref<4xf32>
    %acc = affine.load %init[0] : memref<1xf32>
    %res = addf %acc, %elem : f32
    affine.store %res, %init[0] : memref<1xf32>
}
