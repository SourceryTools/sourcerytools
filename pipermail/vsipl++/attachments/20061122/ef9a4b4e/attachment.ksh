2006-11-22  Don McCoy  <don@codesourcery.com>

	* apps/ssar/kernel1.hpp: Made some data members in constructors local as
	  they did not need to be retained.  Some minor renaming and comment-
	  fixing for consistency.  Fixed the two asserts in interpolate to
	  check for the correct size.
	* apps/ssar/ssar.cpp: Added display of setup time, plus max, min and
	  std-dev for the mean compute time.

