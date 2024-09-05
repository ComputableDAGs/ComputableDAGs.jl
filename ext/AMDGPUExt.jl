module AMDGPUExt

using ComputableDAGs, AMDGPU

# include specialized AMDGPU functions here
include("devices/rocm/impl.jl")

end
