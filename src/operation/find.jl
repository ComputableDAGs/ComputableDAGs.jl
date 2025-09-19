# functions that find operations on the initial graph

using Base.Threads

"""
    insert_operation!(nf::NodeReduction)

Insert the given node reduction into its input nodes' operation caches. This is thread-safe.
"""
function insert_operation!(nr::NodeReduction)
    for n in nr.input
        n.node_reduction = nr
    end
    return nothing
end

"""
    insert_operation!(nf::NodeSplit)

Insert the given node split into its input node's operation cache. This is thread-safe.
"""
function insert_operation!(ns::NodeSplit)
    ns.input.node_split = ns
    return nothing
end

"""
    nr_insertion!(operations::PossibleOperations, node_reductions::Vector{Vector{NodeReduction}})

Insert the node reductions into the graph and the nodes' caches. Employs multithreading for speedup.
"""
function nr_insertion!(
        operations::PossibleOperations, node_reductions::Vector{Vector{NodeReduction}}
    )
    total_len = 0
    for vec in node_reductions
        total_len += length(vec)
    end
    sizehint!(operations.node_reductions, total_len)

    t = @task for vec in node_reductions
        union!(operations.node_reductions, Set(vec))
    end
    schedule(t)

    @threads for vec in node_reductions
        for op in vec
            insert_operation!(op)
        end
    end

    wait(t)

    return nothing
end

"""
    ns_insertion!(operations::PossibleOperations, node_splits::Vector{Vector{NodeSplits}})

Insert the node splits into the graph and the nodes' caches. Employs multithreading for speedup.
"""
function ns_insertion!(
        operations::PossibleOperations, node_splits::Vector{Vector{NodeSplit}}
    )
    total_len = 0
    for vec in node_splits
        total_len += length(vec)
    end
    sizehint!(operations.node_splits, total_len)

    t = @task for vec in node_splits
        union!(operations.node_splits, Set(vec))
    end
    schedule(t)

    @threads for vec in node_splits
        for op in vec
            insert_operation!(op)
        end
    end

    wait(t)

    return nothing
end

"""
    generate_operations(graph::DAG)

Generate all possible operations on the graph. Used initially when the graph is freshly assembled or parsed. Uses multithreading for speedup.

Safely inserts all the found operations into the graph and its nodes.
"""
function generate_operations(graph::DAG)
    tasks_per_thread = 2

    # make sure the graph is fully generated through
    apply_all!(graph)

    nodeArray = collect(graph.nodes)

    # partition the data
    chunk_size = max(1, length(nodeArray) ÷ (tasks_per_thread * nthreads()))
    data_chunks = Iterators.partition(nodeArray, chunk_size)

    # sort all nodes
    @threads for node in nodeArray
        sort_node!(node)
    end

    checkedNodes = Set{Node}()
    checkedNodesLock = SpinLock()

    # --- find possible node reductions ---
    nr_tasks = map(data_chunks) do nodes
        @spawn begin
            foundReductions = Vector{NodeReduction}()
            for node in nodes
                # we're looking for nodes with multiple parents, those parents can then potentially reduce with one another
                if (length(node.parents) <= 1)
                    continue
                end

                candidates = node.parents

                # sort into equivalence classes
                trie = NodeTrie()

                for candidate in candidates
                    # insert into trie
                    insert!(trie, candidate)
                end

                node_reductions = collect(trie)

                for nrVec in node_reductions
                    # parent sets are ordered and any node can only be part of one node_reduction, so a NodeReduction is uniquely identifiable by its first element
                    # this prevents duplicate node_reductions being generated
                    lock(checkedNodesLock)
                    if (nrVec[1] in checkedNodes)
                        unlock(checkedNodesLock)
                        continue
                    else
                        push!(checkedNodes, nrVec[1])
                    end
                    unlock(checkedNodesLock)

                    push!(foundReductions, NodeReduction(nrVec))
                end
            end

            return foundReductions
        end
    end

    generatedReductions = fetch.(nr_tasks)

    # launch thread for node reduction insertion
    # remove duplicates
    nr_task = @spawn nr_insertion!(graph.possible_operations, generatedReductions)

    # find possible node splits
    ns_tasks = map(data_chunks) do nodes
        @spawn begin
            foundSplits = Vector{NodeSplit}()
            for node in nodeArray
                if (can_split(node))
                    push!(foundSplits, NodeSplit(node))
                end
            end
            return foundSplits
        end
    end

    generatedSplits = fetch.(ns_tasks)

    # launch thread for node split insertion
    ns_task = @spawn ns_insertion!(graph.possible_operations, generatedSplits)

    empty!(graph.dirty_nodes)

    wait(nr_task)
    wait(ns_task)

    return nothing
end
