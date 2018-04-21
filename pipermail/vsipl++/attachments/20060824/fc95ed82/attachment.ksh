2006-08-24  Don McCoy  <don@codesourcery.com>

	* src/vsip/impl/fft/util.hpp: Moved description to ops_info.hpp.
	* src/vsip/impl/signal-iir.hpp: Moved ops count to ops_info.hpp.
	* src/vsip/impl/expr_ops_info.hpp: Added Vmmul specializations.
	* src/vsip/impl/signal-conv.hpp: Moved ops count to ops_info.hpp.
	* src/vsip/impl/signal-corr.hpp: Moved ops count to ops_info.hpp.
	* src/vsip/impl/ops_info.hpp: Added op counts as noted.  Removed
          leading spaces from sizes in descriptions.  Sizes for 1-D
          objects no longer show "x1" for the second dimension.  Removed 
	  dimension from Fft and Fftm descriptions.  
	* src/vsip/impl/fft.hpp: Moved ops count to ops_info.hpp.
	* src/vsip/impl/signal-fir.hpp: Moved ops count to ops_info.hpp.
	* src/vsip/impl/expr_serial_dispatch.hpp: Added include for
	  impl/profile.hpp.
