"""
    Node{Task <: AbstractTask}

A node in a [`ComputableDAG`](@ref).
Each node is uniquely identifiable by its `id::UUID`, and identifies other nodes (for its [`dependencies`](@ref), [`dependents`](@ref), etc.) by their respective UUIDs.
A node also has a [`task`] associated with it, which defines the computation it represents in the CDAG.

The node carries information about the dependency structure of the graph; it has:
- [`dependencies`](@ref): A vector of nodes this node needs as input data. Each of the dependency nodes have an `Int` assigned to them, by which their output values are ordered in this node's function call.
- [`dependents`](@ref): A vector of nodes that this node is part of the input(s) for. This node is the dependent of its dependencies and vice versa.

The node also carries information about the schedule of the graph; it has:
- an [`antecedent`](@ref): The node running before this one on the same device, if any (it could be the first one).
- a [`precedent`](@ref): The node running after this one on the same device, if any (it could be the last one).

Finally, a node carries scheduling-related information that may be used by an estimator.
"""
mutable struct Node{Task <: AbstractTask}
    id::UUID

    task::Task

    # **the hypergraph edges**
    # dependencies are the nodes this node depends on for inputs, the associated integers define their argument order
    dependencies::Vector{Tuple{UUID, Int}}

    # dependents are the nodes dependent on this node
    dependents::Vector{UUID}

    # **the scheduler edges**
    # a 0 UUID means the node is not scheduled yet, which should only happen when it's not inserted in the graph yet
    # an Optional value would be bad for type stability, and UUIDs are generated uniqe anyway, so 0 should "never" occur anywhere else
    # antecedent is the node scheduled after this one on the same device. a special value can be used to define "none", like UUID(0)
    antecedent::UUID

    # precedent is the node scheduled before this one on the same device. a special value can be used to define "none", like UUID(0
    precedent::UUID

    # **node scheduler metrics**
    # largest sum of path from entry node to this node
    # strongly correlates with earliest start time
    t_level::Float64

    # largest sum of path from this node to exit node
    # bounded by critical path
    b_level::Float64
end
