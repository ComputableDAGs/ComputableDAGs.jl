module KernelAbstractionsExt

using ComputableDAGs
using KernelAbstractions
using UUIDs
using Random

include("kernel_wrapper.jl")

function ComputableDAGs.init_kernel(mod::Module)
    mod.eval(Meta.parse("@kernel inbounds = true function _ka_broadcast!(out::AbstractVector, @Const(in::AbstractVector), val::Val)
        id = @index(Global)
        @inline out[id] = _compute_expr(in[id], val)
    end"))
    return nothing
end

function ComputableDAGs.kernel(dag::DAG, instance, context_module::Module)
    tape = ComputableDAGs.gen_tape(dag, instance, cpu_st(), ComputableDAGs.GreedyScheduler())

    code = ComputableDAGs.gen_function_body(tape)
    assign_inputs = Expr(:block, ComputableDAGs.expr_from_fc.(tape.input_assign_code)...)

    expr = Expr(:block, assign_inputs, code, :(return $(tape.output_symbol)))

    # generate random UUID for type independent lookup in the expression cache
    val = Val(UUIDs.uuid1(TaskLocalRNG()))
    getfield(context_module, ComputableDAGs.EXPR_SYM)[val] = expr

    # wrap the kernel together with the generated Val{UUID} to opaquely insert it for the caller later
    return KAWrapper(context_module._ka_broadcast!, val)
end

end
