2006-08-13  Don McCoy  <don@codesourcery.com>

	* scripts/config: Changed --enable-profile-timer to --enable-timer.
	* src/vsip/impl/signal-iir.hpp: Added capability to disable profiling 
	  and the performance API.
	* src/vsip/impl/signal-conv.hpp: Likewise.
	* src/vsip/impl/signal-corr.hpp: Likewise.
	* src/vsip/impl/signal-conv-ipp.hpp: Likewise.
	* src/vsip/impl/signal-conv-ext.hpp: Likewise.
	* src/vsip/impl/signal-corr-ext.hpp: Likewise.
	* src/vsip/impl/fft.hpp: Likewise.
	* src/vsip/impl/signal-corr-opt.hpp: Likewise.
	* src/vsip/impl/signal-fir.hpp: Likewise.
	* src/vsip/impl/signal-conv-sal.hpp: Likewise.
	* src/vsip/impl/profile.hpp: Likewise.
	* src/vsip/impl/matvec.hpp: Likewise.
	* configure.ac: Added options for enabling/disabling profiling in 
	  total or in part.  Default is disabled.  The setting is displayed
	  in the summary.  Also made a minor change to allow 
	  --disable-timer to work as expected.
	* doc/quickstart/quickstart.xml:  Changed --enable-profile-timer to 
	  --enable-timer.
	* examples/mercury/mcoe-setup.sh: Likewise.

