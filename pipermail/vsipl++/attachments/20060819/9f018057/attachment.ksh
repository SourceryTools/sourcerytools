2006-08-19  Don McCoy  <don@codesourcery.com>

	* src/vsip/complex.hpp: Added functions to provide names for 
	  the profiler.
	* src/vsip/impl/expr_ops_info.hpp: Renamed expr_ops_per_point.hpp.
	  Added reduction to create tags for use by the profiler.  Added
	  some operation counts for unary and ternary operators.
	* src/vsip/impl/expr_operations.hpp: Added functions to provide 
	  names for the profiler.
	* src/vsip/impl/sal/eval_elementwise.hpp: Updated names.
	* src/vsip/impl/vmmul.hpp: Updated names.
	* src/vsip/impl/eval_dense_expr.hpp: Added functions to provide 
	  names for the profiler.
	* src/vsip/impl/simd/expr_evaluator.hpp: Likewise.
	* src/vsip/impl/simd/eval-generic.hpp: Likewise.
	* src/vsip/impl/fns_elementwise.hpp: Likewise.
	* src/vsip/impl/ipp.hpp: Updated names.
	* src/vsip/impl/expr_ops_per_point.hpp: Renamed expr_ops_info. 
	* src/vsip/impl/fns_userelt.hpp: Added generic functor
	  names unary, binary and ternary for user-defined functions.
	* src/vsip/impl/expr_serial_dispatch.hpp: Extended profile
	  policy to provided an expression tag and operations count
	  to the profiler.
	* src/vsip/impl/expr_serial_evaluator.hpp: Updated names.
	* src/vsip/selgen.hpp: Added functions to provide names for 
	  the profiler.
	* tests/expr_ops_per_point.cpp: Renamed to...
	* tests/expr_ops_info.cpp: ...this.  Added tests for 
	  expression tags.
	* tests/GNUmakefile.inc.in: Modified to allow building tests 
	  individually by invoking it with 'make tests/*'.  
