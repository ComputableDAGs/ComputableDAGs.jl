function ComputableDAGs.measure_device!(device::CUDAGPU; verbose::Bool)
    verbose && @info "Measuring CUDA GPU $(device.device)"

    # TODO implement
    return nothing
end

"""
    devices(::Type{CUDAGPU}; verbose::Bool)

Return a Vector of [`CUDAGPU`](@ref)s available on the current machine. If `verbose` is true, print some additional information.
"""
function ComputableDAGs.devices(::Type{CUDAGPU}; verbose::Bool = false)
    devices = Vector{ComputableDAGs.AbstractDevice}()

    if !CUDA.functional()
        @warn "The CUDA extension is loaded but CUDA.jl is non-functional"
        return devices
    end

    CUDADevices = CUDA.devices()
    verbose && @info "Found $(length(CUDADevices)) CUDA devices"
    for device in CUDADevices
        push!(devices, CUDAGPU(device, -1))
    end

    return devices
end
