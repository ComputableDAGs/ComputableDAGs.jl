function ComputableDAGs.measure_device!(device::ROCmGPU; verbose::Bool)
    verbose && @info "Measuring ROCm GPU $(device.device)"

    # TODO implement
    return nothing
end

"""
    get_devices(::Type{ROCmGPU}; verbose::Bool = false)

Return a Vector of [`ROCmGPU`](@ref)s available on the current machine. If `verbose` is true, print some additional information.
"""
function ComputableDAGs.get_devices(::Type{ROCmGPU}; verbose::Bool=false)
    devices = Vector{ComputableDAGs.AbstractDevice}()

    if !AMDGPU.functional()
        @warn "The AMDGPU extension is loaded but AMDGPU.jl is non-functional"
        return devices
    end

    AMDDevices = AMDGPU.devices()
    verbose && @info "Found $(length(AMDDevices)) AMD devices"
    for device in AMDDevices
        push!(devices, ROCmGPU(device, -1))
    end

    return devices
end
