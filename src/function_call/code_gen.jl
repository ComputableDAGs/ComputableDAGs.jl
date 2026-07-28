"""
    access_expr(fc::FunctionCall{VAL_T}) where {VAL_T}

Return an expression that can be assigned to, from the return symbols in the
given function call. For multiple return symbols, this is a structured
binding.
"""
function access_expr(function_call::FunctionCall{VAL_T}) where {VAL_T}
    if isone(length(function_call.return_symbols))
        # single return value
        return function_call.return_symbols[1]
    end
    return unroll_symbol_vector(function_call.return_symbols)
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

    acc_expr = access_expr(function_call)

    return Expr(:(=), acc_expr, fc_expr)
end
