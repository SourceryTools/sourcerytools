2006-04-03  Don McCoy  <don@codesourcery.com>

	* benchmarks/benchmarks.hpp: Added view_equal() cases for
	  vectors and matrices needed for compiling a debug version
	  linked to other library implementations.
	* benchmarks/fft.cpp: Updated to use benchmarks.hpp.  Fixed
	  instances of () to .get() when extracting values from views.
	* benchmarks/firbank.cpp: Fixed one remaining instance of
	  parallel-related code needed also for compiling the debug
	  version against the reference implementation.
