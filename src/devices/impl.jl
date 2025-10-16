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

Return the
"""
function gen_access_expr(fc::FunctionCall{VAL_T}) where {VAL_T}
    if length(fc.return_types) != 1
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

"""
    gen_local_init(fc::FunctionCall)

Dispatch from the given [`FunctionCall`](@ref) to the lower-level function [`_gen_local_init`](@ref).
"""
function gen_local_init(fc::FunctionCall)
    return Expr(
        :block,
        _gen_local_init.(
            Iterators.flatten(fc.return_symbols),
            Iterators.flatten(
                Iterators.repeated(fc.return_types, length(fc.return_symbols))
            ),
        )...,
    )
end

"""
    _gen_local_init(symbol::Symbol, type::Type)

Return an `Expr` that initializes the symbol in the local scope.
The result looks like `local <symbol>::<type>`.
"""
function _gen_local_init(symbol::Symbol, type::Type)
    return Expr(:local, symbol, :(::), Symbol(type))
end

"""
    wrap_in_let_statement(expr, symbols)

For a given expression and a collection of symbols, generate a let statement that wraps the expression in a let statement with all the symbols, like
`let <symbol[1]>=<symbol[1]>, ..., <symbol[end]>=<symbol[end]> <expr> end`
"""
@inline function wrap_in_let_statement(expr, symbols)
    return Expr(:let, Expr(:block, _gen_let_statement.(symbols)...), expr)
end

"""
    _gen_let_statement(symbol::Symbol)

Return a let-`Expr` like `<symbol> = <symbol>`.
"""
function _gen_let_statement(symbol::Symbol)
    return Expr(:(=), symbol, symbol)
end
