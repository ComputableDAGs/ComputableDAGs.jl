module KernelAbstractionsExt

using ComputableDAGs
using UUIDs
using Random

function ComputableDAGs.kernel(graph::DAG, instance, context_module::Module)
    machine = cpu_st()
    tape = ComputableDAGs.gen_tape(graph, instance, machine, context_module)

    assign_inputs = Expr(:block, ComputableDAGs.expr_from_fc.(tape.input_assign_code)...)
    # TODO: use gen_function_body here
    code = Expr(:block, ComputableDAGs.expr_from_fc.(tape.schedule)...)

    function_id = ComputableDAGs.to_var_name(UUIDs.uuid1(TaskLocalRNG()))
    expr = Meta.parse(
        "@kernel function compute_$(function_id)(input_vector, output_vector)
            id = @index(Global)
            @inline input = input_vector[id]
            $(assign_inputs)
            $code
            @inline output_vector[id] = $(tape.output_symbol)
        end"
    )

    return expr
end

end
