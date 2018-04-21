2006-03-19  Don McCoy  <don@codesourcery.com>

	* configure.ac: added #define for VSIP_IMPL_SOURCERY_VPP.
	* benchmarks/benchmarks.hpp: new file.  encapsulates resources 
	  needed to run benchmarks.  provides some resources for 
	  linking against the reference implementation.
	* benchmarks/loop_ser.hpp: new file with parallel-specific
	  functionality removed (based on loop.hpp).  also used for 
	  linking against the reference implementation.
	* benchmarks/main.cpp: change to use benchmarks.hpp instead
	  of several separate includes.
	* benchmarks/make.standalone: Fixed a bug where it would
	  not recognize that PREFIX was set on the command line.
	  Fixed include paths and build targets.
	* benchmarks/vmul.cpp: change to use benchmarks.hpp instead
	  of several separate includes.  removed implementation-
	  specific functionality where possible and used the new
	  SOURCERY_VPP macro where not.
