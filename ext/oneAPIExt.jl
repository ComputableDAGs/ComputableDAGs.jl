module oneAPIExt

using ComputableDAGs
using UUIDs
using oneAPI

function __init__()
    @debug "Loading oneAPIExt"

    push!(ComputableDAGs.DEVICE_TYPES, oneAPIGPU)
    ComputableDAGs.CACHE_STRATEGIES[oneAPIGPU] = [LocalVariables()]

    return nothing
end

# include specialized oneAPI functions here
include("devices/oneapi/impl.jl")

end
