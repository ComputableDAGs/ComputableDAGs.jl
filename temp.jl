
el_in_p = (identity)(el_in)
el_in_bs = (ComputableDAGs.compute)(
    ComputeTaskQED_U(), el_in_p
)
el_in_bs_p = (identity)(el_in_bs)
el_out_p = (identity)(el_out)
el_out_bs = (ComputableDAGs.compute)(
    ComputeTaskQED_U(), el_out_p
)
el_out_bs_p = (identity)(el_out_bs)
ph_in_p = (identity)(ph_in)
ph_in_bs = (ComputableDAGs.compute)(
    ComputeTaskQED_U(), ph_in_p
)
ph_in_bs_p = (identity)(ph_in_bs)
ph_in_el_out = (ComputableDAGs.compute)(
    ComputeTaskQED_V(), ph_in_bs_p, el_out_bs_p
)
ph_in_el_out_p = (identity)(ph_in_el_out)
ph_in_el_in = (ComputableDAGs.compute)(
    ComputeTaskQED_V(), ph_in_bs_p, el_in_bs_p
)
ph_in_el_in_p = (identity)(ph_in_el_in)
ph_out_p = (identity)(ph_out)
ph_out_bs = (ComputableDAGs.compute)(
    ComputeTaskQED_U(), ph_out_p
)
ph_out_bs_p = (identity)(ph_out_bs)
ph_out_el_in = (ComputableDAGs.compute)(
    ComputeTaskQED_V(), ph_out_bs_p, el_in_bs_p
)
ph_out_el_in_p = (identity)(ph_out_el_in)
diagram_1 = (ComputableDAGs.compute)(
    ComputeTaskQED_S2(),
    ph_out_el_in_p,
    ph_in_el_out_p,
)
diagram_1_p = (identity)(diagram_1)
ph_out_el_out = (ComputableDAGs.compute)(
    ComputeTaskQED_V(), ph_out_bs_p, el_out_bs_p
)
ph_out_el_out_p = (identity)(ph_out_el_out)
diagram_2 = (ComputableDAGs.compute)(
    ComputeTaskQED_S2(),
    ph_in_el_in_p,
    ph_out_el_out_p,
)
diagram_2_p = (identity)(diagram_2)
diagrams_sum = (ComputableDAGs.compute)(
    ComputeTaskQED_Sum(2),
    diagram_2_p,
    diagram_1_p,
)
diagrams_sum_p = (identity)(diagrams_sum)