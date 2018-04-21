2006-09-09  Don McCoy  <don@codesourcery.com>

	Moved two headers from tests/ to src/vsip_csl/:
	* GNUmakefile.in: Added missing VSIP_IMPL_MPI_H definition.
	* tests/extdata-subviews.cpp: Adjusted path.
	* tests/reductions-idx.cpp: Adjusted path.
	* tests/fns_scalar.cpp: Adjusted path.
	* tests/scalar-view.cpp: Adjusted path.
	* tests/regressions/proxy_lvalue_conv.cpp: Adjusted path.
	* tests/view_lvalue.cpp: Adjusted path.
	* tests/solver-qr.cpp: Adjusted path.
	* tests/coverage_ternary.cpp: Adjusted path.
	* tests/reductions-bool.cpp: Adjusted path.
	* tests/extdata-matadd.cpp: Adjusted path.
	* tests/test-storage.hpp: Moved to src/vsip_csl/.
	* tests/view.cpp: Adjusted path.
	* tests/plainblock.hpp: Moved to src/vsip_csl/.
	* tests/extdata.cpp: Adjusted path.
	* tests/coverage_binary.cpp: Adjusted path.
	* tests/extdata-fft.cpp: Adjusted path.
	* tests/coverage_unary.cpp: Adjusted path.
	* tests/extdata-runtime.cpp: Adjusted path.
	* tests/reductions.cpp: Adjusted path.
	* tests/coverage_comparison.cpp: Adjusted path.
	* configure.ac: Fixed missing substitution needed for compiling
	  benchmarks dependent on MPI.
	* benchmarks/mcopy_ipp.cpp: Adjusted path.
	* benchmarks/prod.cpp: Adjusted path.
	* benchmarks/conv_ipp.cpp: Added missing headers.
	* benchmarks/vma.cpp: Adjusted path.
	* benchmarks/vmul_ipp.cpp: Added missing headers.
	* benchmarks/make.standalone: Exclude *_mpi.cpp from default build.
	* benchmarks/mcopy.cpp: Adjusted path.
	* benchmarks/fft_ipp.cpp: Added missing headers.
