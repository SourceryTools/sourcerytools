2006-05-25  Don McCoy  <don@codesourcery.com>

	* benchmarks/hpec-kernel: Removed obsolete directory.
	* benchmarks/loop.hpp: Modified calibration routine to allow
	  it to complete with a wider variety of circumstances.  Removed 
	  class-name qualifier from the m_value() member function 
	  declaration (non-portable).  Removed unreachable 'break' 
	  statements in same function.
	* benchmarks/hpec_kernel/cfar.cpp: New file.  Implements the 
	  HPEC Constant False Alarm Rate Detection kernel-level benchmark.
	* benchmarks/hpec_kernel/firbank.cpp: Fixed an instance where a
	  non-constant value specifies an array size (non-portable).  Also
	  eliminated a sign-change warning on r/wiob_per_point() members and
	  a warning on an initialized, but unused, variable in the ops()
          member function.
	* benchmarks/hpec_kernel/svd.cpp: New file.  Implements the
	  HPEC Singular-Value Decomposition kernel-level benchmark.
	* src/vsip/signal-window.cpp: Added instantiations of three versions
	  of vsip::impl::cost(Block, LP) to include these in the library
	  (because of the way the GreenHills compiler behaves).
	* src/vsip_csl/output.hpp: Removed definition to write a Point to a
	  stream.
