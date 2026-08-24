```@meta
CurrentModule = ComputableDAGs
```

# Tapes

Tapes represent the code to run on a single device.

## Types

```@docs
TapeRack
Tape
```

## Functions

```@docs
lower(::Tape{CPU}, ::Cluster)
lower(::TapeRack, ::Cluster, ::Module)
tape_function
```
