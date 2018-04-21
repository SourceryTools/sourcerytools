2006-09-10  Don McCoy  <don@codesourcery.com>

	* benchmarks/hpec_kernel/cfar.cpp: Fixed performance issue
	  introduced in the last patch.  Now the preferred (i.e. highest
	  performing) storage order is used for each of the three
	  algorithms.
