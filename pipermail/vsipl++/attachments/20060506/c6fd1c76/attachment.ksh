2006-05-06  Don McCoy  <don@codesourcery.com>

	* src/vsip/impl/sal/solver_lu.hpp: Added support for
	  double by using older SAL functions matlud, vrecip and 
	  matfbs.  A compile-time switch enables a choice between
	  the new and the old functions.  The new ones support
	  transpose options (A' x = b) but only work for single-
	  precision values.  When using the old set of functions,
	  an exception will be thrown if the transpose option is
	  anything but 'mat_ntrans'.
