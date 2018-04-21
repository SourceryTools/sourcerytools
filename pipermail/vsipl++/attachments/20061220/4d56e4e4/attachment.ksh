Index: ChangeLog
===================================================================
--- ChangeLog	(revision 158197)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2006-12-20  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/*: Add check to make sure optimized headers aren't
+	  accidentally used in ref-impl.
+	
+2006-12-20  Jules Bergmann  <jules@codesourcery.com>
+
 	Move Ext_data_dist into core.
 	* src/vsip/opt/extdata_local.hpp: Rename to ...
 	* src/vsip/core/extdata_dist.hpp: ... this.  Rename Ext_data_local
Index: src/vsip/core/solver/svd.hpp
===================================================================
--- src/vsip/core/solver/svd.hpp	(revision 157392)
+++ src/vsip/core/solver/svd.hpp	(working copy)
@@ -20,9 +20,9 @@
 #include <vsip/matrix.hpp>
 #include <vsip/math.hpp>
 #include <vsip/core/math_enum.hpp>
-#include <vsip/opt/lapack/bindings.hpp>
 #include <vsip/core/temp_buffer.hpp>
 #ifdef VSIP_IMPL_HAVE_LAPACK
+#  include <vsip/opt/lapack/bindings.hpp>
 #  include <vsip/opt/lapack/svd.hpp>
 #endif
 #ifdef VSIP_IMPL_HAVE_SAL
Index: src/vsip/core/solver/qr.hpp
===================================================================
--- src/vsip/core/solver/qr.hpp	(revision 157392)
+++ src/vsip/core/solver/qr.hpp	(working copy)
@@ -19,11 +19,11 @@
 #include <vsip/support.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/core/math_enum.hpp>
-#include <vsip/opt/lapack/bindings.hpp>
 #include <vsip/core/temp_buffer.hpp>
 #include <vsip/core/working_view.hpp>
 #include <vsip/core/solver/common.hpp>
 #ifdef VSIP_IMPL_HAVE_LAPACK
+#  include <vsip/opt/lapack/bindings.hpp>
 #  include <vsip/opt/lapack/qr.hpp>
 #endif
 #ifdef VSIP_IMPL_HAVE_SAL
Index: src/vsip/opt/fft/workspace.hpp
===================================================================
--- src/vsip/opt/fft/workspace.hpp	(revision 157392)
+++ src/vsip/opt/fft/workspace.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_FFT_WORKSPACE_HPP
 #define VSIP_OPT_FFT_WORKSPACE_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/bridge_util.hpp
===================================================================
--- src/vsip/opt/sal/bridge_util.hpp	(revision 157392)
+++ src/vsip/opt/sal/bridge_util.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_SAL_BRIDGE_UTIL_HPP
 #define VSIP_OPT_SAL_BRIDGE_UTIL_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/svd.hpp
===================================================================
--- src/vsip/opt/sal/svd.hpp	(revision 157392)
+++ src/vsip/opt/sal/svd.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_SAL_SOLVER_SVD_HPP
 #define VSIP_IMPL_SAL_SOLVER_SVD_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/bindings.hpp
===================================================================
--- src/vsip/opt/sal/bindings.hpp	(revision 157392)
+++ src/vsip/opt/sal/bindings.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_SAL_BINDINGS_HPP
 #define VSIP_OPT_SAL_BINDINGS_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/eval_threshold.hpp
===================================================================
--- src/vsip/opt/sal/eval_threshold.hpp	(revision 157392)
+++ src/vsip/opt/sal/eval_threshold.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_OPT_SAL_EVAL_THRESHOLD_HPP
 #define VSIP_OPT_SAL_EVAL_THRESHOLD_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/conv.hpp
===================================================================
--- src/vsip/opt/sal/conv.hpp	(revision 158197)
+++ src/vsip/opt/sal/conv.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_OPT_SAL_CONV_HPP
 #define VSIP_OPT_SAL_CONV_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/eval_vcmp.hpp
===================================================================
--- src/vsip/opt/sal/eval_vcmp.hpp	(revision 157392)
+++ src/vsip/opt/sal/eval_vcmp.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_OPT_SAL_EVAL_VCMP_HPP
 #define VSIP_OPT_SAL_EVAL_VCMP_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/is_op_supported.hpp
===================================================================
--- src/vsip/opt/sal/is_op_supported.hpp	(revision 157392)
+++ src/vsip/opt/sal/is_op_supported.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_OPT_SAL_IS_OP_SUPPORTED_HPP
 #define VSIP_OPT_SAL_IS_OP_SUPPORTED_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/fft.hpp
===================================================================
--- src/vsip/opt/sal/fft.hpp	(revision 157392)
+++ src/vsip/opt/sal/fft.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_SAL_FFT_HPP
 #define VSIP_IMPL_SAL_FFT_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/reductions.hpp
===================================================================
--- src/vsip/opt/sal/reductions.hpp	(revision 157392)
+++ src/vsip/opt/sal/reductions.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_SAL_REDUCTIONS_HPP
 #define VSIP_IMPL_SAL_REDUCTIONS_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/lu.hpp
===================================================================
--- src/vsip/opt/sal/lu.hpp	(revision 157392)
+++ src/vsip/opt/sal/lu.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_SAL_SOLVER_LU_HPP
 #define VSIP_IMPL_SAL_SOLVER_LU_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/cholesky.hpp
===================================================================
--- src/vsip/opt/sal/cholesky.hpp	(revision 157392)
+++ src/vsip/opt/sal/cholesky.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_SAL_SOLVER_CHOLESKY_HPP
 #define VSIP_IMPL_SAL_SOLVER_CHOLESKY_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/elementwise.hpp
===================================================================
--- src/vsip/opt/sal/elementwise.hpp	(revision 157392)
+++ src/vsip/opt/sal/elementwise.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_SAL_ELEMENTWISE_HPP
 #define VSIP_OPT_SAL_ELEMENTWISE_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/qr.hpp
===================================================================
--- src/vsip/opt/sal/qr.hpp	(revision 157392)
+++ src/vsip/opt/sal/qr.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_SAL_SOLVER_QR_HPP
 #define VSIP_IMPL_SAL_SOLVER_QR_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/eval_util.hpp
===================================================================
--- src/vsip/opt/sal/eval_util.hpp	(revision 157392)
+++ src/vsip/opt/sal/eval_util.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_OPT_SAL_EVAL_UTIL_HPP
 #define VSIP_OPT_SAL_EVAL_UTIL_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/eval_reductions.hpp
===================================================================
--- src/vsip/opt/sal/eval_reductions.hpp	(revision 157392)
+++ src/vsip/opt/sal/eval_reductions.hpp	(working copy)
@@ -11,6 +11,10 @@
 #ifndef VSIP_IMPL_SAL_EVAL_REDUCTIONS_HPP
 #define VSIP_IMPL_SAL_EVAL_REDUCTIONS_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/sal/eval_elementwise.hpp
===================================================================
--- src/vsip/opt/sal/eval_elementwise.hpp	(revision 157392)
+++ src/vsip/opt/sal/eval_elementwise.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_OPT_SAL_EVAL_ELEMENTWISE_HPP
 #define VSIP_OPT_SAL_EVAL_ELEMENTWISE_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/extdata.hpp
===================================================================
--- src/vsip/opt/extdata.hpp	(revision 157392)
+++ src/vsip/opt/extdata.hpp	(working copy)
@@ -14,7 +14,7 @@
 #define VSIP_OPT_EXTDATA_HPP
 
 #if VSIP_IMPL_REF_IMPL
-#  error "vsip/opt/extdata.hpp is not part of reference implementation."
+# error "vsip/opt files cannot be used as part of the reference impl."
 #endif
 
 /***********************************************************************
Index: src/vsip/opt/fast_transpose.hpp
===================================================================
--- src/vsip/opt/fast_transpose.hpp	(revision 157392)
+++ src/vsip/opt/fast_transpose.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_FAST_TRANSPOSE_HPP
 #define VSIP_IMPL_FAST_TRANSPOSE_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Includes & Macros
 ***********************************************************************/
