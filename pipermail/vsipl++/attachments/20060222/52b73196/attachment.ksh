2006-02-22  Don McCoy  <don@codesourcery.com>

        * src/vsip/profile.cpp: corrected cases where 'stamp_type'
	  data members are treated as integers.  added overloaded
	  dump() function to print to stdout.
	* src/vsip/impl/profile.hpp: added members zero() and ticks()
	  to handle above cases.
