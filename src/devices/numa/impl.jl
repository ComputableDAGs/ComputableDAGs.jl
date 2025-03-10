using NumaAllocators

"""
    NumaNode <: AbstractCPU

Representation of a specific CPU that code can run on. Implements the [`AbstractDevice`](@ref) interface.
"""
mutable struct NumaNode <: AbstractCPU
    numaId::UInt16
    threads::UInt16
    FLOPS::Float64
    id::UUID
end

push!(DEVICE_TYPES, NumaNode)

function measure_device!(device::NumaNode; verbose::Bool)
    verbose && @info "Measuring Numa Node $(device.numaId)"

    # TODO implement
    return nothing
end

"""
    get_devices(deviceType::Type{T}; verbose::Bool) where {T <: NumaNode}

Return a Vector of [`NumaNode`](@ref)s available on the current machine. If `verbose` is true, print some additional information.
"""
function get_devices(deviceType::Type{T}; verbose::Bool=false) where {T<:NumaNode}
    devices = Vector{AbstractDevice}()
    noNumaNodes = highest_numa_node()

    verbose && @info "Found $(noNumaNodes + 1) NUMA nodes"

    for i in 0:noNumaNodes
        push!(devices, NumaNode(i, 1, -1, UUIDs.uuid1(rng[1])))
    end

    return devices
end
