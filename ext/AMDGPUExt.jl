module AMDGPUExt

using ComputableDAGs
using UUIDs
using AMDGPU

# include specialized AMDGPU functions here
include("devices/rocm/impl.jl")
include("devices/rocm/function.jl")

end
