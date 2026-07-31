"""
    lower(tape::Tape)

Lowers the given [`Tape`](@ref) down to an `Expr` containing all calls in
order, first the input assignments (which may be empty if this is not the
starting device), then all of the schedule tasks.
"""
function lower(tape::Tape{DEV_T}) where {DEV_T <: CPU}
    return Expr(
        :block,
        lower_to_expr.(tape.input_assignment_code, Ref(tape.device))...,
        Expr(:noinline, true),
        lower_to_expr.(tape.schedule, Ref(tape.device))...,
        Expr(:noinline, false),
        Expr(:return, tape.output_symbol)
    )
end

"""
    tape_function(tape)

Return an expression containing the complete function definition generated
from the given [`Tape`](@ref).
"""
function tape_function(tape::Tape, context_module::Module)
    global INITIALIZED_MODULES
    if !(context_module in INITIALIZED_MODULES)
        RuntimeGeneratedFunctions.init(context_module)
        push!(INITIALIZED_MODULES, context_module)
    end

    function_signature = if is_entry(tape.device)
        Expr(:call, Symbol("compute_$(tape.device.id)"), :input)
    else
        Expr(:call, Symbol("compute_$(tape.device.id)"))
    end

    function_body = lower(tape)

    expr = Expr(
        :function,
        function_signature,
        function_body
    )

    return invokelatest(RuntimeGeneratedFunction, @__MODULE__, context_module, expr)
end

"""
    lower(tape_rack::TapeRack)

Lowers the entire given [`TapeRack`](@ref).
"""
function lower(tape_rack::TapeRack)
    functions = tape_function.(tape_rack.tapes)

    # TODO fix
    return functions
end
