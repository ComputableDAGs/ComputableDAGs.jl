# functions that find operations on the initial graph

using Base.Threads

"""
    insert_operation!(dag::DAG, nr::NodeReduction)

Insert the given node reduction into the node's operation cache.
"""
function insert_operation!(dag::DAG, nr::NodeReduction)
    for id in nr.inputs
        dag.nodes[id] = node_with_op(dag.nodes[id], nr)
    end
    return nothing
end

"""
    insert_operation!(dag::DAG, ns::NodeSplit)

Insert the given node split into its input node's operation cache.
"""
function insert_operation!(dag::DAG, ns::NodeSplit)
    dag.nodes[ns.input] = node_with_op(dag.nodes[ns.input], ns)
    return nothing
end

"""
    nr_insertion!(dag::DAG, operations::PossibleOperations, node_reductions::Vector{Vector{NodeReduction}})

Insert the node reductions into the graph and the nodes' caches. Employs multithreading for speedup.
"""
function nr_insertion!(
        dag::DAG, node_reductions::Vector{NodeReduction}
    )
    union!(dag.possible_operations.node_reductions, Set(node_reductions))
    insert_operation!.(Ref(dag), node_reductions)

    return nothing
end

"""
    ns_insertion!(operations::PossibleOperations, node_splits::Vector{Vector{NodeSplits}})

Insert the node splits into the graph and the nodes' caches. Employs multithreading for speedup.
"""
function ns_insertion!(
        dag::DAG, node_splits::Vector{NodeSplit}
    )
    union!(dag.possible_operations.node_splits, Set(node_splits))
    insert_operation!.(Ref(dag), node_splits)

    return nothing
end

"""
    generate_operations(dag::DAG)

Generate all possible operations on the graph. Used initially when the graph is freshly assembled or parsed. Uses multithreading for speedup.

Safely inserts all the found operations into the graph and its nodes.
"""
function generate_operations(dag::DAG)
    # make sure the graph is fully generated through
    apply_all!(dag)

    node_array = collect(dag.nodes)

    # sort all nodes
    @threads for (id, node) in node_array
        sort_node!(node)
    end

    # --- find possible node reductions ---

    found_reductions = Vector{NodeReduction}()
    for (id, node) in node_array
        # we're looking for nodes with multiple parents, those parents can then potentially reduce with one another
        if (length(node.parents) <= 1)
            continue
        end

        candidates = getindex.(Ref(dag.nodes), node.parents)

        # sort into equivalence classes
        trie = NodeTrie()

        for candidate in candidates
            # insert into trie
            insert!(trie, candidate)
        end

        node_reductions = collect(trie)

        for nr_vec in node_reductions
            # parent sets are ordered and any node can only be part of one node_reduction, so a NodeReduction is uniquely identifiable by its first element
            # this prevents duplicate node_reductions being generated
            lock(checked_nodes_lock)
            if (nr_vec[1] in checked_nodes)
                unlock(checked_nodes_lock)
                continue
            else
                push!(checked_nodes, nr_vec[1])
            end
            unlock(checked_nodes_lock)

            push!(found_reductions, NodeReduction(nr_vec))
        end
    end

    # launch thread for node reduction insertion
    # remove duplicates
    nr_insertion!(dag, found_reductions)

    found_splits = Vector{NodeSplit}()
    for (id, node) in node_array
        if (can_split(node))
            push!(found_splits, NodeSplit(id))
        end
    end

    # launch thread for node split insertion
    ns_insertion!(dag, found_splits)

    empty!(dag.dirty_nodes)

    return nothing
end
