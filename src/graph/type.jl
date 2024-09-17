using DataStructures

"""
    PossibleOperations

A struct storing all possible operations on a [`DAG`](@ref).
To get the [`PossibleOperations`](@ref) on a [`DAG`](@ref), use [`get_operations`](@ref).
"""
mutable struct PossibleOperations
    nodeReductions::Set{NodeReduction}
    nodeSplits::Set{NodeSplit}
end

""" 
    DAG

The representation of the graph as a set of [`Node`](@ref)s.

[`Operation`](@ref)s can be applied on it using [`push_operation!`](@ref) and reverted using [`pop_operation!`](@ref) like a stack.
To get the set of possible operations, use [`get_operations`](@ref).
The members of the object should not be manually accessed, instead always use the provided interface functions.
"""
mutable struct DAG
    nodes::Set{Union{DataTaskNode,ComputeTaskNode}}

    # The operations currently applied to the set of nodes
    appliedOperations::Stack{AppliedOperation}

    # The operations not currently applied but part of the current state of the DAG
    operationsToApply::Deque{Operation}

    # The possible operations at the current state of the DAG
    possibleOperations::PossibleOperations

    # The set of nodes whose possible operations need to be reevaluated
    dirtyNodes::Set{Union{DataTaskNode,ComputeTaskNode}}

    # "snapshot" system: keep track of added/removed nodes/edges since last snapshot
    # these are muted in insert_node! etc.
    diff::Diff

    # the cached properties of the DAG
    properties::GraphProperties
end

"""
    PossibleOperations()

Construct and return an empty [`PossibleOperations`](@ref) object.
"""
function PossibleOperations()
    return PossibleOperations(Set{NodeReduction}(), Set{NodeSplit}())
end

"""
    DAG()

Construct and return an empty [`DAG`](@ref).
"""
function DAG()
    return DAG(
        Set{Node}(),
        Stack{AppliedOperation}(),
        Deque{Operation}(),
        PossibleOperations(),
        Set{Node}(),
        Diff(),
        GraphProperties(),
    )
end
