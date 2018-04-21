2005-10-13  Don McCoy  <don@codesourcery.com>
	
	* configure.ac (--enable-sal, --with-sal-include, --with-sal-lib):
	  New options to add support for SAL.
	* src/vsip/GNUmakefile.inc.in: conditionally added sal.cpp.
	* src/vsip/impl/expr_serial_dispatch.hpp: added mercury SAL tag.
	* src/vsip/impl/expr_serial_evaluator.hpp: likewise.
	* src/vsip/impl/sal.cpp: new file, wrappers for +-*/ incl. for
	  real, complex and complex-split types.
	* src/vsip/impl/sal.hpp: likewise.
	* tests/elementwise.cpp: new tests for external libraries providing
	  elementwise funtions.
	* tests/sal-assumptions.cpp: verifies assumptions regarding complex
	  split layout when using SAL library.
