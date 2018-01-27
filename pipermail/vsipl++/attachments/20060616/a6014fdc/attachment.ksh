2006-06-16  Don McCoy  <don@codesourcery.com>

	* benchmarks/hpec_kernel/cfar.cpp: Reorganized such that the three
	  different algorithms are now partially specialized base classes.
	  This eliminates some redundant code and helps highlight the 
	  important parts of the benchmark.  Fixed the verification routine 
	  to work in serial as well as parallel.  Changed the array holding 
	  the number of targets found in each range cell to a Vector to
	  avoid a potential memory leak.  Other minor cleanup.
