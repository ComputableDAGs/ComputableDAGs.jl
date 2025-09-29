using Random
using UUIDs
using Base.Threads

"""
    Node

The abstract base type of every node.

See [`DataTaskNode`](@ref), [`ComputeTaskNode`](@ref) and [`make_node`](@ref).
"""
abstract type Node end

# declare this type here because it's needed
abstract type Operation end

"""
    DataTaskNode <: Node

Any node that transfers data and does no computation.

# Fields
`.task`:            The node's data task type. Usually [`DataTask`](@ref).\\
`.parents`:         A vector of the node's parents (i.e. nodes that depend on this one).\\
`.children`:        A vector of tuples of the node's children (i.e. nodes that this one depends on) and their indices, indicating their order in the resulting function call passed to the task.\\
`.id`:              The node's id. Improves the speed of comparisons and is used as a unique identifier.\\
`.name`:            The name of this node for entry nodes into the graph ([`is_entry_node`](@ref)) to reliably assign the inputs to the correct nodes when executing.\\
"""
struct DataTaskNode{TaskType <: AbstractDataTask} <: Node
    task::TaskType

    # use vectors as sets have way too much memory overhead
    parents::Vector{UUID}
    children::Vector{Tuple{UUID, Int}}

    # need a unique identifier unique to every node
    id::UUID

    # for input nodes we need a name for the node to distinguish between them
    name::String
end

"""
    ComputeTaskNode <: Node

Any node that computes a result from inputs using an [`AbstractComputeTask`](@ref).

# Fields
`.task`:            The node's compute task type. A concrete subtype of [`AbstractComputeTask`](@ref).\\
`.parents`:         A vector of the node's parents (i.e. nodes that depend on this one).\\
`.children`:        A vector of tuples with the node's children (i.e. nodes that this one depends on) and their index, used to order the arguments for the [`AbstractComputeTask`](@ref).\\
`.id`:              The node's id. Improves the speed of comparisons and is used as a unique identifier.\\
"""
struct ComputeTaskNode{TaskType <: AbstractComputeTask} <: Node
    task::TaskType
    parents::Vector{UUID}
    children::Vector{Tuple{UUID, Int}}
    id::UUID
end

"""
    Edge

Type of an edge in the graph. Edges can only exist between a [`DataTaskNode`](@ref) and a [`ComputeTaskNode`](@ref) or vice versa, not between two of the same type of node.

An edge always points from child to parent: `child = e.edge[1]` and `parent = e.edge[2]`. Additionally, the `Edge`` contains the `index` which is used as the child's index in the parent node.

The child is the prerequisite node of the parent.
"""
struct Edge
    # edge points from child to parent
    edge::Tuple{UUID, UUID}
    # the index of the child in parent
    index::Int
end
