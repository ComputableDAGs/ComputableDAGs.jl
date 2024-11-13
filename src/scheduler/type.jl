"""
    FunctionCall{VAL_TYPES}

Type representing a function call. Contains the function to call, argument symbols, the return symbol and the device to execute on.

TODO: extend docs
"""
mutable struct FunctionCall{VAL_T<:Tuple,N_ARG,N_RET}
    func::Function
    value_arguments::Vector{VAL_T}                          # tuple of value arguments for the function call, will be prepended to the other arguments
    arguments::Vector{NTuple{N_ARG,Symbol}}                 # symbols of the inputs to the function call
    return_symbols::Vector{NTuple{N_RET,Symbol}}            # the return symbols
    return_types::NTuple{N_RET,Type}                        # the return type of the function call(s); there can only be one return type since we require type stability
    device::AbstractDevice
end

function FunctionCall(
    func::Function,
    value_arguments::VAL_T,
    arguments::NTuple{N_ARG,Symbol},
    return_symbol::NTuple{N_RET,Symbol},
    return_types::NTuple{N_RET,Type},
    device::AbstractDevice,
) where {VAL_T<:Tuple,N_ARG,N_RET}
    # convenience constructor for function calls that do not use vectorization, which is most of the use cases
    return FunctionCall(
        func, [value_arguments], [arguments], [return_symbol], return_types, device
    )
end

function Base.length(fc::FunctionCall)
    @assert length(fc.value_arguments) == length(fc.arguments) == length(fc.return_symbols) "function call length is undefined, got $(length(fc.value_arguments)) tuples of value arguments, $(length(fc.arguments)) tuples of arguments, and $(length(return_symbols)) return symbols"
    return length(fc.value_arguments)
end
