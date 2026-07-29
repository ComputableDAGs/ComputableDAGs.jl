"""
    send(dm::ZMQDeviceManager, on_machine::Val{true}, destination_dev::UUID, data::Any, data_id::UUID)

Sends the given data to the device manager with the given dest UUID.
"""
function send(dm::ZMQDeviceManager, on_machine::Val{true}, destination_dev::UUID, data::Any, ::UUID)
    dest_socket = dm.ipc_sockets[destination_dev]

    # deserialize ourselves
    iob = IOBuffer()
    serialize(iob, data)
    seekstart(iob)
    content = read(iob)

    @debug "Trying to send $(length(content)) Bytes to $(dest_socket)"
    return ZMQ.send(dest_socket, content)
end

function send(dm::ZMQDeviceManager, on_machine::Val{false}, destination_dev::UUID, data::Any, ::UUID)
    # TODO
    throw(ErrorException("unimplemented"))
end

"""
    get(dm::ZMQDeviceManager, on_machine::Val{true}, origin_dev::UUID, data_id::UUID, ::Type{T})::T where {T}

Get the value with the given ID from the buffer and subsequently delete it
from the buffer. It will be cast into the given type. If the requested value
was not yet received, this function will block until it arrived.

The `on_machine` Val{boolean} switch determines which of the sockets the function
tries to receive from. `true` uses the IPC socket to receive from a device in
the same machine, `false` receives from the TCP socket.
"""
function get(dm::ZMQDeviceManager, on_machine::Val{true}, origin_dev::UUID, data_id::UUID, ::Type{T})::T where {T}
    origin_socket = dm.ipc_sockets[origin_dev]

    @debug "Trying to receive from $(origin_socket)"
    res = ZMQ.recv(origin_socket)

    iob = IOBuffer(res)
    return deserialize(iob)
end

function get(dm::ZMQDeviceManager, on_machine::Val{false}, origin_dev::UUID, data_id::UUID, ::Type{T})::T where {T}
    # TODO
    throw(ErrorException("unimplemented"))
end
