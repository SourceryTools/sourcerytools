2006-03-20  Don McCoy  <don@codesourcery.com>

	* benchmarks/benchmarks.hpp: Updated to reflect new location of 
	  test.hpp (see below).  
	* benchmarks/firbank.cpp: New file. Implements FIR Filter Bank
	  benchmark, one of the MIT/LL PCA Kernel Benchmarks.  Demonstrates
	  two algorithms, time-domain convolution and "fast" convolution
	  based on Fourier transforms.  Optionally supports using external
	  data files where the computed result is compared to the given
	  output file.
	* src/vsip_csl/test.hpp: Moved from tests/ directory and into the 
	  'vsip_csl' namespace.
	* src/vsip_csl/output.hpp: Likewise.
	* src/vsip_csl/load_view.hpp: Likewise.  Changed Load_view to
	  accept only constant filenames.
