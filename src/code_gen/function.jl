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

## Keyword Arguments

`closures_size` (default=0 (off)): The size of closures to use in the main generated code. This specifies the size of code blocks across which the compiler cannot optimize. For sufficiently large functions, a larger value means longer compile times but potentially faster execution time.
"""
function get_compute_function(
    graph::DAG, instance, machine::Machine, context_module::Module; closures_size=0
)
    tape = gen_tape(graph, instance, machine, context_module)

    assign_inputs = Expr(:block, expr_from_fc.(tape.input_assign_code)...)
    code = gen_function_body(tape, context_module; closures_size=closures_size)

    function_id = to_var_name(UUIDs.uuid1(rng[1]))
    res_sym = _gen_access_expr(entry_device(tape.machine), tape.output_symbol)
    expr = #
    Expr(
        :function, # function definition
        Expr(
            :call, Symbol("compute_$function_id"), Expr(:(::), :input, input_type(instance))
        ), # function name and parameters
        Expr(:block, assign_inputs, code, Expr(:return, res_sym)), # function body
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
