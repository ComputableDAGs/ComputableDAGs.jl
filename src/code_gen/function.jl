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

`closures_size` (default=0 (off)): The size of closures to use in the main generated code. This specifies the size of code blocks across which the 
        compiler cannot optimize. For sufficiently large functions, a larger value means longer compile times but potentially faster execution time.
        **Note** that the actually used closure size might be different than the one passed here, since the function automatically chooses a size that
        is close to a n-th root of the total number of loc, based off the given size.
"""
function get_compute_function(
    graph::DAG, instance, machine::Machine, context_module::Module; closures_size=0
)
    tape = gen_tape(graph, instance, machine, context_module)

    code = gen_function_body(tape, context_module; closures_size=closures_size)
    assign_inputs = Expr(:block, expr_from_fc.(tape.input_assign_code)...)

    function_id = to_var_name(UUIDs.uuid1(rng[1]))
    res_sym = tape.output_symbol
    expr = Expr(
        :function, # function definition
        Expr(
            :call, Symbol("compute_$function_id"), Expr(:(::), :input, input_type(instance))
        ), # function name and parameters
        Expr(:block, assign_inputs, code, Expr(:return, res_sym)), # function body
    )

    return RuntimeGeneratedFunction(@__MODULE__, context_module, expr)
end
