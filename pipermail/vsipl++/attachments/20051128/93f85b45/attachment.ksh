2005-11-27  Don McCoy  <don@codesourcery.com>

	* configure.ac: corrected macro for detecting presence of SAL
	* src/vsip/impl/sal.hpp: added convolution function overloaded
	  for float and complex<float>.
	* src/vsip/impl/signal-conv-sal.hpp: new file.  implements 
	  convolution using Mercury SAL library.
	* src/vsip/impl/signal-conv.hpp: searches for SAL tag when
	  choosing convolution functions.
	* tests/convolution.cpp: added new tests for support of 
	  non-unit stride data.
