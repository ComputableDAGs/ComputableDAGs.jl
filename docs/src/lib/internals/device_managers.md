```@meta
CurrentModule = ComputableDAGs
```

# Device Managers

Device managers manage [`AbstractDevice`](@ref)s by taking care of communication
aspects through a unified interface.

## Types

```@docs
AbstractDeviceManager
ZMQDeviceManager
```

## Functions

```@docs
create_zmq_manager
close_zmq_manager
send
get
```
