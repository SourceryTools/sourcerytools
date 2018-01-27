2006-07-16  Don McCoy  <don@codesourcery.com>

	* src/vsip/profile.cpp: Added interfaces for getting total time and
	  number of times called to the Profiler class.  Made event tag const.
	* src/vsip/impl/fft/util.hpp: Added class to build descriptive strings
	  from template parameters.
	* src/vsip/impl/fft.hpp: Unified some functionality by combining the
	  use of the timer with a class that better manages event information.
	  Enahanced event tags to include 1) direction, 2) input data type,
	  3) output data type and 4) return mechanism.  
	* src/vsip/impl/profile.hpp: Made event tags const.  Added 
	  Profile_event class to store event names and operation counts as 
	  well as to manage access to members used by the impl_performance()
	  interface, which it does through an new constructor to the 
	  Scope_event class.  Works in accumulate mode only presently.
	* examples/fft.cpp: Added a demonstration of the impl_performance()
	  interface.
