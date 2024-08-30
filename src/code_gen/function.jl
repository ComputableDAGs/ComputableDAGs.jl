"""
    get_compute_function(
        graph::DAG,
        instance,
        machine::Machine,
        cache_module::Module,
        context_module::Module
    )

Return a function of signature `compute_<id>(input::input_type(instance))`, which will return the result of the DAG computation on the given input.
"""
function get_compute_function(
    graph::DAG,
    instance,
    machine::Machine,
    cache_module::Module = @__MODULE__,
    context_module::Module = @__MODULE__
)
    tape = gen_tape(graph, instance, machine, cache_module, context_module)

    initCaches = Expr(:block, tape.initCachesCode...)
    assignInputs = Expr(:block, expr_from_fc.(tape.inputAssignCode)...)
    code = Expr(:block, expr_from_fc.(tape.computeCode)...)

    functionId = to_var_name(UUIDs.uuid1(rng[1]))
    resSym = eval(gen_access_expr(entry_device(tape.machine), tape.outputSymbol))
    expr = #
        Expr(
            :function, # function definition
            Expr(
                :call,
                Symbol("compute_$functionId"),
                Expr(:(::), :data_input, input_type(instance)),
            ), # function name and parameters
            Expr(:block, initCaches, assignInputs, code, Expr(:return, resSym)), # function body
        )

    return RuntimeGeneratedFunction(cache_module, context_module, expr)
end

"""
    get_cuda_kernel(
        graph::DAG,
        instance,
        machine::Machine,
    )

Return a function of signature `compute_<id>(input::CuVector, output::CuVector, n::Int64)`, which will return the result of the DAG computation of the input on the given output variable.
"""
function get_cuda_kernel(
    graph::DAG,
    instance,
    machine::Machine,
    cache_module::Module = @__MODULE__,
    context_module::Module = @__MODULE__
)
    tape = gen_tape(graph, instance, machine, cache_module, context_module)

    initCaches = Expr(:block, tape.initCachesCode...)
    assignInputs = Expr(:block, expr_from_fc.(tape.inputAssignCode)...)
    code = Expr(:block, expr_from_fc.(tape.computeCode)...)

    functionId = to_var_name(UUIDs.uuid1(rng[1]))
    resSym = eval(gen_access_expr(entry_device(tape.machine), tape.outputSymbol))
    expr = Meta.parse("function compute_$(functionId)(input_vector, output_vector, n::Int64)
                          id = (blockIdx().x - 1) * blockDim().x + threadIdx().x
                          if (id > n)
                              return
                          end
                          @inline data_input = input_vector[id]
                          $(initCaches)
                          $(assignInputs)
                          $code
                          @inline output_vector[id] = $resSym
                          return nothing
                      end")

    return RuntimeGeneratedFunction(cache_module, context_module, expr)
end

"""
    execute(
        graph::DAG,
        instance,
        machine::Machine,
        input,
        cache_module::Module,
        context_module::Module
    )

Execute the code of the given `graph` on the given input values.

This is essentially shorthand for
```julia
tape = gen_tape(graph, instance, machine, cache_module, context_module)
return execute_tape(tape, input)
```
"""
function execute(
    graph::DAG,
    instance,
    machine::Machine,
    input,
    cache_module::Module = @__MODULE__,
    context_module::Module = @__MODULE__
)
    tape = gen_tape(graph, instance, machine, cache_module, context_module)
    return execute_tape(tape, input)
end
