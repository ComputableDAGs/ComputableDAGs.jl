using CUDA

"""
    CUDAGPU <: AbstractGPU

Representation of a specific CUDA GPU that code can run on. Implements the [`AbstractDevice`](@ref) interface.
"""
mutable struct CUDAGPU <: AbstractGPU
    device::Any # TODO: what's the cuda device type?
    cacheStrategy::CacheStrategy
    FLOPS::Float64
end

push!(DEVICE_TYPES, CUDAGPU)

CACHE_STRATEGIES[CUDAGPU] = [LocalVariables()]

default_strategy(::Type{T}) where {T<:CUDAGPU} = LocalVariables()

function measure_device!(device::CUDAGPU; verbose::Bool)
    if verbose
        println("Measuring CUDA GPU $(device.device)")
    end

    # TODO implement
    return nothing
end

"""
    get_devices(deviceType::Type{T}; verbose::Bool) where {T <: CUDAGPU}

Return a Vector of [`CUDAGPU`](@ref)s available on the current machine. If `verbose` is true, print some additional information.
"""
function get_devices(deviceType::Type{T}; verbose::Bool=false) where {T<:CUDAGPU}
    devices = Vector{AbstractDevice}()

    if !CUDA.functional()
        if verbose
            println("CUDA is non-functional")
        end
        return devices
    end

    CUDADevices = CUDA.devices()
    if verbose
        println("Found $(length(CUDADevices)) CUDA devices")
    end
    for device in CUDADevices
        push!(devices, CUDAGPU(device, default_strategy(CUDAGPU), -1))
    end

    return devices
end
