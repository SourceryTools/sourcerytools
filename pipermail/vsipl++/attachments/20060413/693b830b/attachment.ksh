2006-04-13  Assem Salama <assem@codesourcery.com>
	* src/vsip/impl/solver-lu.hpp: Removed Lud_impl from this file and put
	  it in sal/solver_lu.hpp and lapack/solver_lu.hpp. This class has a
	  new tag for implementation. The implementation is chosen using
	  Choose_lud_impl.
	* src/vsip/impl/solver-cholesky.hpp: Removed Chold_impl form this file
	  and put it in sal/solver_cholesky.hpp and lapack/solver_cholesky.hpp.
	  The implementation is chosen using Choose_chold_impl.
	* src/vsip/impl/sal/solver_lu.hpp: New file. This file
	  implements a Lud_impl class using the SAL library. It also
	  has the overloaded functions sal_mat_lud_dec and sal_mat_lud_sol.
	* src/vsip/impl/sal/solver_cholesky.hpp: New file. This file implements
	  a Chold_impl class using the SAL library. It also has the overloaded
	  functions sal_mat_chol_dec and sal_mat_chol_sol.
	* src/vsip/impl/lapack/solver_lu.hpp: New file. This file
	  implements a Lud_impl class using the LAPACK library.
	* src/vsip/impl/lapack/solver_cholesky.hpp: New file. This file
	  implements a Chold_impl class using using the LAPACK library.
	* src/vsip/impl/solver_common.hpp: New file. This file constains common
	  things that the solvers will need. It contains structs for 
	  Is_lud_Impl_avail and Is_chold_impl_avail. It also contains the
	  struct Lapack_tag and enum mat_uplo.

