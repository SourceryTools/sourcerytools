2007-05-15  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/cbe/ppu/alf.hpp: Removed obsolete function calls.
	Removed 'volatile' from alf_comp_kernel() calls:
	* src/vsip/opt/cbe/spu/alf_fconv_c.c
	* src/vsip/opt/cbe/spu/alf_fft_c.c
	* src/vsip/opt/cbe/spu/alf_vmul_c.c
	* src/vsip/opt/cbe/spu/alf_fconv_split_c.c
	* src/vsip/opt/cbe/spu/alf_fconvm_c.c
	* src/vsip/opt/cbe/spu/alf_vmul_split_c.c
	* src/vsip/opt/cbe/spu/alf_vmmul_c.c
	* src/vsip/opt/cbe/spu/alf_vmul_s.c
	* src/vsip/opt/cbe/spu/alf_fconvm_split_c.c
