function ComputableDAGs.kernel(
    ::Type{ROCmGPU}, graph::DAG, instance, context_module::Module
)
    machine = cpu_st()
    tape = ComputableDAGs.gen_tape(graph, instance, machine, context_module)

    assign_inputs = Expr(:block, ComputableDAGs.expr_from_fc.(tape.inputAssignCode)...)

    # TODO use gen_function_body here
    code = Expr(:block, ComputableDAGs.expr_from_fc.(tape.schedule)...)

    function_id = ComputableDAGs.to_var_name(UUIDs.uuid1(ComputableDAGs.rng[1]))
    res_sym = eval(
        ComputableDAGs._gen_access_expr(
            ComputableDAGs.entry_device(tape.machine), tape.outputSymbol
        ),
    )
    expr = Meta.parse(
        "function compute_$(function_id)(input_vector, output_vector, n::Int64)
            id = (workgroupIdx().x - 1) * workgroupDim().x + workgroupIdx().x
            if (id > n)
                return
            end
            @inline data_input = input_vector[id]
            $(assign_inputs)
            $code
            @inline output_vector[id] = $res_sym
            return nothing
        end"
    )

    return expr
end
