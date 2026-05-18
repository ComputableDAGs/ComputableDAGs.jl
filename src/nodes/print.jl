"""
    show(io::IO, n::Node)

Print a short string representation of the node to io.
"""
function Base.show(io::IO, n::Node)
    # TODO: add trimmed UUID?
    return print(io, "Node(", task(n), ")")
end

"""
    var_name(node::Node)

Return the UUID as a string usable as a variable name in code generation.
"""
function var_name(node::Node)
    return "_" * replace(string(node.id), "-" => "_")
end
