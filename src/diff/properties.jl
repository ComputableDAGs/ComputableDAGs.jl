"""
    length(diff::Diff)
    
Return a named tuple of the lengths of the added/removed nodes/edges.
The fields are `.addedNodes`, `.addedEdges`, `.removedNodes` and `.removedEdges`.
"""
function length(diff::Diff)
    return (
        addedNodes=length(diff.addedNodes),
        removedNodes=length(diff.removedNodes),
        addedEdges=length(diff.addedEdges),
        removedEdges=length(diff.removedEdges),
    )
end
