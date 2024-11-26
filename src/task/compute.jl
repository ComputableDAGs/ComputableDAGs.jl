using StaticArrays

"""
    get_function_call(n::Node)
    get_function_call(t::AbstractTask, device::AbstractDevice, in_symbols::NTuple{}, out_symbol::Symbol)

For a node or a task together with necessary information, a [`FunctionCall`](@ref)s for the computation of the node or task.
"""
function get_function_call(
    t::AbstractComputeTask,
    device::AbstractDevice,
    in_symbols::NTuple{N,Symbol},
    out_symbol::Symbol,
) where {N}
    return FunctionCall(compute, (t,), [in_symbols...], [out_symbol], [Any], device)
end

function get_function_call(node::ComputeTaskNode)
    @assert length(children(node)) <= children(task(node)) "node $(node) has too many children for its task: node has $(length(node.children)) versus task has $(children(task(node)))\nnode's children: $(getfield.(node.children, :children))"
    @assert !ismissing(node.device) "trying to get expression for an unscheduled ComputeTaskNode\nnode: $(node)"

    # make sure the node is sorted so the arguments keep their order
    sort_node!(node)

    return get_function_call(
        node.task,
        node.device,
        (Symbol.(to_var_name.(getfield.(getindex.(children(node), 1), :id)))...,),
        Symbol(to_var_name(node.id)),
    )
end

function get_function_call(node::DataTaskNode)
    @assert length(children(node)) == 1 "trying to call get_function_call on a data task node that has $(length(node.children)) children instead of 1\nchildren: $(node.children)"

    # TODO: dispatch to device implementations generating the copy commands
    return FunctionCall(
        identity,
        (),
        [Symbol(to_var_name(first(children(node))[1].id))],
        [Symbol(to_var_name(node.id))],
        [Any],
        first(children(node))[1].device,
    )
end

function get_init_function_call(node::DataTaskNode, device::AbstractDevice)
    @assert isempty(children(node)) "trying to call get_init_function_call on a data task node that is not an entry node."

    return FunctionCall(
        identity,
        (),
        [Symbol("$(to_var_name(node.id))_in")],
        [Symbol(to_var_name(node.id))],
        [Any],
        device,
    )
end

_value_argument_types(fc::FunctionCall) = typeof.(fc.value_arguments[1])
function _argument_types(known_res_types::Dict{Symbol,Type}, fc::FunctionCall)
    return getindex.(Ref(known_res_types), fc.arguments[1])
end

function result_types(
    fc::FunctionCall{VAL_T,F_T}, known_res_types::Dict{Symbol,Type}
) where {VAL_T,F_T<:Function}
    arg_types = (_value_argument_types(fc)..., _argument_types(known_res_types, fc)...)
    types = Base.return_types(fc.func, arg_types)

    N_RET = length(fc.return_types)

    if length(types) > 1
        throw(
            "failure during type inference: function call $(fc.func) with argument types $(arg_types) is type unstable, possible return types: $types",
        )
    end
    if isempty(types)
        throw(
            "failure during type inference: function call $(fc.func) with argument types $(arg_types) has no return types, this is likely because no method matches the arguments",
        )
    end
    if types[1] == Any
        @warn "inferred return type 'Any' in task $fc with argument types $(arg_types)"
    end

    if (N_RET == 1)
        return [types[1]]
    end

    if !(types[1] isa Tuple) || length(types[1].parameters) != N_RET
        throw(
            "failure durng type inference: function call $(fc.func) was expected to return a Tuple with $N_RET elements, but returns $(types[1])",
        )
    end
    return [types[1].parameters...]
end

function result_types(
    fc::FunctionCall{VAL_T,Expr}, known_res_types::Dict{Symbol,Type}
) where {VAL_T}
    # assume that the return type is already set
    @assert length(fc.return_types) == 1
    return [fc.return_types[1]]
end
