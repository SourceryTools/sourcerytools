Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 191006)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -23,6 +23,12 @@
 
 #include <iostream>
 #include <iomanip>
+
+#include <vsip/support.hpp>
+#include <vsip/core/impl_tags.hpp>
+#include <vsip/core/expr/scalar_block.hpp>
+#include <vsip/opt/expr/serial_evaluator.hpp>
+#include <vsip/opt/expr/serial_dispatch_fwd.hpp>
 #include <vsip/core/dispatch_assign_decl.hpp>
 
 
Index: src/vsip/opt/expr/serial_dispatch_fwd.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch_fwd.hpp	(revision 191006)
+++ src/vsip/opt/expr/serial_dispatch_fwd.hpp	(working copy)
@@ -22,6 +22,7 @@
 ***********************************************************************/
 
 #include <vsip/core/config.hpp>
+#include <vsip/core/type_list.hpp>
 #include <vsip/opt/expr/serial_evaluator.hpp>
 
 
Index: src/vsip_csl/img/impl/sfilt_gen.hpp
===================================================================
--- src/vsip_csl/img/impl/sfilt_gen.hpp	(revision 191006)
+++ src/vsip_csl/img/impl/sfilt_gen.hpp	(working copy)
@@ -120,7 +120,7 @@
 		layout_type;
   typedef typename vsip::impl::View_of_dim<1, T, vsip::Dense<1, T> >::type
 		coeff_view_type;
-  typedef vsip::impl::Ext_data<typename coeff_view_type::block_type,
+  typedef vsip::impl::Persistent_ext_data<typename coeff_view_type::block_type,
 			       layout_type>
 		c_ext_type;
 
@@ -152,12 +152,6 @@
   Utility Definitions
 ***********************************************************************/
 
-
-
-/***********************************************************************
-  Utility Definitions
-***********************************************************************/
-
 /// Construct a convolution object.
 
 template <typename            T,
@@ -177,8 +171,8 @@
     coeff1_     (coeff1.size()),
     coeff0_ext_ (coeff0_.block(), vsip::impl::SYNC_IN),
     coeff1_ext_ (coeff1_.block(), vsip::impl::SYNC_IN),
-    pcoeff0_    (coeff0_ext_.data()),
-    pcoeff1_    (coeff1_ext_.data()),
+    pcoeff0_    (NULL),
+    pcoeff1_    (NULL),
 
     kernel_size_(vsip::Domain<2>(coeff0.size(), coeff1.size())),
     input_size_ (input_size),
@@ -188,6 +182,12 @@
   coeff0_ = coeff0;
   coeff1_ = coeff1;
 
+  coeff0_ext_.begin();
+  coeff1_ext_.begin();
+
+  pcoeff0_ = coeff0_ext_.data();
+  pcoeff1_ = coeff1_ext_.data();
+
   in_buffer_  = new T[input_size_.size()];
   out_buffer_ = new T[output_size_.size()];
   tmp_buffer_ = new T[output_size_.size()];
@@ -206,6 +206,9 @@
 ~Sfilt_impl()
   VSIP_NOTHROW
 {
+  coeff0_ext_.end();
+  coeff1_ext_.end();
+
   delete[] tmp_buffer_;
   delete[] out_buffer_;
   delete[] in_buffer_;
Index: src/vsip_csl/img/separable_filter.hpp
===================================================================
--- src/vsip_csl/img/separable_filter.hpp	(revision 191006)
+++ src/vsip_csl/img/separable_filter.hpp	(working copy)
@@ -67,8 +67,12 @@
   : public impl::Sfilt_impl<T, SuppT, EdgeT, N_times, A_hint,
 			    typename impl::Choose_sfilt_impl<2, T>::type>
 {
-  typedef impl::Sfilt_impl<T, SuppT, EdgeT, N_times, A_hint,
-			   typename impl::Choose_sfilt_impl<2, T>::type>
+  // Compile-time values and typedefs.
+public:
+  typedef typename impl::Choose_sfilt_impl<2, T>::type impl_tag;
+
+private:
+  typedef impl::Sfilt_impl<T, SuppT, EdgeT, N_times, A_hint, impl_tag>
 		base_type;
   static vsip::dimension_type const dim = 2;
 
Index: tests/vsip_csl/sfilt.cpp
===================================================================
--- tests/vsip_csl/sfilt.cpp	(revision 191006)
+++ tests/vsip_csl/sfilt.cpp	(working copy)
@@ -14,6 +14,7 @@
 
 #if VERBOSE
 #  include <iostream>
+#  include <vsip/opt/diag/eval.hpp>
 #endif
 
 #include <vsip/initfin.hpp>
@@ -97,6 +98,9 @@
   std::cout << "error: " << error << std::endl;
   if (error >= -100)
   {
+    std::cout << "BE:"
+	      << vsip::impl::diag_detail::Dispatch_name<
+                    typename filt_type::impl_tag>::name() << std::endl;
     std::cout << "k0:\n" << k0;
     std::cout << "k1:\n" << k1;
     std::cout << "ref_k:\n" << ref_k;
