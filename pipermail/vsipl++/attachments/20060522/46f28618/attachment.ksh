2006-05-22  Assem Salama <assem@codesourcery.com>
	* src/vsip_csl/matlab_bin_formatter.hpp: New file. This file allows a
	  user to output a matrix to matlab 'mat' file that can be read in.
	  This file has two structures, Matlab_bin_hdr and Matlab_bin_formatter.
	  The user outputs to a binary file using the << operator.
	* src/vsip_csl/matlab_defines.h: New file. This file contains defines
	  that are needed by the Matlab_bin_formatter.
	* src/vsip_csl/matlab_text_formatter.hpp: New file. This file allows a
	  user to output vector or a matrix to a text Matlab m file. The
	  user does this by using the << operator.
	* src/vsip_csl/output.hpp: Removed usage of Point.
