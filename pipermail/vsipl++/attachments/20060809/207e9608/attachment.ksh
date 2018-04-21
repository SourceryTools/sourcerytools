2006-08-09  Don McCoy  <don@codesourcery.com>

	* src/vsip/impl/expr_op_names.hpp: New file.  Creates names that can be
	  used as tags for the profiler.
	* src/vsip/impl/eval_dense_expr.hpp: Added profiling for 2/3D -> 1D 
	  conversion.
	* src/vsip/impl/expr_ops_per_point.hpp: Added some unary and ternary
	  operators.
	* src/vsip/impl/expr_serial_evaluator.hpp: Added profiling for loop
	  fusion and transpose expression evaluation.
	* tests/expr_ops_per_point.cpp: Added some new tests for unary operators.
	* tests/expr_op_names.cpp: New file.  Tests expression tags.
	* tests/GNUmakefile.inc.in: Modified to allow building tests individually
	  by invoking it with 'make tests/*'.  
