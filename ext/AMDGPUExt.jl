module AMDGPUExt

using ComputableDAGs
using UUIDs
using Random
using AMDGPU

function __init__()
    @debug "Loading AMDGPUExt"

    push!(ComputableDAGs.DEVICE_TYPES, ROCmGPU)

    return nothing
end

# include specialized AMDGPU functions here
include("devices/rocm/impl.jl")

end