Index: src/vsip/opt/pas/block.hpp
===================================================================
--- src/vsip/opt/pas/block.hpp	(revision 157392)
+++ src/vsip/opt/pas/block.hpp	(working copy)
@@ -1,15 +1,19 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/impl/pas-block.hpp
+/** @file    vsip/opt/pas_block.hpp
     @author  Jules Bergmann
     @date    2006-06-22
     @brief   VSIPL++ Library: Distributed block class.
 
 */
 
-#ifndef VSIP_IMPL_PAS_BLOCK_HPP
-#define VSIP_IMPL_PAS_BLOCK_HPP
+#ifndef VSIP_OPT_PAS_BLOCK_HPP
+#define VSIP_OPT_PAS_BLOCK_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -1046,4 +1050,4 @@
 
 #undef VSIP_IMPL_PAS_BLOCK_VERBOSE
 
-#endif // VSIP_IMPL_PAS_BLOCK_HPP
+#endif // VSIP_OPT_PAS_BLOCK_HPP
Index: src/vsip/opt/pas/assign_eb.hpp
===================================================================
--- src/vsip/opt/pas/assign_eb.hpp	(revision 157392)
+++ src/vsip/opt/pas/assign_eb.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_PAR_ASSIGN_PAS_EB_HPP
 #define VSIP_IMPL_PAR_ASSIGN_PAS_EB_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/pas/util.hpp
