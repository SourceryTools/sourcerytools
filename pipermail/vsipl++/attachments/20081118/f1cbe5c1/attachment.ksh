2008-11-17  Don McCoy  <don@codesourcery.com>

	* src/vsip/core/cvsip/matvec.hpp: Converted evalutators to use the new
	  dispatch.
	* src/vsip/core/dispatch.hpp: New file.  Provide prototypes for Signature
	  and Evaluator needed for producing reference build.
	* src/vsip/core/matvec_prod.hpp: Converted to new dispatch.
	* src/vsip/core/matvec.hpp: Likewise.
	* src/vsip/core/impl_tags.hpp: Moved operator tags from 
	  general_evaluator.hpp to here.
	* src/vsip/opt/sal/eval_misc.hpp: Converted to new dispatch.
	* src/vsip/opt/dispatch.hpp: Removed redundant definitions now found
	  in core/dispatch.hpp.
	* src/vsip/opt/cbe/cml/matvec.hpp: Converted to new dispatch.
	* src/vsip/opt/lapack/matvec.hpp: Likewise.
	* tests/matvec.cpp: Modified routine to check gemp results to use
	  error_db() instead of a loop using equal().
