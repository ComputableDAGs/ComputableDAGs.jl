"""
    oneAPIGPU <: AbstractGPU

Representation of a specific Intel GPU that code can run on. Implements the [`AbstractDevice`](@ref) interface.
"""
mutable struct oneAPIGPU <: ComputableDAGs.AbstractGPU
    device::Any
    cacheStrategy::CacheStrategy
    FLOPS::Float64
end

push!(ComputableDAGs.DEVICE_TYPES, oneAPIGPU)

ComputableDAGs.CACHE_STRATEGIES[oneAPIGPU] = [LocalVariables()]

ComputableDAGs.default_strategy(::Type{oneAPIGPU}) = LocalVariables()

function ComputableDAGs.measure_device!(device::oneAPIGPU; verbose::Bool)
    if verbose
        println("Measuring oneAPI GPU $(device.device)")
    end

    # TODO implement
    return nothing
end

"""
    get_devices(::Type{oneAPIGPU}; verbose::Bool = false)

Return a Vector of [`oneAPIGPU`](@ref)s available on the current machine. If `verbose` is true, print some additional information.
"""
function get_devices(::Type{oneAPIGPU}; verbose::Bool=false)
    devices = Vector{AbstractDevice}()

    if !oneAPI.functional()
        if verbose
            println("oneAPI is non-functional")
        end
        return devices
    end

    oneAPIDevices = oneAPI.devices()
    if verbose
        println("Found $(length(oneAPIDevices)) oneAPI devices")
    end
    for device in oneAPIDevices
        push!(devices, oneAPIGPU(device, default_strategy(oneAPIGPU), -1))
    end

    return devices
end
