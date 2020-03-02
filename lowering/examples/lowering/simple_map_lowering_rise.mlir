func @print_memref_f32(memref<*xf32>)
func @simple_map_example() {

    %res = rise.fun {
        %array = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>
        %doubleFun = rise.lambda (%summand) : !rise.fun<data<float> -> data<float>> {
            %addFun = rise.add #rise.float
            %double = rise.apply %addFun, %summand, %summand
            rise.return %double : !rise.data<float>
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
