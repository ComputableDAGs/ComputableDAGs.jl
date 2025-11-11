function expr_from_fc(fc::FunctionCall{VAL_T, <:Function}) where {VAL_T}
    if length(fc) == 1
        func_call = Expr(:call, fc.func, fc.value_arguments[1]..., fc.arguments[1]...)
    else
        # TBW; dispatch to device specific vectorization
        throw("unimplemented")
    end
    access_expr = gen_access_expr(fc)
    return Expr(:(=), access_expr, func_call)
end

function expr_from_fc(fc::FunctionCall{VAL_T, Expr}) where {VAL_T}
    @assert length(fc) == 1 && isempty(fc.value_arguments[1]) "function call assigning an expression cannot be vectorized and cannot contain value arguments\n$fc"

    access_expr = gen_access_expr(fc)
    return Expr(:(=), access_expr, fc.func)
end

"""
    gen_input_assignment_code(
        input_symbols::Dict{String, Vector{Symbol}},
        instance::Any,
        machine::Machine
    )

Return a `Vector{FunctionCall}` doing the input assignments from the given `problem_input` onto the `input_symbols`.
"""
function gen_input_assignment_code(
        input_symbols::Dict{String, Vector{Symbol}}, instance, machine::Machine
    )
    assign_inputs = Vector{FunctionCall}()
    for (name, symbols) in input_symbols
        for symbol in symbols
            device = entry_device(machine)

            fc = FunctionCall(
                input_expr(instance, name, :input),
                (),
                Symbol[:input],
                Symbol[symbol],
                device,
            )

            push!(assign_inputs, fc)
        end
    end

    return assign_inputs
end

"""
    gen_function_body(tape::Tape)

Generate the function body from the given [`Tape`](@ref).
"""
function gen_function_body(tape::Tape)
    @debug "generating function body"

    return Expr(:block, expr_from_fc.(tape.schedule)...)
end

"""
    gen_tape(
        dag::DAG,
        instance::Any,
        machine::Machine,
        scheduler::AbstractScheduler,
    )

Generate the code for a given graph. The return value is a [`Tape`](@ref).
"""
function gen_tape(
        dag::DAG,
        instance,
        machine::Machine,
        scheduler::AbstractScheduler,
    )
    @debug "generating tape"
    schedule = schedule_dag(scheduler, dag, machine)
    function_body = lower(schedule, machine)

    # get input symbols
    input_syms = Dict{String, Vector{Symbol}}()
    for node in entry_nodes(dag)
        if !haskey(input_syms, node.name)
            input_syms[node.name] = Vector{Symbol}()
        end

        push!(input_syms[node.name], Symbol("$(to_var_name(node.id))_in"))
    end

    # get out_symbol
    out_sym = Symbol(to_var_name(exit_node(dag).id))

    assign_inputs = gen_input_assignment_code(input_syms, instance, machine)

    INPUT_T = input_type(instance)
    return Tape{INPUT_T}(assign_inputs, function_body, out_sym, instance, machine)
end
