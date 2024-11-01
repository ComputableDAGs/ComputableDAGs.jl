"""
    device_types()

Return a vector of available and implemented device types.

See also: [`DEVICE_TYPES`](@ref)
"""
function device_types()
    return DEVICE_TYPES
end

"""
    entry_device(machine::Machine)

Return the "entry" device, i.e., the device that starts CPU threads and GPU kernels, and takes input values and returns the output value.
"""
function entry_device(machine::Machine)
    return machine.devices[1]
end

"""
    cpu_st()

A function returning a [`Machine`](@ref) that only has a single thread of one CPU.
It is the simplest machine definition possible and produces a simple function when used with [`get_compute_function`](@ref).
"""
function cpu_st()
    return Machine([NumaNode(0, 1, -1.0, UUIDs.uuid1())], [-1.0;;])
end

"""
    gen_access_expr(fc::FunctionCall)

Dispatch from the given [`FunctionCall`](@ref) to the interface function `_gen_access_expr`(@ref).
"""
function gen_access_expr(fc::FunctionCall)
    return _gen_access_expr(fc.device, fc.return_symbol)
end

"""
    gen_local_init(fc::FunctionCall)

Dispatch from the given [`FunctionCall`](@ref) to the interface function `_gen_local_init`(@ref).
"""
function gen_local_init(fc::FunctionCall)
    return _gen_local_init(fc, fc.device)
end
