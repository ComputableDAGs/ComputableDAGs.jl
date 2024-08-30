
"""
    AbstractModel

Base type for all models. From this, [`AbstractProblemInstance`](@ref)s can be constructed.

See also: [`problem_instance`](@ref)
"""
abstract type AbstractModel end

"""
    problem_instance(::AbstractModel, ::Vararg)

Interface function that must be implemented for any implementation of [`AbstractModel`](@ref). This function should return a specific [`AbstractProblemInstance`](@ref) given some parameters.
"""
function problem_instance end

"""
    AbstractProblemInstance

Base type for problem instances. An object of this type of a corresponding [`AbstractModel`](@ref) should uniquely identify a problem instance of that model.
"""
abstract type AbstractProblemInstance end

"""
    input_type(problem::AbstractProblemInstance)

Return the input type for a specific [`AbstractProblemInstance`](@ref). This can be a specific type or a supertype for which all child types are expected to work.
"""
function input_type end

"""
    graph(::AbstractProblemInstance)

Generate the [`DAG`](@ref) for the given [`AbstractProblemInstance`](@ref). Every entry node (see [`get_entry_nodes`](@ref)) to the graph must have a name set. Implement [`input_expr`](@ref) to return a valid expression for each of those names.
"""
function graph end

"""
    input_expr(instance::AbstractProblemInstance, name::String, input_symbol::Symbol)

For the given [`AbstractProblemInstance`](@ref), the entry node name, and the symbol of the problem input (where a variable of type `input_type(...)` will exist), return an `Expr` that gets that specific input value from the input symbol.
"""
function input_expr end
