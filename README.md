# MLIR

## Rise Dialect

[paper](https://michel.steuwer.info/publications/2020/AccML/)
[poster](https://drive.google.com/file/d/1mFumDjE5GHcsp9AFEDqF6kx4X9mT0LRT/view)




### Design


##### Operations: 
- rise.lambda
- rise.apply

- rise.zip
- rise.map
- rise.reduce
- rise.tuple
- rise.fst
- rise.snd

- rise.fun
- rise.in
- rise.return
- rise.add
- rise.mul

##### Typesystem:

- We strongly differ between functions and data. e.g we can never store functions
  in an array 
- Nats are used for indexing Arrays. They will support computations an the
  indices.
- We will see whether we can integrate more closely with datatypes of other
  dialects (e.g. memrefs)
![typesystem](ressources/type_system.png)

All our operations return a **RiseType**. `rise.literal` and `rise.apply` return a **Data** and all others return a **FunType**. 
This means an operation will never directly produce a `!rise.float` but always
a `rise.data<float>`: a float wrapped in a **Data**.

Next to the operations we have the following Attributes:
`NatAttr`             -> `#rise.nat<natural_number_here>`           e.g. #rise.nat<1>

`DataTypeAttr`        -> `#rise.some_datatype_here`                 e.g. #rise.float or #rise.array<float, 4>

`LiteralAttr`         -> `#rise.lit<some_datatype_and_its_value>`   e.g  #rise.lit<float<2>> (printing form likely to change soon to seperate type from value better!)


##### We follow the mlir syntax:

Operations begin with:      `rise.`

Types begin with:           `!rise.`    (although we omit !rise. when nesting types)

Attributes begin with:      `#rise.`

See the following examples:

- `!rise.float` -                           Float type

- `!rise.array<4, float>` -                 ArrayType of size 4 with elementType float

- `!rise.array<2, array<2, int>` -         ArrayType of size 2 with elementType Arraytype of size 2 with elementType int


- `!rise.data<float>>` -                    Data containing the DataType Float (might for example be the result of a Lambda)
  
- `!rise.data<array<4, float>>` -           Data containint an ArrayType of size 4 with elementType float

- `!rise.fun<data<float> -> data<int>>` -   FunType from data<float> to data<int>
  
- `!rise.fun<fun<data<int> -> data<int>> -> data<int>>` -   FunType with input FunType from (data<int> to data<int>) to data<int> 
  
Note FunTypes always have a RiseType (either Data or FunType) both as input and output!


- `#rise.lit<float<4>>` -                   LiteralAttribute containing a float of value 4

- `#rise.lit<array<4, float, [1,2,3,4]>` - LiteralAttribute containing an Array of 4 floats with values, 1,2,3 and 4 




### Lowering to imperative

Lowering rise code (everything within rise.fun) to imperative is accomplished
with the `riseToImperative` pass of `mlir-opt`. This brings us from the
functional lambda calculus representation of mlir to an imperative
representation, which for us right now means a mixture of the std, loop and
linalg dialects.
Leveraging the existing passes in MLIR, we can emit the llvm IR dialect by
executing the passes: `mlir-opt -convert-rise-to-imperative -convert-linalg-to-loops -convert-loop-to-std -convert-std-to-llvm`


##### Intermediate Stage
Besides the operations shown above which model lambda calculus, we also have
the the following `codegen` operations, which drive imperative code generation. These are intermediate operations in the sense that they are created and consumed in the riseToImperative pass. They will not be emmitted.

- rise.codegen.assign
- rise.codegen.idx
- rise.codegen.bin_op
- rise.codegen.zip
- rise.codegen.fst
- rise.codegen.snd

These Intermediate operations are constructed during the first lowering phase
(rise -> intermediate) and mostly used to model indexing for reading and
writing multidimensional data. For details on the translation of these codegen
operations to the final indexings refer to Figure 6 of [this paper[1]](https://michel.steuwer.info/files/publications/2017/arXiv-2017.pdf).



##### Here are further descriptions of lowering specific examples:
- [current state of lowering to imperative](lowering/state_of_lowering_23_03.md)
- [current(outdated) state of lowering to imperative](lowering/state_of_lowering.md)
- [lowering strategy and concepts](lowering/lowering_strategy_and_concepts.md)
- [lowering a simple reduction](lowering/simple_reduction_lowering.md)
- [lowering a simple 2D map](lowering/simple_2D_map_lowering.md)
- [lowering a simple map](lowering/simple_map_lowering.md)
- [lowering a simple zip](lowering/simple_zip_lowering.md)

outdated but kept around for later reference:
- [outdated - lowering a simple reduction - example](lowering/old_reduce_lowering_to_imperative.md)
- [outdated - lowering a reduction - IR transformation](lowering/old_reduction_lowering_IR_transformations.md)
- [concept for lowering a dot_product](lowering/concept_for_lowering_dot_product.md)
- [matrix-multiplication example](lowering/matrix_multiplication_example_uday.md)
