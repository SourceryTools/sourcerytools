2008-11-17  Don McCoy  <don@codesourcery.com>

	* src/vsip/core/cvsip/matvec.hpp: Converted evalutators to use the new
	  dispatch.
	* src/vsip/core/dispatch.hpp: New file.  Provide prototypes for Signature
	  and Evaluator needed for producing reference build.
	* src/vsip/core/matvec_prod.hpp: Converted to new dispatch.
	* src/vsip/core/matvec.hpp: Likewise.
	* src/vsip/opt/sal/eval_misc.hpp: Likewise.
	* src/vsip/opt/cbe/cml/matvec.hpp: Likewise.
