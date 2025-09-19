# Code Generation

## Types
```@autodocs
Modules = [ComputableDAGs]
Pages = ["code_gen/type.jl"]
Order = [:type, :constant, :function]
```

## Function Generation
Implementations for generation of a callable function. A function generated this way cannot immediately be called. One Julia World Age has to pass before this is possible, which happens when the global Julia scope advances. If the DAG and therefore the generated function becomes too large, use the tape machine instead, since compiling large functions becomes infeasible.
```@autodocs
Modules = [ComputableDAGs]
Pages = ["code_gen/function.jl"]
Order = [:function]
```

## Tape Machine
```@autodocs
Modules = [ComputableDAGs]
Pages = ["code_gen/tape_machine.jl"]
Order = [:function]
```
