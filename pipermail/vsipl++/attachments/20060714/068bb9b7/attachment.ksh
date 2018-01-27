2006-07-14  Don McCoy  <don@codesourcery.com>

	* src/vsip/impl/profile.hpp: Renamed Scope_enable class to Profile.
	* src/vsip_csl/error_db.hpp:  Moved from tests directory for use
	  with benchmarking and examples as well.
	* src/vsip_csl/load_view.hpp: Likewise.
	* src/vsip_csl/output.hpp: Likewise.
	* src/vsip_csl/ref_conv.hpp: Likewise.
	* src/vsip_csl/ref_corr.hpp: Likewise.
	* src/vsip_csl/ref_dft.hpp: Likewise.
	* src/vsip_csl/ref_matvec.hpp: Likewise.
	* src/vsip_csl/save_view.hpp: Likewise.
	* src/vsip_csl/test.hpp: Likewise.
	* src/vsip_csl/test-precision.hpp: Likewise.
	* tests/*.cpp: Updated to use headers in src/vsip_csl/ and to
	  use the 'vsip_csl' namespace.
	* tests/parallel/*.cpp: Likewise.
	* tests/regressions/*.cpp: Likewise.
	* tests/solver-common.hpp: Updated to specify vsip_csl:: for
	  Precision_traits<>.  Moved compare_view() to...
	* tests/solver-svd.cpp: here.
	* vendor/GNUmakefile.inc.in: Fixed error in cleaning FFTW.
	* benchmarks/hpec_kernel/svd.cpp: Corrected path to 
	  vsip_csl/test-precision.hpp.
	* examples/fft.cpp: Added comments, improved readability.
	* examples/GNUmakefile.inc.in: Added a 'clean' target.
