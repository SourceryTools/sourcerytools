2005-12-20  Don McCoy  <don@codesourcery.com>

	* GNUmakefile.in: moved variables for detecting libraries to here.
	* configure.ac: create additional output varibles for same.
	* benchmarks/GNUmakefile.inc.in: modified to remove tests that are
	  dependent on libraries that are not available.  fixed 'bench' to
	  only build those tests.  deleted debugging target.
	* benchmarks/dot.cpp: corrected evaluator tag for vector-vector 
	  dot product.
	* src/vsip/GNUmakefile.inc.in: moved variables to top-level makefile.
