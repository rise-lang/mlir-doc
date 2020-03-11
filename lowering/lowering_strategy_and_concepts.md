[index](../README.md)
##### Notes beforehand
- a rise program is always embedded in the region of a **rise.fun**

# Lowering Concepts


The Lowering of the functional Rise dialect to imperative is strongly
influenced by [this paper[1]](https://michel.steuwer.info/files/publications/2017/arXiv-2017.pdf) (see section 4).


## Implementation
- We create a function *riseFun* and replace all uses of the result of rise.fun with a call to *riseFun*

    `%0 = rise.fun {...}`        ->          `%0 = call @riseFun`
- Lowering is started by calling the **AccT** with the last **Apply** in a rise
program. 
- From this apply we walk bottom-up through the program and lower the
  operations according to [1].
- Finally we erase the rise.fun operation

#### Acct(ApplyOp apply, OutputPathType outputPath){...}
Invariants:
- The **insertionPoint** of the rewriter is expected to be set before calling
  Acct. This function will only set the insertionPoint relative to the given
one.

Process:
- Get the applied function (first operand of the given ApplyOp)
- If it is another apply (i.e. partial application) we walk the applies until we find the applied function which is not an ApplyOp. In this process we also collect all other operands of the applies.
- The applied function provides context about what to do with the collected operands. Depending on this we generate code (e.g. a loop.for for a rise.reduce) and call the ConT/AccT for specific(all?) operands.
    - for rise.map (rise.apply %mapFun %lambda %array) we do:
        ```
        contArray   = ConT(%array)
        lowerBound  = rewriter.create<ConstantIndexOp>(0)
        upperBound  = rewriter.create<ConstantIndexOp>(getAttr(n))
        step        = rewriter.create<ConstantIndexOp>(1)
        forLoop     = rewriter.create<loop::ForOp>(lowerBound, upperBound, step)
        load        = rewriter.create<std::LoadOp>(contArray, loopInductionVar)
        contLambda  = AccT(%lambda)
        store       = rewriter.store<std::StoreOp>(contArray, loopInductionVar)
        ```

- When **rise.add** or **rise.mul** are used without apply and passed directly to e.g
  rise.reduce we expand them during lowering to a lambda.

#### ConT(mlir::Value contValue) {...}

## Design Discussion

notes:
    - output "Acceptor", which is the out, the rise.fun has as first argument
      is of rise DataType and has to be passed to AccT.
    - I have to implement other Acceptors as operationsj
    - I have to implement at least rise.idx, rise.assign, rise.unzip. These ar


#### Interface of rise.fun  
Current proposal:
- to interface nicely with other mlir IRs (namely Affine, Linalg + others using
  memregs) we accept memrefs as input and return memrefs.

Quote: "In particular, the **MemRefType** represents dense **non-contiguous** memory
regions. This structure should extend beyond simple dense data types and
generalize to ragged, sparse and mixed dens/sparse **tensors** as well as to **trees,
hash tables, tables of records** and maybe even **graphs**."

    Example
    ```C++
    rise.fun (%in: memref<4xf32>) {
        %in_rise = rise.in %in
        //type: (memref<4xf32>) -> !rise.data<array<4, float>>
        ...
        rise.return %riseArray : !rise.data<array<4, float>>
    } : (memref<4xf32>) -> memref<4xf32>
    ```
    ```
                |
                |
                V
    ```
   
    mockup: 
    ```C++
    module {
    func @riseFun(%in) -> memref<4xf32> {
        %in_rise = rise.cast %in                                    // cast into a rise type
        %c0 = constant 0 : index
        %c4 = constant 4 : index
        %c1 = constant 1 : index
        loop.for %arg0 = %c0 to %c4 step %c1 {
            %1 = load %in_rise[%arg0] : memref<4xf32>
            %2 = addf %1, %1 : f32
            store %2, %in_rise[%arg0] : memref<4xf32>
        }
        return %0 : memref<4xf32>
    }
    func @print_memref_f32(memref<*xf32>)
    func @simple_map_example() {
        %in = alloc() : memref<4xf32>
        %cst = constant 5.000000e+00 : f32
        linalg.fill(%in, %cst) : memref<4xf32>, f32

        %0 = call @riseFun(%in) : () -> memref<4xf32>
        %1 = memref_cast %0 : memref<4xf32> to memref<*xf32>
        call @print_memref_f32(%1) : (memref<*xf32>) -> ()
        return
    }
    ```
Extension to support outputting to a given memref.
- inputs in first (), output(s?) in second pair of ()
- When output is given we work with it, otherwise we allocate memory for the
  output ourself
    ```C++
    rise.fun (%in: memref<4xf32>)(out: %out: memref<4xf32>) {
        %in_rise = rise.in %in
        //type: (memref<4xf32>) -> !rise.data<array<4, float>>
        ...
        rise.return %riseArray : !rise.data<array<4, float>>
    } : (memref<4xf32>) -> memref<4xf32>
    ```



## Open Questions

- Currently I expect a "chain" of applies to be partial application
and treat them like a single apply. However this breaks in this case. How could
we handle this?
    ```C++
        %map1 = rise.map #rise.nat<4> #rise.array<4, !rise.float> #rise.array<4, !rise.float>
        %map2 = rise.map #rise.nat<4> #rise.float #rise.float

        %mapInner = rise.apply %map2, %doubleFun //: !rise.fun<fun<data<float> -> data<float>> -> fun<data<array<4, float>> -> data<array<4, float>>>>, %doubleFun
        %map2D = rise.apply %map1, %mapInner //: !rise.fun<fun<data<array<4, float>> -> data<array<4, float>>> -> fun<data<array<4, array<4, float>>> -> data<array<4, array<4, float>>>>>, %mapInner
        %res = rise.apply %map2D, %array2D

//        %res = rise.apply %map1, %map2, %doubleFun, %array2D

    ```

- What type should the arguments of rise.fun have? 
    - memref vs one of our types?
    - lowering to memreft is fine, we can always write another pass which
      lowers using different types.
    - we should not restrict our IR to use memref. We should prob. require our
      own type and handle this during lowering
    - Problem with this: How will other dialect pass arguments to us then?
    - We could also make no restrictions on the types of rise.fun and handle
      conversion of the arguments during lowering.  

Where are we in this picture?

![some image](https://user-images.githubusercontent.com/10148468/73613904-2f720a00-45c8-11ea-8265-1c856c02525b.png "")