===================================================================
--- src/vsip/opt/pas/util.hpp	(revision 157392)
+++ src/vsip/opt/pas/util.hpp	(working copy)
@@ -1,14 +1,18 @@
 /* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/impl/pas/util.hpp
+/** @file    vsip/opt/pas/util.hpp
     @author  Jules Bergmann
     @date    2006-08-29
     @brief   VSIPL++ Library: Parallel Services: PAS utilities
 */
 
-#ifndef VSIP_IMPL_PAS_UTIL_HPP
-#define VSIP_IMPL_PAS_UTIL_HPP
+#ifndef VSIP_OPT_PAS_UTIL_HPP
+#define VSIP_OPT_PAS_UTIL_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -59,4 +63,4 @@
 } // namespace vsip::impl::pas
 } // namespace vsip::impl
 } // namespace vsip
-#endif // VSIP_IMPL_PAS_UTIL_HPP
+#endif // VSIP_OPT_PAS_UTIL_HPP
Index: src/vsip/opt/pas/assign_direct.hpp
===================================================================
--- src/vsip/opt/pas/assign_direct.hpp	(revision 157392)
+++ src/vsip/opt/pas/assign_direct.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_PAS_ASSIGN_DIRECT_HPP
 #define VSIP_OPT_PAS_ASSIGN_DIRECT_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/pas/param.hpp
===================================================================
--- src/vsip/opt/pas/param.hpp	(revision 157392)
+++ src/vsip/opt/pas/param.hpp	(working copy)
@@ -1,17 +1,27 @@
 /* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/impl/pas/param.hpp
+/** @file    vsip/opt/pas/param.hpp
     @author  Jules Bergmann
     @date    2006-08-09
     @brief   VSIPL++ Library: Parallel Services: PAS parameters
 
 */
 
-#ifndef VSIP_IMPL_PAS_PARAM_HPP
-#define VSIP_IMPL_PAS_PARAM_HPP
+#ifndef VSIP_PAS_PAS_PARAM_HPP
+#define VSIP_PAS_PAS_PARAM_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
 #include <vsip/core/config.hpp>
 
+
+
 /***********************************************************************
   Macros
 ***********************************************************************/
@@ -64,4 +74,4 @@
      abort();								\
   }
 
-#endif // VSIP_IMPL_PAS_PARAM_HPP
+#endif // VSIP_PAS_PAS_PARAM_HPP
Index: src/vsip/opt/pas/broadcast.hpp
===================================================================
--- src/vsip/opt/pas/broadcast.hpp	(revision 157392)
+++ src/vsip/opt/pas/broadcast.hpp	(working copy)
@@ -1,15 +1,19 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/impl/pas_broadcast.hpp
+/** @file    vsip/opt/broadcast.hpp
     @author  Jules Bergmann
     @date    2005-08-23
     @brief   VSIPL++ Library: PAS Broadcast.
 
 */
 
-#ifndef VSIP_IMPL_PAS_BROADCAST_HPP
-#define VSIP_IMPL_PAS_BROADCAST_HPP
+#ifndef VSIP_OPT_PAS_BROADCAST_HPP
+#define VSIP_OPT_PAS_BROADCAST_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -172,4 +176,4 @@
 } // namespace vsip::impl
 } // namespace vsip
 
