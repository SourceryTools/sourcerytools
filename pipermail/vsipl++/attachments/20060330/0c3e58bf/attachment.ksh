2006-03-30  Assem Salama <assem@codesourcery.com>
	* src/vsip/impl/length.hpp: Changed the extent function in this file
	  to return Length instead of point. This extent takes a Block.
	* src/vsip/impl/par-util.hpp: Changed the foreach_point function to
	  work on Index instead of Point.
	* src/vsip/impl/point-fcn.hpp: Added new extent functions to return
	  Length instead of Point.
	* src/vsip/impl/point.hpp: Added new functions to make Index and
	  Length work correctly. The new functions are get,put,next,valid,
	  and domain_nth.
	* tests/output.hpp: Changed the << operator to operate on an Index.
	* tests/appmap.cpp: Converted this test to use Length and Index.
	* tests/fast-block.cpp: Same as appmap.cpp
	* tests/us-block.cpp: Same as above.
	* tests/user_storage.cpp: Same as above.
	* tests/util-par.hpp: Same as above.
	* tests/view.cpp: Same as above.
	* tests/vmmul.cpp: Same as above.

	
