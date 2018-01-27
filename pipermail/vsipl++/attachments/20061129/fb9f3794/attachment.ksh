2006-11-29  Don McCoy  <don@codesourcery.com>

	* GNUmakefile.in: Installs profile formatting tool.
	* apps/ssar/GNUmakefile: Added mechanism to control
	  floating-point precision.  Added profiling target.
	  Fixed to correctly handle prefix.
	* apps/ssar/kernel1.hpp: Moved filenames to ssar.cpp.
	  Updated what views are saved for debug purposes.
	* apps/ssar/make_set1_images.sh: Fixed to account
	  for debug views that are no longer saved.
	* apps/ssar/ssar.cpp: Added filenames and precision.
	* apps/ssar/set1/ref_image.view: Renamed as 
	  ref_image_dp.view.
	* apps/ssar/set1/ref_image_sp.view: New file.  Used
	  for comparison when single-precision is selected.
	* apps/ssar/README: New file.  Describes benchmark and 
	  how to run it.
