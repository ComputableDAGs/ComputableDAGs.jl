function ComputableDAGs.kernel(
    ::Type{CUDAGPU}, graph::DAG, instance, context_module::Module
)
    machine = cpu_st()
    tape = ComputableDAGs.gen_tape(graph, instance, machine, context_module)

    assign_inputs = Expr(:block, ComputableDAGs.expr_from_fc.(tape.input_assign_code)...)
    # TODO: use gen_function_body here
    code = Expr(:block, ComputableDAGs.expr_from_fc.(tape.schedule)...)

    function_id = ComputableDAGs.to_var_name(UUIDs.uuid1(ComputableDAGs.rng[1]))
    expr = Meta.parse(
        "function compute_$(function_id)(input_vector, output_vector, n::Int64)
            id = (blockIdx().x - 1) * blockDim().x + threadIdx().x
            if (id > n)  
                return
            end
            @inline input = input_vector[id]
            $(assign_inputs)
            $code
            @inline output_vector[id] = $(tape.output_symbol)
            return nothing
        end"
    )

    return expr
end
