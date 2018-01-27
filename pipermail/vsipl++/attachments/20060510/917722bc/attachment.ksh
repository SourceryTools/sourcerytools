2006-05-10  Jules Bergmann  <jules@codesourcery.com>

	Update FFTW3 to build for GreenHills/MCOE/PowerPC:
	* vendor/fftw/kernel/cycle.h (getticks): Add tick counter for
	  GreenHills/PowerPC combination.
	* vendor/fftw/libbench2/timer.c
	* vendor/fftw/libbench2/Makefile.in: Make $OBJEXT correct.
	* vendor/fftw/tests/Makefile.in: Likewise.
	* vendor/fftw/tools/Makefile.in: Likewise.

