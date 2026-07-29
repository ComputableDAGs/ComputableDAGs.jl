"""
    AbstractDeviceManager

Base type for device managers. A device manager uses a communication protocol
to send and receive data to and from other device managers. They always reside
on CPUs and buffer received data.
"""
abstract type AbstractDeviceManager end

"""
    ZMQDeviceManager

Device manager using ZeroMQ.
"""
struct ZMQDeviceManager <: AbstractDeviceManager
    tcp_sockets::Dict{UUID, Socket}
    ipc_sockets::Dict{UUID, Socket}
end
