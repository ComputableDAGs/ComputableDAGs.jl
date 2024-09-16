module CUDAExt

using ComputableDAGs
using UUIDs
using CUDA

# include specialized CUDA functions here
include("devices/cuda/impl.jl")
include("devices/cuda/function.jl")

end
