2006-08-10  Don McCoy  <don@codesourcery.com>

	* src/vsip/initfin.cpp: Modified to hand off command-line arguments 
	  to the new object made for handling profiler options.  These allow 
	  the profiler to be enabled without altering an existing program.
	* src/vsip/profile.cpp: New definition of Profiler_options class.
	* src/vsip/initfin.hpp: New static member to hold pointer to options object.
	* src/vsip/impl/profile.hpp: New declaration for Profiler_options class.
