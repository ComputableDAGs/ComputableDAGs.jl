function expr_from_fc(fc::FunctionCall{VAL_T,F_T}) where {VAL_T,F_T<:Function}
    if length(fc) == 1
        func_call = Expr(
            :call,
            fc.func,
            fc.value_arguments[1]...,
            _gen_access_expr.(Ref(fc.device), fc.arguments[1])...,
        )
    else
        # TBW; dispatch to device specific vectorization
        throw("unimplemented")
    end
    access_expr = gen_access_expr(fc)
    return Expr(:(=), access_expr, func_call)
end

function expr_from_fc(fc::FunctionCall{VAL_T,Expr}) where {VAL_T}
    @assert length(fc) == 1 && isempty(fc.arguments[1]) && isempty(fc.value_arguments[1]) "function call assigning an expression has an unallowed combination of arguments, which is not allowed\n$fc"
    return Expr(:(=), gen_access_expr(fc), fc.func)
end

"""
    gen_input_assignment_code(
        input_symbols::Dict{String, Vector{Symbol}},
        instance::AbstractProblemInstance,
        machine::Machine,
        input_type::Type,
        context_module::Module
    )

Return a `Vector{Expr}` doing the input assignments from the given `problem_input` onto the `input_symbols`.
"""
function gen_input_assignment_code(
    input_symbols::Dict{String,Vector{Symbol}},
    instance,
    machine::Machine,
    input_type::Type,
    context_module::Module,
)
    assign_inputs = Vector{FunctionCall}()
    for (name, symbols) in input_symbols
        for symbol in symbols
            device = entry_device(machine)

            f_id = Symbol(to_var_name(UUIDs.uuid1(rng[threadid()])))

            fc_setup = FunctionCall(
                Expr(:->, :x, input_expr(instance, name, :x)),
                (),
                Symbol[],
                Symbol[f_id],
                Type[Nothing],
                device,
            )

            fc = FunctionCall(
                _call, (), Symbol[f_id, :input], Symbol[symbol], Type[Nothing], device
            )

            ret_expr = Expr(
                :call, Base.return_types, fc_setup.func, Expr(:tuple, input_type)
            )
            ret_type = context_module.eval(ret_expr)
            @assert length(ret_type) == 1
            fc.return_types = [ret_type[1]]

            push!(assign_inputs, fc_setup)
            push!(assign_inputs, fc)
        end
    end

    return assign_inputs
end

"""
    gen_function_body(tape::Tape, context_module::Module; closures_size)

Generate the function body from the given [`Tape`](@ref).

## Keyword Arguments
`closures_size`: The size of closures to generate (in lines of code). Closures introduce function barriers in the function body, preventing some optimizations by the compiler and therefore greatly reducing compile time. A value of 1 or less will disable the use of closures entirely.
"""
function gen_function_body(tape::Tape, context_module::Module; closures_size::Int)
    # only need to annotate types later when using closures
    types = infer_types!(tape)

    if closures_size >= 1
        s = log(closures_size, length(tape.schedule))
        closures_depth = ceil(Int, s) # tend towards more levels/smaller closures
        closures_size = ceil(Int, length(tape.schedule)^(1 / closures_depth))
    end

    @debug "generating function body with closure size $closures_size"

    return _gen_function_body(
        tape.schedule, types, tape.machine, context_module; closures_size=closures_size
    )
end

function _gen_function_body(
    fc_vec::AbstractVector{FunctionCall},
    type_dict::Dict{Symbol,Type},
    machine::Machine,
    context_module::Module;
    closures_size=0,
)
    @debug "generating function body from $(length(fc_vec)) function calls with closure size $closures_size"
    if closures_size <= 1 || closures_size >= length(fc_vec)
        return Expr(:block, expr_from_fc.(fc_vec)...)
    end

    # iterate from end to beginning
    # this helps because we can collect all undefined arguments to the closures that have to be returned somewhere earlier
    undefined_argument_symbols = Set{Symbol}()
    # the final return symbol is the return of the entire generated function, it always has to be returned
    push!(undefined_argument_symbols, gen_access_expr(fc_vec[end]))

    closured_fc_vec = FunctionCall[]
    for i in length(fc_vec):(-closures_size):1
        e = i
        b = max(i - closures_size, 1)
        code_block = fc_vec[b:e]

        pushfirst!(
            closured_fc_vec,
            _closure_fc(
                code_block, type_dict, machine, undefined_argument_symbols, context_module
            ),
        )
    end

    return _gen_function_body(
        closured_fc_vec, type_dict, machine, context_module; closures_size=closures_size
    )
