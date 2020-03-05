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

#### Acct (maybe rename to ApplyT or so?)
Invariants:
- The **insertionPoint** of the rewriter is expected to be set before calling
  Acct. This function will only set the insertionPoint relative to the given
one.
- 


#### ConT (maybe rename to PatternT or so?)


## Open Questions
- What type should the arguments of rise.fun have? 
    - memref vs one of our types?
    - lowering to memreft is fine, we can always write another pass which
      lowers using different types.
    - we should not restrict our IR to use memref. We should prob. require our
      own type and handle this during lowering
    - Problem with this: How will other dialect pass arguments to us then?
    - We could also make no restrictions on the types of rise.fun and handle
      conversion of the arguments during lowering.  
- Names AccT and ConT don't really correspond to the equivalents in the paper
  [1], Rename them?
- Right now I handle things like rise.add and rise.lambda differently. I have
  to think more about this.
