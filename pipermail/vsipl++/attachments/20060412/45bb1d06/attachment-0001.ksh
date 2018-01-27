2006-04-12 Don McCoy  <don@codesourcery.com>

	* GNUmakefile.in: Added hpec-kernel and vsip_csl directories 
	  to the makefile include list.
	* benchmarks/firbank.cpp: Moved to benchmarks/hpec-kernel.
	* benchmarks/hpec-kernel/GNUmakefile.inc.in: New file.  Makefile 
	  for use when building from source.
	* benchmarks/hpec-kernel/firbank.cpp: Moved from benchmarks.
	* benchmarks/hpec-kernel/make.standalone: New file.  Stand-alone
	  makefile for post-install use.
	* src/vsip_csl/GNUmakefile.inc.in: New file.  Makefile for building
	  extensions library.  Adds install target for copying vsip_csl
	  headers alongside the standard vsip headers.
