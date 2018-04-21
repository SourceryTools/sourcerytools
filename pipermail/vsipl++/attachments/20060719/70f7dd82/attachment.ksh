2006-07-19  Don McCoy  <don@codesourcery.com>

	* src/vsip/profile.cpp: Changed event() function to optionally take 
	  a timestamp as an argument.  The default creates a zero timestamp
          indicating it should generate its own timestamp.
	* src/vsip/impl/fft/util.hpp: Added class to build descriptive strings
	  from a mixture of normal parameters and template parameters.
	* src/vsip/impl/fft.hpp: Unified some functionality by combining the
	  use of the timer with a class that better manages event information.
	  Enahanced event tags to include 1) direction, 2) input data type,
	  3) output data type, 4) return mechanism and 5) size.  
	* src/vsip/impl/profile.hpp: Made event tags const in some places and
	  std::strings in others, so that the tag pointers did not have to 
	  persist longer than the object being profiled.  Added class to 
	  store event names and operation counts as well as to manage access 
	  to the timer needed by impl_performance().
	* examples/fft.cpp: Added a demonstration of the impl_performance()
	  interface.  Minor cleanup.
