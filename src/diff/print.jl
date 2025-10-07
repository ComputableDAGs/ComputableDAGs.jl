"""
    show(io::IO, diff::Diff)

Pretty-print a [`Diff`](@ref). Called via print, println and co.
"""
function Base.show(io::IO, diff::Diff)
    print(io, "Nodes: ")
    print(io, length(diff.added_nodes) + length(diff.removed_nodes))
    print(io, ", Edges: ")
    return print(io, length(diff.added_edges) + length(diff.removed_edges))
end
