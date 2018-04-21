2007-03-28  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/cbe/ppu/fft.cpp: Use new parameters header.
	* src/vsip/opt/cbe/ppu/fastconv.cpp: Likewise.
	* src/vsip/opt/cbe/ppu/fft.hpp: Likewise.
	* src/vsip/opt/cbe/ppu/fastconv.hpp: Likewise.
	* src/vsip/opt/cbe/fconv_params.h: New header (was common.h).  Also
	  modified to handle addresses in a portable (32/64-bit) way.
	* src/vsip/opt/cbe/spu/alf_fconv_c.c: Use new header.
	* src/vsip/opt/cbe/spu/alf_fft_c.c: Likewise.
	* src/vsip/opt/cbe/spu/alf_fconv_split_c.c: Likewise.
	* src/vsip/opt/cbe/fft_params.h: New header (from common.h).
	* src/vsip/opt/cbe/common.h: Removed.
