using StaticArrays

"""
    function_call(n::Node)
    function_call(t::AbstractTask, device::AbstractDevice, in_symbols::NTuple{}, out_symbol::Symbol)

For a node or a task together with necessary information, a [`FunctionCall`](@ref)s for the computation of the node or task.
"""
function function_call(
        t::AbstractComputeTask,
        device::AbstractDevice,
        in_symbols::NTuple{N, Symbol},
        out_symbol::Symbol,
    ) where {N}
    return FunctionCall(compute, (t,), [in_symbols...], [out_symbol], Type[Any], device)
end

function function_call(node::ComputeTaskNode, device::AbstractDevice)
    # make sure the node is sorted so the arguments keep their order
    sort_node!(node)

    return function_call(
        node.task,
        device,
        (Symbol.(to_var_name.(getindex.(node.children, 1)))...,),
        Symbol(to_var_name(node.id)),
    )
end

function function_call(node::DataTaskNode, device::AbstractDevice)
    @assert length(node.children) == 1 "trying to call function_call on a data task node that has $(length(node.children)) children instead of 1\nchildren: $(node.children)"

    # TODO: dispatch to device implementations generating the copy commands
    return FunctionCall(
        identity,
        (),
        [Symbol(to_var_name(first(node.children)[1]))],
        [Symbol(to_var_name(node.id))],
        Type[Any],
        device,
    )
end

function init_function_call(node::DataTaskNode, device::AbstractDevice)
    @assert isempty(node.children) "trying to call init_function_call on a data task node that is not an entry node."

    return FunctionCall(
        identity,
        (),
        [Symbol("$(to_var_name(node.id))_in")],
        [Symbol(to_var_name(node.id))],
        Type[Any],
        device,
    )
end

_value_argument_types(fc::FunctionCall) = typeof.(fc.value_arguments[1])
function _argument_types(known_res_types::Dict{Symbol, Type}, fc::FunctionCall)
    return getindex.(Ref(known_res_types), fc.arguments[1])
end

function _validate_result_types(fc::FunctionCall, types, arg_types)
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
        return nothing
    end

    if !(types[1] isa Tuple) || length(types[1].parameters) != N_RET
        throw(
            "failure during type inference: function call $(fc.func) was expected to return a Tuple with $N_RET elements, but returns $(types[1])",
        )
    end
    return nothing
end

@inline function _assert_array_types(args)
    return @assert false "all arguments of a vectorized compute task must be arrays"
end
@inline _assert_array_types() = nothing
@inline function _assert_array_types(arg::AbstractArray, args...)
    return _assert_array_types(args)
end

function compute(::VectorizedComputeTask{T}, args...) where {T <: AbstractComputeTask}
    _assert_array_types(args)

    res = similar(args[1])
    c = 1
    @simd for args in Iterators.zip(args)
        res[c] = compute(T(), args...)
        c += 1
    end
    return res
end
