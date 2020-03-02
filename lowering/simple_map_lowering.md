[index](../README.md)
# Lowering a simple map

##### initial rise_mlir code
```C++
func @print_memref_f32(memref<*xf32>)
func @simple_map_example() {

    %res = rise.fun {
        %array = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>
        %doubleFun = rise.lambda (%summand) : !rise.fun<data<float> -> data<float>> {
            %addFun = rise.add #rise.float
            %doubled = rise.apply %addFun, %summand, %summand
            rise.return %doubled : !rise.data<float>
        }
        %map4IntsToInts = rise.map #rise.nat<4> #rise.float #rise.float
        %mapDoubleFun = rise.apply %map4IntsToInts, %doubleFun
        %doubledArray = rise.apply %mapDoubleFun, %array

        rise.return %doubledArray : !rise.data<array<4, float>>
    } : () -> memref<4xf32>

    %print_me = memref_cast %res : memref<4xf32> to memref<*xf32>
    call @print_memref_f32(%print_me): (memref<*xf32>) -> ()
    return
}
```
[file](examples/lowering/simple_map_lowering_rise.mlir)

            |       Lowering to Imperative: mlir-opt reduce.mlir -convert-rise-to-imperative        
            |           Dialect Conversion: (rise)              -> (std x loop x linalg) 
            |           rise.fun                                -> @riseFun(): () -> (memref) ... call @riseFun
            |           rise.literal                            -> alloc() : memref ... linalg.fill
            |           rise.map ... rise.apply ... rise.apply  -> loop.for
            |           rise.lambda{rise.add} //cheated for now -> load... addf ... store 
            V
```C++
module {
  func @riseFun() -> memref<4xf32> {
    %0 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4xf32>, f32
    %c0 = constant 0 : index
    %c4 = constant 4 : index
    %c1 = constant 1 : index
    loop.for %arg0 = %c0 to %c4 step %c1 {
      %1 = load %0[%arg0] : memref<4xf32>
      %2 = addf %1, %1 : f32
      store %2, %0[%arg0] : memref<4xf32>
    }
    return %0 : memref<4xf32>
  }
  func @print_memref_f32(memref<*xf32>)
  func @simple_map_example() {
    %0 = call @riseFun() : () -> memref<4xf32>
    %1 = memref_cast %0 : memref<4xf32> to memref<*xf32>
    call @print_memref_f32(%1) : (memref<*xf32>) -> ()
    return
  }
}
```
[file](examples/lowering/simple_map_lowering_imperative.mlir)

            |       Lowering to LLVM IR
            |           -convert-linalg-to-loops
            |           -convert-loop-to-std
            |           -convert-std-to-llvm
            V
[llvm ir](examples/lowering/simple_map_lowering_llvm.mlir)
```Bash
mlir-opt simple_map_lowering.mlir -convert-rise-to-imperative -convert-linalg-to-loops -convert-loop-to-std -convert-std-to-llvm | mlir-cpu-runner -e simple_map_example -entry-point-result=void -shared-libs=libmlir_runner_utils.so
Unranked Memref rank = 1 descriptor@ = 0x7ffd81181870
Memref base@ = 0x55883b438ec0 rank = 1 offset = 0 sizes = [4] strides = [1] data = 
[10,  10,  10,  10]
```
Find this example [here](https://github.com/rise-lang/mlir/blob/feature/riseConversion/mlir/test/Conversion/RiseToImperative/simple_map.mlir)
