2007-03-23  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/cbe/ppu/fastconv.cpp: Changed kernel stack 
	  allocation to allow split complex case to work with up
	  to 4 K points.
	* src/vsip/opt/cbe/ppu/fastconv.hpp: Changed mininum and 
	  maximum size constants to come from a common location.
	* src/vsip/opt/cbe/spu/alf_fconv_c.c: Added asserts to
	  verify transfer size is under the 16 KB limit.
	* src/vsip/opt/cbe/spu/alf_fconv_split_c.c: Likewise.
	* src/vsip/opt/cbe/spu/spe_assert.h: New file.  Replaces
          native assert() function for SPE code.
	* src/vsip/opt/cbe/common.h: Added defines for different
	  cases (split/interleaved complex).
