"""
    Node

TBW
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
    # antecedent is the node scheduled after this one on the same device. a special value can be used to define "none", like UUID(0)
    antecedent::UUID

    # precedent is the node scheduled before this one on the same device. a special value can be used to define "none", like UUID(0)
    precedent::UUID

    # **node scheduler metrics**
    # largest sum of path from entry node to this node
    # strongly correlates with earliest start time
    t_level::Float64

    # largest sum of path from this node to exit node
    # bounded by critical path
    b_level::Float64
end
