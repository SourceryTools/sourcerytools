2006-07-20  Assem Salama <assem@codesourcery.com>
	* src/vsip_csl/matlab_file.cpp: New file. Implements some functions of
	  Matlab_file class.
	* src/vsip_csl/matlab_file.hpp: New file. This is the defintion of
	  Matlab_file class. This class implements a higher level interface
	  to Matlab_bin_formatter using iterators.
	* src/vsip_csl/GNUmakefile.inc.in: Added matlab_file.cpp to sources.
	* tests/matlab_iter_test.cpp: New file. This file tests the Matlab
	  file iterator interface
