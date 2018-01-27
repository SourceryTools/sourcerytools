2008-05-01  Don McCoy  <don@codesourcery.com>

	* m4/lapack.m4: Adjust CLAPACK_NOOPT to include -m32 or -m64
	  when appropriate.
	* vendor/clapack/blas/SRC/f2c.h: Fix definition of 'integer'
	  to be consistent with the other two copies of f2c.h in
	  the clapack source tree.
