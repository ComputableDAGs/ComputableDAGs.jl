# Estimation

## Interface

The interface that has to be implemented for an estimator.

```@autodocs
Modules = [ComputableDAGs]
Pages = ["estimator/interface.jl"]
Order = [:type, :constant, :function]
```

## Global Metric Estimator

Implementation of a global metric estimator. It uses the graph properties compute effort, data transfer, and compute intensity.

```@autodocs
Modules = [ComputableDAGs]
Pages = ["estimator/global_metric.jl"]
Order = [:type, :function]
```
