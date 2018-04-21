2007-02-12  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/cbe/ppu/fft.cpp: Added handlers for 8K point FFTs.
	* src/vsip/opt/cbe/ppu/task_manager.hpp: Declared FFT SPE image.
	* src/vsip/opt/cbe/ppu/fft.hpp: Added scale parameter for evaluators.
	* src/vsip/opt/cbe/ppu/alf.hpp: Increased stack size, added assert()
	  to check return value for add_* functions.
	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Added FFT library.
	* src/vsip/opt/cbe/spu/vmul.cpp: Removed, obsolete.
	* src/vsip/opt/cbe/spu/alf_fft_c.c: New file, implements 1-D FFT.
	* src/vsip/opt/cbe/vmul.h: Removed, obsolete.
	* src/vsip/opt/cbe/common.h: New file, definitions common to both
	  SPE and PPE sides.
