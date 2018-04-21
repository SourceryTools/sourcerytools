2006-11-13  Don McCoy  <don@codesourcery.com>

	* apps/ssar/kernel1.hpp: Speedups - Changed to return FFT results by 
	  reference instead of by value (eqs. 59, 63, 66, 69 and 94).  Eliminated 
	  two temporary variables (eqs. 66 and 68).  Used column-major format for 
	  the intermediate and result (eq. 62), which involves a column-vector
  	  multiply and an FFTM by columns.  Computed scale prior to the zero-
	  padding operation (eq. 65) to allow it to dispatch to an SIMD routine.
