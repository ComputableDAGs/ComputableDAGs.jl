```@meta
CurrentModule = ComputableDAGs
```

# Cluster/Machines

## Types

```@docs
Cluster
Machine
```

## Functions

```@docs
has_device(machine::Machine, device_id::UUID)
has_device(cluster::Cluster, device_id::UUID)
local_devices
network_devices
device_manager_type
```
