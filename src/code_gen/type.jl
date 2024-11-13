
"""
    Tape{INPUT}

TODO: update docs
- `INPUT` the input type of the problem instance

- `code::Vector{Expr}`: The julia expression containing the code for the whole graph.
- `output_symbol::Symbol`: The symbol of the final calculated value
"""
struct Tape{INPUT}
    input_assign_code::Vector{FunctionCall}
    schedule::Vector{FunctionCall}
    output_symbol::Symbol
    instance::Any
    machine::Machine
end
