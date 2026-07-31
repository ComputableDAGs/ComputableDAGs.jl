"""
    to_var_name(id::UUID)

Return the uuid as a string usable as a variable name in code generation.
"""
function to_var_name(id::UUID)
    str = "_" * replace(string(id), "-" => "_")
    return str
end

"""
    access_expr(symbols::AbstractVector{Symbol})
    access_expr(symbol::Symbol)

Return an expression that can be assigned to, from the given symbol(s).
For multiple symbols, this is a structured binding.
"""
function access_expr(symbols::AbstractVector{Symbol})
    if isone(length(symbols))
        # no structured binding necessary
        return access_expr(symbols[1])
    end
    return unroll_symbol_vector(symbols)
end
function access_expr(symbol::Symbol)
    return symbol
end

"""
    lower_to_expr(function_call::FunctionCall{VAL_T}, dev::CPU) where {VAL_T}

Generate and return an expression from this function call.
"""
function lower_to_expr(function_call::FunctionCall{VAL_T}, ::CPU) where {VAL_T}
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
    lower_to_expr(assignment::ExprAssignment, dev::CPU)

Generate and return an expression from this expression assignment.
"""
function lower_to_expr(assignment::ExprAssignment, ::CPU)
    return Expr(
        :(=),
        assignment.return_symbol,
        assignment.expr
    )
end

"""
    lower_to_expr(send_instruction::SendInstruction, ::CPU)

Generate and return an expression from this send instruction on a [`CPU`](@ref).
"""
function lower_to_expr(send_instruction::SendInstruction, ::CPU)
    return if send_instruction.on_machine
        Expr(
            :call,
            send,
            DEVICE_MANAGER_SYM,
            Val(true),
            send_instruction.dest.id,
            Symbol(to_var_name(send_instruction.id)),
            send_instruction.id,
        )
    else
        Expr(
            :call,
            send,
            DEVICE_MANAGER_SYM,
            Val(false),
            send_instruction.dest.id,
            Symbol(to_var_name(send_instruction.id)),
            send_instruction.id
        )
    end
end

"""
    lower_to_expr(recv_instruction::RecvInstruction, ::CPU)

Generate and return an expression from this receive instruction on a [`CPU`](@ref).
"""
function lower_to_expr(recv_instruction::RecvInstruction, ::CPU)
    recv_expr = if recv_instruction.on_machine
        Expr(
            :call,
            get,
            DEVICE_MANAGER_SYM,
            Val(true),
            recv_instruction.origin.id,
            recv_instruction.id,
            recv_instruction.type,
        )
    else
        Expr(
            :call,
            get,
            DEVICE_MANAGER_SYM,
            Val(false),
            recv_instruction.origin.id,
            recv_instruction.id,
            recv_instruction.type,
        )
    end

    return Expr(
        :(=),
        Symbol(to_var_name(recv_instruction.id)),
        recv_expr
    )
end