-#endif // VSIP_IMPL_PAS_BROADCAST_HPP
+#endif // VSIP_OPT_PAS_BROADCAST_HPP
Index: src/vsip/opt/pas/services.hpp
===================================================================
--- src/vsip/opt/pas/services.hpp	(revision 157392)
+++ src/vsip/opt/pas/services.hpp	(working copy)
@@ -1,15 +1,19 @@
 /* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/impl/par-services-pas.hpp
+/** @file    vsip/opt/pas/services.hpp
     @author  Jules Bergmann
     @date    2006-06-21
     @brief   VSIPL++ Library: Parallel Services: PAS
 
 */
 
-#ifndef VSIP_IMPL_PAR_SERVICES_PAS_HPP
-#define VSIP_IMPL_PAR_SERVICES_PAS_HPP
+#ifndef VSIP_OPT_PAS_SERVICES_HPP
+#define VSIP_OPT_PAS_SERVICES_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 // Only par-services-xxx.hpp header should be included
 #ifdef VSIP_IMPL_PAR_SERVICES_UNIQUE
 #  error "Only one par-services-xxx.hpp should be included"
@@ -710,4 +714,4 @@
 } // namespace vsip::impl
 } // namespace vsip
 
-#endif // VSIP_IMPL_PAR_SERVICES_PAS_HPP
+#endif // VSIP_OPT_PAS_SERVICES_HPP
Index: src/vsip/opt/pas/assign.hpp
===================================================================
--- src/vsip/opt/pas/assign.hpp	(revision 157392)
+++ src/vsip/opt/pas/assign.hpp	(working copy)
@@ -1,15 +1,19 @@
 /* Copyright (c)  2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/impl/par_assign_pas.hpp
+/** @file    vsip/opt/pas/assign.hpp
     @author  Jules Bergmann
     @date    2005-06-22
     @brief   VSIPL++ Library: Parallel assignment algorithm for PAS.
 
 */
 
-#ifndef VSIP_IMPL_PAR_ASSIGN_PAS_HPP
-#define VSIP_IMPL_PAR_ASSIGN_PAS_HPP
+#ifndef VSIP_OPT_PAS_ASSIGN_HPP
+#define VSIP_OPT_PAS_ASSIGN_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -258,4 +262,4 @@
 
 } // namespace vsip
 
-#endif // VSIP_IMPL_PAR_ASSIGN_PAS_HPP
+#endif // VSIP_OPT_PAS_ASSIGN_HPP
Index: src/vsip/opt/pas/offset.hpp
===================================================================
--- src/vsip/opt/pas/offset.hpp	(revision 157392)
+++ src/vsip/opt/pas/offset.hpp	(working copy)
@@ -1,14 +1,18 @@
 /* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/impl/offset.hpp
+/** @file    vsip/opt/pas/offset.hpp
     @author  Jules Bergmann
     @date    2006-09-01
     @brief   VSIPL++ Library: Offset class.
 */
 
-#ifndef VSIP_IMPL_OFFSET_HPP
-#define VSIP_IMPL_OFFSET_HPP
+#ifndef VSIP_OPT_PAS_OFFSET_HPP
+#define VSIP_OPT_PAS_OFFSET_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -81,4 +85,4 @@
 } // namespace vsip::impl
 } // namespace vsip
 
-#endif // VSIP_IMPL_OFFSET_HPP
+#endif // VSIP_OPT_PAS_OFFSET_HPP
Index: src/vsip/opt/rt_extdata.hpp
===================================================================
--- src/vsip/opt/rt_extdata.hpp	(revision 157392)
+++ src/vsip/opt/rt_extdata.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_RT_EXTDATA_HPP
 #define VSIP_OPT_RT_EXTDATA_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/dispatch.hpp
