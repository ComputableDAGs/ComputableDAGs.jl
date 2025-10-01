module MatrixMultiplicationImpl

using ComputableDAGs

const STRASSEN_MIN_SIZE = 32    # minimum matrix size to use Strassen algorithm instead of naive algorithm
const DEFAULT_TYPE = Float64    # default type of matrix multiplication assumed

# problem model definition
struct MatrixMultiplication{T}
    size::Int   # size of multiplication
end

MatrixMultiplication(size::Int) = MatrixMultiplication{DEFAULT_TYPE}(size)

# TODO: use actual numbers here for the compute efforts, these are just placeholders. they would have to scale with the sizes
@compute_task Slice{X_SLICE, Y_SLICE} 10 1
@compute_task Add 32 2 (+)
@compute_task Subtract 32 2 (-)
@compute_task MultBase 512 2 (*)
@compute_task MultStrassen 256 4 (C11, C12, C21, C22) -> [C11 C12; C21 C22]

# relies on the type parameters, so long form compute function definition outside of the @compute_task macro
@inline ComputableDAGs.compute(
    ::Slice{UR_X, UR_Y}, A::AbstractMatrix
) where {UR_X, UR_Y} = A[UR_X, UR_Y]

# return data node with the result
function _dag_build_helper!(
        mm::MatrixMultiplication{T},
        A::DataTaskNode,    # Data node that contains matrix A
        B::DataTaskNode,    # Data node that contains matrix B
    ) where {T}
    mm_size = mm.size
    @assert iseven(mm_size) "matrix size is not even: $mm_size"
    mm_half_size = div(mm_size, 2)

    data_size = mm.size^2 * sizeof(T)
    data_size_half = div(data_size, 4)

    if mm_size < STRASSEN_MIN_SIZE
        return @add_call MultBase() data_size A B
    end

    # STRASSEN step
    h1 = 1:mm_half_size
    h2 = (mm_half_size + 1):mm_size

    # -- Subindexing of A and B to prepare A_11, A_12, and so on
    A11 = @add_call Slice{h1, h1}() data_size_half A
    A12 = @add_call Slice{h1, h2}() data_size_half A
    A21 = @add_call Slice{h2, h1}() data_size_half A
    A22 = @add_call Slice{h2, h2}() data_size_half A

    B11 = @add_call Slice{h1, h1}() data_size_half B
    B12 = @add_call Slice{h1, h2}() data_size_half B
    B21 = @add_call Slice{h2, h1}() data_size_half B
    B22 = @add_call Slice{h2, h2}() data_size_half B

    # M1 = (A11 + A22) x (B11 + B22)
    A_sum = @add_call Add() data_size_half A11 A22
    B_sum = @add_call Add() data_size_half B11 B22

    M1 = _dag_build_helper!(MatrixMultiplication{T}(mm_half_size), A_sum, B_sum)

    # M2 = (A21 + A22) x B11
    A_sum = @add_call Add() data_size_half A21 A22
    M2 = _dag_build_helper!(MatrixMultiplication{T}(mm_half_size), A_sum, B11)

    # M3 = A11 x (B12 - B22)
    B_dif = @add_call Subtract() data_size_half B12 B22
    M3 = _dag_build_helper!(MatrixMultiplication{T}(mm_half_size), A11, B_dif)

    # M4 = A22 x (B21 - B11)
    B_dif = @add_call Subtract() data_size_half B21 B11
    M4 = _dag_build_helper!(MatrixMultiplication{T}(mm_half_size), A22, B_dif)

    # M5 = (A11 + A12) x B22
    A_sum = @add_call Add() data_size_half A11 A12
    M5 = _dag_build_helper!(MatrixMultiplication{T}(mm_half_size), A_sum, B22)

    # M6 = (A21 - A11) x (B11 + B12)
    A_dif = @add_call Subtract() data_size_half A21 A11
    B_sum = @add_call Add() data_size_half B11 B12
    M6 = _dag_build_helper!(MatrixMultiplication{T}(mm_half_size), A_dif, B_sum)

    # M7 = (A12 - A22) x (B21 + B22)
    A_dif = @add_call Subtract() data_size_half A12 A22
    B_sum = @add_call Add() data_size_half B21 B22
    M7 = _dag_build_helper!(MatrixMultiplication{T}(mm_half_size), A_dif, B_sum)

    # C11 = M1 + M4 - M5 + M7
    s1 = @add_call Add() data_size_half M1 M4
    s2 = @add_call Subtract() data_size_half M7 M5
    C11 = @add_call Add() data_size_half s1 s2

    # C12 = M3 + M5
    C12 = @add_call Add() data_size_half M3 M5

    # C21 = M2 + M4
    C21 = @add_call Add() data_size_half M2 M4

    # C22 = M1 - M2 + M3 + M6
    s3 = @add_call Subtract() data_size_half M1 M2
    s4 = @add_call Add() data_size_half M3 M6
    C22 = @add_call Add() data_size_half s3 s4

    # Assemble new Matrix C
    C = @add_call MultStrassen() data_size C11 C12 C21 C22
    return C
end

function ComputableDAGs.graph(mm::MatrixMultiplication{T}) where {T}
    return @assemble_dag begin
        A = @add_entry "A" (mm.size^2 * sizeof(T))
        B = @add_entry "B" (mm.size^2 * sizeof(T))

        _dag_build_helper!(mm, A, B)
    end
end

function ComputableDAGs.input_expr(
        ::MatrixMultiplication, name::String, input_symbol::Symbol
    )
    if name == "A"
        return Meta.parse("$input_symbol[1]")
    elseif name == "B"
        return Meta.parse("$input_symbol[2]")
    else
        throw("unknown data node name $name")
    end
end

function ComputableDAGs.input_type(mm::MatrixMultiplication{T}) where {T}
    return Tuple{Matrix{T}, Matrix{T}}
end

export MatrixMultiplication

end
