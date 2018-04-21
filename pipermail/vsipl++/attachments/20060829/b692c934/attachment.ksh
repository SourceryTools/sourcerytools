2006-08-29  Don McCoy  <don@codesourcery.com>

	* src/vsip/impl/par-foreach.hpp: Added missing header.
	* src/vsip/impl/expr_serial_dispatch.hpp: Modified Eval_profile_policy
	  to incur less overhead when profiling is configured but not 
	  currently being used (i.e. a Profile object has not been created yet.
	* src/vsip/impl/profile.hpp: Added member function that reports the
	  current profile mode.
