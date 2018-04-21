Index: src/vsip/opt/reductions/par_reductions.hpp
===================================================================
--- src/vsip/opt/reductions/par_reductions.hpp	(revision 174145)
+++ src/vsip/opt/reductions/par_reductions.hpp	(working copy)
@@ -23,7 +23,17 @@
 namespace impl
 {
 
-template <template <typename> class ReduceT,
+template <template <typename> class ReduceT>
+struct ReduceOp { typedef Op_reduce_idx<ReduceT> reduce_op; };
+
+template <>
+struct ReduceOp<Min_magsq_value >
+  { typedef Op_reduce_idx<Min_value> reduce_op; };
+template <>
+struct ReduceOp<Max_magsq_value >
+  { typedef Op_reduce_idx<Max_value> reduce_op; };
+
+template <typename                  ReduceT,
           typename                  T,
           dimension_type            dim,
 	  typename                  Block>
@@ -35,8 +45,8 @@
 		order_type;
 
   General_dispatch<
-		impl::Op_reduce_idx<ReduceT>,
-		typename ReduceT<T>::result_type,
+		ReduceT,
+		T,
 		impl::Op_list_3<Block const&,
                                 Index<dim>&,
                                 order_type>,
@@ -75,10 +85,13 @@
   vect_type                               results(a_proc_set.size(),map);
   vect_idx_type                           results_idx(a_proc_set.size(),map);
 
+  Vector<typename Block::value_type> temp_vect(get_local_block(a));
   if(a.map().subblock() != no_subblock) 
   {
-    results.local().put(0,
-      reduce_idx_blk<ReduceT,T>(get_local_block(a),my_res_idx));
+    typename ReduceT<T>::result_type result = 
+      reduce_idx_blk<Op_reduce_idx<ReduceT>,typename ReduceT<T>::result_type>
+        (get_local_block(a),my_res_idx);
+    results.local().put(0,result);
     my_g_res_idx = global_from_local_index_blk(a,my_res_idx);
     results_idx.local().put(0,my_g_res_idx);
   }
@@ -93,7 +106,8 @@
   global_results     = results;
   global_results_idx = results_idx;
 
-  global_res = reduce_idx_blk<ReduceT,T>
+  global_res = reduce_idx_blk<typename ReduceOp<ReduceT>::reduce_op,
+                              typename ReduceT<T>::result_type>
       (global_results.block(),global_res_idx);
   idx = global_results_idx.get(global_res_idx[0]);
 
