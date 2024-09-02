using StaticArrays

"""
    get_function_call(n::Node)
    get_function_call(t::AbstractTask, device::AbstractDevice, inSymbols::AbstractVector, outSymbol::Symbol)

For a node or a task together with necessary information, return a vector of [`FunctionCall`](@ref)s for the computation of the node or task.

For ordinary compute or data tasks the vector will contain exactly one element.
"""
function get_function_call(
    t::CompTask, device::AbstractDevice, inSymbols::AbstractVector, outSymbol::Symbol
) where {CompTask<:AbstractComputeTask}
    return [FunctionCall(compute, SVector{1,Any}(t), inSymbols, outSymbol, device)]
end

function get_function_call(node::ComputeTaskNode)
    @assert length(children(node)) <= children(task(node)) "Node $(node) has too many children for its task: node has $(length(node.children)) versus task has $(children(task(node)))\nNode's children: $(getfield.(node.children, :children))"
    @assert !ismissing(node.device) "Trying to get expression for an unscheduled ComputeTaskNode\nNode: $(node)"

    if (length(node.children) <= 800)
        #only use an SVector when there are few children
        return get_function_call(
            node.task,
            node.device,
            SVector{length(node.children),Symbol}(
                Symbol.(to_var_name.(getfield.(children(node), :id)))...
            ),
            Symbol(to_var_name(node.id)),
        )
    else
        return get_function_call(
            node.task,
            node.device,
            Symbol.(to_var_name.(getfield.(children(node), :id))),
            Symbol(to_var_name(node.id)),
        )
    end
end

function get_function_call(node::DataTaskNode)
    @assert length(children(node)) == 1 "Trying to call get_expression on a data task node that has $(length(node.children)) children instead of 1"

    # TODO: dispatch to device implementations generating the copy commands
    return [
        FunctionCall(
            unpack_identity,
            SVector{0,Any}(),
            SVector{1,Symbol}(Symbol(to_var_name(first(children(node)).id))),
            Symbol(to_var_name(node.id)),
            first(children(node)).device,
        ),
    ]
end

function get_init_function_call(node::DataTaskNode, device::AbstractDevice)
    @assert isempty(children(node)) "Trying to call get_init_expression on a data task node that is not an entry node."

    return FunctionCall(
        unpack_identity,
        SVector{0,Any}(),
        SVector{1,Symbol}(Symbol("$(to_var_name(node.id))_in")),
        Symbol(to_var_name(node.id)),
        device,
    )
end
