2006-09-02  Don McCoy  <don@codesourcery.com>

	* src/vsip/initfin.cpp: Corrected comment, now that...
	* src/vsip/profile.cpp: ...arguments are removed from the list 
	  passed to the Profile_options constructor.  Added new function 
	  member for that purpose.
	* src/vsip/impl/profile.hpp: Added definitions for the different 
	  values for VSIP_IMPL_PROFILER.  Revised comments.
	* configure.ac: Removed configuration options related to profiling.
	* examples/fft.cpp: Added command-line arguments to library
	  initialization call.  Changed profiler output filename.
	* examples/png.cpp: Added command-line arguments.
	* examples/example1.cpp: Added command-line arguments.
