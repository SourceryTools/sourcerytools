2006-11-03  Don McCoy  <don@codesourcery.com>

	* src/vsip_csl/load_view.hpp: Added load_view_as<> to read in a file
	  of one type into a view of another (using view_cast<> template).
	* src/vsip_csl/save_view.hpp: Likewise added save_view_as<>.
	* apps/ssar/load_save.hpp: Removed.
	* apps/ssar/kernel1.hpp: Changed to use new load/save...as functions.
	* apps/ssar/GNUmakefile: Removed load_save.hpp dependency.
	* apps/ssar/viewtoraw.cpp: Simplified using view_cast<>
