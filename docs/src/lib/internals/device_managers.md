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
create_device_manager
close_device_manager
send
get
device_manager_setup_code
device_manager_destroy_code
```
