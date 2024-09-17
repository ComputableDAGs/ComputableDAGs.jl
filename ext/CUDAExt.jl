module CUDAExt

using ComputableDAGs
using UUIDs
using CUDA

function __init__()
    @debug "Loading CUDAExt"

    push!(ComputableDAGs.DEVICE_TYPES, CUDAGPU)
    ComputableDAGs.CACHE_STRATEGIES[CUDAGPU] = [LocalVariables()]

    return nothing
end

# include specialized CUDA functions here
include("devices/cuda/impl.jl")
include("devices/cuda/function.jl")

end
