2006-07-07  Don McCoy  <don@codesourcery.com>
	
	* src/vsip/profile.cpp: Modified the event() function to store the 
	  'value' parameter when in 'accumulate' mode.
	* src/vsip/impl/ops_info.hpp: Copied from benchmarks directory so that 
	  it could be used for profiling function calls.
	* src/vsip/impl/signal-conv.hpp: Added call to log events when in the 
	  various operator() functions.
	* src/vsip/impl/signal-corr.hpp: Likewise.
	* src/vsip/impl/fft.hpp: Likewise.
	* src/vsip/impl/profile.hpp: Added third member to Accum_entry 
	  struct in order to store operation count (passed in through the
	  event class through the 'value' parameter).
	* examples/fft.cpp: New file.  Demonstrates profiling capability
	  for a simple fft.
	* examples/GNUmakefile.inc.in: Simplified build targets so that
	  it would accept 'make examples' in order to build all of them.
	  It also will build any .cpp file dropped into that directory, 
	  without having to explicitly add the new target.
