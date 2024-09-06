module AMDGPUExt

using ComputableDAGs, AMDGPU
using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

# include specialized AMDGPU functions here
include("devices/rocm/impl.jl")

end
