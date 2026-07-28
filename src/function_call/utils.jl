"""
    unroll_symbol_vector(vec::Vector{Symbol})

Return the given `Vector` or `Tuple` as a single `String` without quotation
marks or brackets.
"""
function unroll_symbol_vector(vec::VEC) where {VEC <: Union{AbstractVector, Tuple}}
    return Expr(:tuple, vec...)
end
