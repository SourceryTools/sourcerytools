2008-06-04  Don McCoy  <don@codesourcery.com>

	* src/vsip/core/vmmul.hpp: Corrected spelling error.
	* src/vsip/core/type_list.hpp: Added room for an additional type.
	* src/vsip/opt/cbe/cml/transpose.hpp: New file.  Bindings and
	  serial evaluator for transpose operations using CML.
	* src/vsip/opt/diag/eval.hpp: Added diagnostics for Cml_tag.
	* src/vsip/opt/expr/serial_dispatch.hpp: Include CML transpose header.
	* src/vsip/opt/expr/serial_dispatch_fwd.hpp: Add new tag for CML.
