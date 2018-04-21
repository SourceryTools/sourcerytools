2008-09-01  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/ukernel/cbe_accel/alf_base.hpp: Modified the way offsets
	  are calculated to account for the possibility of different data types 
	  for each of views being streamed to a kernel.  Added utility function
	  for calculating the byte offset of an input segment.
	* src/vsip/opt/ukernel/kernels/cbe_accel/scmadd_f.cpp: New file, 
	  extends multiply-add function to allow for a scalar-complex multiply.
	* src/vsip/opt/ukernel/kernels/cbe_accel/scmadd_f.hpp: new file, 
	  scalar-complex multiply-add kernel.
	* src/vsip/opt/ukernel/kernels/host/madd.hpp: Declare scmadd kernel.
	* tests/ukernel/madd.cpp: Adjusted tests for above.
