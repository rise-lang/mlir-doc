[index](../README.md)
# Lowering a simple reduction

##### initial rise_mlir code
```C++
func @print_memref_f32(memref<*xf32>)
func @simple_reduction() {

    %res = rise.fun {
        //Array
        %array0 = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>

        //Reduction
        %addFun = rise.add #rise.float
        %initializer = rise.literal #rise.lit<float<0>>
        %reduce4Ints = rise.reduce #rise.nat<4> #rise.float #rise.float
        %result = rise.apply %reduce4Ints, %addFun, %initializer, %array0

        rise.return %result : !rise.data<float>
    } : () -> memref<4xf32>

    %print_me = memref_cast %res : memref<1xf32> to memref<*xf32>
    call @print_memref_f32(%print_me): (memref<*xf32>) -> ()

    return
```
[file](examples/lowering/simple_reduction_lowering_rise.mlir)

            |       Lowering to Imperative: mlir-opt reduce.mlir -convert-rise-to-imperative        
            |           Dialect Conversion: (rise) -> (std x loop x linalg) 
            |           rise.fun                   -> @riseFun(): () -> (memref) ... call @riseFun
            |           rise.literal               -> alloc() : memref ... linalg.fill
            |           rise.reduce ... rise.apply -> loop.for
            |           rise.add                   -> load... addf ... store 
            V
```C++
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
```
[file](examples/lowering/simple_reduction_lowering_imperative.mlir)

            |       Lowering to LLVM IR
            |           -convert-linalg-to-loops
            |           -convert-loop-to-std
            |           -convert-std-to-llvm
            V
[llvm ir](examples/lowering/simple_reduction_lowering_llvm.mlir)
```Bash
mlir-opt reduce.mlir -convert-rise-to-imperative -convert-linalg-to-loops -convert-loop-to-std -convert-std-to-llvm | mlir-cpu-runner -e main -entry-point-result=void -shared-libs=libmlir_runner_utils.so
Unranked Memref rank = 1 descriptor@ = 0x7ffc151b7290
Memref base@ = 0x55f80a1d3120 rank = 1 offset = 0 sizes = [1] strides = [1] data = 
[20]
```
Find this example [here](https://github.com/rise-lang/mlir/blob/feature/riseConversion/mlir/test/Conversion/RiseToImperative/reduce.mlir)
