Index: ChangeLog
===================================================================
--- ChangeLog	(revision 151867)
+++ ChangeLog	(working copy)
@@ -1,9 +1,30 @@
+2006-10-18  Jules Bergmann  <jules@codesourcery.com>
+
+	Use non-early-binding pas assignment algorithm for expressions.
+	* src/vsip/core/parallel/choose_assign_impl.hpp
+	  (Choose_par_assign_impl): Add EarlyBinding template parameter to
+	  select whether early-binding or dynamic assignment should be used.
+	* src/vsip/opt/dispatch_assign.hpp (Dispatch_assign_helper): Likewise.
+	* src/vsip/core/setup_assign.hpp: Use Dispatch_assign_helper with
+	  EarlyBinding = true.
+	* src/vsip/opt/parallel/expr.hpp: Use Dispatch_assign_helper with
+	  EarlyBinding = false.
+	
+	* src/vsip/opt/pas/assign.hpp: Fix bug, not setting PAS_WAIT if
+	  src and dst distributions have same dim-order; move dynamic
+	  xfer construction/destruction into object constructor/destructor
+	  (courtesy John Watson / MCS).
+	
+	* src/vsip/core/vmmul.hpp: Add missing include.
+	
 2006-10-18  Assem Salame <assem@codesourcery.com>
+	
 	* src/vsip/core/cvsip/cvsip.hpp: Fixed typo.
 	  VSIPL_IMPL_CVSIP_HAVE_DOUBLE should have been
 	  VSIPL_IMPL_CVSIP_HAVE_FLOAT.
 
 2006-10-18  Assem Salame <assem@codesourcery.com>
+	
 	* src/vsip/core/cvsip/cvsip.hpp: New file. This file implements some
 	  basic cvsip bindings for use in VSIPL++.
 
Index: src/vsip/core/setup_assign.hpp
===================================================================
--- src/vsip/core/setup_assign.hpp	(revision 151867)
+++ src/vsip/core/setup_assign.hpp	(working copy)
@@ -297,7 +297,8 @@
     typedef typename Block1::map_type map1_type;
     typedef typename Block2::map_type map2_type;
 
-    typedef typename impl::Dispatch_assign_helper<dim, Block1, Block2>::type
+    typedef typename
+      impl::Dispatch_assign_helper<dim, Block1, Block2, true>::type
       raw_dispatch_type;
 
     typedef typename
Index: src/vsip/core/vmmul.hpp
===================================================================
--- src/vsip/core/vmmul.hpp	(revision 151867)
+++ src/vsip/core/vmmul.hpp	(working copy)
@@ -18,6 +18,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/core/promote.hpp>
+#include <vsip/opt/expr/serial_evaluator.hpp>
 
 
 
Index: src/vsip/core/parallel/choose_assign_impl.hpp
===================================================================
--- src/vsip/core/parallel/choose_assign_impl.hpp	(revision 151867)
+++ src/vsip/core/parallel/choose_assign_impl.hpp	(working copy)
@@ -33,10 +33,11 @@
 // Only valid if Block1 and Block2 are simple distributed blocks.
 
 #if VSIP_IMPL_PAR_SERVICE == 0 || VSIP_IMPL_PAR_SERVICE == 1
-  // MPI
+// MPI
 template <dimension_type Dim,
 	  typename       Block1,
-	  typename       Block2>
+	  typename       Block2,
+	  bool           EarlyBinding>
 struct Choose_par_assign_impl
 {
   typedef typename Block1::map_type map1_type;
@@ -51,17 +52,21 @@
 	::type type;
 };
 #else
+// PAS
 template <dimension_type Dim,
 	  typename       Block1,
-	  typename       Block2>
+	  typename       Block2,
+	  bool           EarlyBinding>
 struct Choose_par_assign_impl
 {
   static int const  is_pas_assign = Is_pas_block<Block1>::value &&
                                     Is_pas_block<Block2>::value;
 
   typedef typename
-  ITE_Type<is_pas_assign, As_type<Pas_assign_eb>,
-                          As_type<Direct_pas_assign>
+  ITE_Type<is_pas_assign, 
+	   ITE_Type<EarlyBinding, As_type<Pas_assign_eb>,
+		                  As_type<Pas_assign> >,
+	   As_type<Direct_pas_assign>
           >::type type;
 };
 #endif
Index: src/vsip/opt/pas/assign.hpp
===================================================================
--- src/vsip/opt/pas/assign.hpp	(revision 151867)
+++ src/vsip/opt/pas/assign.hpp	(working copy)
@@ -98,9 +98,11 @@
 
     // Set default values if temporary buffer is not necessary
     // Either not in pset, or local_nbytes == 0
-    move_desc_ = NULL;
-    pull_flags_ = 0;
+    move_desc_  = NULL;
+    push_flags_ = PAS_WAIT;
 
+    rc = pas_dynamic_xfer_create(num_processors(), 3, 0, &dynamic_xfer_);
+    assert(rc == CE_SUCCESS);
 
     // Setup tmp buffer
     if (pas_pset_is_member(all_pset))
