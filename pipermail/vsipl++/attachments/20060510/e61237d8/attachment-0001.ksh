2006-05-10  Jules Bergmann  <jules@codesourcery.com>

	* vendor/GNUmakefile.inc.in: Only build ATLAS' libf77blas if
	  USE_FORTRAN_LAPACK defined.
	* vendor/atlas/configure.ac (--disable-fortran): New option,
	  disables Fortran API checks and disables building of Fortran
	  ATLAS libs through BUILD_FORTRAN_LIBS AC_SUBST.
	* vendor/atlas/Make.ARCH.in (BUILD_FORTRAN_LIBS): Use it.
	* vendor/atlas/makes/Make.bin: Separate targets for non-Fortran
	  and Fortran libs.  Fortran targets disabled by !BUILD_FORTRAN_LIBS.

