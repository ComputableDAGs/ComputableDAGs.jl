"""
    get_compute_function(
        graph::DAG,
        instance,
        machine::Machine,
        context_module::Module
    )

Return a function of signature `compute_<id>(input::input_type(instance))`, which will return the result of the DAG computation on the given input.
The final argument `context_module` should always be `@__MODULE__` to be able to use functions defined in the caller's environment. For this to work,
you need 
```Julia
using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)
```
in your top level.
"""
function get_compute_function(
    graph::DAG, instance, machine::Machine, context_module::Module
)
    tape = gen_tape(graph, instance, machine, context_module)

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

    return RuntimeGeneratedFunction(@__MODULE__, context_module, expr)
end

"""
    execute(
        graph::DAG,
        instance,
        machine::Machine,
        input,
        context_module::Module
    )

Execute the code of the given `graph` on the given input values.

This is essentially shorthand for
```julia
tape = gen_tape(graph, instance, machine, context_module)
return execute_tape(tape, input)
```
"""
function execute(graph::DAG, instance, machine::Machine, input, context_module::Module)
    tape = gen_tape(graph, instance, machine, context_module)
    return execute_tape(tape, input)
end
