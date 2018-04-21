2008-05-24  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/cbe/cml/matvec.hpp: Added evaluators for matrix-vector
	  and vector-matrix product dispatch to CML.
	* src/vsip/opt/cbe/cml/prod.hpp: Bindings for mv- and vm-products.
	* tests/matvec-prodmv.cpp: Added tests using subviews to cover cases
	  where vector strides are not one and matrix rows are not dense
	  (although rows must be unit stride).
