"""
    Machine

A machine represents one physical computer architecture, in which all devices
can communicate with each other without network. It is made up of one or more
[`AbstractDevice`](@ref)s. A machine can be part of a [`Cluster`](@ref).
"""
struct Machine
    devices::Vector{AbstractDevice}
end

"""
    Cluster{DEV_MANAGER <: AbstractDeviceManager}

A cluster represents the entirety of the hardware that a
[`ComputableDAG`](@ref) can be executed on. It is made up of one or more
[`Machine`](@ref)s. It also knows about the type of
[`AbstractDeviceManager`](@ref) used by the cluster.
"""
struct Cluster{DEV_MANAGER <: AbstractDeviceManager}
    machines::Vector{Machine}
end
