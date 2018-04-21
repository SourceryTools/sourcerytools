2006-03-22  Assem Salama <assem@codesourcery.com>

	* CVSROOT/modules: Modified the line for clapack to only pull out SRC
	  directory	
	* vendor/clapack/SRC/make.inc.in: New file. This file was added because
	  clapack checkout only contains the SRC. This was done because we
	  don't need the other directories that clapack comes with.
	* vendor/clapack/SRC/cblaswr.c: New file. This file used to be in
	  vendor/clapack/blas/WRAP. This file was moved into SRC so that we can
	  just checkout SRC.
	* vendor/clapack/SRC/crotg.c: New file. This file also used to be in
	  vendor/clapack/blas/WRAP. This file was moved so that we just use
	  SRC directory
	* vendor/clapack/SRC/zrotg.c: New file. This file used to be in
	  vendor/clapack/blas/WRAP. It is now in SRC directory
	* vendor/clapack/SRC/GNUmakefile.in: Modified makefile to include the
	  new c files in the compile.
	* vendor/GNUmakefile.inc: Modified this makefile to make CLAPACK from
	  SRC directory.
	* configure.ac: Added an option to configure to allow user to override
	  CFLAGS for CLAPACK. The option is called --with-clapack-cflags. If
	  this option is not specified, the normal CFLAGS gets assigned to
	  CLAPACK_CFLAGS.
