"""
    get_machine_info(verbose::Bool)

Return the [`Machine`](@ref) currently running on. The parameter `verbose` defaults to true when interactive.
"""
function get_machine_info(; verbose::Bool = Base.is_interactive)
    devices = Vector{AbstractDevice}()

    for device in device_types()
        devs = get_devices(device; verbose = verbose)
        for dev in devs
            push!(devices, dev)
        end
    end

    no_devices = length(devices)
    @assert no_devices > 0 "No devices were found, but at least one NUMA node should always be available!"

    transfer_rates = Matrix{Float64}(undef, no_devices, no_devices)
    fill!(transfer_rates, -1)
    return Machine(devices, transfer_rates)
end
