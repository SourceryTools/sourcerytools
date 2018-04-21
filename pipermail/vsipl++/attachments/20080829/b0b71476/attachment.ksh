2008-08-29  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/ukernel.hpp: Added debug printfs to Ps_helper dump()
	  routine and corrected calls to it in apply() function.  Added
	  new apply() and operator() functions for three inputs/one output.
	* src/vsip/opt/ukernel/cbe_accel/alf_base.hpp: Added a Kernel_helper
	  routine for three inputs and one output.
	* src/vsip/opt/ukernel/cbe_accel/resource_manager.hpp: Corrected typo.
	* src/vsip/opt/ukernel/cbe_accel/ukernel.hpp: Corrected @file path
	  and inclusion macros.  Partially documented Pinfo data members.
	* src/vsip/opt/ukernel/cbe_accel/debug.hpp: New file. Debug dump
	  routine for Pinfo structure.
	* src/vsip/opt/ukernel/kernels/cbe_accel/madd_f.cpp: New file.  
	  Kernel declaration for elementwise scalar multiply-add.
	* src/vsip/opt/ukernel/kernels/cbe_accel/cmadd_f.cpp: New file.
	  Kernel declaration for elementwise complex interleaved multiply-add.
	* src/vsip/opt/ukernel/kernels/cbe_accel/madd_f.hpp: New file.  
	  Elementwise multiply-add kernel for scalar floats.
	* src/vsip/opt/ukernel/kernels/cbe_accel/cmadd_f.hpp: New file.  
	  Elementwise multiply-add kernel for complex interleaved.
	* src/vsip/opt/ukernel/kernels/cbe_accel/id1_f.hpp: Fixed @file path.
	* src/vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.hpp: Fixed @file path.
	* src/vsip/opt/ukernel/kernels/cbe_accel/id2_f.hpp: Fixed @file path.
	* src/vsip/opt/ukernel/kernels/cbe_accel/cfft_f.hpp: Fixed @file path.
	* src/vsip/opt/ukernel/kernels/cbe_accel/vmul_f.hpp: Fixed @file path.
	* src/vsip/opt/ukernel/kernels/host/madd.hpp: New file.  Host-side
	  definitions for elementwise multiply-add user-defined kernel.
	* tests/GNUmakefile.inc.in: Added ukernel sub-directory to sources.
	* tests/ukernel/vmul.cpp: Uncommented test cases.
	* tests/ukernel/madd.cpp: New file.  Tests for mul-add kernel.