@@ -136,8 +138,6 @@
 
 	rc = pas_move_desc_set_tmp_pbuf(move_desc_, tmp_pbuf_, 0);
 	assert(rc == CE_SUCCESS);
-
-	pull_flags_ = PAS_WAIT;
       }
     }
   }
@@ -155,6 +155,9 @@
       rc = pas_pbuf_destroy(tmp_pbuf_, reserved_flags);
       assert(rc == CE_SUCCESS);
     }
+
+    rc = pas_dynamic_xfer_destroy(dynamic_xfer_, 0);
+    assert(rc == CE_SUCCESS);
   }
 
 
@@ -167,10 +170,6 @@
     PAS_id src_pset = src_.block().map().impl_ll_pset();
     PAS_id dst_pset = dst_.block().map().impl_ll_pset();
 
-    PAS_dynamic_xfer_handle dynamic_xfer=NULL;
-    rc = pas_dynamic_xfer_create(num_processors(), 3, 0, &dynamic_xfer);
-    assert(rc == CE_SUCCESS);
-
     // -------------------------------------------------------------------
     // Tell source that dst is ready
     if (pas_pset_is_member(dst_pset))
@@ -200,14 +199,14 @@
       std::cout << "[" << local_processor() << "] "
 		<< "push start" << std::endl << std::flush;
 #endif
-      rc = pas_push(dynamic_xfer, move_desc_,
+      rc = pas_push(dynamic_xfer_, move_desc_,
 		    src_.block().impl_ll_pbuf(),
 		    src_.block().impl_ll_dist(),
 		    dst_.block().impl_ll_pbuf(),
 		    dst_.block().impl_ll_dist(),
 		    pas::Pas_datatype<T1>::value(),
 		    done_sem_index_,
-		    pull_flags_ | VSIP_IMPL_PAS_XFER_ENGINE |
+		    push_flags_ | VSIP_IMPL_PAS_XFER_ENGINE |
 		    VSIP_IMPL_PAS_SEM_GIVE_AFTER,
 		    NULL); 
       assert(rc == CE_SUCCESS);
@@ -221,9 +220,6 @@
     // Wait for push to complete.
     if (pas_pset_is_member(dst_pset))
       pas::semaphore_take(src_pset, done_sem_index_);
-
-    rc = pas_dynamic_xfer_destroy(dynamic_xfer, 0);
-    assert(rc == CE_SUCCESS);
   }
 
 
@@ -232,11 +228,12 @@
   typename View_of_dim<Dim, T1, Block1>::type       dst_;
   typename View_of_dim<Dim, T2, Block2>::const_type src_;
 
-  PAS_move_desc_handle move_desc_;
-  PAS_pbuf_handle      tmp_pbuf_;
-  long                 pull_flags_;
-  long                 ready_sem_index_;
-  long                 done_sem_index_;
+  PAS_dynamic_xfer_handle dynamic_xfer_;
+  PAS_move_desc_handle    move_desc_;
+  PAS_pbuf_handle         tmp_pbuf_;
+  long                    push_flags_;
+  long                    ready_sem_index_;
+  long                    done_sem_index_;
 };
 
 /***********************************************************************
Index: src/vsip/opt/dispatch_assign.hpp
===================================================================
--- src/vsip/opt/dispatch_assign.hpp	(revision 151867)
+++ src/vsip/opt/dispatch_assign.hpp	(working copy)
@@ -58,7 +58,8 @@
 
 template <dimension_type Dim,
 	  typename       Block1,
-	  typename       Block2>
+	  typename       Block2,
+	  bool           EarlyBinding>
 struct Dispatch_assign_helper
 {
   typedef typename Block1::map_type map1_type;
@@ -81,8 +82,8 @@
   static int const  lhs_cost      = Ext_data_cost<Block1>::value;
   static int const  rhs_cost      = Ext_data_cost<Block2>::value;
 
-
-  typedef typename Choose_par_assign_impl<Dim, Block1, Block2>::type
+  typedef typename
+    Choose_par_assign_impl<Dim, Block1, Block2, EarlyBinding>::type
     par_assign_type;
 
   typedef typename
@@ -101,7 +102,7 @@
 	  typename       Block1,
 	  typename       Block2,
 	  typename       Tag
-	  = typename Dispatch_assign_helper<Dim, Block1, Block2>::type>
+	  = typename Dispatch_assign_helper<Dim, Block1, Block2, false>::type>
 struct Dispatch_assign;
 
 
Index: src/vsip/opt/parallel/expr.hpp
===================================================================
--- src/vsip/opt/parallel/expr.hpp	(revision 151867)
+++ src/vsip/opt/parallel/expr.hpp	(working copy)
@@ -85,7 +85,8 @@
   typedef typename View_of_dim<Dim, value_type, BlockT>::const_type
 		src_view_type;
 
-  typedef typename Choose_par_assign_impl<Dim, dst_block_type, BlockT>::type
+  typedef typename
+    Choose_par_assign_impl<Dim, dst_block_type, BlockT, false>::type
     par_assign_type;
 
 
