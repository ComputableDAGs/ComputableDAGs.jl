
"""
    AbstractOptimizer

Abstract base type for optimizer implementations.
"""
abstract type AbstractOptimizer end

"""
    optimize_step!(optimizer::AbstractOptimizer, graph::DAG)

Interface function that must be implemented by implementations of [`AbstractOptimizer`](@ref). Returns `true` if an operations has been applied, `false` if not, usually when a fixpoint of the algorithm has been reached.

It should do one smallest logical step on the given [`DAG`](@ref), muting the graph and, if necessary, the optimizer's state.
"""
function optimize_step! end

"""
    optimize!(optimizer::AbstractOptimizer, graph::DAG, n::Int)

Function calling the given optimizer `n` times, muting the graph. Returns `true` if the requested number of operations has been applied, `false` if not, usually when a fixpoint of the algorithm has been reached.

If a more efficient method exists, this can be overloaded for a specific optimizer.
"""
function optimize!(optimizer::AbstractOptimizer, graph::DAG, n::Int)
    for i in 1:n
        if !optimize_step!(optimizer, graph)
            return false
        end
    end
    return true
end

"""
    fixpoint_reached(optimizer::AbstractOptimizer, graph::DAG)

Interface function that can be implemented by optimization algorithms that can reach a fixpoint, returning as a `Bool` whether it has been reached. The default implementation returns `false`.

See also: [`optimize_to_fixpoint!`](@ref)
"""
function fixpoint_reached(optimizer::AbstractOptimizer, graph::DAG)
    return false
end

"""
    optimize_to_fixpoint!(optimizer::AbstractOptimizer, graph::DAG)

Interface function that can be implemented by optimization algorithms that can reach a fixpoint. The algorithm will be run until that fixpoint is reached, at which point [`fixpoint_reached`](@ref) should return true.

A usual implementation might look like this:
```julia
    function optimize_to_fixpoint!(optimizer::MyOptimizer, graph::DAG)
        while !fixpoint_reached(optimizer, graph)
            optimize_step!(optimizer, graph)
        end
        return nothing
    end
```
"""
function optimize_to_fixpoint! end
