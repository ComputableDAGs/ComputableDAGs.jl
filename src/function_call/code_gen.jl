"""
    access_expr(return_symbols::AbstractVector{Symbol})

Return an expression that can be assigned to, from the given return symbols.
For multiple return symbols, this is a structured binding.
"""
function access_expr(return_symbols::AbstractVector{Symbol})
    if isone(length(return_symbols))
        # no structured binding necessary
        return return_symbols[1]
    end
    return unroll_symbol_vector(return_symbols)
end

"""
    lower_to_expr(function_call::FunctionCall{VAL_T}) where {VAL_T}

Generate and return an expression from this function call.
"""
function lower_to_expr(function_call::FunctionCall{VAL_T}) where {VAL_T}
    fc_expr = Expr(
        :call,
        function_call.func,
        function_call.value_arguments...,
        function_call.arguments...
    )

    acc_expr = access_expr(function_call.return_symbols)

    return Expr(:(=), acc_expr, fc_expr)
end

"""
    lower_to_expr(assignment::ExprAssignment)

Generate and return an expression from this expression assignment.
"""
function lower_to_expr(assignment::ExprAssignment)
    return Expr(
        :(=),
        assignment.return_symbol,
        assignment.expr
    )
end
