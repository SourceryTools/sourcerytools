2008-07-17  Don McCoy  <don@codesourcery.com>

	* diffview.cpp: Added capability to swap bytes when on big-endian 
	  systems.
	* GNUmakefile: Corrects use of fmt-profile.pl when $(prefix) isn't
	  used.
	* kernel1.hpp:  Added capability to swap bytes when on big-endian 
	  systems.
	* make_set1_images.sh: Improved readability.
	* viewtoraw.cpp:  Added capability to swap bytes when on big-endian 
	  systems.  Fixed header file path for view_cast.hpp.
	* ssar.cpp:  Added capability to swap bytes when on big-endian 
	  systems plus command-line switches to override the default behavior.
