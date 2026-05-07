```@meta
CurrentModule = ComputableDAGs
```

# Tasks

Tasks are the fundamental representation of pieces of work to be done, most commonly computation of single inputs into single outputs. Tasks have a computation associated with them, which is implemented as multiple dispatch on an instance of the task and all its arguments, see [`compute`](@ref ComputableDAGs.compute).

## Types

```@docs
AbstractTask
AbstractComputeTask
```

## Functions

```@docs
compute
```
