2006-07-15  Assem Salama <assem@codesourcery.com>
	
	* tests/matlab_bin_file_test.cpp: New file. This file tests the low
	  level Matlab_bin_formatter interface.
	* src/vsip/tensor.hpp: Added the extent method to operator on a tensor
	  view.
	* src/vsip/impl/layout.hpp: Added get_real_ptr and get_imag_ptr.
	* src/vsip_csl/matlab_bin_formatter.hpp: Fixed compile error.
