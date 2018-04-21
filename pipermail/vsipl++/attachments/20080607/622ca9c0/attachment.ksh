2008-06-07  Don McCoy  <don@codesourcery.com>

	* src/vsip/core/cvsip/fir.hpp: Changed dispatch to avoid incrementing
	  the reference count twice when creating the backend (once on creation
	  and once when passing into the Ref_counted_ptr holder).
	* src/vsip/opt/ipp/fir.hpp: Likewise.
	* src/vsip/opt/signal/fir_opt.hpp: Likewise.
