include("bfam2d.jl")

using bfam2d
bfam = bfam2d
using MPI

function test_refine(which_tree, level, x, y, user_data)
  refine = 0
  if rand() < 0.5 && level < 4
    refine = 1
  end
  return Cint(refine)
end

MPI.Init()

bfam.init()

conn = bfam.connectivity_brick(2, 3, false, true)

comm = MPI.COMM_WORLD
mesh_min_elements = 0
mesh_min_level = 0
domain = bfam.domain_pxest_new_ext_f(comm, conn, mesh_min_elements,
                                              mesh_min_level, 1)
                                              println(domain.pxest_ptr)

bfam.domain_pxest_refine(domain, 1, test_refine, C_NULL)
bfam.domain_balance(domain)
bfam.domain_pxest_write(domain, "pxest2d")

MPI.Finalized()
