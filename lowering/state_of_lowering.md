[index](../README.md)


### changes
- translation is much more similar to the description in the paper and less
  ad-hoc than before
- introduced new intermediate patterns for this: rise.idx, rise.bin_op, rise.assign
- see example below on state after "Acceptor Translation"
- rise.fun does not produce a value anymore.
- rise.fun gets an output memref as 1st argument
- rise.fun will prob. be a normal mlir func with a rise attribute in the future



    Example
    ```C++
func @print_memref_f32(memref<*xf32>)
func @rise_fun(memref<4xf32>)
func @array_times_2() {
    
    rise.fun "rise_fun" (%outArg:memref<4xf32>) {
        %out = rise.out %outArg
        %array = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>
        %doubleFun = rise.lambda (%summand) : !rise.fun<data<float> -> data<float>> {
            %addFun = rise.add #rise.float
            %doubled = rise.apply %addFun, %summand, %summand
            rise.return %doubled : !rise.data<float>
        }
        %map4IntsToInts = rise.map #rise.nat<4> #rise.float #rise.float
        %doubledArray = rise.apply %map4IntsToInts, %doubleFun, %array

        rise.return %doubledArray : !rise.data<array<4, float>>
    }

    //prepare output Array
    %outputArray = alloc() : memref<4xf32>
    call @rise_fun(%outputArray) : (memref<4xf32>) -> ()

    %print_me = memref_cast %outputArray : memref<4xf32> to memref<*xf32>
    call @print_memref_f32(%print_me): (memref<*xf32>) -> ()
    return
}
    ```
    
    ```
        |       Lowering to Imperative: mlir-opt map_add.mlir -convert-rise-to-imperative        
        |           Dialect Conversion: (rise)              -> (std x loop x linalg) 
        |           rise.fun                                -> @riseFun(): (memref) -> () ... call @riseFun
        |           rise.literal                            -> alloc() : memref ... linalg.fill
        |           rise.map ... rise.apply ... rise.apply  -> loop.for
        |           rise.lambda{rise.add}                   -> rise.bin_op ... rise.assign
        V
    ```
   
    ```C++
module {
  func @rise_fun(%arg0: memref<4xf32>) {
    %0 = alloc() : memref<4xf32>
    %cst = constant 5.000000e+00 : f32
    linalg.fill(%0, %cst) : memref<4xf32>, f32 
    %c0 = constant 0 : index 
    %c4 = constant 4 : index 
    %c1 = constant 1 : index 
    loop.for %arg1 = %c0 to %c4 step %c1 {
      %1 = "rise.idx"(%0, %arg1) : (memref<4xf32>, index) -> memref<f32> 
      %2 = "rise.idx"(%arg0, %arg1) : (memref<4xf32>, index) -> memref<f32> 
      %3 = "rise.bin_op"(%1, %1) : (memref<f32>, memref<f32>) -> f32 
      "rise.assign"(%3, %2) : (f32, memref<f32>) -> () 
    }
    return loc("map_add.mlir":18:9)
  } 
  func @print_memref_f32(memref<*xf32>) 
  func @array_times_2() {
    %0 = alloc() : memref<4xf32>
    call @rise_fun(%0) : (memref<4xf32>) -> ()
    %1 = memref_cast %0 : memref<4xf32> to memref<*xf32>
    call @print_memref_f32(%1) : (memref<*xf32>) -> () 
    return
  }
}
```
interesting picture
![some image](https://user-images.githubusercontent.com/10148468/73613904-2f720a00-45c8-11ea-8265-1c856c02525b.png "")
