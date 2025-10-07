"""
    length(diff::Diff)

Return a named tuple of the lengths of the added/removed nodes/edges.
The fields are `.added_nodes`, `.added_edges`, `.removed_nodes` and `.removed_edges`.
"""
function Base.length(diff::Diff)
    return (
        added_nodes = length(diff.added_nodes),
        removed_nodes = length(diff.removed_nodes),
        added_edges = length(diff.added_edges),
        removed_edges = length(diff.removed_edges),
    )
end
