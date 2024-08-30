"""
    show(io::IO, diff::Diff)

Pretty-print a [`Diff`](@ref). Called via print, println and co.
"""
function show(io::IO, diff::Diff)
    print(io, "Nodes: ")
    print(io, length(diff.addedNodes) + length(diff.removedNodes))
    print(io, ", Edges: ")
    return print(io, length(diff.addedEdges) + length(diff.removedEdges))
end
