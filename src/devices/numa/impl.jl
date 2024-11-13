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

"""
    _gen_access_expr(device::NumaNode, symbol::Symbol)

Interface implementation, dispatched to from [`gen_access_expr`](@ref).
"""
function _gen_access_expr(::NumaNode, symbol::Symbol)
    # TODO rewrite these with Expr instead of quote node
    s = Symbol("data_$symbol")
    quote_node = Meta.parse(":($s)")
    return eval(quote_node)
end

"""
    _gen_local_init(device::NumaNode, symbol::Symbol, type::Type)

Interface implementation, dispatched to from [`gen_local_init`](@ref).
"""
function _gen_local_init(::NumaNode, symbol::Symbol, type::Type)
    s = Symbol("data_$(symbol)")
    quote_node = Expr(:local, s, :(::), Symbol(type))
    return quote_node
end
