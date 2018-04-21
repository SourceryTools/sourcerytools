2007-05-09  Don McCoy  <don@codesourcery.com>

	* benchmarks/mpi/alltoall.cpp: Fixed header path, derived from 
	  benchmark base class in order to provide diag() function.
	* benchmarks/mpi/copy.cpp: Derived from benchmark base.
	* benchmarks/ipp/fft.cpp: Derived from benchmark base.  Fixed riob 
	  and wiob_per_point functions to avoid warning about sign.
	* benchmarks/ipp/fft_ext.cpp: Likewise.
	* benchmarks/ipp/vmul.cpp: Derived from benchmark base.
	* benchmarks/ipp/conv.cpp: Derived from benchmark base, fix 
	  header paths.
	* benchmarks/ipp/mcopy.cpp: Likewise.
	* benchmarks/fftw3/fftm.cpp: Fixed riob/wiob warning.
	* benchmarks/lapack/qrd.cpp: Derived from benchmark base.
	* benchmarks/fftm.cpp: Fixed riob/wiob warning.
	* benchmarks/sal/fft.cpp: Fixed missing typename keyword for Scalar_of.
	* benchmarks/hpec_kernel/cfar_c.cpp: Derived from benchmark base.
	* benchmarks/vmmul.cpp: Fixed riob/wiob warning.
	* benchmarks/make.standalone: Renamed to makefile.standalone.in
	  (now installed as */benchmarks/Makefile).
	* benchmarks/GNUmakefile.inc.in: Modified to install the benchmark
	  source code.
