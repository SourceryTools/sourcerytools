2008-08-20  Don McCoy  <don@codesourcery.com>

	    * apps/ssar/diffview.cpp: Allow little-endian data files to be 
	      read properly on big-endian systems.
	    * apps/ssar/GNUmakefile: Changed to let profile formatting script 
	      be found even if 'prefix' is not set.  Added 'show' target.
	      Added -f flag to 'clean' target commands.  Renamed 'profile'
	      target to include the scale factor (1 or 3 now).
	    * apps/ssar/kernel1.hpp (scale_): Made scale parameter floating 
	      point instead of an integer.
	      (swap_bytes_): Made new parameter to control byte-swapping.
	    * apps/ssar/make_set1_images.sh: Generalized to 'make_images.sh'.
	    * apps/ssar/viewtoraw.cpp: Corrected location of 'view_cast.hpp'
	      header file.  Made compatible with big-endian systems.
	    * apps/ssar/ssar.cpp: Made compatible with big-endian systems.
	    * apps/ssar/data1: New directory with binary views for SCALE
	      factor of 1.
	    * apps/ssar/data1/dims.txt: New file, dimensions for SCALE == 1.
	    * apps/ssar/make_images.sh: Converts saved views first to raw
	      format, then to pgm format.  Size parameters are passed in on
	      the command-line.
	    * apps/ssar/set1: Renamed directory 'data3' to show scale factor.
	    * apps/ssar/set1/dims.txt: Moved to data3 directory (SCALE == 3).
	    * apps/ssar/README: Modified to explain new make targets.
