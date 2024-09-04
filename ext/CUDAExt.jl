module CUDAExt

using GraphComputing
using CUDA
using RuntimeGeneratedFunctions

# include specialized CUDA functions here
include("devices/cuda/impl.jl")
include("devices/cuda/function.jl")

end
