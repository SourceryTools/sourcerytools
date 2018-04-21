2006-07-18  Don McCoy  <don@codesourcery.com>

	* configure.ac: Removed path to vendor/fftw/lib from LDFLAGS as these
	  are now copied over to the lib/ directory.
	* benchmarks/GNUmakefile.inc.in: Updated makefile to specify vsip
	  library using -L and -l (as is done in examples/).
