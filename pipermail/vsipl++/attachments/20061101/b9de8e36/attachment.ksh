2006-11-01  Don McCoy  <don@codesourcery.com>

	* src/vsip_csl/matlab_utils.hpp: New file.  Moved fft_shift
	  routines from kernel1.hpp to here.  Added versions returning
	  results by reference.  Changed get/put loop to use assignment
	  using subviews.
	* apps/ssar/load_save.hpp: Updated for post 1.2 changes.
	* apps/ssar/diffview.cpp: Added -c option for complex views 
	  (this is also the default).  Simplified compare_view by
	  making it a template function.
	* apps/ssar/kernel1.hpp: Changed to use new fftshift routines.
	* apps/ssar/viewtoraw.cpp: Added -c option.
	* apps/ssar/Makefile: Renamed to GNUmakefile.
