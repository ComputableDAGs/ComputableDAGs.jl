using AMDGPU

"""
    ROCmGPU <: AbstractGPU

Representation of a specific AMD GPU that code can run on. Implements the [`AbstractDevice`](@ref) interface.
"""
mutable struct ROCmGPU <: GraphComputing.AbstractGPU
    device::Any
    cacheStrategy::CacheStrategy
    FLOPS::Float64
end

push!(GraphComputing.DEVICE_TYPES, ROCmGPU)

GraphComputing.CACHE_STRATEGIES[ROCmGPU] = [LocalVariables()]

GraphComputing.default_strategy(::Type{ROCmGPU}) = LocalVariables()

function GraphComputing.measure_device!(device::ROCmGPU; verbose::Bool)
    if verbose
        println("Measuring ROCm GPU $(device.device)")
    end

    # TODO implement
    return nothing
end

"""
    get_devices(::Type{ROCmGPU}; verbose::Bool = false)

Return a Vector of [`ROCmGPU`](@ref)s available on the current machine. If `verbose` is true, print some additional information.
"""
function get_devices(::Type{ROCmGPU}; verbose::Bool=false)
    devices = Vector{AbstractDevice}()

    if !AMDGPU.functional()
        if verbose
            println("AMDGPU is non-functional")
        end
        return devices
    end

    AMDDevices = AMDGPU.devices()
    if verbose
        println("Found $(length(AMDDevices)) AMD devices")
    end
    for device in AMDDevices
        push!(devices, ROCmGPU(device, default_strategy(ROCmGPU), -1))
    end

    return devices
end
