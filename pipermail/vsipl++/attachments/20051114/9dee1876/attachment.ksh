2005-11-14  Don McCoy  <don@codesourcery.com>

	* tests/matvec-prod.cpp: added tests for special cases such
	  as split complex layout and subviews (different strides).
	* src/vsip/impl/eval-sal.hpp: new file.  dispatch routines
	  for matrix/vector products, outer and gemp.
	* src/vsip/impl/matvec-prod.hpp: include eval-sal.hpp.
	* src/vsip/impl/matvec.hpp: include eval-sal.hpp and math-enum.hpp.
	* src/vsip/impl/sal.hpp: added new overloaded translation 
	  functions for matrix/vector products, outer and gemp.


	  
