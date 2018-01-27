2005-11-04  Don McCoy  <don@codesourcery.com>

	* tests/matvec-prod.cpp: Re-arranged tests to avoid running tests
	  repeatedly with the same ordering.  Added tests for vector-matrix
	  and matrix-vector products.
	* tests/matvec.cpp: added test for outer().
	* tests/ref_matvec.hpp: modified ref::outer() to conjugate complex
	  values.  Added vector-vector product to use for matrix-matrix
	  product.  Added v-m and m-v products as well.
	* src/vsip/impl/eval-blas.hpp: Added evaluators for BLAS outer,
	  m-v prod, v-m prod and general matrix multiply (gemm).  Fixed
	  a bug in the runtime check for m-m prod that only affected
	  col-major cases.
	* src/vsip/impl/general_dispatch.hpp: Added operation tags for
	  m-v and v-m products.  New implementation tag for SAL.  New
	  wrapper classes for operand lists of 3 and 4 arguments along
	  with the corresponding dispatch classes.
	* src/vsip/impl/lapack.hpp: Included prototypes for gemv and ger
	  BLAS functions with overloaded wrappers for calling them.
	* src/vsip/impl/matvec-prod.hpp: Added generic evaluators for
	  m-v and v-m products.  Added dispatch functions for same.
	* src/vsip/impl/matvec.hpp: Same as above for outer and gemp.