end

"""
    _closure_fc()

From the given function calls, make and return a new function call representing all of them together.
The undefined_argument_symbols is the set of all Symbols that need to be returned if available inside the code_block. They get updated inside this function.
"""
function _closure_fc(
    code_block::AbstractVector{FunctionCall},
    types::Dict{Symbol,Type},
    machine::Machine,
    undefined_argument_symbols::Set{Symbol},
    context_module::Module,
)
    return_symbols = Symbol[]
    for s in
        Iterators.flatten(Iterators.flatten(getfield.(code_block, Ref(:return_symbols))))
        push!(return_symbols, s)
    end

    ret_symbols_set = Set(return_symbols)
    arg_symbols_set = Set{Symbol}()
    for fc in code_block
        for symbol in Iterators.flatten(fc.arguments)
            # symbol won't be defined if it is first calculated in the closure
            # so don't add it to the arguments in this case
            if !(symbol in ret_symbols_set)
                push!(undefined_argument_symbols, symbol)

                push!(arg_symbols_set, symbol)
            end
        end
    end

    setdiff!(arg_symbols_set, ret_symbols_set)
    intersect!(ret_symbols_set, undefined_argument_symbols)

    arg_symbols_t = [arg_symbols_set...]
    ret_symbols_t = [ret_symbols_set...]

    closure = context_module.eval(
        Expr(                                   # create the closure: () -> code block; return (locals)
            :->,
            Expr(:tuple, arg_symbols_t...),     # closure arguments
            Expr(                               # actual function body of the closure
                :block,
                expr_from_fc.(code_block)...,
                Expr(
                    :return,                    # have to make sure to not return a tuple of length 1
                    if length(ret_symbols_t) == 1
                        ret_symbols_t[1]
                    else
                        Expr(:tuple, ret_symbols_t...)
                    end,
                ),
            ),
        ),
    )

    ret_types = (getindex.(Ref(types), ret_symbols_t))

    fc = FunctionCall(
        closure, (), arg_symbols_t, ret_symbols_t, ret_types, entry_device(machine)
    )

    setdiff!(undefined_argument_symbols, ret_symbols_set)

    return fc
end

"""
    gen_tape(
        graph::DAG,
        instance::AbstractProblemInstance,
        machine::Machine,
        context_module::Module,
        scheduler::AbstractScheduler = GreedyScheduler()
    )

Generate the code for a given graph. The return value is a [`Tape`](@ref).
"""
function gen_tape(
    graph::DAG,
    instance,
    machine::Machine,
    context_module::Module,
    scheduler::AbstractScheduler=GreedyScheduler(),
)
    @debug "generating tape"
    schedule = schedule_dag(scheduler, graph, machine)
    function_body = lower(schedule, machine)

    # get input symbols
    input_syms = Dict{String,Vector{Symbol}}()
    for node in get_entry_nodes(graph)
        if !haskey(input_syms, node.name)
            input_syms[node.name] = Vector{Symbol}()
        end

        push!(input_syms[node.name], Symbol("$(to_var_name(node.id))_in"))
    end

    # get outSymbol
    outSym = Symbol(to_var_name(get_exit_node(graph).id))

    INPUT_T = input_type(instance)
    assign_inputs = gen_input_assignment_code(
        input_syms, instance, machine, INPUT_T, context_module
    )

    return Tape{INPUT_T}(assign_inputs, function_body, outSym, instance, machine)
end
