"""
    Operation

An abstract base class for operations. An operation can be applied to a [`DAG`](@ref), changing its nodes and edges.

Possible operations on a [`DAG`](@ref) can be retrieved using [`get_operations`](@ref).

See also: [`push_operation!`](@ref), [`pop_operation!`](@ref)
"""
abstract type Operation end

"""
    AppliedOperation

An abstract base class for already applied operations.
An applied operation can be reversed iff it is the last applied operation on the DAG.
Every applied operation stores a [`Diff`](@ref) from when it was initially applied to be able to revert the operation.

See also: [`revert_operation!`](@ref).
"""
abstract type AppliedOperation end

"""
    NodeReduction <: Operation

The NodeReduction operation. Represents the reduction of two or more nodes with one another.
Only one of the input nodes is kept, while all others are deleted and their parents are accumulated in the kept node's parents instead.

After the node reduction is applied, the graph has `length(nr.input) - 1` fewer nodes.

# Requirements for successful application

A vector of nodes can be reduced if:
- All nodes are in the graph.
- All nodes have the same task type.
- All nodes have the same set of children.

[`is_valid_node_reduction_input`](@ref) can be used to `@assert` these requirements.

See also: [`can_reduce`](@ref)
"""
struct NodeReduction{NodeType <: Node} <: Operation
    input::Vector{NodeType}
end

"""
    AppliedNodeReduction <: AppliedOperation

The applied version of the [`NodeReduction`](@ref).
"""
struct AppliedNodeReduction{NodeType <: Node} <: AppliedOperation
    operation::NodeReduction{NodeType}
    diff::Diff
end

"""
    NodeSplit <: Operation

The NodeSplit operation. Represents the split of its input node into one node for each of its parents. It is the reverse operation to the [`NodeReduction`](@ref).

# Requirements for successful application

A node can be split if:
- It is in the graph.
- It has at least 2 parents.

[`is_valid_node_split_input`](@ref) can be used to `@assert` these requirements.

See also: [`can_split`](@ref)
"""
struct NodeSplit{NodeType <: Node} <: Operation
    input::NodeType
end

"""
    AppliedNodeSplit <: AppliedOperation

The applied version of the [`NodeSplit`](@ref).
"""
struct AppliedNodeSplit{NodeType <: Node} <: AppliedOperation
    operation::NodeSplit{NodeType}
    diff::Diff
end
