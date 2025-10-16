"""
    get_compute_function(
        dag::DAG,
        instance,
        machine::Machine,
        context_module::Module
    )

Return a function of signature `compute_<id>(input::input_type(instance))`, which will return the result of the DAG computation on the given input.
The final argument `context_module` should always be `@__MODULE__` to be able to use functions defined in the caller's environment.

## Keyword Arguments

`closures_size` (default=0 (off)): The size of closures to use in the main generated code. This specifies the size of code blocks across which the
        compiler cannot optimize. For sufficiently large functions, a larger value means longer compile times but potentially faster execution time.
        **Note** that the actually used closure size might be different than the one passed here, since the function automatically chooses a size that
        is close to a n-th root of the total number of loc, based off the given size.
`concrete_input_type` (default=`input_type(instance)`): A type that will be used as the expected input type of the generated function. If
    omitted, the `input_type` of the problem instance is used. Note that the `input_type` of the instance will still be used as the annotated
    type in the generated function header.
"""
function get_compute_function(
        dag::DAG,
        instance,
        machine::Machine,
        context_module::Module;
        closures_size::Int = 0,
        concrete_input_type::Type = Nothing,
    )
    global INITIALIZED_MODULES
    if !(context_module in INITIALIZED_MODULES)
        RuntimeGeneratedFunctions.init(context_module)
        push!(INITIALIZED_MODULES, context_module)
    end

    tape = gen_tape(dag, instance, machine, context_module)

    code = gen_function_body(
        tape,
        context_module;
        closures_size = closures_size,
        concrete_input_type = concrete_input_type,
    )
    assign_inputs = Expr(:block, expr_from_fc.(tape.input_assign_code)...)

    function_id = to_var_name(UUIDs.uuid1(TaskLocalRNG()))
    res_sym = tape.output_symbol
    expr = Expr(
        :function, # function definition
        Expr(
            :call, Symbol("compute_$function_id"), Expr(:(::), :input, input_type(instance))
        ), # function name and parameters
        Expr(
            :block,
            assign_inputs,
            Expr(:noinline, true),
            code,
            Expr(:noinline, false),
            Expr(:return, res_sym)
        ), # function body
    )

    return invokelatest(RuntimeGeneratedFunction, @__MODULE__, context_module, expr)
end
