2005-12-05  Don McCoy  <don@codesourcery.com>

	* src/vsip/signal-window.cpp: replaced ramp, clip and frequency
	  swap inline code with library functions.
	* src/vsip/signal-window.hpp: deleted unneeded function
	  impl::frequency_swap().
