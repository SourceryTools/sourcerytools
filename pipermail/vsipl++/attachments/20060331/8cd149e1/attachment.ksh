2006-03-31  Don McCoy  <don@codesourcery.com>

	* benchmarks/fastconv.cpp: Updated to use benchmarks.hpp.  Separated
	  out parallel-dependent code to allow it to compile against the
	  reference implementation.
	* benchmarks/loop.hpp: Moved references to parallel-related namespaces
	  into the code blocks separated by the PARALLEL_LOOP define.
