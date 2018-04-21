2006-03-29  Assem Salama <assem@codesourcery.com>

	* src/vsip/impl/lapack.hpp: Included rest of blas functions in the
	  VSIP_IMPL_USE_CBLAS directive. The new groups are trsm, gemv, gemm,
	  and ger.

	* vendor/clapack/SRC/blaswrap.h: Changed this header file to optionaly
	  include cblaswr.h if NO_INLINE_WRAP is not defined. This allows us to
	  inline the wrapper functions. When this define is not defined, we
	  define INLINE to inline and include cblaswr.h

	* vendor/clapack/SRC/cblaswr.c: Took out all of the functions in this
	  file and moved them to cblaswr.h. When they were moved, we added an
	  INLINE infront of each function. This define can be defined as
	  inline or just empty. If NO_INLINE_WRAP is defined, we define INLINE
	  to empty and include cblaswr.h.

	* vendor/clapack/SRC/make.inc.in: Added the flag -DNO_INLINE_WRAP to
	  CFLAGS. The default is to not inline the blas wrappers. We have
	  noticed slightly better performance on smaller vectors when the blas
	  wrappers are not inlined.

	* vendor/clapack/SRC/cblaswr.h: New file. This file has all of the
	  functions that were in cblaswr.c. The functions have INLINE perpeneded
	  to them.

