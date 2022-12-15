using Test

# Assume that everything has been configured correctly via environment
# variables in CI and `configure_packages.jl`.
# From here on, all packages should be configured as desired and we can load
# everything and perform the tests.
using MPI: MPI
using P4est

import MPIPreferences
@info "Testing P4est.jl with" MPIPreferences.binary MPIPreferences.abi


# This belongs to the testset "p4est_qcoord_to_vertex" below. However,
# it looks like we need to define the functions outside of `@testset`
# to make `@cfunction` work.
function iter_volume_for_p4est_qcoord_to_vertex(info::Ptr{p4est_iter_volume_info_t}, user_data)
  info = unsafe_load(info)
  p4est = unsafe_load(info.p4est)
  quad = unsafe_load(info.quad)

  vxyz = Array{Float64}(undef, 3)
  p4est_qcoord_to_vertex(p4est.connectivity, info.treeid, quad.x, quad.y, vxyz)

  println(vxyz)
  return nothing
end


@testset "P4est.jl tests" begin
  @test_nowarn MPI.Init()

  @testset "uses_mpi" begin
    @test P4est.uses_mpi() == true
  end

  @testset "p4est_connectivity_new_periodic" begin
    connectivity = @test_nowarn p4est_connectivity_new_periodic()
    @test p4est_connectivity_new_periodic() isa Ptr{p4est_connectivity}
    @test_nowarn p4est_connectivity_destroy(connectivity)
  end

  @testset "p4est_connectivity_is_valid" begin
    connectivity = @test_nowarn p4est_connectivity_new_periodic()
    @test p4est_connectivity_is_valid(connectivity) == 1
    @test_nowarn p4est_connectivity_destroy(connectivity)
  end

  @testset "unsafe_load" begin
    connectivity = @test_nowarn p4est_connectivity_new_periodic()
    connectivity_obj = unsafe_load(connectivity)
    @test connectivity_obj.num_vertices == 4
    @test_nowarn p4est_connectivity_destroy(connectivity)
  end

  @testset "p4est_qcoord_to_vertex" begin
    iter_volume_c = @cfunction(iter_volume_for_p4est_qcoord_to_vertex, Cvoid, (Ptr{p4est_iter_volume_info_t}, Ptr{Cvoid}))
    connectivity = @test_nowarn p4est_connectivity_new_brick(2, 2, 0, 0)
    p4est = @test_nowarn p4est_new_ext(MPI.COMM_WORLD, connectivity, 0, 0, true, 0, C_NULL, C_NULL)
    p4est_iterate(p4est, C_NULL, C_NULL, iter_volume_c, C_NULL, C_NULL)
    @test_nowarn p4est_destroy(p4est)
    @test_nowarn p4est_connectivity_destroy(connectivity)
  end
end
