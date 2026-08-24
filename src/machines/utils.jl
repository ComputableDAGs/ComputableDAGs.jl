"""
    device_manager_type(::Cluster{T})

Helper function which returns the device manager type of the given cluster.
"""
device_manager_type(::Cluster{T}) where {T} = T

"""
    has_device(machine::Machine, device_id::UUID)

Return whether the [`AbstractDevice`](@ref) with the given id is part of the
[`Machine`](@ref).
"""
function has_device(machine::Machine, device_id::UUID)
    return any(dev -> dev.id == device_id, machine.devices)
end

"""
    has_devices(cluster::Cluster, device_id::UUID)

Return whether the [`AbstractDevice`](@ref) with the given id is part of the
[`Cluster`](@ref).
"""
function has_device(cluster::Cluster, device_id::UUID)
    no_machines = sum(has_device.(cluster.machines, Ref(device_id)))

    if no_machines > 1
        @warn "device with id $device_id is part of more than one machine ($no_machines machines) in the given cluster"
    end

    return no_machines >= 1
end

"""
    local_devices(cluster::Cluster, device_id::UUID)

Return the vector of other devices in the [`Cluster`](@ref) that are
reachable without network, i.e., that live on the same [`Machine`](@ref).
"Other" devices means excluding the one with the given device id.

See also: [`network_devices`](@ref)
"""
function local_devices(cluster::Cluster, device_id::UUID)
    for m in cluster.machines
        if has_device(m, device_id)
            return filter(dev -> dev.id != device_id, m.devices)
        end
    end
    @warn "local_devices requested of a device (id: $device_id) that is not part of the cluster"
    return AbstractDevice[]
end

"""
    network_devices(cluster::Cluster, device_id::UUID)

Return the list of other devices in the [`Cluster`](@ref) that are
only reachable through the network, i.e., that live on other
[`Machine`](@ref)s.

See also: [`local_devices`](@ref)
"""
function network_devices(cluster::Cluster, device_id::UUID)
    devs = AbstractDevice[]
    for m in cluster.machines
        if !has_device(m, device_id)
            append!(devs, m.devices)
        end
    end

    return devs
end
