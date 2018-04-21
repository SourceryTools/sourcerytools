2006-06-03  Assem Salama <assem@codesourcery.com>
	
	* configure.ac: Added a new lapack option. The user can now say
	  --with-lapack=simple. This will build VSIPL++ with the BLAS that
	  comes with CLAPACK.
	* vendor/GNUmakefile.inc.in: Added an option to compile the BLAS
	  library that comes with CLAPACK.
	* vendor/clapack/SRC/make.inc.in: Changed library names to liblapack.a
	  and libcblas.a. That way, the user can use -llapack and -lcblas.
	* vendor/clapack/blas/SRC/GNUmakefile.in: New file. This file used to
	  be Makefile. This file uses configure variable srcdir.
	* vendor/clapack/blas/blaswrap.h: Added a define at the top to not
	  redefine blas functions to f2c functions.
	* examples/GNUmakefile.inc.in: Changed typo that prevented VSIPL++
	  from finishing a complete build.
