module P4est

using CBinding: @cstruct
using Reexport: @reexport

include("libp4est.jl")

"""
    uses_mpi()

Returns true if the p4est library was compiled with MPI enabled.
"""
uses_mpi() = isdefined(@__MODULE__, :P4EST_ENABLE_MPI)

end
