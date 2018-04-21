2008-08-22  Don McCoy  <don@codesourcery.com>

	* apps/ssar/GNUmakefile: Changed loop count when profiling back to 10.
	* apps/ssar/kernel1.hpp: Added member data to store calculated 
	  operation counts.  Used those in place of hard-coded operation counts
	  in profiling statements.  Rolled the subtraction of the number of 
	  interpolation sidelobes into the matrix of indices for the output 
	  matrix.
