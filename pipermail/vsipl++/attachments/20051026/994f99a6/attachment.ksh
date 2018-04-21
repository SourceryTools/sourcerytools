2005-10-26  Don McCoy  <don@codesourcery.com>

	* src/vsip/impl/eval-sal.hpp: new file.  overloaded translation
	  functions for matrix/vector products in SAL.  dispatch routines
	  for same.
	* src/vsip/impl/general_dispatch.hpp: new OpTags for matrix-vector
	  and vector-matrix products.  added ImplTag for Mercury SAL.
	* src/vsip/impl/matvec-prod.hpp: added generic evaluators for m-v 
	  and v-m products.  changed product functions to go through dispatch.
	* src/vsip/impl/matvec.hpp: include eval-sal.hpp.


	  
