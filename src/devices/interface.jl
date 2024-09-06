"""
    AbstractDevice

Abstract base type for every device, like GPUs, CPUs or any other compute devices.
Every implementation needs to implement various functions and needs a member `cacheStrategy`.
"""
abstract type AbstractDevice end

abstract type AbstractCPU <: AbstractDevice end

abstract type AbstractGPU <: AbstractDevice end

"""
    Machine

A representation of a machine to execute on. Contains information about its architecture (CPUs, GPUs, maybe more). This representation can be used to make a more accurate cost prediction of a [`DAG`](@ref) state.

See also: [`Scheduler`](@ref)
"""
struct Machine
    devices::Vector{AbstractDevice}

    transferRates::Matrix{Float64}
end

"""
    CacheStrategy

Abstract base type for caching strategies.

See also: [`strategies`](@ref)
"""
abstract type CacheStrategy end

"""
    LocalVariables <: CacheStrategy

A caching strategy relying solely on local variables for every input and output.

Implements the [`CacheStrategy`](@ref) interface.
"""
struct LocalVariables <: CacheStrategy end

"""
    Dictionary <: CacheStrategy

A caching strategy relying on a dictionary of Symbols to store every input and output.

Implements the [`CacheStrategy`](@ref) interface.
"""
struct Dictionary <: CacheStrategy end

"""
    DEVICE_TYPES::Vector{Type}

Global vector of available and implemented device types. Each implementation of a [`AbstractDevice`](@ref) should add its concrete type to this vector.

See also: [`device_types`](@ref), [`get_devices`](@ref)
"""
DEVICE_TYPES = Vector{Type}()

"""
    CACHE_STRATEGIES::Dict{Type{AbstractDevice}, Symbol}

Global dictionary of available caching strategies per device. Each implementation of [`AbstractDevice`](@ref) should add its available strategies to the dictionary.

See also: [`strategies`](@ref)
"""
CACHE_STRATEGIES = Dict{Type,Vector{CacheStrategy}}()

"""
    default_strategy(deviceType::Type{T}) where {T <: AbstractDevice}

Interface function that must be implemented for every subtype of [`AbstractDevice`](@ref). Returns the default [`CacheStrategy`](@ref) to use on the given device type.
See also: [`cache_strategy`](@ref), [`set_cache_strategy`](@ref)
"""
function default_strategy end

"""
    get_devices(t::Type{T}; verbose::Bool) where {T <: AbstractDevice}

Interface function that must be implemented for every subtype of [`AbstractDevice`](@ref). Returns a `Vector{Type}` of the devices for the given [`AbstractDevice`](@ref) Type available on the current machine.
"""
function get_devices end

"""
    measure_device!(device::AbstractDevice; verbose::Bool)

Interface function that must be implemented for every subtype of [`AbstractDevice`](@ref). Measures the compute speed of the given device and writes into it.
"""
function measure_device! end

"""
    gen_cache_init_code(device::AbstractDevice)

Interface function that must be implemented for every subtype of [`AbstractDevice`](@ref) and at least one [`CacheStrategy`](@ref). Returns an `Expr` initializing this device's variable cache.
    
The strategy is a symbol
"""
function gen_cache_init_code end

"""
    gen_access_expr(device::AbstractDevice, symbol::Symbol)

Interface function that must be implemented for every subtype of [`AbstractDevice`](@ref) and at least one [`CacheStrategy`](@ref).
Return an `Expr` or `QuoteNode` accessing the variable identified by [`symbol`].
"""
function gen_access_expr end

"""
    cuda_kernel(graph::DAG, instance, context_module::Module)

Return a function of signature `compute_<id>(input::CuVector, output::CuVector, n::Int64)`, which will return the result of the DAG computation of the input on the given output variable.

!!! note
    This function is only available when the CUDA Extension is loaded by `using CUDA` before `using ComputableDAGs`
"""
function cuda_kernel end
