Index: src/vsip/core/solver/llsqsol.hpp
===================================================================
--- src/vsip/core/solver/llsqsol.hpp	(revision 217743)
+++ src/vsip/core/solver/llsqsol.hpp	(working copy)
@@ -60,31 +60,23 @@
   assert(x.size(1) == p);
     
 
-  // These two methods produce equivalent results.  However, the second
-  // method requires full-QR, which not all backends provide.
+  storage_type qrd_type;
 
-#if VSIP_IMPL_USE_QRD_LSQSOL
-  qrd<T, by_reference> qr(m, n, qrd_saveq1);
-    
+  // Determine whether to use skinny or full QR.
+  if (impl::Qrd_traits<qrd<T, by_reference> >::supports_qrd_saveq1)
+    qrd_type = qrd_saveq1;
+  else if (impl::Qrd_traits<qrd<T, by_reference> >::supports_qrd_saveq)
+    qrd_type = qrd_saveq;
+  else
+    VSIP_IMPL_THROW(impl::unimplemented(
+	      "llsqsol: qrd supports neither qrd_saveq1 or qrd_saveq"));
+  
+  qrd<T, by_reference> qr(m, n, qrd_type);
+  
   qr.decompose(a);
-
+  
   qr.lsqsol(b, x);
-#else
-  qrd<T, by_reference> qr(m, n, qrd_saveq);
-    
-  qr.decompose(a);
 
-  mat_op_type const tr = impl::Is_complex<T>::value ? mat_herm : mat_trans;
-    
-  Matrix<T> c(m, p);
-    
-  // 1. compute C = Q'B:     R X = C
-  qr.template prodq<tr, mat_lside>(b, c);
-  
-  // 2. solve for X:         R X = C
-  qr.template rsol<mat_ntrans>(c(Domain<2>(n, p)), T(1), x);
-#endif
-  
   return x;
 }
 
Index: src/vsip/core/solver/qr.hpp
===================================================================
--- src/vsip/core/solver/qr.hpp	(revision 217743)
+++ src/vsip/core/solver/qr.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/solver/qr.hpp
     @author  Jules Bergmann
@@ -23,7 +23,6 @@
 #include <vsip/core/working_view.hpp>
 #include <vsip/core/solver/common.hpp>
 #ifdef VSIP_IMPL_HAVE_LAPACK
-#  include <vsip/opt/lapack/bindings.hpp>
 #  include <vsip/opt/lapack/qr.hpp>
 #endif
 #ifdef VSIP_IMPL_HAVE_SAL
@@ -91,6 +90,19 @@
 #endif
 };
 
+
+
+// Qrd traits.  Determine which QR types (no-save, skinny, full) are
+// supported.
+
+template <typename QrT>
+struct Qrd_traits
+{
+  static bool const supports_qrd_saveq1  = QrT::supports_qrd_saveq1;
+  static bool const supports_qrd_saveq   = QrT::supports_qrd_saveq;
+  static bool const supports_qrd_nosaveq = QrT::supports_qrd_nosaveq;
+};
+
 } // namespace vsip::impl
 
 /// QR solver object.
@@ -110,6 +122,9 @@
   typedef typename impl::Choose_qrd_impl<T>::use_type use_type;
   typedef impl::Qrd_impl<T,true, use_type> base_type;
 
+  // template <typename>
+  friend struct impl::Qrd_traits<qrd<T, by_reference> >;
+
   // Constructors, copies, assignments, and destructors.
 public:
   qrd(length_type rows, length_type cols, storage_type st)
Index: src/vsip/core/cvsip/qr.hpp
===================================================================
--- src/vsip/core/cvsip/qr.hpp	(revision 217743)
+++ src/vsip/core/cvsip/qr.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery inc.  All rights reserved. */
+/* Copyright (c) 2006, 2008 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/cvsip/qr.hpp
     @author  Assem Salama
@@ -74,6 +74,12 @@
   typedef Layout<2, row2_type, Stride_unit_dense, complex_type> data_LP;
   typedef Fast_block<2, T, data_LP> data_block_type;
 
+  // Qrd types supported.
+protected:
+  static bool const supports_qrd_saveq1  = true;
+  static bool const supports_qrd_saveq   = false;
+  static bool const supports_qrd_nosaveq = true;
+
   // Constructors, copies, assignments, and destructors.
 public:
   Qrd_impl(length_type, length_type, storage_type)
@@ -165,7 +171,6 @@
 {
   assert(m_ > 0 && n_ > 0 && m_ >= n_);
   assert(st_ == qrd_nosaveq || st_ == qrd_saveq || st_ == qrd_saveq1);
-
 }
 
 
Index: src/vsip/opt/sal/qr.hpp
===================================================================
--- src/vsip/opt/sal/qr.hpp	(revision 217743)
+++ src/vsip/opt/sal/qr.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -182,6 +182,12 @@
   typedef Layout<2, col2_type, Stride_unit_dense, complex_type> t_data_LP;
   typedef Fast_block<2, T, t_data_LP> t_data_block_type;
 
+  // Qrd types supported.
+protected:
+  static bool const supports_qrd_saveq1  = true;
+  static bool const supports_qrd_saveq   = false;
+  static bool const supports_qrd_nosaveq = true;
+
   // Constructors, copies, assignments, and destructors.
 public:
   Qrd_impl(length_type, length_type, storage_type)
Index: src/vsip/opt/cbe/cml/qr.hpp
===================================================================
--- src/vsip/opt/cbe/cml/qr.hpp	(revision 217743)
+++ src/vsip/opt/cbe/cml/qr.hpp	(working copy)
@@ -66,6 +66,12 @@
   typedef Layout<2, col2_type, Stride_unit_dense, complex_type> t_data_LP;
   typedef Fast_block<2, T, t_data_LP> t_data_block_type;
 
+  // Qrd types supported.
+protected:
+  static bool const supports_qrd_saveq1  = false;
+  static bool const supports_qrd_saveq   = true;
+  static bool const supports_qrd_nosaveq = true;
+
   // Constructors, copies, assignments, and destructors.
 public:
   Qrd_impl(length_type, length_type, storage_type)
Index: src/vsip/opt/lapack/qr.hpp
===================================================================
--- src/vsip/opt/lapack/qr.hpp	(revision 217743)
+++ src/vsip/opt/lapack/qr.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -67,6 +67,12 @@
   typedef Layout<2, col2_type, Stride_unit_dense, Cmplx_inter_fmt> data_LP;
   typedef Fast_block<2, T, data_LP> data_block_type;
 
+  // Qrd types supported.
+protected:
+  static bool const supports_qrd_saveq1  = true;
+  static bool const supports_qrd_saveq   = true;
+  static bool const supports_qrd_nosaveq = true;
+
   // Constructors, copies, assignments, and destructors.
 public:
   Qrd_impl(length_type, length_type, storage_type)
