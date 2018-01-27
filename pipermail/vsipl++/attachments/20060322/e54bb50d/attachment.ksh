2006-03-22  Assem Salama <assem@codesourcery.com>

	* CVSROOT/modules: Modified the line for clapack to only pull out SRC
	  directory	
	* vendor/clapack/SRC/make.inc.in: New file. This file was added because
	  clapack checkout only contains the SRC. This was done because we
	  don't need the other directories that clapack comes with.
	* vendor/GNUmakefile.inc: Modified this makefile to make CLAPACK from
	  SRC directory.
	* configure.ac: Added an option to configure to allow user to override
	  CFLAGS for CLAPACK. The option is called --with-clapack-cflags. If
	  this option is not specified, the normal CFLAGS gets assigned to
	  CLAPACK_CFLAGS.
