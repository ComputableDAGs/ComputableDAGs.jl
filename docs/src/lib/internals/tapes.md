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
lower(::Tape{CPU}, devices_on_machine::AbstractVector{UUID})
lower(::TapeRack)
tape_function
```
