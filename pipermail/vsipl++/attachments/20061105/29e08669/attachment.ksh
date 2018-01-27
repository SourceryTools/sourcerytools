2006-11-05  Don McCoy  <don@codesourcery.com>

	* apps/ssar/kernel1.hpp: Reorganized such that as much processing
	  as possible is done at create time.  Removed all but one of
	  the explicit loops from the main compute process.
	* apps/ssar/ssar.cpp: Changed to allow the input (raw radar data)
	  and output (viewable image) to be passed to Kernel1.
