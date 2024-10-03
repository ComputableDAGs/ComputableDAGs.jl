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

function expr_from_fc(fc::FunctionCall{VectorT,0}) where {VectorT}
    func_call = Expr(
        :call,
        fc.func,
        eval.(
            _gen_access_expr.(Ref(fc.device), Ref(fc.device.cacheStrategy), fc.arguments)
        )...,
    )
    access_expr = eval(gen_access_expr(fc))

    return Expr(:(=), access_expr, func_call)
end

"""
    expr_from_fc(fc::FunctionCall)

For a given function call, return an expression evaluating it.
"""
function expr_from_fc(fc::FunctionCall{VectorT,M}) where {VectorT,M}
    func_call = Expr(
        :call,
        fc.func,
        fc.value_arguments...,
        eval.(
            _gen_access_expr.(Ref(fc.device), Ref(fc.device.cacheStrategy), fc.arguments)
        )...,
    )
    access_expr = eval(gen_access_expr(fc))

    return Expr(:(=), access_expr, func_call)
end

"""
    gen_cache_init_code(machine::Machine)

For each [`AbstractDevice`](@ref) in the given [`Machine`](@ref), returning a `Vector{Expr}` doing the initialization.
"""
function gen_cache_init_code(machine::Machine)
    initialize_caches = Vector{Expr}()

    for device in machine.devices
        push!(initialize_caches, gen_cache_init_code(device))
    end

    return initialize_caches
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
                RuntimeGeneratedFunction(
                    @__MODULE__,
                    context_module,
                    Expr(:->, :x, input_expr(instance, name, :x)),
                ),
                SVector{0,Any}(),
                SVector{1,Symbol}(:input),
                symbol,
                device,
            )

            push!(assign_inputs, fc)
        end
    end

    return assign_inputs
end

"""
    gen_function_body(fc_vec::Vector{FunctionCall}; closures_size)

Generate the function body from the given `Vector` of [`FunctionCall`](@ref)s.

## Keyword Arguments
`closures_size`: The size of closures to generate (in lines of code). Closures introduce function barriers in the function body, preventing some optimizations by the compiler and therefore greatly reducing compile time. A value of 1 or less will disable the use of closures entirely.
"""
function gen_function_body(fc_vec::Vector{FunctionCall}; closures_size::Int)
    if (closures_size <= 1)
        return Expr(:block, expr_from_fc.(fc_vec)...)
    end

    closures = Vector{Expr}()
    for i in 1:closures_size:length(fc_vec)
        code_block = fc_vec[i:min(i + closures_size, length(fc_vec))]

        # collect `local var` statements that need to exist before the closure starts
        # since the return symbols are always unique, this has to happen for each fc and there will be no duplicates
        local_inits = gen_local_init.(code_block)

        closure = Expr(         # call to the following closure (no arguments)
            :call,
            Expr(               # create the closure: () -> code block; return nothing
                :->,
                :(),
                Expr(#          # actual function body of the closure
                    :block,
                    expr_from_fc.(code_block)...,
                    Expr(:return, :nothing),
                ),
            ),
        )
        # combine to one closure call, including all the local inits and the actual call to the closure
        push!(closures, Expr(:block, local_inits..., closure))
    end

    return Expr(:block, closures...)
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

    # get inSymbols
    inputSyms = Dict{String,Vector{Symbol}}()
    for node in get_entry_nodes(graph)
        if !haskey(inputSyms, node.name)
            inputSyms[node.name] = Vector{Symbol}()
        end

        push!(inputSyms[node.name], Symbol("$(to_var_name(node.id))_in"))
    end

    # get outSymbol
    outSym = Symbol(to_var_name(get_exit_node(graph).id))

    initCaches = gen_cache_init_code(machine)
    assign_inputs = gen_input_assignment_code(inputSyms, instance, machine, context_module)

    return Tape{input_type(instance)}(
        initCaches, assign_inputs, schedule, inputSyms, outSym, Dict(), instance, machine
    )
end

"""
    execute_tape(tape::Tape, input::Input) where {Input}

Execute the given tape with the given input.

For implementation reasons, this disregards the set [`CacheStrategy`](@ref) of the devices and always uses a dictionary.
"""
function execute_tape(tape::Tape, input)
    cache = Dict{Symbol,Any}()
    cache[:input] = input
    # simply execute all the code snippets here
    @assert typeof(input) <: input_type(tape.instance) "expected tape input type to fit $(input_type(tape.instance)) but got $(typeof(input))"
    for expr in tape.initCachesCode
        @eval $expr
    end

    for function_call in tape.inputAssignCode
        call_fc(function_call, cache)
    end
    for function_call in tape.computeCode
        call_fc(function_call, cache)
    end

    return cache[tape.outputSymbol]
end