===================================================================
--- src/vsip/opt/dispatch.hpp	(revision 157392)
+++ src/vsip/opt/dispatch.hpp	(working copy)
@@ -9,8 +9,22 @@
 #ifndef VSIP_OPT_DISPATCH_HPP
 #define VSIP_OPT_DISPATCH_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
 #include <vsip/support.hpp>
 
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
 namespace vsip
 {
 namespace impl
Index: src/vsip/opt/us_block.hpp
===================================================================
--- src/vsip/opt/us_block.hpp	(revision 157392)
+++ src/vsip/opt/us_block.hpp	(working copy)
@@ -1,14 +1,14 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/opt/us_block.hpp
+/** @file    vsip/core/us_block.hpp
     @author  Jules Bergmann
     @date    2006-01-31
     @brief   VSIPL++ Library: User-storage block class.
 
 */
 
-#ifndef VSIP_OPT_US_BLOCK_HPP
-#define VSIP_OPT_US_BLOCK_HPP
+#ifndef VSIP_CORE_US_BLOCK_HPP
+#define VSIP_CORE_US_BLOCK_HPP
 
 /***********************************************************************
   Included Files
@@ -417,4 +417,4 @@
 
 } // namespace vsip
 
-#endif // VSIP_IMPL_US_BLOCK_HPP
+#endif // VSIP_CORE_US_BLOCK_HPP
Index: src/vsip/opt/ipp/bindings.hpp
===================================================================
--- src/vsip/opt/ipp/bindings.hpp	(revision 157392)
+++ src/vsip/opt/ipp/bindings.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_IMPL_IPP_HPP
 #define VSIP_IMPL_IPP_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/ipp/fft.hpp
===================================================================
--- src/vsip/opt/ipp/fft.hpp	(revision 157392)
+++ src/vsip/opt/ipp/fft.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_IPP_FFT_HPP
 #define VSIP_IMPL_IPP_FFT_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/ipp/fir.hpp
===================================================================
--- src/vsip/opt/ipp/fir.hpp	(revision 157392)
+++ src/vsip/opt/ipp/fir.hpp	(working copy)
@@ -9,10 +9,24 @@
 #ifndef VSIP_OPT_IPP_FIR_HPP
 #define VSIP_OPT_IPP_FIR_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
 #include <vsip/support.hpp>
 #include <vsip/core/signal/fir_backend.hpp>
 #include <vsip/opt/dispatch.hpp>
 
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
 namespace vsip
 {
 namespace impl
Index: src/vsip/opt/ipp/conv.hpp
===================================================================
--- src/vsip/opt/ipp/conv.hpp	(revision 157392)
+++ src/vsip/opt/ipp/conv.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_IMPL_SIGNAL_CONV_IPP_HPP
 #define VSIP_IMPL_SIGNAL_CONV_IPP_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/fftw3/fft.hpp
===================================================================
--- src/vsip/opt/fftw3/fft.hpp	(revision 157392)
+++ src/vsip/opt/fftw3/fft.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_OPT_FFTW3_FFT_HPP
 #define VSIP_OPT_FFTW3_FFT_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/lapack/svd.hpp
===================================================================
--- src/vsip/opt/lapack/svd.hpp	(revision 157392)
+++ src/vsip/opt/lapack/svd.hpp	(working copy)
@@ -1,15 +1,19 @@
 /* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    vsip/impl/lapack/solver_svd.hpp
+/** @file    vsip/opt/lapack/svd.hpp
     @author  Assem Salama
     @date    2006-04-25
     @brief   VSIPL++ Library: SVD Linear system solver.
 
 */
 
-#ifndef VSIP_IMPL_SOLVER_LAPACK_SVD_HPP
-#define VSIP_IMPL_SOLVER_LAPACK_SVD_HPP
+#ifndef VSIP_OPT_LAPACK_SVD_HPP
+#define VSIP_OPT_LAPACK_SVD_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -663,4 +667,4 @@
 
 } // namespace vsip
 
-#endif // VSIP_IMPL_LAPACK_SOLVER_SVD_HPP
+#endif // VSIP_OPT_LAPACK_SVD_HPP
Index: src/vsip/opt/lapack/bindings.hpp
===================================================================
--- src/vsip/opt/lapack/bindings.hpp	(revision 157392)
+++ src/vsip/opt/lapack/bindings.hpp	(working copy)
@@ -22,6 +22,10 @@
 #ifndef VSIP_OPT_LAPACK_MISC_HPP
 #define VSIP_OPT_LAPACK_MISC_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/lapack/matvec.hpp
===================================================================
--- src/vsip/opt/lapack/matvec.hpp	(revision 157392)
+++ src/vsip/opt/lapack/matvec.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_LAPACK_MATVEC_HPP
 #define VSIP_OPT_LAPACK_MATVEC_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/lapack/acml_cblas.hpp
