module CUDAExt

using ComputableDAGs
using UUIDs
using Random
using CUDA

function __init__()
    @debug "Loading CUDAExt"

    push!(ComputableDAGs.DEVICE_TYPES, CUDAGPU)

    return nothing
end

# include specialized CUDA functions here
include("devices/cuda/impl.jl")
include("devices/cuda/function.jl")

end
