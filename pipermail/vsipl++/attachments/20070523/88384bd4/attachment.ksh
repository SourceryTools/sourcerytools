2007-05-23  Don McCoy  <don@codesourcery.com>

	* configure.ac: Search for the compilers that come with the Cell SDK
	  over the default system ones (gcc and g++).
	* benchmarks/cell/bw.cpp: Remove debug code.
	* benchmarks/makefile.standalone.in: Allow configuration
	  parameters to set build variables to default values.
	* benchmarks/hpec_kernel/GNUmakefile.inc.in: Conditionalize
	  building of SVD benchmark on whether or not LAPACK is available.
