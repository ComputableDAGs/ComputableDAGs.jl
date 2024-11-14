# TODO: do this with macros
function call_fc(
    fc::FunctionCall{VectorT,0}, cache::Dict{Symbol,Any}
) where {VectorT<:SVector{1}}
    cache[fc.return_symbol] = fc.func(cache[fc.arguments[1]])
    return nothing
end

function call_fc(
    fc::FunctionCall{VectorT,1}, cache::Dict{Symbol,Any}
) where {VectorT<:SVector{1}}
    cache[fc.return_symbol] = fc.func(fc.value_arguments[1], cache[fc.arguments[1]])
    return nothing
end

function call_fc(
    fc::FunctionCall{VectorT,0}, cache::Dict{Symbol,Any}
) where {VectorT<:SVector{2}}
    cache[fc.return_symbol] = fc.func(cache[fc.arguments[1]], cache[fc.arguments[2]])
    return nothing
end

function call_fc(
    fc::FunctionCall{VectorT,1}, cache::Dict{Symbol,Any}
) where {VectorT<:SVector{2}}
    cache[fc.return_symbol] = fc.func(
        fc.value_arguments[1], cache[fc.arguments[1]], cache[fc.arguments[2]]
    )
    return nothing
end

function call_fc(fc::FunctionCall{VectorT,1}, cache::Dict{Symbol,Any}) where {VectorT}
    cache[fc.return_symbol] = fc.func(
        fc.value_arguments[1], getindex.(Ref(cache), fc.arguments)...
    )
    return nothing
end

"""
    call_fc(fc::FunctionCall, cache::Dict{Symbol, Any})

Execute the given [`FunctionCall`](@ref) on the dictionary.

Several more specialized versions of this function exist to reduce vector unrolling work for common cases.
"""
function call_fc(fc::FunctionCall{VectorT,M}, cache::Dict{Symbol,Any}) where {VectorT,M}
    cache[fc.return_symbol] = fc.func(
        fc.value_arguments..., getindex.(Ref(cache), fc.arguments)...
    )
    return nothing
end

function expr_from_fc(fc::FunctionCall{VAL_T,N_ARG,N_RET}) where {VAL_T,N_ARG,N_RET}
    if length(fc) == 1
        func_call = Expr(
            :call,
            fc.func,
            (
                fc.value_arguments[1]...,
                _gen_access_expr.(Ref(fc.device), fc.arguments[1])...,
            )...,
        )
    else
        # TBW; dispatch to device specific vectorization
        throw("unimplemented")
    end
    access_expr = gen_access_expr(fc)
    return Expr(:(=), access_expr, func_call)
end

"""
    gen_input_assignment_code(
        input_symbols::Dict{String, Vector{Symbol}},
        instance::AbstractProblemInstance,
        machine::Machine,
        context_module::Module
    )

Return a `Vector{Expr}` doing the input assignments from the given `problem_input` onto the `input_symbols`.
"""
function gen_input_assignment_code(
    input_symbols::Dict{String,Vector{Symbol}},
    instance,
    machine::Machine,
    context_module::Module,
)
    assign_inputs = Vector{FunctionCall}()
    for (name, symbols) in input_symbols
        # make a function for this, since we can't use anonymous functions in the FunctionCall

        for symbol in symbols
            device = entry_device(machine)

            fc = FunctionCall(
                context_module.eval(Expr(:->, :x, input_expr(instance, name, :x))),
                (),
                (:input,),
                (symbol,),
                (Nothing,),
                device,
            )

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

    # TODO calculate closures size better

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

    arg_symbols_t = (arg_symbols_set...,)
    ret_symbols_t = (ret_symbols_set...,)

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

See also: [`execute`](@ref), [`execute_tape`](@ref)
"""
function gen_tape(
    graph::DAG,
    instance,
    machine::Machine,
    context_module::Module,
    scheduler::AbstractScheduler=GreedyScheduler(),
)
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

    assign_inputs = gen_input_assignment_code(input_syms, instance, machine, context_module)

    return Tape{input_type(instance)}(
        assign_inputs, function_body, outSym, instance, machine
    )
end

"""
    execute_tape(tape::Tape, input::Input) where {Input}

Execute the given tape with the given input.

!!! warning
    This is very slow and might not work. This is to be majorly revamped.
"""
function execute_tape(tape::Tape, input)
    cache = Dict{Symbol,Any}()
    cache[:input] = input
    # simply execute all the code snippets here
    @assert typeof(input) <: input_type(tape.instance) "expected tape input type to fit $(input_type(tape.instance)) but got $(typeof(input))"

    compute_code = tape.schedule

    for function_call in tape.input_assign_code
        call_fc(function_call, cache)
    end
    for function_call in compute_code
        call_fc(function_call, cache)
    end

    return cache[tape.output_symbol]
end
