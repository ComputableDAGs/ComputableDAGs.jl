module MatrixMultiplicationImpl

using ComputableDAGs

const STRASSEN_MIN_SIZE = 64    # minimum matrix size to use Strassen algorithm instead of naive algorithm

# problem model definition
struct MatrixMultiplication
    size::Int   # size of multiplication
end

struct ComputeTask_Slice{X_SLICE,Y_SLICE} <: AbstractComputeTask end        # perform a matrix slicing operation, subindexing the matrix with the ranges X_SLICE and Y_SLICE
struct ComputeTask_Add <: AbstractComputeTask end          # perform matrix addition
struct ComputeTask_Sub <: AbstractComputeTask end          # perform matrix subtraction
struct ComputeTask_MultBase <: AbstractComputeTask end     # perform matrix multiplication on two matrices using naive algorithm
struct ComputeTask_MultStrassen <: AbstractComputeTask end # perform one strassen assembly step from C11, C12, C21, C22

ComputableDAGs.children(::ComputeTask_Slice) = 1        # A
ComputableDAGs.children(::ComputeTask_Add) = 2          # A, B
ComputableDAGs.children(::ComputeTask_Sub) = 2          # A, B
ComputableDAGs.children(::ComputeTask_MultBase) = 2     # A, B
ComputableDAGs.children(::ComputeTask_MultStrassen) = 7 # M1...M7

ComputableDAGs.compute_effort(::ComputeTask_Slice) = 0
ComputableDAGs.compute_effort(::ComputeTask_Add) = 0
ComputableDAGs.compute_effort(::ComputeTask_Sub) = 0
ComputableDAGs.compute_effort(::ComputeTask_MultBase) = 0
ComputableDAGs.compute_effort(::ComputeTask_MultStrassen) = 0

@inline ComputableDAGs.compute(
    ::ComputeTask_Slice{UR_X,UR_Y}, A::AbstractMatrix
) where {UR_X,UR_Y} = A[UR_X, UR_Y]
@inline ComputableDAGs.compute(::ComputeTask_Add, A::AbstractMatrix, B::AbstractMatrix) =
    A + B
@inline ComputableDAGs.compute(::ComputeTask_Sub, A::AbstractMatrix, B::AbstractMatrix) =
    A - B
@inline ComputableDAGs.compute(
    ::ComputeTask_MultBase, A::AbstractMatrix, B::AbstractMatrix
) = A * B

function ComputableDAGs.compute(
    ::ComputeTask_MultStrassen,
    C11::AbstractMatrix,
    C12::AbstractMatrix,
    C21::AbstractMatrix,
    C22::AbstractMatrix,
)
    # One Strassen step from precomputed matrices M1...M7
    # result will be [C11 C12; C21 C22], where
    # C11 = M1 + M4 - M5 + M7
    # C12 = M3 + M5
    # C21 = M2 + M4
    # C22 = M1 - M2 + M3 + M6
    return [
        C11 C12
        C21 C22
    ]
end

function ComputableDAGs.input_type(mm::MatrixMultiplication)
    return Tuple{<:AbstractMatrix,<:AbstractMatrix}
end

