module AMDGPUExt

using GraphComputing, AMDGPU

# include specialized AMDGPU functions here
include("devices/rocm/impl.jl")

end
