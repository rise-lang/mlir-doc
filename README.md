# MLIR

## Rise Dialect
The bigger picture: [paper](https://michel.steuwer.info/publications/2020/AccML/)

A nice looking picture: [poster](https://drive.google.com/file/d/1mFumDjE5GHcsp9AFEDqF6kx4X9mT0LRT/view)

A 30fps sequence of pictures: [Rise @ MLIR ODM talk](https://drive.google.com/drive/u/0/folders/1ysFBcQhlgDiJg-K87m4WRTa7dKLUyiDM)

### Design

##### Operations:

*Core lambda calculus*:
`rise.lambda`
`rise.apply`
`rise.return`

*Patterns*:
`rise.zip`
`rise.mapSeq`
`rise.mapPar`
`rise.reduceSeq`
`rise.tuple`
`rise.fst`
`rise.snd`

*Interoperability*:
`rise.embed`
`rise.in`
`rise.out`

##### Typesystem:

- We clearly separate between functions and data, i.e. we can never store functions
  in an array
- **Nat**s are used for denoting the dimensions of **Array**s. They will support computations in the indices.
- **Scalar**s are used to wrap arbitrary scalar types from other MLIR dialects e.g. `scalar<f32>`


![typesystem](resources/type_system_new.png)

All our operations return a **RiseType**. `rise.literal` and `rise.apply` return a **Data** and all others return a **FunType**. 

Next to the operations we have the following *Attributes*:
`NatAttr`             -> `#rise.nat<natural_number_here>`           e.g. `#rise.nat<1>`

`DataTypeAttr`        -> `#rise.some_datatype_here`                 e.g. `#rise.scalar<f32> or #rise.array<4, scalar<f32>>`

`LiteralAttr`         -> `#rise.lit<some_datatype_and_its_value>`   e.g  `#rise.lit<2.0>` (printing form likely to change soon to seperate type from value better!)


##### Syntax:

We follow the mlir syntax.

*Operations* begin with:      `rise.`

*Types* begin with:           `!rise.`    (although we omit `!rise.` when nesting types, e.g. `!rise.array<4, scalar<f32>>` instead of `!rise.array<4, !rise.scalar<f32>>`)

*Attributes* begin with:      `#rise.`

See the following examples of types:

- `!rise.scalar<f32>` -                           Float type

- `!rise.array<4, scalar<f32>>` -                 ArrayType of size `4` with elementType `scalar<f32>`

- `!rise.array<2, array<2, scalar<f32>>` -         ArrayType of size `2` with elementType Arraytype of size `2` with elementType `scalar<f32>`


Note FunTypes always have a RiseType (either Data or FunType) both as input and output!

- `!rise.fun<tuple<scalar<f32>, scalar<f32>> -> scalar<f32>>` -   FunType from a tuple of two `scalar<f32>` to a single `scalar<f32>`
  
- `!rise.fun<fun<scalar<f32> -> scalar<f32>> -> scalar<f32>>` -   FunType with input FunType from (`scalar<f32>` to `scalar<f32>`) to `scalar<f32>` 

See the following examples of attributes:

- `#rise.lit<4.0>` -                   LiteralAttribute containing a `float` of value `4`

- `#rise.lit<array<4, scalar<f32>, [1,2,3,4]>` - LiteralAttribute containing an Array of `4` floats with values, 1,2,3 and 4 

##### Modeling of Lambda Calculus:

Consider the following example: `map(fun(summand => summand + summand), [5, 5, 5, 5])` that will compute `[10, 10, 10, 10]`.

We have the `map` function that is called with two arguments: a lambda expression that doubles it's input and an array literal.
We model each of these components individually:
 - the function call via a `rise.apply` operation;
 - the `map` function via the `rise.map` operation;
 - the lambda expression via the `rise.lambda` operation; and finally
 - the array literal via the `rise.literal` operation.
 
Overall the example in the Rise MLIR dialect looks like
```
%array = rise.literal #rise.lit<array<4, !rise.float, [5,5,5,5]>>
%doubleFun = rise.lambda (%summand : !rise.scalar<f32>) -> !rise.scalar<f32> {
  %doubled = rise.embed(%summand) {
    %added = addf %summand, %summand : f32
    rise.return %added : f32
  }
  rise.return %doubled : !rise.scalar<f32>
}
%map = rise.map #rise.nat<4> #rise.scalar<f32> #rise.scalar<f32>
%mapDoubleFun = rise.apply %map, %doubleFun %array
```

Let us highlight some key principles regarding the `map` operation that are true for all Rise patterns (`zip`, `fst`, ...):
- `rise.map` is a function that is called using `rise.apply`.
- For `rise.map` a couple of attributes are specified, here: `rise.map #rise.nat<4> #rise.scalar<f32> #rise.scalar<f32>`.
  These are required to specify the type of the `map` function at this specific call site.
  You can think about the `rise.map` operation as being *polymorphic* and that the attributes specify the type parameters to make the resulting MLIR value `%map` *monomorphic* (i.e. it has a concrete type free of type parameters).

### Lowering to imperative

Lowering rise code to imperative is accomplished
with the `riseToImperative` pass of `mlir-opt`.

This brings us from the functional lambda calculus representation of rise to an imperative
representation, which for us right now means a mixture of the std, loop and
linalg dialects.

Leveraging the existing passes in MLIR, we can emit the llvm IR dialect by
executing the passes: `mlir-opt -convert-rise-to-imperative -convert-linalg-to-loops -convert-loop-to-std -convert-std-to-llvm`


##### Intermediate Stage
The operations shown above model lambda calculus together with common data parallel patterns and some operations for interoperability with other dialetcs.
Besides we also have the following internal `codegen` operations, which drive the imperative code generation. These are intermediate operations in the sense that they are created and consumed in the riseToImperative pass. They should not be used manually. They will not be emmitted in the lowered code.

- `rise.codegen.assign`
- `rise.codegen.idx`
- `rise.codegen.zip`
- `rise.codegen.fst`
- `rise.codegen.snd`

These Intermediate operations are constructed during the first lowering phase
`(rise -> intermediate)` and are mostly used to model indexing for reading and
writing multidimensional data. They have similarities with views on the data. For details on the translation of these codegen
operations to the final indexings refer to Figure 6 of [this paper[1]](https://michel.steuwer.info/files/publications/2017/arXiv-2017.pdf).


#### Lowering different examples to imperative code (scf + std)
- [lowering with better composability](lowering/lowering_with_better_composability.md)

#### Design Discussions
- [changing types of intermediate codegen
  representation](lowering/changing_intermediate_types.md)


##### Outdated but kept for future reference: Here are further descriptions of lowering specific examples:
- [current state of lowering to imperative](lowering/state_of_lowering_23_03.md)
- [current(outdated) state of lowering to imperative](lowering/state_of_lowering.md)
- [lowering strategy and concepts](lowering/lowering_strategy_and_concepts.md)
- [lowering a simple reduction](lowering/simple_reduction_lowering.md)
- [lowering a simple 2D map](lowering/simple_2D_map_lowering.md)
- [lowering a simple map](lowering/simple_map_lowering.md)
- [lowering a simple zip](lowering/simple_zip_lowering.md)
- [outdated - lowering a simple reduction - example](lowering/old_reduce_lowering_to_imperative.md)
- [outdated - lowering a reduction - IR transformation](lowering/old_reduction_lowering_IR_transformations.md)
- [concept for lowering a dot_product](lowering/concept_for_lowering_dot_product.md)
- [matrix-multiplication example](lowering/matrix_multiplication_example_uday.md)
