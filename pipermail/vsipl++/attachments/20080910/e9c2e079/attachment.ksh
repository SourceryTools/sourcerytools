2008-09-10  Don McCoy  <don@codesourcery.com>

	* vsip/opt/ukernel.hpp: Added Ps_helper class for three-dimensional
	  views.  Documented the principal member function as well.
	* vsip/opt/ukernel/cbe_accel/alf_base.hpp: Fixed effective address
	  calculation for DMA's larger than 16KB.  Added support for three
	  dimensional views, provided the last two are dense (because they
	  are streamed together).
	* vsip/opt/ukernel/cbe_accel/debug.hpp: Moved an include file so
	  that it would build with NDEBUG defined.
	* vsip/opt/ukernel/kernels/cbe_accel/interp_f.cpp: New file, 
	  declaration of user-defined kernel for SSAR interpolation function.
	* vsip/opt/ukernel/kernels/cbe_accel/interp_f.hpp: New file, 
	  definition for above.
	* vsip/opt/ukernel/kernels/host/interp.hpp: New file, host-side
	  portion of user-defined interpolation kernel.
	* vsip/opt/ukernel/ukernel_params.hpp: Expanded struct to include
	  values for a third dimension.
	* vsip/GNUmakefile.inc.in: Create relevant ukernel header directories.
	* GNUmakefile.in: Install relevant ukernel headers.
	* tests/ukernel/interp.cpp: Interpolation unit test.
