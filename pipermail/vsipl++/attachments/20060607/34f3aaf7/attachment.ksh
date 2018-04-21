2006-06-07  Don McCoy  <don@codesourcery.com>

	* benchmarks/hpec_kernel/cfar.cpp: Added new algorithm that
          processes the data cube one range-vector at a time.  Corrected
	  a bug in the verification code that prevented it from checking all 
	  targets that it found.  Adjusted the sensitivity (mu) constant and
          the distribution of the background noise in order to avoid missing
          or finding extra targets.
        * src/vsip_csl/test-precision.hpp: moved from tests directory.
