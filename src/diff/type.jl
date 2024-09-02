"""
    Diff

A named tuple representing a difference of added and removed nodes and edges on a [`DAG`](@ref).
"""
const Diff = NamedTuple{
    (:addedNodes, :removedNodes, :addedEdges, :removedEdges, :updatedChildren),
    Tuple{
        Vector{Node},Vector{Node},Vector{Edge},Vector{Edge},Vector{Tuple{Node,AbstractTask}}
    },
}

function Diff()
    return (
        addedNodes=Vector{Node}(),
        removedNodes=Vector{Node}(),
        addedEdges=Vector{Edge}(),
        removedEdges=Vector{Edge}(),

        # children were updated in the task, updatedChildren[x][2] is the task before the update
        updatedChildren=Vector{Tuple{Node,AbstractTask}}(),
    )::Diff
end
