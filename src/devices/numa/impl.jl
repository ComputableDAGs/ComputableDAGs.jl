using NumaAllocators

"""
    NumaNode <: AbstractCPU

Representation of a specific CPU that code can run on. Implements the [`AbstractDevice`](@ref) interface.
"""
mutable struct NumaNode <: AbstractCPU
    numaId::UInt16
    threads::UInt16
    cacheStrategy::CacheStrategy
    FLOPS::Float64
    id::UUID
end

push!(DEVICE_TYPES, NumaNode)

CACHE_STRATEGIES[NumaNode] = [LocalVariables()]

default_strategy(::Type{T}) where {T<:NumaNode} = LocalVariables()

function measure_device!(device::NumaNode; verbose::Bool)
    if verbose
        println("Measuring Numa Node $(device.numaId)")
    end

    # TODO implement
    return nothing
end

"""
    get_devices(deviceType::Type{T}; verbose::Bool) where {T <: NumaNode}

Return a Vector of [`NumaNode`](@ref)s available on the current machine. If `verbose` is true, print some additional information.
"""
function get_devices(deviceType::Type{T}; verbose::Bool = false) where {T<:NumaNode}
    devices = Vector{AbstractDevice}()
    noNumaNodes = highest_numa_node()

    if (verbose)
        println("Found $(noNumaNodes + 1) NUMA nodes")
    end
    for i = 0:noNumaNodes
        push!(devices, NumaNode(i, 1, default_strategy(NumaNode), -1, UUIDs.uuid1(rng[1])))
    end

    return devices
end

"""
    gen_cache_init_code(device::NumaNode)

Generate code for initializing the [`LocalVariables`](@ref) strategy on a [`NumaNode`](@ref).
"""
function gen_cache_init_code(device::NumaNode)
    if typeof(device.cacheStrategy) <: LocalVariables
        # don't need to initialize anything
        return Expr(:block)
    elseif typeof(device.cacheStrategy) <: Dictionary
        return Meta.parse("cache_$(to_var_name(device.id)) = Dict{Symbol, Any}()")
        # TODO: sizehint?
    end

    return error(
        "Unimplemented cache strategy \"$(device.cacheStrategy)\" for device \"$(device)\"",
    )
end

"""
    gen_access_expr(device::NumaNode, symbol::Symbol)

Generate code to access the variable designated by `symbol` on a [`NumaNode`](@ref), using the [`CacheStrategy`](@ref) set in the device.
"""
function gen_access_expr(device::NumaNode, symbol::Symbol)
    return _gen_access_expr(device, device.cacheStrategy, symbol)
end

"""
    _gen_access_expr(device::NumaNode, ::LocalVariables, symbol::Symbol)

Internal function for dispatch, used in [`gen_access_expr`](@ref).
"""
function _gen_access_expr(device::NumaNode, ::LocalVariables, symbol::Symbol)
    s = Symbol("data_$symbol")
    quoteNode = Meta.parse(":($s)")
    return quoteNode
end

"""
    _gen_access_expr(device::NumaNode, ::Dictionary, symbol::Symbol)

Internal function for dispatch, used in [`gen_access_expr`](@ref).
"""
function _gen_access_expr(device::NumaNode, ::Dictionary, symbol::Symbol)
    accessStr = ":(cache_$(to_var_name(device.id))[:$symbol])"
    quoteNode = Meta.parse(accessStr)
    return quoteNode
end
