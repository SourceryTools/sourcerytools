2008-06-01  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/sal/bridge_util.hpp: Added missing header file.
	* src/vsip/opt/sal/eval_misc.hpp: Corrected spelling error.
	  (VSIP_IMPL_SAL_USE_MAT_MUL): Added guard against multiple definitions.
	  Corrected bug in outer product evaluator where it was checking the
	  dimension order of the wrong block.
