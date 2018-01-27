2006-04-03  Assem Salama <assem@codesourcery.com>
	* src/vsip/dense.hpp: Converted this file to use Index and Length
	  instead of Point.
	* src/vsip/matrix.hpp: Same as above.
	* src/vsip/vector.hpp: Same as above.
	* src/vsip/impl/block-copy.hpp: Same as above.
	* src/vsip/impl/extdata.hpp: Same as above.
	* src/vsip/impl/fast-block.hpp: Same as above.
	* src/vsip/impl/lvalue-proxy.hpp: Same as above.
	* src/vsip/impl/par-assign.hpp: Same as above.
	* src/vsip/impl/par-chain-assign.hpp: Same as above.
	* src/vsip/impl/par-foreach.hpp: Same as above.
	* src/vsip/impl/layout.hpp: Same as above. Had to change index
	  index functions to take Index instead of Point.
	* src/vsip/domain.hpp: Added operators ==,-,and + for Index.
	* src/vsip/impl/domain-utils.hpp: Added extent functions that return
	  Length instead of point.
	* src/vsip/impl/par-util.hpp: Changed the foreach_point function to
	  work on Index instead of Point.
	* src/vsip/impl/point-fcn.hpp: Removed this file from cvs. The use of
	  Point is deprecated. We now use Index and Length.
	* src/vsip/impl/point.hpp: Removed this from cvs. We now use Length and
	  Index instead of Point.
	* tests/output.hpp: Changed the << operator to operate on an Index.
	* tests/appmap.cpp: Converted this test to use Length and Index.
	* tests/fast-block.cpp: Same as appmap.cpp
	* tests/us-block.cpp: Same as above.
	* tests/user_storage.cpp: Same as above.
	* tests/util-par.hpp: Same as above.
	* tests/view.cpp: Same as above.
	* tests/vmmul.cpp: Same as above.
	* tests/parallel/block.cpp: Same as above.
	* tests/parallel/expr.cpp: Same as above.
	* tests/parallel/subviews.cpp: Same as above.

