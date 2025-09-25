"""
    empty!(diff::Diff)

Reset the given diff, clearing everything.
"""
function Base.empty!(diff::Diff)
    empty!(diff.added_nodes)
    empty!(diff.removed_nodes)
    empty!(diff.added_edges)
    empty!(diff.removed_edges)

    empty!(diff.updated_children)
    return nothing
end
