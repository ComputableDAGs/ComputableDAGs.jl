module KernelAbstractionsExt

using ComputableDAGs
using KernelAbstractions
using UUIDs
using Random

include("kernel_wrapper.jl")

function ComputableDAGs.init_kernel(mod::Module)
    mod.eval(Meta.parse("@kernel inbounds = true function _ka_broadcast!(@Const(in::AbstractVector), out::AbstractVector, val::Val)
        id = @index(Global)
        @inline out[id] = _compute_expr(in[id], val)
    end"))
    return nothing
end


function ComputableDAGs.kernel(graph::DAG, instance, context_module::Module)
    machine = cpu_st()
    tape = ComputableDAGs.gen_tape(graph, instance, machine, context_module)

    assign_inputs = Expr(:block, ComputableDAGs.expr_from_fc.(tape.input_assign_code)...)
    # TODO: use gen_function_body here
    code = Expr(:block, ComputableDAGs.expr_from_fc.(tape.schedule)...)
    expr = Expr(:block, assign_inputs, code, :(return $(tape.output_symbol)))

    val = Val(UUIDs.uuid1(TaskLocalRNG()))
    getfield(context_module, ComputableDAGs.EXPR_SYM)[val] = expr

    return KAWrapper(context_module._ka_broadcast!, val)
end

end
