2007-05-24  Don McCoy  <don@codesourcery.com>

	* benchmarks/cell/bw.cpp: Remove debug code.
	* benchmarks/makefile.standalone.in: Allow configuration
	  parameters to set build variables to default values.
	* benchmarks/hpec_kernel/GNUmakefile.inc.in: Conditionalize
	  building of SVD benchmark on whether or not LAPACK is available.
