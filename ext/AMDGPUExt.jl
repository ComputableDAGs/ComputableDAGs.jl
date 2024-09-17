module AMDGPUExt

using ComputableDAGs
using UUIDs
using AMDGPU

function __init__()
    @debug "Loading AMDGPUExt"

    push!(ComputableDAGs.DEVICE_TYPES, ROCmGPU)
    ComputableDAGs.CACHE_STRATEGIES[ROCmGPU] = [LocalVariables()]

    return nothing
end

# include specialized AMDGPU functions here
include("devices/rocm/impl.jl")
include("devices/rocm/function.jl")

end
