2008-05-20  Don McCoy  <don@codesourcery.com>

	* src/vsip/core/matvec_prod.hpp: Fixed bug in size passed for transpose
	  product case.
	* src/vsip/opt/cbe/ppu/alf.hpp: Removed conditionals around ALF
	  initialization -- now uses cml_init/fini exclusively.
	* src/vsip/opt/cbe/cml/matvec.hpp: Modified evaluator to handle 
	  transpose cases.
	* src/vsip/opt/cbe/cml/prod.hpp: Added bindings for transpose cases.
	* tests/matvec-prod.cpp: Modified transpose product tests to run
	  them with different orderings, as is done with normal products.
	  Only added orderings relevant to CML so as not to expand the
	  test coverage unnecessarily.  Also fixed the test to make it call
	  prodt() directly instead of prod(a, trans(b)).
