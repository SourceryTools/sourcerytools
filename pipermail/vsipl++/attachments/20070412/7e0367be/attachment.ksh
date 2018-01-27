2007-04-12  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/cbe/ppu/eval_fastconv.hpp: Added two new expression 
	  templates for cases utilizing a matrix of coefficients.
	* src/vsip/opt/cbe/ppu/fastconv.hpp: Reorganization to better
	  handle coefficients.
	* tests/fastconv.cpp: New tests for expressions.
	* benchmarks/fastconv.cpp: New tests to evalutate performance.
