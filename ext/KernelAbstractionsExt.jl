module KernelAbstractionsExt

using ComputableDAGs
using KernelAbstractions
using UUIDs
using Random

function ComputableDAGs.init_kernel(mod::Module)
    mod.eval(Meta.parse("@kernel inbounds = true function _ka_broadcast!(@Const(in::AbstractVector), out::AbstractVector)
        id = @index(Global)
        @inline out[id] = _compute_expr(in[id])
    end"))
    return nothing
end

function ComputableDAGs.kernel(graph::DAG, instance, context_module::Module; concrete_input_type::Type = Nothing)
    machine = cpu_st()
    tape = ComputableDAGs.gen_tape(graph, instance, machine, context_module)

    assign_inputs = Expr(:block, ComputableDAGs.expr_from_fc.(tape.input_assign_code)...)
    # TODO: use gen_function_body here
    code = Expr(:block, ComputableDAGs.expr_from_fc.(tape.schedule)...)

    expr = Expr(:block, assign_inputs, code, :(return $(tape.output_symbol)))

    T = if isnothing(concrete_input_type)
        ComputableDAGs.input_type(instance)
    else
        concrete_input_type
    end

    if haskey(getfield(context_module, ComputableDAGs.EXPR_SYM), T)
        @warn "a KernelAbstractions broadcasting kernel for input type $T has already been defined and will be overwritten\nthis new function only takes effect if the old definition has not been called yet"
    end
    getfield(context_module, ComputableDAGs.EXPR_SYM)[T] = expr

    return context_module._ka_broadcast!
end

end
