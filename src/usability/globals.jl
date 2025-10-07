"""
    CURRENT_DAG::DAG

The unique current global DAG, when assembling it using the usability macros; this is always an empty DAG outside of the `assemble_dag` macro.
"""
const __CURRENT_DAG__::Ref{DAG} = Ref(DAG())
