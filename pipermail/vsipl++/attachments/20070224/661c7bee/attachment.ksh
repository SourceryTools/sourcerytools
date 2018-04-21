2007-02-24  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/cbe/ppu/task_manager.hpp: Added new task definition.
	* src/vsip/opt/cbe/ppu/fastconv.cpp: New file - fast convolution task type.
	* src/vsip/opt/cbe/ppu/fastconv.hpp: Likewise.
	* src/vsip/opt/cbe/spu/alf_fconv_c.c: New file - fast convolution kernel.
	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Build new kernel.
	* src/vsip/opt/cbe/common.h: Added definitions for fast convolution.
	* src/vsip/GNUmakefile.inc.in: Added bindings for new kernel.
	* examples/fconv.cpp: Example driver program.
