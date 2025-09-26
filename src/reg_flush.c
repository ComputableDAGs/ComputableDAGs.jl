#include <stdio.h>

// this function does nothing, but it is external and volatile, forcing the
// callsite to flush all its registers before calling it
void jl_flushpoint(void) { asm volatile("" ::: "memory"); }
