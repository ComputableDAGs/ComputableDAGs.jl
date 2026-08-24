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
    create_device_manager(
        cluster::Cluster{ZMQDeviceManager},
        this::UUID,
    )

Create a [`ZMQDeviceManager`](@ref) from the given cluster for the given
device ID.

See also: [`close_device_manager`](@ref)
"""
function create_device_manager(
        cluster::Cluster{ZMQDeviceManager},
        this::UUID,
    )
    ctx = ZMQ.context()

    devices_on_machine = local_devices(cluster, this)
    devices_off_machine = network_devices(cluster, this)

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

        ipc_sockets[dev.id] = Socket(ctx, PAIR)

        # smaller id creates the socket, bigger id connects
        if this < dev.id
            bind(ipc_sockets[dev.id], "ipc://" * _socket_path_from_ids(this, dev.id))
        else
            # TODO: make this a non-busy wait somehow
            while !issocket(_socket_path_from_ids(dev.id, this))
                # TODO: fix
                # this sucks badly but yield is not enough when julia isn't executed with some number of threads
                # I assume it's because it yields between thread 0 and 1 and never gets to threads 2+
                sleep(0.001)
                yield()
            end
            connect(ipc_sockets[dev.id], "ipc://" * _socket_path_from_ids(dev.id, this))
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
    close_device_manager(manager::ZMQDeviceManager, this::UUID)

Closes the own sockets of the given manager and deletes the temporary socket files.

See also: [`create_device_manager`](@ref)
"""
function close_device_manager(manager::ZMQDeviceManager, this::UUID)
    @debug "closing ZMQ Device Manager with ID $this"

    # RAII would be cool :(
    for (dev_id, s) in manager.ipc_sockets
        close(s)
        # only remove the ones this device created
        if (this < dev_id)
            try
                sock_path = _socket_path_from_ids(this, dev_id)
                rm(sock_path)
            catch
                @warn "failed to remove socket file"
            end
        end
    end
    for (_, s) in manager.tcp_sockets
        close(s)
    end

    return nothing
end
