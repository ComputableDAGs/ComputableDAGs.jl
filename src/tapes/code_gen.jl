"""
    lower(tape::Tape{<:CPU}, cluster::Cluster)

Lowers the given [`Tape`](@ref) down to an `Expr` containing all calls in
order, first the input assignments (which may be empty if this is not the
starting device), then all of the schedule tasks.

The cluster is required to set up the device managers correctly.
"""
function lower(tape::Tape{CPU}, cluster::Cluster)
    return Expr(
        :block,
        device_manager_setup_code(tape.device.id, cluster),
        lower_to_expr.(tape.input_assignment_code, Ref(tape.device))...,
        Expr(:noinline, true),
        lower_to_expr.(tape.schedule, Ref(tape.device))...,
        Expr(:noinline, false),
        device_manager_destroy_code(tape.device.id),
        Expr(:return, is_entry(tape.device) ? tape.output_symbol : nothing)
    )
end


"""
    tape_function(
        tape::Tape,
        cluster::Cluster,
        context_module::Module
    )

Return a callable function containing the complete function definition
generated from the given [`Tape`](@ref). The context module should be set to
`@__MODULE__` by the caller to ensure functions from their context module can
be seen inside the generated function.

The [`Cluster`](@ref) is required to set up the device managers correctly.
"""
function tape_function(tape::Tape, cluster::Cluster, context_module::Module)
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

    function_body = lower(tape, cluster)

    expr = Expr(
        :function,
        function_signature,
        function_body
    )

    return invokelatest(RuntimeGeneratedFunction, @__MODULE__, context_module, expr)
end

"""
    lower(tape_rack::TapeRack, cluster::Cluster, context_module::Module)

Lowers the entire given [`TapeRack`](@ref).
"""
function lower(tape_rack::TapeRack, cluster::Cluster, context_module::Module)
    functions = tape_function.(tape_rack.tapes, Ref(cluster), Ref(context_module))

    # TODO fix
    return functions
end
