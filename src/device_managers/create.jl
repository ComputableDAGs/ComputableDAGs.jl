function _socket_path_from_ids(id1::UUID, id2::UUID)
    return "/tmp/cdags_" * string(id1) * "_" * string(id2) * ".socket"
end

function _bind_tcp_on_free_port(socket::Socket)
    port = MANAGEMENT_PORT + 1
    cont = true
    while cont
        try
            bind(socket, "tcp://0.0.0.0:" * string(port))
            cont = false
        catch e
            if e isa StateError
                port += 1
            else
                rethrow(e)
            end
        end
    end

    return port
end

"""
    create_zmq_manager(
        this::UUID,
        devices_on_machine::AbstractVector{UUID},
        devices_off_machine::AbstractVector{UUID}
    )

Create a [`ZMQDeviceManager`](@ref) from the given device IDs.

See also: [`close_zmq_manager`](@ref)
"""
function create_zmq_manager(this::UUID, devices_on_machine::AbstractVector{UUID}, devices_off_machine::AbstractVector{UUID})
    ctx = ZMQ.context()

    # TODO: set up socket on management port with some sort of publish/subscribe protocol for every device to publish
    # its own address/port and collect every other device's address/port
    if !isempty(devices_off_machine)
        @warn "There are off-machine devices which is not currently implemented"
    end

    # Set up own TCP socket per off-machine device
    #=
    for dev in devices_off_machine
        tcp_sockets[dev] = Socket(ctx, PAIR)
        port = _bind_tcp_on_free_port(tcp_sockets[dev])
        @debug "Set up TCP socket on port $port"
    end
    =#

    # Set up own IPC socket per on-machine device
    ipc_sockets = Dict{UUID, Socket}()
    for dev in devices_on_machine
        @debug "connecting/binding $dev on $this"
        if this == dev
            continue
        end

        ipc_sockets[dev] = Socket(ctx, PAIR)

        # smaller id creates the socket, bigger id connects
        if this < dev
            bind(ipc_sockets[dev], "ipc://" * _socket_path_from_ids(this, dev))
        else
            # TODO: make this a non-busy wait somehow
            while !issocket(_socket_path_from_ids(dev, this))
                # TODO: fix
                # this sucks badly but yield is not enough when julia isn't executed with some number of threads
                # I assume it's because it yields between thread 0 and 1 and never gets to threads 2+
                sleep(0.001)
                yield()
            end
            connect(ipc_sockets[dev], "ipc://" * _socket_path_from_ids(dev, this))
        end
    end

    @debug "Device Manager created"
    # TODO: add off-machine devices here

    return ZMQDeviceManager(
        Dict{UUID, Socket}(),     #tcp_sockets,
        ipc_sockets,
    )
end

"""
    close_zmq_manager(manager::ZMQDeviceManager, this::UUID)

Closes the own sockets of the given manager and deletes the temporary socket files.

See also: [`create_zmq_manager`](@ref)
"""
function close_zmq_manager(manager::ZMQDeviceManager, this::UUID)
    @debug "closing ZMQ Device Manager with ID $this"

    # RAII would be cool :(
    for (dev, s) in manager.ipc_sockets
        close(s)
        # only remove the ones this device created
        if (this < dev)
            try
                sock_path = _socket_path_from_ids(this, dev)
                rm(sock_path)
            catch
                @warn "failed to remove socket file"
            end
        end
    end
    for (dev, s) in manager.tcp_sockets
        close(s)
    end

    return nothing
end
