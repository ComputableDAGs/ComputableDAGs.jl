"""
    show(io::IO, n::Node)

Print a short string representation of the node to io.
"""
function Base.show(io::IO, n::Node)
    return print(io, "Node(", task(n), ")")
end

"""
    show(io::IO, e::Edge)

Print a short string representation of the edge to io.
"""
function Base.show(io::IO, e::Edge)
    return print(io, "Edge(", e.edge[1], ", ", e.edge[2], ")")
end

"""
    to_var_name(id::UUID)

Return the uuid as a string usable as a variable name in code generation.
"""
function to_var_name(id::UUID)
    str = "_" * replace(string(id), "-" => "_")
    return str
end
