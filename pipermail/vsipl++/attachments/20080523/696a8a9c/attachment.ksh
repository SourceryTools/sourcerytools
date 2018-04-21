2008-05-23  Don McCoy  <don@codesourcery.com>

	* src/vsip/core/general_evaluator.hpp: New operator tag for conjugate
	  matrix-matrix products.
	* src/vsip/core/matvec_prod.hpp: New generic evaluator for conjugate
	  products to allow dispatch to backends that support it.  Functions
	  prodj and prodh now use it.
	  (prodh): Fixed bug in return matrix size.
	* src/vsip/opt/cbe/cml/matvec.hpp: New evaluator for conjugate and
	  conjugate transpose (hermitian) matrix products, dispatching to CML.
	* src/vsip/opt/cbe/cml/prod.hpp: Added bindings for conj and herm.
	* tests/matvec-prodjh.cpp: Fixed tests for conj and herm to use
	  prodj and prodh instead of conj and herm operators.
