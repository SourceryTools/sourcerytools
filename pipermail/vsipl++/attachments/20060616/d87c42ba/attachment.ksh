2006-06-16  Don McCoy  <don@codesourcery.com>

	* benchmarks/GNUmakefile.inc.in: Renamed 'bench' target to 'benchmarks'.  Cleaned
	  up the section that removes tests with missing dependencies.
	* benchmarks/make.standalone: Added functionality from make.standalone from
	  the benchmarks/hpec_kernel/ subdirectory.  Added 'benchmarks' and 'hpec_kernel' 
	  targets for consistency with targets in GNUmakefiles.
	* benchmarks/hpec_kernel/GNUmakefile.inc.in:  Added 'hpec_kernel' target.
	* benchmarks/hpec_kernel/make.standalone: Removed.
	* benchmarks/hpec_kernel/firbank.cpp: Used helper class of Fir objects to 
	  make memory allocation exception-safe.  Added comments.
	* src/vsip_csl/output.hpp: Added operator<< overloads for vsip::impl::Length
	  and vsip::impl::Index.
	* benchmarks/conv.cpp: Repointed to headers in src/vsip_csl/ rather than tests/.
	* benchmarks/copy.cpp: Likewise.
	* benchmarks/corr.cpp: Likewise.
	* benchmarks/dot.cpp: Likewise.
	* benchmarks/fftm.cpp: Likewise.
	* benchmarks/fir.cpp: Likewise.
	* benchmarks/mcopy.cpp: Likewise.
	* benchmarks/mcopy_ipp.cpp: Likewise.
	* benchmarks/mpi_alltoall.cpp: Likewise.
	* benchmarks/prod.cpp: Likewise.
	* benchmarks/prod_var.cpp: Likewise.
	* benchmarks/qrd.cpp: Likewise.  Also provided third template parameter for
	  vsip::impl::Qrd_impl (it used to default to Lapack).
	* benchmarks/sumval.cpp: Likewise.
	* benchmarks/vmmul.cpp: Likewise.
	* benchmarks/vmul_c.cpp: Likewise.
