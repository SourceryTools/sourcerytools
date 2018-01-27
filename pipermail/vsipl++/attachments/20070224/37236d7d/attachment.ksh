2007-02-24  Don McCoy  <don@codesourcery.com>

	* benchmarks/fastconv.cpp: Created Cell option (-20), range cells fixed.
	  Changed to derive from Benchmark_base.
	* examples/fconv.cpp: Added macros to guard against unconditional 
	  inclusion of Cell-specific code.
