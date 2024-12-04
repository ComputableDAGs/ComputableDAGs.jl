"""
    input_type(problem_instance)

Return the input type for a specific `problem_instance`. This can be a specific type or a supertype for which all child types are expected to be implemented.

For more details on the `problem_instance`, please refer to the documentation.
"""
function input_type end

"""
    graph(problem_instance)

Generate the [`DAG`](@ref) for the given `problem_instance`. Every entry node (see [`get_entry_nodes`](@ref)) to the graph must have a name set. Implement [`input_expr`](@ref) to return a valid expression for each of those names.

For more details on the `problem_instance`, please refer to the documentation.
"""
function graph end

"""
    input_expr(problem_instance, name::String, input_symbol::Symbol)

For the given `problem_instance`, the entry node name, and the symbol of the problem input (where a variable of type `input_type(...)` will exist), return an `Expr` that gets that specific input value from the input symbol.

For more details on the `problem_instance`, please refer to the documentation.
"""
function input_expr end
