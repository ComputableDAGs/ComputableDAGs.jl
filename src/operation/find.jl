# functions that find operations on the inital graph

using Base.Threads

"""
    insert_operation!(nf::NodeReduction)

Insert the given node reduction into its input nodes' operation caches. This is thread-safe.
"""
function insert_operation!(nr::NodeReduction)
    for n in nr.input
        n.nodeReduction = nr
    end
    return nothing
end

"""
    insert_operation!(nf::NodeSplit)

Insert the given node split into its input node's operation cache. This is thread-safe.
"""
function insert_operation!(ns::NodeSplit)
    ns.input.nodeSplit = ns
    return nothing
end

"""
    nr_insertion!(operations::PossibleOperations, nodeReductions::Vector{Vector{NodeReduction}})

Insert the node reductions into the graph and the nodes' caches. Employs multithreading for speedup.
"""
function nr_insertion!(
    operations::PossibleOperations,
    nodeReductions::Vector{Vector{NodeReduction}},
)
    total_len = 0
    for vec in nodeReductions
        total_len += length(vec)
    end
    sizehint!(operations.nodeReductions, total_len)

    t = @task for vec in nodeReductions
        union!(operations.nodeReductions, Set(vec))
    end
    schedule(t)

    @threads for vec in nodeReductions
        for op in vec
            insert_operation!(op)
        end
    end

    wait(t)

    return nothing
end

"""
    ns_insertion!(operations::PossibleOperations, nodeSplits::Vector{Vector{NodeSplits}})

Insert the node splits into the graph and the nodes' caches. Employs multithreading for speedup.
"""
function ns_insertion!(
    operations::PossibleOperations,
    nodeSplits::Vector{Vector{NodeSplit}},
)
    total_len = 0
    for vec in nodeSplits
        total_len += length(vec)
    end
    sizehint!(operations.nodeSplits, total_len)

    t = @task for vec in nodeSplits
        union!(operations.nodeSplits, Set(vec))
    end
    schedule(t)

    @threads for vec in nodeSplits
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
    generatedReductions = [Vector{NodeReduction}() for _ = 1:nthreads()]
    generatedSplits = [Vector{NodeSplit}() for _ = 1:nthreads()]

    # make sure the graph is fully generated through
    apply_all!(graph)

    nodeArray = collect(graph.nodes)

    # sort all nodes
    @threads for node in nodeArray
        sort_node!(node)
    end

    checkedNodes = Set{Node}()
    checkedNodesLock = SpinLock()
    # --- find possible node reductions ---
    @threads for node in nodeArray
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

        nodeReductions = collect(trie)

        for nrVec in nodeReductions
            # parent sets are ordered and any node can only be part of one nodeReduction, so a NodeReduction is uniquely identifiable by its first element
            # this prevents duplicate nodeReductions being generated
            lock(checkedNodesLock)
            if (nrVec[1] in checkedNodes)
                unlock(checkedNodesLock)
                continue
            else
                push!(checkedNodes, nrVec[1])
            end
            unlock(checkedNodesLock)

            push!(generatedReductions[threadid()], NodeReduction(nrVec))
        end
    end


    # launch thread for node reduction insertion
    # remove duplicates
    nr_task = @spawn nr_insertion!(graph.possibleOperations, generatedReductions)

    # find possible node splits
    @threads for node in nodeArray
        if (can_split(node))
            push!(generatedSplits[threadid()], NodeSplit(node))
        end
    end

    # launch thread for node split insertion
    ns_task = @spawn ns_insertion!(graph.possibleOperations, generatedSplits)

    empty!(graph.dirtyNodes)

    wait(nr_task)
    wait(ns_task)

    return nothing
end
