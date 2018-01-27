2007-04-06  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/cbe/ppu/eval_fastconv.hpp: Specified value for new template
	  parameter required for Fastconv object.
	* src/vsip/opt/cbe/ppu/task_manager.hpp: Defined tasks for new kernel.
	* src/vsip/opt/cbe/ppu/fastconv.cpp: Adjusted bindings to work with 
	  both the current and the new kernel.  Fixed a bug in the split case
	  where the addresses were being incremented by twice the desired value.
	* src/vsip/opt/cbe/ppu/fastconv.hpp: Modified to allow unique coefficients
	  to be used for each row when performing multiple fast convolutions.
	* src/vsip/opt/cbe/spu/fft_1d_r2.h: Removed debug printf.
	* src/vsip/opt/cbe/spu/alf_fconvm_c.c: New file, implements fast 
	  convolution for interleaved complex data with unique coefficients.
	* src/vsip/opt/cbe/spu/alf_fconvm_split_c.c: New file, as above for
	  the complex split case.
	* tests/fastconv.cpp: Added new test cases for matrices of coefficients, 
	  parameterized on whether or not the FFT on them is done in advance.
	* benchmarks/cell/fastconv.cpp: Added two new cases as above.
	* benchmarks/alloc_block.hpp: Changed the specialization for Local_map
	  to only be defined for the one-dimensional case.
	* examples/fconv.cpp: Specified template parameter for Fastconv.
