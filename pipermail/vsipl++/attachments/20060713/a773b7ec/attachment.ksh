2006-07-13  Don McCoy  <don@codesourcery.com>

	* src/vsip/impl/profile.hpp: Renamed Scope_enable class to Profile.
	* src/vsip_csl/error_db.hpp:  Copied from tests directory for use
	  with benchmarking and examples as well.
	* src/vsip_csl/ref_corr.hpp: Likewise.
	* src/vsip_csl/ref_conv.hpp: Likewise.
	* src/vsip_csl/ref_dft.hpp: Likewise.
	* src/vsip_csl/ref_matvec.hpp: Likewise.
	* vendor/GNUmakefile.inc.in: Fixed error in cleaning FFTW.
	* examples/fft.cpp: Added comments, improved readability.
	* examples/GNUmakefile.inc.in: Added a 'clean' target.
