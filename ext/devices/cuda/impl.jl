"""
    CUDAGPU <: AbstractGPU

Representation of a specific CUDA GPU that code can run on. Implements the [`AbstractDevice`](@ref) interface.
"""
mutable struct CUDAGPU <: GraphComputing.AbstractGPU
    device::Any # TODO: what's the cuda device type?
    cacheStrategy::CacheStrategy
    FLOPS::Float64
end

push!(GraphComputing.DEVICE_TYPES, CUDAGPU)

GraphComputing.CACHE_STRATEGIES[CUDAGPU] = [LocalVariables()]

GraphComputing.default_strategy(::Type{CUDAGPU}) = LocalVariables()

function GraphComputing.measure_device!(device::CUDAGPU; verbose::Bool)
    if verbose
        println("Measuring CUDA GPU $(device.device)")
    end

    # TODO implement
    return nothing
end

"""
    get_devices(::Type{CUDAGPU}; verbose::Bool)

Return a Vector of [`CUDAGPU`](@ref)s available on the current machine. If `verbose` is true, print some additional information.
"""
function get_devices(::Type{CUDAGPU}; verbose::Bool=false)
    devices = Vector{GraphComputing.AbstractDevice}()

    if !CUDA.functional()
        if verbose
            println("CUDA.jl is non-functional")
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
