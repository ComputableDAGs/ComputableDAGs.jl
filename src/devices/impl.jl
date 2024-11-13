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

Dispatch from the given [`FunctionCall`](@ref) to the interface function [`_gen_access_expr`](@ref).
"""
function gen_access_expr(fc::FunctionCall{VAL_T,N_ARG,N_RET}) where {VAL_T,N_ARG,N_RET}
    vec = Expr[]
    for ret_symbols in fc.return_symbols
        push!(vec, unroll_symbol_vector(_gen_access_expr.(Ref(fc.device), ret_symbols)))
    end
    if length(vec) > 1
        return unroll_symbol_vector(vec)
    else
        return vec[1]
    end
end

function gen_access_expr(fc::FunctionCall{VAL_T,N_ARG,1}) where {VAL_T,N_ARG}
    vec = Symbol[]
    for ret_symbols in fc.return_symbols
        push!(vec, _gen_access_expr.(Ref(fc.device), ret_symbols[1]))
    end
    if length(vec) > 1
        return unroll_symbol_vector(vec)
    else
        return vec[1]
    end
end

"""
    gen_local_init(fc::FunctionCall)

Dispatch from the given [`FunctionCall`](@ref) to the interface function [`_gen_local_init`](@ref).
"""
function gen_local_init(fc::FunctionCall)
    return Expr(
        :block,
        _gen_local_init.(
            Ref(fc.device),
            Iterators.flatten(fc.return_symbols),
            Iterators.cycle(fc.return_types, length(fc.return_symbols)),
        )...,
    )
end
