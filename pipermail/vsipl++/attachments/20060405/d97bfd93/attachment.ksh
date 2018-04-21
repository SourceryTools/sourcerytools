2006-04-05  Don McCoy  <don@codesourcery.com>

	* benchmarks/loop.hpp: Added secs_per_pt metric calculation.
	* benchmarks/main.cpp: Added new option -lat to show latency,
	  which is just the inverse of pts_per_sec.  In other words,
	  it displays the average time consumed per point computed.
