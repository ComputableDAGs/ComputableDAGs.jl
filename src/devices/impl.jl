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
It is the simplest machine definition possible and produces a simple function when used with [`compute_function`](@ref).
"""
function cpu_st()
    return Machine([NumaNode(0, 1, -1.0, UUIDs.uuid1(TaskLocalRNG()))], [-1.0;;])
end

"""
    gen_access_expr(fc::FunctionCall)

Return an expression that can be assigned to from the return symbols in the given function call.
For a function call with only one return symbol, this might be just the variable name as an expression.
For multiple return symbols, this is a structured binding.
"""
function gen_access_expr(fc::FunctionCall{VAL_T}) where {VAL_T}
    if length(fc.return_symbols[1]) != 1
        # general case
        vec = Expr[]
        for ret_symbols in fc.return_symbols
            push!(vec, unroll_symbol_vector(ret_symbols))
        end
        if length(vec) > 1
            return unroll_symbol_vector(vec)
        else
            return vec[1]
        end
    end

    # single return value per function
    vec = Symbol[]
    for ret_symbols in fc.return_symbols
        push!(vec, ret_symbols[1])
    end
    if length(vec) > 1
        return unroll_symbol_vector(vec)
    else
        return vec[1]
    end
end
