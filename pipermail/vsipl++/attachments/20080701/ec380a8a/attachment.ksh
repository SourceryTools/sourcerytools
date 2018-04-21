2008-07-01  Don McCoy  <don@codesourcery.com>

	* src/vsip_csl/matlab.hpp: Added another template parameter to allow
	  the addition of two specializations for correctly handling the
	  swapping of complex values.
	* src/vsip_csl/save_view.hpp: Fixed problem in save: view is now 
	  cloned before bytes are swapped to avoid altering source view.
	* tests/vsip_csl/load_view_cplx.cpp: Complex tests from load_view.cpp.
	  Added regression tests for save_view (source view swapped in place)
	  and for complex value swapping issue.
	* tests/vsip_csl/load_save.hpp: Common code from load_view.cpp.
	* tests/vsip_csl/load_view.cpp: Split off into second source file
	  (load_view_cplx.cpp) to speed compilation.  Scalar types are tested
	  in this file.