# return data node with the result
function _dag_build_helper!(
    g::DAG,
    A::DataTaskNode,    # Data node that contains matrix A
    B::DataTaskNode,    # Data node that contains matrix B
    mm_size::Int,
)
    @assert iseven(mm_size) "matrix size is not even: $mm_size"
    mm_half_size = div(mm_size, 2)

    if mm_size < STRASSEN_MIN_SIZE
        mb_task = insert_node!(g, ComputeTask_MultBase())
        mb_data = insert_node!(g, DataTask(0))

        insert_edge!(g, A, mb_task, 1)
        insert_edge!(g, B, mb_task, 2)
        insert_edge!(g, mb_task, mb_data)
        return mb_data
    end

    # STRASSEN step
    h1 = 1:mm_half_size
    h2 = (mm_half_size + 1):mm_size

    # -- Subindexing of A and B to prepare A_11, A_12, and so on
    A11_t = insert_node!(g, ComputeTask_Slice{h1,h1}())
    insert_edge!(g, A, A11_t)
    A12_t = insert_node!(g, ComputeTask_Slice{h1,h2}())
    insert_edge!(g, A, A12_t)
    A21_t = insert_node!(g, ComputeTask_Slice{h2,h1}())
    insert_edge!(g, A, A21_t)
    A22_t = insert_node!(g, ComputeTask_Slice{h2,h2}())
    insert_edge!(g, A, A22_t)

    A11_d = insert_node!(g, DataTask(0))
    insert_edge!(g, A11_t, A11_d)
    A12_d = insert_node!(g, DataTask(0))
    insert_edge!(g, A12_t, A12_d)
    A21_d = insert_node!(g, DataTask(0))
    insert_edge!(g, A21_t, A21_d)
    A22_d = insert_node!(g, DataTask(0))
    insert_edge!(g, A22_t, A22_d)

    B11_t = insert_node!(g, ComputeTask_Slice{h1,h1}())
    insert_edge!(g, B, B11_t)
    B12_t = insert_node!(g, ComputeTask_Slice{h1,h2}())
    insert_edge!(g, B, B12_t)
    B21_t = insert_node!(g, ComputeTask_Slice{h2,h1}())
    insert_edge!(g, B, B21_t)
    B22_t = insert_node!(g, ComputeTask_Slice{h2,h2}())
    insert_edge!(g, B, B22_t)

    B11_d = insert_node!(g, DataTask(0))
    insert_edge!(g, B11_t, B11_d)
    B12_d = insert_node!(g, DataTask(0))
    insert_edge!(g, B12_t, B12_d)
    B21_d = insert_node!(g, DataTask(0))
    insert_edge!(g, B21_t, B21_d)
    B22_d = insert_node!(g, DataTask(0))
    insert_edge!(g, B22_t, B22_d)

    # M1 = (A11 + A22) x (B11 + B22)
    local M1_d::DataTaskNode
    begin
        A_sum_t = insert_node!(g, ComputeTask_Add()) # A11 + A22
        B_sum_t = insert_node!(g, ComputeTask_Add()) # B11 + B22
        insert_edge!(g, A11_d, A_sum_t, 1)
        insert_edge!(g, A22_d, A_sum_t, 2)
        insert_edge!(g, B11_d, B_sum_t, 1)
        insert_edge!(g, B22_d, B_sum_t, 2)
        A_sum_d = insert_node!(g, DataTask(0))
        B_sum_d = insert_node!(g, DataTask(0))
        insert_edge!(g, A_sum_t, A_sum_d)
        insert_edge!(g, B_sum_t, B_sum_d)

        M1_d = _dag_build_helper!(g, A_sum_d, B_sum_d, mm_half_size)
    end

    # M2 = (A21 + A22) x B11
    local M2_d::DataTaskNode
    begin
        A_sum_t = insert_node!(g, ComputeTask_Add()) # A21 + A22
        insert_edge!(g, A21_d, A_sum_t, 1)
        insert_edge!(g, A22_d, A_sum_t, 2)
        A_sum_d = insert_node!(g, DataTask(0))
        insert_edge!(g, A_sum_t, A_sum_d)

        M2_d = _dag_build_helper!(g, A_sum_d, B11_d, mm_half_size)
    end

    # M3 = A11 x (B12 - B22)
    local M3_d::DataTaskNode
    begin
        B_dif_t = insert_node!(g, ComputeTask_Sub()) # B12 - B22
        insert_edge!(g, B12_d, B_dif_t, 1)
        insert_edge!(g, B22_d, B_dif_t, 2)
        B_dif_d = insert_node!(g, DataTask(0))
        insert_edge!(g, B_dif_t, B_dif_d)

        M3_d = _dag_build_helper!(g, A11_d, B_dif_d, mm_half_size)
    end

    # M4 = A22 x (B21 - B11)
    local M4_d::DataTaskNode
    begin
        B_dif_t = insert_node!(g, ComputeTask_Sub()) # B21 - B11
        insert_edge!(g, B21_d, B_dif_t, 1)
        insert_edge!(g, B11_d, B_dif_t, 2)
        B_dif_d = insert_node!(g, DataTask(0))
        insert_edge!(g, B_dif_t, B_dif_d)

        M4_d = _dag_build_helper!(g, A22_d, B_dif_d, mm_half_size)
    end

    # M5 = (A11 + A12) x B22
    local M5_d::DataTaskNode
    begin
        A_sum_t = insert_node!(g, ComputeTask_Add()) # A11 + A12
        insert_edge!(g, A11_d, A_sum_t, 1)
        insert_edge!(g, A12_d, A_sum_t, 2)
        A_sum_d = insert_node!(g, DataTask(0))
        insert_edge!(g, A_sum_t, A_sum_d)

        M5_d = _dag_build_helper!(g, A_sum_d, B22_d, mm_half_size)
    end

    # M6 = (A21 - A11) x (B11 + B12)
    local M6_d::DataTaskNode
    begin
        A_dif_t = insert_node!(g, ComputeTask_Sub()) # A21 - A11
        B_sum_t = insert_node!(g, ComputeTask_Add()) # B11 + B12
        insert_edge!(g, A21_d, A_dif_t, 1)
        insert_edge!(g, A11_d, A_dif_t, 2)
        insert_edge!(g, B11_d, B_sum_t, 1)
        insert_edge!(g, B12_d, B_sum_t, 2)
        A_dif_d = insert_node!(g, DataTask(0))
        B_sum_d = insert_node!(g, DataTask(0))
        insert_edge!(g, A_dif_t, A_dif_d)
        insert_edge!(g, B_sum_t, B_sum_d)

        M6_d = _dag_build_helper!(g, A_dif_d, B_sum_d, mm_half_size)
    end

    # M7 = (A12 - A22) x (B21 + B22)
    local M7_d::DataTaskNode
    begin
        A_dif_t = insert_node!(g, ComputeTask_Sub()) # A12 - A22
        B_sum_t = insert_node!(g, ComputeTask_Add()) # B21 + B22
        insert_edge!(g, A12_d, A_dif_t, 1)
        insert_edge!(g, A22_d, A_dif_t, 2)
        insert_edge!(g, B21_d, B_sum_t, 1)
        insert_edge!(g, B22_d, B_sum_t, 2)
        A_dif_d = insert_node!(g, DataTask(0))
        B_sum_d = insert_node!(g, DataTask(0))
        insert_edge!(g, A_dif_t, A_dif_d)
        insert_edge!(g, B_sum_t, B_sum_d)

        M7_d = _dag_build_helper!(g, A_dif_d, B_sum_d, mm_half_size)
    end

    # C11 = M1 + M4 - M5 + M7
    local C11_d::DataTaskNode
    begin
        s1_t = insert_node!(g, ComputeTask_Add()) # M1 + M4
        s2_t = insert_node!(g, ComputeTask_Sub()) # M7 - M5
        C11_t = insert_node!(g, ComputeTask_Add()) # s1 + s2
        insert_edge!(g, M1_d, s1_t, 1)  # +M1
        insert_edge!(g, M4_d, s1_t, 2)  # +M4
        insert_edge!(g, M7_d, s2_t, 1)  # +M7
        insert_edge!(g, M5_d, s2_t, 2)  # -M5

        s1_d = insert_node!(g, DataTask(0))
        s2_d = insert_node!(g, DataTask(0))
        insert_edge!(g, s1_t, s1_d)
        insert_edge!(g, s2_t, s2_d)

        insert_edge!(g, s1_d, C11_t, 1)
        insert_edge!(g, s2_d, C11_t, 2)

        C11_d = insert_node!(g, DataTask(0))
        insert_edge!(g, C11_t, C11_d)
    end

    # C12 = M3 + M5
    local C12_d::DataTaskNode
    begin
        C12_t = insert_node!(g, ComputeTask_Add())
        C12_d = insert_node!(g, DataTask(0))
        insert_edge!(g, M3_d, C12_t, 1)
        insert_edge!(g, M5_d, C12_t, 2)
        insert_edge!(g, C12_t, C12_d)
    end

    # C21 = M2 + M4
    local C21_d::DataTaskNode
    begin
        C21_t = insert_node!(g, ComputeTask_Add())
        C21_d = insert_node!(g, DataTask(0))
        insert_edge!(g, M2_d, C21_t, 1)
        insert_edge!(g, M4_d, C21_t, 2)
        insert_edge!(g, C21_t, C21_d)
    end

    # C22 = M1 - M2 + M3 + M6
    local C22_d::DataTaskNode
    begin
        s1_t = insert_node!(g, ComputeTask_Sub()) # M1 - M2
        s2_t = insert_node!(g, ComputeTask_Add()) # M3 + M6
        C22_t = insert_node!(g, ComputeTask_Add()) # s1 + s2
        insert_edge!(g, M1_d, s1_t, 1)  # +M1
        insert_edge!(g, M2_d, s1_t, 2)  # -M2
        insert_edge!(g, M3_d, s2_t, 1)  # +M3
        insert_edge!(g, M6_d, s2_t, 2)  # +M6

        s1_d = insert_node!(g, DataTask(0))
        s2_d = insert_node!(g, DataTask(0))
        insert_edge!(g, s1_t, s1_d)
        insert_edge!(g, s2_t, s2_d)

        insert_edge!(g, s1_d, C22_t, 1)
        insert_edge!(g, s2_d, C22_t, 2)

        C22_d = insert_node!(g, DataTask(0))
        insert_edge!(g, C22_t, C22_d)
    end

    # Assemble new Matrix C

    assemble_t = insert_node!(g, ComputeTask_MultStrassen())
    insert_edge!(g, C11_d, assemble_t, 1)
    insert_edge!(g, C12_d, assemble_t, 2)
    insert_edge!(g, C21_d, assemble_t, 3)
    insert_edge!(g, C22_d, assemble_t, 4)

    C_d = insert_node!(g, DataTask(0))
    insert_edge!(g, assemble_t, C_d)

    return C_d
end

function ComputableDAGs.graph(mm::MatrixMultiplication)
    g = DAG()

    A_d = insert_node!(g, DataTask(0), "A")
    B_d = insert_node!(g, DataTask(0), "B")

    C_d = _dag_build_helper!(g, A_d, B_d, mm.size)

    return g
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

export MatrixMultiplication

end