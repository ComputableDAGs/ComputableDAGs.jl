"""
    compute_function_expr(
        dag::DAG,
        instance,
        machine::Machine,
        scheduler::AbstractScheduler
    )

Helper function, returning the complete function expression.
"""
function compute_function_expr(
        dag::DAG,
        instance,
        machine::Machine,
        scheduler::AbstractScheduler
    )
    tape = gen_tape(dag, instance, machine, scheduler)

    code = gen_function_body(tape)
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

    return expr
end

"""
    compute_function(
        dag::DAG,
        instance,
        machine::Machine,
        context_module::Module,
        scheduler::AbstractScheduler = GreedyScheduler(),
    )

Return a function of signature `compute_<id>(input::input_type(instance))`, which will return the result of the DAG computation on the given input.
The final argument `context_module` should always be `@__MODULE__` to be able to use functions defined in the caller's environment.
"""
function compute_function(
        dag::DAG,
        instance,
        machine::Machine,
        context_module::Module,
        scheduler::AbstractScheduler = GreedyScheduler()
    )
    global INITIALIZED_MODULES
    if !(context_module in INITIALIZED_MODULES)
        RuntimeGeneratedFunctions.init(context_module)
        push!(INITIALIZED_MODULES, context_module)
    end

    expr = compute_function_expr(dag, instance, machine, scheduler)
    return invokelatest(RuntimeGeneratedFunction, @__MODULE__, context_module, expr)
end
