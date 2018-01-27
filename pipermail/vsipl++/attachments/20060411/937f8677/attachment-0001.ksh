2006-04-11  Assem Salama <assem@codesourcery.com>
	* src/vsip/solver.hpp: Added an include for the new sal solver. This
	  include only gets include if VSIP_IMPL_USE_SAL_SOL is defined.
	* src/vsip/impl/sal.hpp: Added overloaded functions sal_mat_lud_dec and
	  sal_mat_lud_sol to decompose and solve using SAL library.
	* src/vsip/impl/sal/solver_lu.hpp: New file. This file implements a new
	  Lud_impl class in the sal namespace. This new class uses the SAL
	  library.

