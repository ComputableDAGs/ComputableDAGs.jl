"""
    measure_devices(machine::Machine; verbose::Bool)

Measure FLOPS, RAM, cache sizes and what other properties can be extracted for the devices in the given machine.
"""
function measure_devices!(machine::Machine; verbose::Bool=Base.is_interactive())
    for device in machine.devices
        measure_device!(device; verbose=verbose)
    end

    return nothing
end

"""
    measure_transfer_rates(machine::Machine; verbose::Bool)

Measure the transfer rates between devices in the machine.
"""
function measure_transfer_rates!(machine::Machine; verbose::Bool=Base.is_interactive())
    # TODO implement
    return nothing
end
