
"""
    GreedyScheduler

A greedy implementation of a scheduler, creating a topological ordering of nodes and naively balancing them onto the different devices.
"""
struct GreedyScheduler <: AbstractScheduler end

function schedule_dag(::GreedyScheduler, graph::DAG, machine::Machine)
    nodeQueue = PriorityQueue{Node,Int}()

    # use a priority equal to the number of unseen children -> 0 are nodes that can be added
    for node in get_entry_nodes(graph)
        enqueue!(nodeQueue, node => 0)
    end

    schedule = Vector{FunctionCall}()
    sizehint!(schedule, length(graph.nodes))

    # keep an accumulated cost of things scheduled to this device so far
    deviceAccCost = PriorityQueue{AbstractDevice,Float64}()
    for device in machine.devices
        enqueue!(deviceAccCost, device => 0)
    end

    node = nothing
    while !isempty(nodeQueue)
        @assert peek(nodeQueue)[2] == 0
        node = dequeue!(nodeQueue)

        # assign the device with lowest accumulated cost to the node (if it's a compute node)
        if (isa(node, ComputeTaskNode))
            lowestDevice = peek(deviceAccCost)[1]
            node.device = lowestDevice
            deviceAccCost[lowestDevice] = compute_effort(task(node))
        end

        if (node isa DataTaskNode && length(node.children) == 0)
            push!(schedule, get_init_function_call(node, entry_device(machine)))
        else
            push!(schedule, get_function_call(node)...)
        end

        for parent in parents(node)
            # reduce the priority of all parents by one
            if (!haskey(nodeQueue, parent))
                enqueue!(nodeQueue, parent => length(children(parent)) - 1)
            else
                nodeQueue[parent] = nodeQueue[parent] - 1
            end
        end
    end

    return schedule
end
