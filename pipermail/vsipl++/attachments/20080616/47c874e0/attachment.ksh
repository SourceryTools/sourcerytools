2008-06-16  Don McCoy  <don@codesourcery.com>

	* src/vsip_csl/load_view.hpp: Add capability to swap bytes.  Default 
	  behavior remains to not swap.
	* src/vsip_csl/save_view.hpp: Likewise.
	* tests/vsip_csl/load_view.cpp: Extend test to cover cases where 
	  bytes are swapped (equivalent to writing in big-endian format).
