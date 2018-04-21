2006-07-28  Don McCoy  <don@codesourcery.com>

	* src/vsip/profile.cpp: Changed 'mflops' to 'mops'.
	* src/vsip/impl/fft/util.hpp: Updated tag(s) used in profiling.
	* src/vsip/impl/signal-iir.hpp: Added profiling code.
	* src/vsip/impl/signal-conv.hpp: Updated profiling code.
	* src/vsip/impl/signal-corr.hpp: Likewise.
	* src/vsip/impl/ops_info.hpp: Added descriptive tags for profiling.
	* src/vsip/impl/fft.hpp: Changed 'mflops' to 'mops'.
	* src/vsip/impl/signal-fir.hpp: Added profiling code.
	* src/vsip/impl/profile.hpp: Modified to allow use of strings in 
	  addition to char pointers in the Scope_event class.
	* src/vsip/impl/matvec.hpp: Added profiling code.
	* apps/sarsim/sarsim.hpp: Changed 'mflops' to 'mops'.
	* benchmarks/dist_vmul.cpp: Corrected missing impl:: on op counts.
	* benchmarks/GNUmakefile.inc.in: Omit building mpi benchmarks when
	  not compiled with mpi.
	* examples/fft.cpp: Changed 'mflops' to 'mops'.
