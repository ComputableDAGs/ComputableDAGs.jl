"""
    Diff

A named tuple representing a difference of added and removed nodes and edges on a [`DAG`](@ref).
"""
const Diff = NamedTuple{
    (:added_nodes, :removed_nodes, :added_edges, :removed_edges, :updated_children),
    Tuple{
        Vector{Node}, Vector{Node}, Vector{Edge}, Vector{Edge}, Vector{Tuple{Node, AbstractTask}},
    },
}

function Diff()
    return (
        added_nodes = Vector{Node}(),
        removed_nodes = Vector{Node}(),
        added_edges = Vector{Edge}(),
        removed_edges = Vector{Edge}(),

        # children were updated in the task, updated_children[x][2] is the task before the update
        updated_children = Vector{Tuple{Node, AbstractTask}}(),
    )::Diff
end
