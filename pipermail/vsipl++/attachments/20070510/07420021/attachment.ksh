2007-05-10  Don McCoy  <don@codesourcery.com>

	* benchmarks/hpec_kernel/cfar.cpp: Derive from Benchmark_base, 
	  add compiler directive to exclude hybrid case for non-SSE
	  platforms.
	* benchmarks/hpec_kernel/firbank.cpp: Derive from Benchmark_base,
	  add new test case for expression involving FFTMs.
	* benchmarks/hpec_kernel/svd.cpp: Derive from Benchmark_base.
	* benchmarks/hpec_kernel/cfar_c.cpp: Likewise.  Added compiler
	  directive to exclude SIMD code for non-SSE platforms.
