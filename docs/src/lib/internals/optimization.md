# Optimization

## Interface

The interface that has to be implemented for an optimization algorithm.

```@autodocs
Modules = [ComputableDAGs]
Pages = ["optimization/interface.jl"]
Order = [:type, :constant, :function]
```

## Random Walk Optimizer

Implementation of a random walk algorithm.

```@autodocs
Modules = [ComputableDAGs]
Pages = ["optimization/random_walk.jl"]
Order = [:type, :function]
```

## Reduction Optimizer

Implementation of a an optimizer that reduces as far as possible.

```@autodocs
Modules = [ComputableDAGs]
Pages = ["optimization/reduce.jl"]
Order = [:type, :function]
```

## Split Optimizer

Implementation of an optimizer that splits as far as possible.

```@autodocs
Modules = [ComputableDAGs]
Pages = ["optimization/split.jl"]
Order = [:type, :function]
```


## Greedy Optimizer

Implementation of a greedy optimization algorithm.

```@autodocs
Modules = [ComputableDAGs]
Pages = ["optimization/greedy.jl"]
Order = [:type, :function]
```
