using KernelAbstractions

"""
    _is_test_platform_active(env_vars::AbstractVector{String}, default::Bool)::Bool

# Args
- `env_vars::AbstractVector{String}`: List of the names of environment variables. The value of the
    first defined variable in the list is parsed and returned.
- `default::Bool`: If none of the variables named in `env_vars` are defined, this value is returned.

# Return

Return if platform is active or not.
"""
function _is_test_platform_active(env_vars::AbstractVector{String}, default::Bool)::Bool
    for env_var in env_vars
        if haskey(ENV, env_var)
            return tryparse(Bool, ENV[env_var])
        end
    end
    return default
end

"""
    get_test_setup(backend::KernelAbstractions.Backend)

Interface function: return test setup for given backend.

"""
function get_test_setup end

struct TestSetup{VB <: Tuple, VT <: Tuple, T <: Tuple}
    backend::VB
    vector_types::VT
    element_types::T
end

function TestSetup(backend::Backend, vector_types::Tuple, element_types::Tuple)
    return TestSetup((backend,), vector_types, element_types)
end

function combinations(stp::TestSetup)
    return Iterators.product(stp.backend, stp.vector_types, stp.element_types)
end