===================================================================
--- src/vsip/opt/lapack/acml_cblas.hpp	(revision 157392)
+++ src/vsip/opt/lapack/acml_cblas.hpp	(working copy)
@@ -1,6 +1,6 @@
 /* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    vsip/impl/acml_cblas.hpp
+/** @file    vsip/opt/lapack/acml_cblas.hpp
     @author  Jules Bergmann
     @date    2005-08-19
     @brief   VSIPL++ Library: ACML CBLAS wrappers.
@@ -10,9 +10,13 @@
     same name.  This file provides CBLAS bindings to ACML.
 */
 
-#ifndef VSIP_IMPL_ACML_CBLAS_HPP
-#define VSIP_IMPL_ACML_CBLAS_HPP
+#ifndef VSIP_OPT_LAPACK_ACML_CBLAS_HPP
+#define VSIP_OPT_LAPACK_ACML_CBLAS_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -100,4 +104,4 @@
   *reinterpret_cast<std::complex<double>*>(dotc) = zdotc(n, x, incx, y, incy);
 }
 
-#endif // VSIP_IMPL_ACML_CBLAS_HPP
+#endif // VSIP_OPT_LAPACK_ACML_CBLAS_HPP
Index: src/vsip/opt/lapack/lu.hpp
===================================================================
--- src/vsip/opt/lapack/lu.hpp	(revision 157392)
+++ src/vsip/opt/lapack/lu.hpp	(working copy)
@@ -1,15 +1,19 @@
 /* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    vsip/impl/lapack/solver_lu.hpp
+/** @file    vsip/core/lapack/lu.hpp
     @author  Assem Salama
     @date    2006-04-13
     @brief   VSIPL++ Library: LU linear system solver using lapack.
 
 */
 
-#ifndef VSIP_IMPL_LAPACK_SOLVER_LU_HPP
-#define VSIP_IMPL_LAPACK_SOLVER_LU_HPP
+#ifndef VSIP_CORE_LAPACK_LU_HPP
+#define VSIP_CORE_LAPACK_LU_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -231,4 +235,4 @@
 } // namespace vsip
 
 
-#endif // VSIP_IMPL_LAPACK_SOLVER_LU_HPP
+#endif // VSIP_CORE_LAPACK_LU_HPP
Index: src/vsip/opt/lapack/cholesky.hpp
===================================================================
--- src/vsip/opt/lapack/cholesky.hpp	(revision 157392)
+++ src/vsip/opt/lapack/cholesky.hpp	(working copy)
@@ -1,15 +1,19 @@
 /* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    vsip/impl/lapack/solver_cholesky.hpp
+/** @file    vsip/opt/lapack/cholesky.hpp
     @author  Assem Salama
     @date    2006-04-13
     @brief   VSIPL++ Library: Cholesky Linear system solver using LAPACK.
 
 */
 
-#ifndef VSIP_IMPL_LAPACK_SOLVER_CHOLESKY_HPP
-#define VSIP_IMPL_LAPACK_SOLVER_CHOLESKY_HPP
+#ifndef VSIP_OPT_LAPACK_CHOLESKY_HPP
+#define VSIP_OPT_LAPACK_CHOLESKY_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -198,4 +202,4 @@
 } // namespace vsip
 
 
-#endif // VSIP_IMPL_LAPACK_SOLVER_CHOLESKY_HPP
+#endif // VSIP_OPT_LAPACK_CHOLESKY_HPP
Index: src/vsip/opt/lapack/qr.hpp
===================================================================
--- src/vsip/opt/lapack/qr.hpp	(revision 157392)
+++ src/vsip/opt/lapack/qr.hpp	(working copy)
@@ -7,9 +7,13 @@
 
 */
 
-#ifndef VSIP_IMPL_LAPACK_SOLVER_QR_HPP
-#define VSIP_IMPL_LAPACK_SOLVER_QR_HPP
+#ifndef VSIP_OPT_LAPACK_QR_HPP
+#define VSIP_OPT_LAPACK_QR_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -520,4 +524,4 @@
 } // namespace vsip
 
 
