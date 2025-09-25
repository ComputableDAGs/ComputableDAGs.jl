function DataTaskNode(t::AbstractDataTask, name = "")
    return DataTaskNode(
        t,
        Vector{UUID}(),
        Vector{Tuple{UUID, Int}}(),      # TODO this can only ever be a single child
        uuid1(TaskLocalRNG()),
        missing,
        missing,
        name,
    )
end
function ComputeTaskNode(t::AbstractComputeTask)
    return ComputeTaskNode(
        t,                              # task
        Vector{UUID}(),                 # parents
        Vector{Tuple{UUID, Int}}(),     # children
        uuid1(TaskLocalRNG()),          # id
        missing,                        # node reduction
        missing,                        # node split
    )
end

"""
    node_with_op(node::Node, operation::Operation)

Return a copy of the given node with the given operation set. Necessary to keep the Node struct immutable.
"""
node_with_op(node::ComputeTaskNode, ns::NodeSplit) = ComputeTaskNode(node.task, node.parents, node.children, node.id, node.node_reduction, ns)
node_with_op(node::ComputeTaskNode, nr::NodeReduction) = ComputeTaskNode(node.task, node.parents, node.children, node.id, nr, node.node_split)
node_with_op(node::DataTaskNode, ns::NodeSplit) = DataTaskNode(node.task, node.parents, node.children, node.id, node.node_reduction, ns, node.name)
node_with_op(node::DataTaskNode, nr::NodeReduction) = DataTaskNode(node.task, node.parents, node.children, node.id, nr, node.node_split, node.name)

"""
    node_without_operation(node::Node, op_type::Type{Operation})

Return a copy of the given node without any of the given operation type set.
"""
node_without_operation(node::ComputeTaskNode, ::Type{NodeSplit}) = ComputeTaskNode(node.task, node.parents, node.children, node.id, node.node_reduction, missing)
node_without_operation(node::ComputeTaskNode, ::Type{NodeReduction}) = ComputeTaskNode(node.task, node.parents, node.children, node.id, missing, node.node_split)
node_without_operation(node::DataTaskNode, ::Type{NodeSplit}) = DataTaskNode(node.task, node.parents, node.children, node.id, node.node_reduction, missing, node.name)
node_without_operation(node::DataTaskNode, ::Type{NodeReduction}) = DataTaskNode(node.task, node.parents, node.children, node.id, missing, node.node_split, node.name)

Base.copy(n::ComputeTaskNode) = ComputeTaskNode(copy(task(n)), UUID[], Tuple{UUID, Int}[], uuid1(TaskLocalRNG()), missing, missing)
Base.copy(n::DataTaskNode) = DataTaskNode(copy(task(n)), UUID[], Tuple{UUID, Int}[], uuid1(TaskLocalRNG()), missing, missing, n.name)

"""
    make_node(t::AbstractTask)

Fallback implementation of `make_node` for an [`AbstractTask`](@ref), throwing an error.
"""
function make_node(t::AbstractTask)
    return error("Cannot make a node from this task type")
end

"""
    make_node(t::AbstractDataTask)

Construct and return a new [`DataTaskNode`](@ref) with the given task.
"""
function make_node(t::AbstractDataTask, name::String = "")
    return DataTaskNode(t, name)
end

"""
    make_node(t::AbstractComputeTask)

Construct and return a new [`ComputeTaskNode`](@ref) with the given task.
"""
function make_node(t::AbstractComputeTask)
    return ComputeTaskNode(t)
end

"""
    make_edge(n1::Node, n2::Node, index::Int)

Fallback implementation of `make_edge` throwing an error. If you got this error it likely means you tried to construct an edge between two nodes of the same type.
"""
function make_edge(n1::Node, n2::Node, index::Int = 0)
    return error("can only create edges from compute to data node or reverse")
end

"""
    make_edge(n1::ComputeTaskNode, n2::DataTaskNode, index::Int)

Construct and return a new [`Edge`](@ref) pointing from `n1` (child) to `n2` (parent).

The index parameter is 0 by default and is passed to the parent node as argument index for its child.
"""
function make_edge(n1::ComputeTaskNode, n2::DataTaskNode, index::Int = 0)
    return Edge((n1.id, n2.id), index)
end

"""
    make_edge(n1::DataTaskNode, n2::ComputeTaskNode)

Construct and return a new [`Edge`](@ref) pointing from `n1` (child) to `n2` (parent).

The index parameter is 0 by default and is passed to the parent node as argument index for its child.
"""
function make_edge(n1::DataTaskNode, n2::ComputeTaskNode, index::Int = 0)
    return Edge((n1.id, n2.id), index)
end
