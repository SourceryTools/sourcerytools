2006-04-30  Don McCoy  <don@codesourcery.com>

	* benchmarks/ops_info.hpp: Added operations count information for
	  square and divide for complex and real numbers.
	* benchmakrs/vdiv.cpp: New file.  Implements virtually the same
	  tests as for vmul.cpp - a mix of real and complex inputs, in-
	  place, as well as split- vs interleaved-format.
