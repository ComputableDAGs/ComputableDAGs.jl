
"""
    GreedyScheduler

A greedy implementation of a scheduler, creating a topological ordering of nodes and naively balancing them onto the different devices.
"""
struct GreedyScheduler <: AbstractScheduler end

function schedule_dag(::GreedyScheduler, graph::DAG, machine::Machine)
    node_dict = Dict{Node,Int}()   # dictionary of nodes with the number of not-yet-scheduled children
    node_stack = Stack{Node}()      # stack of currently schedulable nodes, i.e., nodes with all of their children already scheduled
    # the stack makes sure that closely related nodes will be scheduled one after another

    # use a priority equal to the number of unseen children -> 0 are nodes that can be added
    for node in get_entry_nodes(graph)
        push!(node_stack, node)
    end

    schedule = Node[]
    sizehint!(schedule, length(graph.nodes))

    # keep an accumulated cost of things scheduled to this device so far
    device_acc_cost = PriorityQueue{AbstractDevice,Float64}()
    for device in machine.devices
        enqueue!(device_acc_cost, device => 0)
    end

    local node
    while !isempty(node_stack)
        node = pop!(node_stack)

        # assign the device with lowest accumulated cost to the node (if it's a compute node)
        if (isa(node, ComputeTaskNode))
            lowest_device = peek(device_acc_cost)[1]
            node.device = lowest_device
            device_acc_cost[lowest_device] = compute_effort(task(node))
        end

        push!(schedule, node)

        # find all parent's priority, reduce by one if in the node_dict
        # if it reaches zero, push onto node_stack
        for parent in parents(node)
            parents_prio = get(node_dict, parent, length(children(parent))) - 1
            if parents_prio == 0
                delete!(node_dict, parent)
                push!(node_stack, parent)
            else
                node_dict[parent] = parents_prio
            end
        end
    end

    @assert isempty(node_dict) "found unschedulable nodes, this most likely means the graph has a cycle"

    return schedule
end