-#endif // VSIP_IMPL_LAPACK_SOLVER_QR_HPP
+#endif // VSIP_OPT_LAPACK_QR_HPP
Index: src/vsip/opt/parallel/proxy_local_block.hpp
===================================================================
--- src/vsip/opt/parallel/proxy_local_block.hpp	(revision 157392)
+++ src/vsip/opt/parallel/proxy_local_block.hpp	(working copy)
@@ -1,14 +1,14 @@
 /* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    vsip/opt/proxy_local_block.hpp
+/** @file    vsip/core/proxy_local_block.hpp
     @author  Jules Bergmann
     @date    2005-08-21
     @brief   VSIPL++ Library: ...
 
 */
 
-#ifndef VSIP_OPT_PROXY_LOCAL_BLOCK_HPP
-#define VSIP_OPT_PROXY_LOCAL_BLOCK_HPP
+#ifndef VSIP_CORE_PROXY_LOCAL_BLOCK_HPP
+#define VSIP_CORE_PROXY_LOCAL_BLOCK_HPP
 
 /***********************************************************************
   Included Files
@@ -130,4 +130,4 @@
 
 
 
-#endif // VSIP_IMPL_PROXY_LOCAL_BLOCK_HPP
+#endif // VSIP_CORE_PROXY_LOCAL_BLOCK_HPP
Index: src/vsip/opt/parallel/foreach.hpp
===================================================================
--- src/vsip/opt/parallel/foreach.hpp	(revision 157392)
+++ src/vsip/opt/parallel/foreach.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_PARALLEL_FOREACH_HPP
 #define VSIP_OPT_PARALLEL_FOREACH_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/simd/rscvmul.hpp
===================================================================
--- src/vsip/opt/simd/rscvmul.hpp	(revision 157392)
+++ src/vsip/opt/simd/rscvmul.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_SIMD_RSCVMUL_HPP
 #define VSIP_OPT_SIMD_RSCVMUL_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 157392)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_SIMD_HPP
 #define VSIP_IMPL_SIMD_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/simd/vadd.hpp
===================================================================
--- src/vsip/opt/simd/vadd.hpp	(revision 157392)
+++ src/vsip/opt/simd/vadd.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_SIMD_VADD_HPP
 #define VSIP_OPT_SIMD_VADD_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/opt/simd/expr_evaluator.hpp	(revision 157392)
+++ src/vsip/opt/simd/expr_evaluator.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_SIMD_EXPR_EVALUATOR_HPP
 #define VSIP_IMPL_SIMD_EXPR_EVALUATOR_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/simd/vgt.hpp
===================================================================
--- src/vsip/opt/simd/vgt.hpp	(revision 157392)
+++ src/vsip/opt/simd/vgt.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_SIMD_VGT_HPP
 #define VSIP_OPT_SIMD_VGT_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/simd/vlogic.hpp
===================================================================
--- src/vsip/opt/simd/vlogic.hpp	(revision 157392)
+++ src/vsip/opt/simd/vlogic.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_SIMD_VLOGIC_HPP
 #define VSIP_OPT_SIMD_VLOGIC_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/simd/vmul.hpp
===================================================================
--- src/vsip/opt/simd/vmul.hpp	(revision 157392)
+++ src/vsip/opt/simd/vmul.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_SIMD_VMUL_HPP
 #define VSIP_OPT_SIMD_VMUL_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/simd/eval_generic.hpp
===================================================================
--- src/vsip/opt/simd/eval_generic.hpp	(revision 157392)
+++ src/vsip/opt/simd/eval_generic.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_IMPL_SIMD_EVAL_GENERIC_HPP
 #define VSIP_IMPL_SIMD_EVAL_GENERIC_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/simd/expr_iterator.hpp
===================================================================
--- src/vsip/opt/simd/expr_iterator.hpp	(revision 157392)
+++ src/vsip/opt/simd/expr_iterator.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_IMPL_SIMD_EXPR_ITERATOR_HPP
 #define VSIP_IMPL_SIMD_EXPR_ITERATOR_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 157392)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_OPT_DIAG_EVAL_HPP
 #define VSIP_OPT_DIAG_EVAL_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/signal/fir_opt.hpp
===================================================================
--- src/vsip/opt/signal/fir_opt.hpp	(revision 157392)
+++ src/vsip/opt/signal/fir_opt.hpp	(working copy)
@@ -9,6 +9,14 @@
 #ifndef VSIP_OPT_SIGNAL_FIR_OPT_HPP
 #define VSIP_OPT_SIGNAL_FIR_OPT_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
 #include <vsip/support.hpp>
 #include <vsip/core/signal/fir_backend.hpp>
 #include <vsip/opt/dispatch.hpp>
@@ -16,6 +24,12 @@
 #include <vsip/domain.hpp>
 #include <vsip/core/view_traits.hpp>
 
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
 namespace vsip
 {
 namespace impl
Index: src/vsip/opt/signal/conv_ext.hpp
===================================================================
--- src/vsip/opt/signal/conv_ext.hpp	(revision 158197)
+++ src/vsip/opt/signal/conv_ext.hpp	(working copy)
@@ -1,6 +1,6 @@
 /* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    vsip/opt/signal/conv-ext.hpp
+/** @file    vsip/opt/signal/conv_ext.hpp
     @author  Jules Bergmann
     @date    2005-06-09
     @brief   VSIPL++ Library: Convolution class implementation using Ext_data.
@@ -9,6 +9,10 @@
 #ifndef VSIP_OPT_SIGNAL_CONV_EXT_HPP
 #define VSIP_OPT_SIGNAL_CONV_EXT_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/signal/corr_ext.hpp
===================================================================
--- src/vsip/opt/signal/corr_ext.hpp	(revision 158197)
+++ src/vsip/opt/signal/corr_ext.hpp	(working copy)
@@ -1,14 +1,18 @@
 /* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    vsip/core/signal/corr-ext.hpp
+/** @file    vsip/opt/signal/corr_ext.hpp
     @author  Jules Bergmann
     @date    2005-10-05
     @brief   VSIPL++ Library: Correlation class implementation using Ext_data.
 */
 
