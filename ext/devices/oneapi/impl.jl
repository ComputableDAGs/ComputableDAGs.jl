function ComputableDAGs.measure_device!(device::oneAPIGPU; verbose::Bool)
    verbose && @info "Measuring oneAPI GPU $(device.device)"

    # TODO implement
    return nothing
end

"""
    get_devices(::Type{oneAPIGPU}; verbose::Bool = false)

Return a Vector of [`oneAPIGPU`](@ref)s available on the current machine. If `verbose` is true, print some additional information.
"""
function ComputableDAGs.get_devices(::Type{oneAPIGPU}; verbose::Bool=false)
    devices = Vector{ComputableDAGs.AbstractDevice}()

    if !oneAPI.functional()
        @warn "the oneAPI extension is loaded but oneAPI.jl is non-functional"
        return devices
    end

    oneAPIDevices = oneAPI.devices()
    verbose && @info "Found $(length(oneAPIDevices)) oneAPI devices"
    for device in oneAPIDevices
        push!(devices, oneAPIGPU(device, -1))
    end

    return devices
end
