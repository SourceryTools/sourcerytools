2008-05-13  Don McCoy  <don@codesourcery.com>

	* src/vsip/core/matvec_prod.hpp: Fixes a typo affecting the headers
	  included when building the reference implementation.  Adds include
	  for new CML backend for matrix products.
	* src/vsip/core/impl_tags.hpp: New tag for CML backend.
	* src/vsip/opt/general_dispatch.hpp: Adds CML tag to typelist.
	* src/vsip/opt/cbe/cml/matvec.hpp: New file.  Handles matrix product
	  dispatch to CML backend.
	* src/vsip/opt/cbe/cml/prod.hpp: Wrappers (bindings) for matrix
	  produt functions in CML.
	* src/vsip/opt/cbe/cml/traits.hpp: Helper traits classes that pertain
	  strictly to CML.
	* src/vsip/GNUmakefile.inc.in: Adds new install directory.
	* GNUmakefile.in: Adds new header include directory.
	* examples/mprod.cpp: New file.  Demonstrates matrix product API.
