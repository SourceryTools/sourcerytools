2006-07-21  Don McCoy  <don@codesourcery.com>

	* src/vsip/impl/ops_info.hpp: Moved from benchmarks/ directory.
	* benchmarks/*.cpp: Adjusted for above, accounting for the
	  new location and that it is now in the impl namespace.
	* benchmarks/hpec_kernel/*.cpp: Likewise.
	* benchmarks/benchmarks.hpp: Likewise.  Also added a definition
	  of Ops_info for building against non-Sourcery libraries.
	* benchmarks/prod_var.cpp: Fixed ref_matvec include to point
	  to new location in vsip_csl/.  Dis-ambiguated a call to
	  prod() and dot() by adding the vsip:: qualifier.
	* benchmarks/fft_ext_ipp.cpp: Likewise for test.hpp
	* benchmarks/maxval.cpp: Likewise.
	* benchmarks/hpec_kernel/GNUmakefile.inc.in: Fixed to include
	  vsip library using -L and -l.
