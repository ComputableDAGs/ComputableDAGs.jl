```@meta
CurrentModule = ComputableDAGs
```

# Nodes

Nodes are the objects that make up the computational graphs that everything bases on.

## Types

```@docs
Node
```

## Functions

```@docs
Node(task::Task) where {Task <: AbstractComputeTask}
is_entry_node
is_exit_node
task
var_name
Base.show(io::IO, node::Node)
```
