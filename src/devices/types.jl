"""
    AbstractDevice

Base type for devices of different architectures which can run
[`AbstractInstruction`](@ref).
"""
abstract type AbstractDevice end

"""
    AbstractCPU <: AbstractDevice

Base type for CPU devices.
"""
abstract type AbstractCPU <: AbstractDevice end

"""
    AbstractGPU <: AbstractDevice

Base type for GPU devices.
"""
abstract type AbstractGPU <: AbstractDevice end

"""
    CPU <: AbstractCPU
"""
struct CPU <: AbstractCPU
    id::UUID

    nthreads::Int

    entry_dev::Bool

    """
        CPU(nthreads::Int, entry_dev::Bool)

    Construct a CPU device with a random ID and the given properties.
    """
    function CPU(nthreads::Int, entry_dev::Bool)
        return new(UUIDs.uuid1(), nthreads, entry_dev)
    end
    # TODO: numa regions, architecture, etc?
end