-#ifndef VSIP_CORE_SIGNAL_CORR_EXT_HPP
-#define VSIP_CORE_SIGNAL_CORR_EXT_HPP
+#ifndef VSIP_OPT_SIGNAL_CORR_EXT_HPP
+#define VSIP_OPT_SIGNAL_CORR_EXT_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -354,4 +358,4 @@
 } // namespace vsip::impl
 } // namespace vsip
 
-#endif // VSIP_IMPL_SIGNAL_CORR_EXT_HPP
+#endif // VSIP_OPT_SIGNAL_CORR_EXT_HPP
Index: src/vsip/opt/signal/corr_opt.hpp
===================================================================
--- src/vsip/opt/signal/corr_opt.hpp	(revision 157392)
+++ src/vsip/opt/signal/corr_opt.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/opt/signal/corr-opt.hpp
     @author  Jules Bergmann
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_SIGNAL_CORR_OPT_HPP
 #define VSIP_OPT_SIGNAL_CORR_OPT_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/expr/ops_info.hpp
===================================================================
--- src/vsip/opt/expr/ops_info.hpp	(revision 157392)
+++ src/vsip/opt/expr/ops_info.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_EXPR_OPS_INFO_HPP
 #define VSIP_OPT_EXPR_OPS_INFO_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/expr/serial_dispatch.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch.hpp	(revision 157392)
+++ src/vsip/opt/expr/serial_dispatch.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_EXPR_SERIAL_DISPATCH_HPP
 #define VSIP_OPT_EXPR_SERIAL_DISPATCH_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/expr/serial_dispatch_fwd.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch_fwd.hpp	(revision 157392)
+++ src/vsip/opt/expr/serial_dispatch_fwd.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_OPT_EXPR_SERIAL_DISPATCH_FWD_HPP
 #define VSIP_OPT_EXPR_SERIAL_DISPATCH_FWD_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/expr/serial_evaluator.hpp
===================================================================
--- src/vsip/opt/expr/serial_evaluator.hpp	(revision 157392)
+++ src/vsip/opt/expr/serial_evaluator.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_OPT_EXPR_SERIAL_EVALUATOR_HPP
 #define VSIP_OPT_EXPR_SERIAL_EVALUATOR_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
Index: src/vsip/opt/expr/eval_dense.hpp
===================================================================
--- src/vsip/opt/expr/eval_dense.hpp	(revision 157392)
+++ src/vsip/opt/expr/eval_dense.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_EXPR_EVAL_DENSE_HPP
 #define VSIP_OPT_EXPR_EVAL_DENSE_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
