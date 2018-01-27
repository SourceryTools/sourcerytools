2007-01-02  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/cbe/ppu/vmul.cpp: New file - driver for SPE-based 
	  vector multiply.
	* src/vsip/opt/cbe/ppu/vmul.hpp: New file.
	* src/vsip/opt/cbe/ppu/bindings.cpp: Changed to call SPE-based vmul.
	* src/vsip/opt/cbe/spu/vmul.cpp: Static (resident) elementwise
	  vector multiply function.
	* src/vsip/opt/cbe/vmul.h: Data structures shared between the SPU
	  and PPU code.
	* src/vsip/GNUmakefile.inc.in: Added new source file.
