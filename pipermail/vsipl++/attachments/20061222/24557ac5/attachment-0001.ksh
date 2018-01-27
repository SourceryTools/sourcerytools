Index: src/vsip/core/reductions/types.hpp
===================================================================
--- src/vsip/core/reductions/types.hpp	(revision 158327)
+++ src/vsip/core/reductions/types.hpp	(working copy)
@@ -1,6 +1,6 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/impl/reductions-types.hpp
+/** @file    vsip/core/reductions/types.hpp
     @author  Jules Bergmann
     @date    2006-01-10
     @brief   VSIPL++ Library: Enumeration type for reduction functions.
Index: src/vsip/core/counter.hpp
===================================================================
--- src/vsip/core/counter.hpp	(revision 158327)
+++ src/vsip/core/counter.hpp	(working copy)
@@ -1,6 +1,6 @@
-/* Copyright (c) 2005 CodeSourcery, LLC.  All rights reserved.  */
+/* Copyright (c) 2005, 2006 CodeSourcery.  All rights reserved.  */
 
-/** @file    impl/core/counter.hpp
+/** @file    vsip/core/counter.hpp
     @author  Zack Weinberg
     @date    2005-01-21
     @brief   VSIPL++ Library: Checked counter classes.
Index: src/vsip/core/check_config.hpp
===================================================================
--- src/vsip/core/check_config.hpp	(revision 158327)
+++ src/vsip/core/check_config.hpp	(working copy)
@@ -1,6 +1,6 @@
 /* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/impl/check_config.hpp
+/** @file    vsip/core/check_config.hpp
     @author  Jules Bergmann
     @date    2006-10-04
     @brief   VSIPL++ Library: Check library configuration.
Index: src/vsip/core/parallel/distributed_block.hpp
===================================================================
--- src/vsip/core/parallel/distributed_block.hpp	(revision 158327)
+++ src/vsip/core/parallel/distributed_block.hpp	(working copy)
@@ -1,6 +1,6 @@
 /* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    vsip/impl/distributed-block.hpp
+/** @file    vsip/core/parallel/distributed-block.hpp
     @author  Jules Bergmann
     @date    2005-03-22
     @brief   VSIPL++ Library: Distributed block class.
Index: src/vsip/core/parallel/copy_chain.hpp
===================================================================
--- src/vsip/core/parallel/copy_chain.hpp	(revision 158327)
+++ src/vsip/core/parallel/copy_chain.hpp	(working copy)
@@ -1,6 +1,6 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/impl/copy_chain.hpp
+/** @file    vsip/core/parallel/copy_chain.hpp
     @author  Jules Bergmann
     @date    2005-07-29
     @brief   VSIPL++ Library: Pseudo-DMA Chain for par-services-none.
Index: src/vsip/core/parallel/assign_fwd.hpp
===================================================================
--- src/vsip/core/parallel/assign_fwd.hpp	(revision 158327)
+++ src/vsip/core/parallel/assign_fwd.hpp	(working copy)
@@ -1,6 +1,6 @@
 /* Copyright (c)  2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/impl/par_assign_fwd.hpp
+/** @file    vsip/core/parallel/par_assign_fwd.hpp
     @author  Jules Bergmann
     @date    2006-07-14
     @brief   VSIPL++ Library: Parallel assignment class.
Index: src/vsip/complex.hpp
===================================================================
--- src/vsip/complex.hpp	(revision 158327)
+++ src/vsip/complex.hpp	(working copy)
@@ -10,7 +10,7 @@
     specified in the [complex] section of the VSIPL++ specifiction.
 
     vsip::complex declaration and functions not explicitly specified
-    in [math.fns.elementwise] are declared in vsip/impl/complex-decl.hpp.
+    in [math.fns.elementwise] are declared in vsip/core/complex_decl.hpp.
 
     Functions from [math.fns.elementwise] are covered in
     vsip/core/fns_elementwise.hpp, which is included from vsip/math.hpp.
Index: src/vsip/opt/fft/workspace.hpp
===================================================================
--- src/vsip/opt/fft/workspace.hpp	(revision 158327)
+++ src/vsip/opt/fft/workspace.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/fft/workspace.cpp
     @author  Stefan Seefeld
     @date    2006-02-21
Index: src/vsip/opt/sal/bridge_util.hpp
===================================================================
--- src/vsip/opt/sal/bridge_util.hpp	(revision 158327)
+++ src/vsip/opt/sal/bridge_util.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/sal/bridge_util.hpp
     @author  Jules Bergmann
     @date    2006-05-30
Index: src/vsip/opt/sal/svd.hpp
===================================================================
--- src/vsip/opt/sal/svd.hpp	(revision 158327)
+++ src/vsip/opt/sal/svd.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/sal/solver_svd.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/sal/svd.hpp
     @author  Assem Salama
     @date    2006-04-24
     @brief   VSIPL++ Library: SVD linear system solver using SAL.
Index: src/vsip/opt/sal/bindings.hpp
===================================================================
--- src/vsip/opt/sal/bindings.hpp	(revision 158327)
+++ src/vsip/opt/sal/bindings.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/sal/bindings.hpp
     @author  Don McCoy
     @date    2005-10-04
Index: src/vsip/opt/sal/eval_misc.hpp
===================================================================
--- src/vsip/opt/sal/eval_misc.hpp	(revision 158327)
+++ src/vsip/opt/sal/eval_misc.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/opt/sal/eval-misc.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/sal/eval_misc.hpp
     @author  Don McCoy
     @date    2005-10-17
     @brief   VSIPL++ Library: SAL evaluators (for use in general dispatch).
Index: src/vsip/opt/sal/eval_threshold.hpp
===================================================================
--- src/vsip/opt/sal/eval_threshold.hpp	(revision 158327)
+++ src/vsip/opt/sal/eval_threshold.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/sal/eval_threshold.hpp
     @author  Jules Bergmann
     @date    2006-10-18
Index: src/vsip/opt/sal/conv.hpp
===================================================================
--- src/vsip/opt/sal/conv.hpp	(revision 158327)
+++ src/vsip/opt/sal/conv.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/sal/conv.hpp
     @author  Don McCoy
     @date    2005-11-18
Index: src/vsip/opt/sal/fft.cpp
===================================================================
--- src/vsip/opt/sal/fft.cpp	(revision 158327)
+++ src/vsip/opt/sal/fft.cpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/sal/fft.cpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/sal/fft.cpp
     @author  Stefan Seefeld
     @date    2006-02-20
     @brief   VSIPL++ Library: FFT wrappers and traits to bridge with 
Index: src/vsip/opt/sal/eval_vcmp.hpp
===================================================================
--- src/vsip/opt/sal/eval_vcmp.hpp	(revision 158327)
+++ src/vsip/opt/sal/eval_vcmp.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/sal/eval_vcmp.hpp
     @author  Jules Bergmann
     @date    2006-10-26
Index: src/vsip/opt/sal/is_op_supported.hpp
===================================================================
--- src/vsip/opt/sal/is_op_supported.hpp	(revision 158327)
+++ src/vsip/opt/sal/is_op_supported.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/sal/is_op_supported.hpp
     @author  Jules Bergmann
     @date    2006-10-26
Index: src/vsip/opt/sal/fft.hpp
===================================================================
--- src/vsip/opt/sal/fft.hpp	(revision 158327)
+++ src/vsip/opt/sal/fft.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/sal/fft.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/sal/fft.hpp
     @author  Stefan Seefeld
     @date    2006-02-02
     @brief   VSIPL++ Library: FFT wrappers and traits to bridge with 
Index: src/vsip/opt/sal/reductions.hpp
===================================================================
--- src/vsip/opt/sal/reductions.hpp	(revision 158327)
+++ src/vsip/opt/sal/reductions.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/sal/reduct.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/sal/reductions.hpp
     @author  Jules Bergmann
     @date    2006-10-04
     @brief   VSIPL++ Library: Wrappers to bridge with Mercury SAL
Index: src/vsip/opt/sal/lu.hpp
===================================================================
--- src/vsip/opt/sal/lu.hpp	(revision 158327)
+++ src/vsip/opt/sal/lu.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/sal/solver_lu.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/sal/lu.hpp
     @author  Assem Salama
     @date    2006-04-04
     @brief   VSIPL++ Library: LU linear system solver using SAL.
Index: src/vsip/opt/sal/elementwise.hpp
===================================================================
--- src/vsip/opt/sal/elementwise.hpp	(revision 158327)
+++ src/vsip/opt/sal/elementwise.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/sal/elementwise.hpp
     @author  Don McCoy
     @date    2005-10-04
Index: src/vsip/opt/sal/cholesky.hpp
===================================================================
--- src/vsip/opt/sal/cholesky.hpp	(revision 158327)
+++ src/vsip/opt/sal/cholesky.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/sal/solver_cholesky.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/sal/cholesky.hpp
     @author  Assem Salama
     @date    2006-04-13
     @brief   VSIPL++ Library: Cholesky linear system solver using SAL.
Index: src/vsip/opt/sal/qr.hpp
===================================================================
--- src/vsip/opt/sal/qr.hpp	(revision 158327)
+++ src/vsip/opt/sal/qr.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/sal/solver_qr.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/sal/qr.hpp
     @author  Assem Salama
     @date    2006-04-17
     @brief   VSIPL++ Library: QR linear system solver using SAL.
Index: src/vsip/opt/sal/eval_util.hpp
===================================================================
--- src/vsip/opt/sal/eval_util.hpp	(revision 158327)
+++ src/vsip/opt/sal/eval_util.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/opt/sal/eval_common.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/sal/eval_util.hpp
     @author  Jules Bergmann
     @date    2006-05-26
     @brief   VSIPL++ Library: Util routines for Mercury SAL Dispatch.
Index: src/vsip/opt/sal/eval_reductions.hpp
===================================================================
--- src/vsip/opt/sal/eval_reductions.hpp	(revision 158327)
+++ src/vsip/opt/sal/eval_reductions.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/sal/eval_reductions.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/sal/eval_reductions.hpp
     @author  Jules Bergmann
     @date    2006-05-30
     @brief   VSIPL++ Library: Reduction functions returning indices.
Index: src/vsip/opt/sal/eval_elementwise.hpp
===================================================================
--- src/vsip/opt/sal/eval_elementwise.hpp	(revision 158327)
+++ src/vsip/opt/sal/eval_elementwise.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/sal/eval_elementwise.hpp
     @author  Jules Bergmann
     @date    2006-05-26
Index: src/vsip/opt/sal/bindings.cpp
===================================================================
--- src/vsip/opt/sal/bindings.cpp	(revision 158327)
+++ src/vsip/opt/sal/bindings.cpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/sal.cpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/sal/bindings.cpp
     @author  Don McCoy
     @date    2005-10-04
     @brief   VSIPL++ Library: Wrappers and traits to bridge with 
Index: src/vsip/opt/extdata.hpp
===================================================================
--- src/vsip/opt/extdata.hpp	(revision 158327)
+++ src/vsip/opt/extdata.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/extdata.hpp
     @author  Jules Bergmann
     @date    2005-02-11
Index: src/vsip/opt/profile.cpp
===================================================================
--- src/vsip/opt/profile.cpp	(revision 158327)
+++ src/vsip/opt/profile.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/profile.cpp
     @author  Jules Bergmann
     @date    2005-05-20
Index: src/vsip/opt/fast_transpose.hpp
===================================================================
--- src/vsip/opt/fast_transpose.hpp	(revision 158327)
+++ src/vsip/opt/fast_transpose.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/fast-transpose.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/fast-transpose.hpp
     @author  Jules Bergmann
     @date    2005-05-10
     @brief   VSIPL++ Library: Fast matrix tranpose algorithms.
Index: src/vsip/opt/general_dispatch.hpp
===================================================================
--- src/vsip/opt/general_dispatch.hpp	(revision 158327)
+++ src/vsip/opt/general_dispatch.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/general_dispatch.hpp
     @author  Jules Bergmann
     @date    2005-10-10
Index: src/vsip/opt/pas/assign_eb.hpp
===================================================================
--- src/vsip/opt/pas/assign_eb.hpp	(revision 158327)
+++ src/vsip/opt/pas/assign_eb.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c)  2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/par_assign_pas_eb.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/pas/assign_eb.hpp
     @author  Jules Bergmann
     @date    2005-06-22
     @brief   VSIPL++ Library: Parallel assignment algorithm for PAS.
Index: src/vsip/opt/pas/block.hpp
===================================================================
--- src/vsip/opt/pas/block.hpp	(revision 158327)
+++ src/vsip/opt/pas/block.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/opt/pas_block.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/pas/block.hpp
     @author  Jules Bergmann
     @date    2006-06-22
     @brief   VSIPL++ Library: Distributed block class.
Index: src/vsip/opt/pas/util.hpp
===================================================================
--- src/vsip/opt/pas/util.hpp	(revision 158327)
+++ src/vsip/opt/pas/util.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/pas/util.hpp
     @author  Jules Bergmann
     @date    2006-08-29
Index: src/vsip/opt/pas/assign_direct.hpp
===================================================================
--- src/vsip/opt/pas/assign_direct.hpp	(revision 158327)
+++ src/vsip/opt/pas/assign_direct.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/pas/assign_direct.hpp
     @author  Jules Bergmann
     @date    2005-08-21
Index: src/vsip/opt/pas/param.hpp
===================================================================
--- src/vsip/opt/pas/param.hpp	(revision 158327)
+++ src/vsip/opt/pas/param.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/pas/param.hpp
     @author  Jules Bergmann
     @date    2006-08-09
Index: src/vsip/opt/pas/broadcast.hpp
===================================================================
--- src/vsip/opt/pas/broadcast.hpp	(revision 158327)
+++ src/vsip/opt/pas/broadcast.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/opt/broadcast.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/pas/broadcast.hpp
     @author  Jules Bergmann
     @date    2005-08-23
     @brief   VSIPL++ Library: PAS Broadcast.
Index: src/vsip/opt/pas/services.hpp
===================================================================
--- src/vsip/opt/pas/services.hpp	(revision 158327)
+++ src/vsip/opt/pas/services.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/pas/services.hpp
     @author  Jules Bergmann
     @date    2006-06-21
Index: src/vsip/opt/pas/assign.hpp
===================================================================
--- src/vsip/opt/pas/assign.hpp	(revision 158327)
+++ src/vsip/opt/pas/assign.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c)  2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/pas/assign.hpp
     @author  Jules Bergmann
     @date    2005-06-22
Index: src/vsip/opt/pas/offset.hpp
===================================================================
--- src/vsip/opt/pas/offset.hpp	(revision 158327)
+++ src/vsip/opt/pas/offset.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/pas/offset.hpp
     @author  Jules Bergmann
     @date    2006-09-01
Index: src/vsip/opt/rt_extdata.hpp
===================================================================
--- src/vsip/opt/rt_extdata.hpp	(revision 158327)
+++ src/vsip/opt/rt_extdata.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/rt_extdata.hpp
     @author  Jules Bergmann
     @date    2005-05-03
Index: src/vsip/opt/dispatch.hpp
===================================================================
--- src/vsip/opt/dispatch.hpp	(revision 158327)
+++ src/vsip/opt/dispatch.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, Inc.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/dispatch.hpp
     @author  Stefan Seefeld
     @date    2006-11-03
Index: src/vsip/opt/profile.hpp
===================================================================
--- src/vsip/opt/profile.hpp	(revision 158327)
+++ src/vsip/opt/profile.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/profile.hpp
     @author  Jules Bergmann
     @date    2005-05-20
Index: src/vsip/opt/choose_access.hpp
===================================================================
--- src/vsip/opt/choose_access.hpp	(revision 158327)
+++ src/vsip/opt/choose_access.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/choose-access.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/choose-access.hpp
     @author  Jules Bergmann
     @date    2005-04-13
     @brief   VSIPL++ Library: Template mechanism to choose the appropriate
Index: src/vsip/opt/ipp/fft.cpp
===================================================================
--- src/vsip/opt/ipp/fft.cpp	(revision 158327)
+++ src/vsip/opt/ipp/fft.cpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/ipp/fft.cpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ipp/fft.cpp
     @author  Stefan Seefeld, Nathan Myers
     @date    2006-05-05
     @brief   VSIPL++ Library: FFT wrappers and traits to bridge with 
Index: src/vsip/opt/ipp/fir.cpp
===================================================================
--- src/vsip/opt/ipp/fir.cpp	(revision 158327)
+++ src/vsip/opt/ipp/fir.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/ipp/fir.cpp
     @author  Stefan Seefeld
     @date    2006-11-02
Index: src/vsip/opt/ipp/bindings.hpp
===================================================================
--- src/vsip/opt/ipp/bindings.hpp	(revision 158327)
+++ src/vsip/opt/ipp/bindings.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/ipp.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ipp/bindings.hpp
     @author  Stefan Seefeld
     @date    2005-08-10
     @brief   VSIPL++ Library: Wrappers and traits to bridge with Intel's IPP.
Index: src/vsip/opt/ipp/fft.hpp
===================================================================
--- src/vsip/opt/ipp/fft.hpp	(revision 158327)
+++ src/vsip/opt/ipp/fft.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/ipp/fft.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ipp/fft.hpp
     @author  Stefan Seefeld
     @date    2006-05-05
     @brief   VSIPL++ Library: FFT wrappers and traits to bridge with 
Index: src/vsip/opt/ipp/fir.hpp
===================================================================
--- src/vsip/opt/ipp/fir.hpp	(revision 158327)
+++ src/vsip/opt/ipp/fir.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/ipp/fir.hpp
     @author  Stefan Seefeld
     @date    2006-11-02
Index: src/vsip/opt/ipp/conv.hpp
===================================================================
--- src/vsip/opt/ipp/conv.hpp	(revision 158327)
+++ src/vsip/opt/ipp/conv.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/signal-conv-ipp.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ipp/conv.hpp
     @author  Jules Bergmann
     @date    2005-08-31
     @brief   VSIPL++ Library: Convolution class implementation using IPP.
Index: src/vsip/opt/ipp/bindings.cpp
===================================================================
--- src/vsip/opt/ipp/bindings.cpp	(revision 158327)
+++ src/vsip/opt/ipp/bindings.cpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/ipp.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ipp/bindings.hpp
     @author  Stefan Seefeld
     @date    2005-08-10
     @brief   VSIPL++ Library: Wrappers and traits to bridge with Intel's IPP.
Index: src/vsip/opt/fftw3/fft.cpp
===================================================================
--- src/vsip/opt/fftw3/fft.cpp	(revision 158327)
+++ src/vsip/opt/fftw3/fft.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/fftw3/fft.cpp
     @author  Stefan Seefeld
     @date    2006-04-10
Index: src/vsip/opt/fftw3/fft_impl.cpp
===================================================================
--- src/vsip/opt/fftw3/fft_impl.cpp	(revision 158327)
+++ src/vsip/opt/fftw3/fft_impl.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/fftw3/fft_impl.cpp
     @author  Stefan Seefeld
     @date    2006-04-10
Index: src/vsip/opt/fftw3/fft.hpp
===================================================================
--- src/vsip/opt/fftw3/fft.hpp	(revision 158327)
+++ src/vsip/opt/fftw3/fft.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/fftw3/fft.hpp
     @author  Stefan Seefeld
     @date    2006-03-06
Index: src/vsip/opt/lapack/svd.hpp
===================================================================
--- src/vsip/opt/lapack/svd.hpp	(revision 158327)
+++ src/vsip/opt/lapack/svd.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/lapack/svd.hpp
     @author  Assem Salama
     @date    2006-04-25
Index: src/vsip/opt/lapack/bindings.hpp
===================================================================
--- src/vsip/opt/lapack/bindings.hpp	(revision 158327)
+++ src/vsip/opt/lapack/bindings.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/opt/lapack/misc.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/lapack/bindings.hpp
     @author  Jules Bergmann
     @date    2005-08-19
     @brief   VSIPL++ Library: Lapack interface
@@ -88,7 +92,7 @@
 #  define VSIP_IMPL_USE_CBLAS_DOT    1
 #  define VSIP_IMPL_USE_CBLAS_OTHERS 1
 #elif VSIP_IMPL_USE_CBLAS == 3
-#  include <vsip/impl/lapack/acml_cblas.hpp>
+#  include <vsip/opt/lapack/acml_cblas.hpp>
 #  define VSIP_IMPL_USE_CBLAS_DOT    1
 #  define VSIP_IMPL_USE_CBLAS_OTHERS 0
 #else
Index: src/vsip/opt/lapack/matvec.hpp
===================================================================
--- src/vsip/opt/lapack/matvec.hpp	(revision 158327)
+++ src/vsip/opt/lapack/matvec.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/lapack/matvec.hpp
     @author  Jules Bergmann
     @date    2005-10-11
Index: src/vsip/opt/lapack/acml_cblas.hpp
===================================================================
--- src/vsip/opt/lapack/acml_cblas.hpp	(revision 158327)
+++ src/vsip/opt/lapack/acml_cblas.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/lapack/acml_cblas.hpp
     @author  Jules Bergmann
     @date    2005-08-19
Index: src/vsip/opt/lapack/lu.hpp
===================================================================
--- src/vsip/opt/lapack/lu.hpp	(revision 158327)
+++ src/vsip/opt/lapack/lu.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/core/lapack/lu.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/lapack/lu.hpp
     @author  Assem Salama
     @date    2006-04-13
     @brief   VSIPL++ Library: LU linear system solver using lapack.
Index: src/vsip/opt/lapack/cholesky.hpp
===================================================================
--- src/vsip/opt/lapack/cholesky.hpp	(revision 158327)
+++ src/vsip/opt/lapack/cholesky.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/lapack/cholesky.hpp
     @author  Assem Salama
     @date    2006-04-13
Index: src/vsip/opt/lapack/qr.hpp
===================================================================
--- src/vsip/opt/lapack/qr.hpp	(revision 158327)
+++ src/vsip/opt/lapack/qr.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/lapack/solver_qr.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/lapack/qr.hpp
     @author  Jules Bergmann
     @date    2005-08-19
     @brief   VSIPL++ Library: QR Linear system solver using Lapack.
Index: src/vsip/opt/lapack/bindings.cpp
===================================================================
--- src/vsip/opt/lapack/bindings.cpp	(revision 158327)
+++ src/vsip/opt/lapack/bindings.cpp	(working copy)
@@ -1,9 +1,13 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/lapack.cpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/lapack/bindings.cpp
     @author  Jules Bergmann
     @date    2005-10-11
-    @brief   VSIPL++ Library: Lacpack interface
+    @brief   VSIPL++ Library: Lapack interface
 */
 
 /***********************************************************************
Index: src/vsip/opt/simd/vadd.cpp
===================================================================
--- src/vsip/opt/simd/vadd.cpp	(revision 158327)
+++ src/vsip/opt/simd/vadd.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/simd/vadd.cpp
     @author  Jules Bergmann
     @date    2006-06-08
Index: src/vsip/opt/simd/rscvmul.hpp
===================================================================
--- src/vsip/opt/simd/rscvmul.hpp	(revision 158327)
+++ src/vsip/opt/simd/rscvmul.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/simd/rscvmul.hpp
     @author  Jules Bergmann
     @date    2006-03-28
Index: src/vsip/opt/simd/vgt.cpp
===================================================================
--- src/vsip/opt/simd/vgt.cpp	(revision 158327)
+++ src/vsip/opt/simd/vgt.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/simd/vgt.cpp
     @author  Jules Bergmann
     @date    2006-07-26
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 158327)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/simd/simd.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/simd/simd.hpp
     @author  Jules Bergmann
     @date    2006-01-25
     @brief   VSIPL++ Library: SIMD traits.
Index: src/vsip/opt/simd/vadd.hpp
===================================================================
--- src/vsip/opt/simd/vadd.hpp	(revision 158327)
+++ src/vsip/opt/simd/vadd.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/simd/vadd.hpp
     @author  Jules Bergmann
     @date    2006-06-08
Index: src/vsip/opt/simd/vlogic.cpp
===================================================================
--- src/vsip/opt/simd/vlogic.cpp	(revision 158327)
+++ src/vsip/opt/simd/vlogic.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/simd/vlogic.cpp
     @author  Jules Bergmann
     @date    2006-07-28
Index: src/vsip/opt/simd/vmul.cpp
===================================================================
--- src/vsip/opt/simd/vmul.cpp	(revision 158327)
+++ src/vsip/opt/simd/vmul.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/simd/vmul.cpp
     @author  Jules Bergmann
     @date    2006-01-25
Index: src/vsip/opt/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/opt/simd/expr_evaluator.hpp	(revision 158327)
+++ src/vsip/opt/simd/expr_evaluator.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery, Inc.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/simd/expr_evaluator.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/simd/expr_evaluator.hpp
     @author  Stefan Seefeld
     @date    2006-07-25
     @brief   VSIPL++ Library: SIMD expression evaluator logic.
Index: src/vsip/opt/simd/vgt.hpp
===================================================================
--- src/vsip/opt/simd/vgt.hpp	(revision 158327)
+++ src/vsip/opt/simd/vgt.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/simd/vgt.hpp
     @author  Jules Bergmann
     @date    2006-07-26
Index: src/vsip/opt/simd/eval_generic.hpp
===================================================================
--- src/vsip/opt/simd/eval_generic.hpp	(revision 158327)
+++ src/vsip/opt/simd/eval_generic.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/simd/eval-generic.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/simd/eval-generic.hpp
     @author  Jules Bergmann
     @date    2006-01-25
     @brief   VSIPL++ Library: Wrappers and traits to bridge with generic SIMD.
Index: src/vsip/opt/simd/vlogic.hpp
===================================================================
--- src/vsip/opt/simd/vlogic.hpp	(revision 158327)
+++ src/vsip/opt/simd/vlogic.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/simd/vlogic.hpp
     @author  Jules Bergmann
     @date    2006-07-28
Index: src/vsip/opt/simd/vmul.hpp
===================================================================
--- src/vsip/opt/simd/vmul.hpp	(revision 158327)
+++ src/vsip/opt/simd/vmul.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/simd/vmul.hpp
     @author  Jules Bergmann
     @date    2006-01-25
Index: src/vsip/opt/simd/rscvmul.cpp
===================================================================
--- src/vsip/opt/simd/rscvmul.cpp	(revision 158327)
+++ src/vsip/opt/simd/rscvmul.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/simd/rscvmul.cpp
     @author  Jules Bergmann
     @date    2006-03-28
Index: src/vsip/opt/simd/expr_iterator.hpp
===================================================================
--- src/vsip/opt/simd/expr_iterator.hpp	(revision 158327)
+++ src/vsip/opt/simd/expr_iterator.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery, Inc.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/simd/expr_iterator.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/simd/expr_iterator.hpp
     @author  Stefan Seefeld
     @date    2006-07-18
     @brief   VSIPL++ Library: SIMD expression iterators.
Index: src/vsip/opt/parallel/foreach.hpp
===================================================================
--- src/vsip/opt/parallel/foreach.hpp	(revision 158327)
+++ src/vsip/opt/parallel/foreach.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/parallel/foreach.hpp
     @author  Jules Bergmann
     @date    2005-06-08
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 158327)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/diag/eval_vcmp.hpp
     @author  Jules Bergmann
     @date    2006-10-26
Index: src/vsip/opt/signal/fir_opt.hpp
===================================================================
--- src/vsip/opt/signal/fir_opt.hpp	(revision 158327)
+++ src/vsip/opt/signal/fir_opt.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/signal/fir_opt.hpp
     @author  Stefan Seefeld
     @date    2006-11-02
Index: src/vsip/opt/signal/conv_ext.hpp
===================================================================
--- src/vsip/opt/signal/conv_ext.hpp	(revision 158327)
+++ src/vsip/opt/signal/conv_ext.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/signal/conv_ext.hpp
     @author  Jules Bergmann
     @date    2005-06-09
Index: src/vsip/opt/signal/corr_ext.hpp
===================================================================
--- src/vsip/opt/signal/corr_ext.hpp	(revision 158327)
+++ src/vsip/opt/signal/corr_ext.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/signal/corr_ext.hpp
     @author  Jules Bergmann
     @date    2005-10-05
Index: src/vsip/opt/signal/corr_opt.hpp
===================================================================
--- src/vsip/opt/signal/corr_opt.hpp	(revision 158327)
+++ src/vsip/opt/signal/corr_opt.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/signal/corr-opt.hpp
     @author  Jules Bergmann
     @date    2005-10-05
Index: src/vsip/opt/expr/ops_info.hpp
===================================================================
--- src/vsip/opt/expr/ops_info.hpp	(revision 158327)
+++ src/vsip/opt/expr/ops_info.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/expr/ops_info.hpp
     @author  Jules Bergmann
     @date    2006-08-04
Index: src/vsip/opt/expr/serial_dispatch.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch.hpp	(revision 158327)
+++ src/vsip/opt/expr/serial_dispatch.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/expr/serial_dispatch.hpp
     @author  Stefan Seefeld
     @date    2005-08-05
Index: src/vsip/opt/expr/serial_dispatch_fwd.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch_fwd.hpp	(revision 158327)
+++ src/vsip/opt/expr/serial_dispatch_fwd.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/expr/serial_dispatch_fwd.hpp
     @author  Stefan Seefeld
     @date    2005-08-05
Index: src/vsip/opt/expr/serial_evaluator.hpp
===================================================================
--- src/vsip/opt/expr/serial_evaluator.hpp	(revision 158327)
+++ src/vsip/opt/expr/serial_evaluator.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/expr/serial_evaluator.hpp
     @author  Stefan Seefeld
     @date    2005-08-10
Index: src/vsip/opt/expr/eval_dense.hpp
===================================================================
--- src/vsip/opt/expr/eval_dense.hpp	(revision 158327)
+++ src/vsip/opt/expr/eval_dense.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip/opt/expr/eval_dense.hpp
     @author  Jules Bergmann
     @date    2006-06-05
Index: src/vsip_csl/matlab_file.cpp
===================================================================
--- src/vsip_csl/matlab_file.cpp	(revision 158327)
+++ src/vsip_csl/matlab_file.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/matlab_file.cpp
     @author  Assem Salama
     @date    2006-06-21
Index: src/vsip_csl/error_db.hpp
===================================================================
--- src/vsip_csl/error_db.hpp	(revision 158327)
+++ src/vsip_csl/error_db.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/error_db.cpp
     @author  Jules Bergmann
     @date    2005-12-12
Index: src/vsip_csl/matlab_file.hpp
===================================================================
--- src/vsip_csl/matlab_file.hpp	(revision 158327)
+++ src/vsip_csl/matlab_file.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/matlab_file.hpp
     @author  Assem Salama
     @date    2006-06-21
Index: src/vsip_csl/matlab.hpp
===================================================================
--- src/vsip_csl/matlab.hpp	(revision 158327)
+++ src/vsip_csl/matlab.hpp	(working copy)
@@ -1,3 +1,9 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 #ifndef VSIP_CSL_MATLAB_HPP
 #define VSIP_CSL_MATLAB_HPP
 
Index: src/vsip_csl/output.hpp
===================================================================
--- src/vsip_csl/output.hpp	(revision 158327)
+++ src/vsip_csl/output.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/output.hpp
     @author  Jules Bergmann
     @date    2005-03-22
Index: src/vsip_csl/ref_conv.hpp
===================================================================
--- src/vsip_csl/ref_conv.hpp	(revision 158327)
+++ src/vsip_csl/ref_conv.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/ref_conv.cpp
     @author  Jules Bergmann
     @date    2005-12-28
Index: src/vsip_csl/ref_corr.hpp
===================================================================
--- src/vsip_csl/ref_corr.hpp	(revision 158327)
+++ src/vsip_csl/ref_corr.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/ref_corr.cpp
     @author  Jules Bergmann
     @date    2005-12-09
Index: src/vsip_csl/test-precision.hpp
===================================================================
--- src/vsip_csl/test-precision.hpp	(revision 158327)
+++ src/vsip_csl/test-precision.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/test-precision.cpp
     @author  Jules Bergmann
     @date    2005-09-12
Index: src/vsip_csl/load_view.hpp
===================================================================
--- src/vsip_csl/load_view.hpp	(revision 158327)
+++ src/vsip_csl/load_view.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/load_view.hpp
     @author  Jules Bergmann
     @date    2005-09-30
Index: src/vsip_csl/ref_dft.hpp
===================================================================
--- src/vsip_csl/ref_dft.hpp	(revision 158327)
+++ src/vsip_csl/ref_dft.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/ref_dft.cpp
     @author  Jules Bergmann
     @date    2006-03-03
Index: src/vsip_csl/ref_matvec.hpp
===================================================================
--- src/vsip_csl/ref_matvec.hpp	(revision 158327)
+++ src/vsip_csl/ref_matvec.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/ref_matvec.hpp
     @author  Jules Bergmann
     @date    2005-10-11
Index: src/vsip_csl/matlab_bin_formatter.hpp
===================================================================
--- src/vsip_csl/matlab_bin_formatter.hpp	(revision 158327)
+++ src/vsip_csl/matlab_bin_formatter.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/matlab_bin_formatter.hpp
     @author  Assem Salama
     @date    2006-05-22
Index: src/vsip_csl/plainblock.hpp
===================================================================
--- src/vsip_csl/plainblock.hpp	(revision 158327)
+++ src/vsip_csl/plainblock.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/plainblock.hpp
     @author  Jules Bergmann
     @date    02/11/2005
Index: src/vsip_csl/png.cpp
===================================================================
--- src/vsip_csl/png.cpp	(revision 158327)
+++ src/vsip_csl/png.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/png.cpp
     @author  Stefan Seefeld
     @date    2006-03-21
Index: src/vsip_csl/test.hpp
===================================================================
--- src/vsip_csl/test.hpp	(revision 158327)
+++ src/vsip_csl/test.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/test.hpp
     @author  Jules Bergmann
     @date    2005-01-25
Index: src/vsip_csl/matlab_utils.hpp
===================================================================
--- src/vsip_csl/matlab_utils.hpp	(revision 158327)
+++ src/vsip_csl/matlab_utils.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    matlab_utils.hpp
     @author  Don McCoy
     @date    2006-10-31
Index: src/vsip_csl/test-storage.hpp
===================================================================
--- src/vsip_csl/test-storage.hpp	(revision 158327)
+++ src/vsip_csl/test-storage.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    tests/test-storage.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/test-storage.hpp
     @author  Jules Bergmann
     @date    03/24/2005
     @brief   VSIPL++ Library: Generalized view storage for tests.
Index: src/vsip_csl/png.hpp
===================================================================
--- src/vsip_csl/png.hpp	(revision 158327)
+++ src/vsip_csl/png.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/png.hpp
     @author  Stefan Seefeld
     @date    2006-03-21
Index: src/vsip_csl/matlab_text_formatter.hpp
===================================================================
--- src/vsip_csl/matlab_text_formatter.hpp	(revision 158327)
+++ src/vsip_csl/matlab_text_formatter.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/matlab_text_formatter.hpp
     @author  Assem Salama
     @date    2006-05-22
Index: src/vsip_csl/save_view.hpp
===================================================================
--- src/vsip_csl/save_view.hpp	(revision 158327)
+++ src/vsip_csl/save_view.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    vsip_csl/save_view.cpp
     @author  Jules Bergmann
     @date    2005-09-30
Index: tests/extdata-subviews.cpp
===================================================================
--- tests/extdata-subviews.cpp	(revision 158327)
+++ tests/extdata-subviews.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/extdata-subviews.cpp
     @author  Jules Bergmann
     @date    2005-07-22
Index: tests/rt_extdata.cpp
===================================================================
--- tests/rt_extdata.cpp	(revision 158327)
+++ tests/rt_extdata.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/rt_extdata.cpp
     @author  Jules Bergmann
     @date    2006-05-03
Index: tests/reductions-idx.cpp
===================================================================
--- tests/reductions-idx.cpp	(revision 158327)
+++ tests/reductions-idx.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/reductions-idx.cpp
     @author  Jules Bergmann
     @date    2005-07-11
Index: tests/sal-assumptions.cpp
===================================================================
--- tests/sal-assumptions.cpp	(revision 158327)
+++ tests/sal-assumptions.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/sal-assumptions.cpp
     @author  Don McCoy
     @date    2005-10-13
Index: tests/user_storage.cpp
===================================================================
--- tests/user_storage.cpp	(revision 158327)
+++ tests/user_storage.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/user_storage.cpp
     @author  Jules Bergmann
     @date    2005-05-16
Index: tests/subblock.cpp
===================================================================
--- tests/subblock.cpp	(revision 158327)
+++ tests/subblock.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/subblock.cpp
     @author  Zack Weinberg
     @date    2005-01-28
Index: tests/window.cpp
===================================================================
--- tests/window.cpp	(revision 158327)
+++ tests/window.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/window.cpp
     @author  Don McCoy
     @date    2005-09-15
Index: tests/coverage_common.hpp
===================================================================
--- tests/coverage_common.hpp	(revision 158327)
+++ tests/coverage_common.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/expr-coverage.hpp
     @author  Jules Bergmann
     @date    2005-09-13
Index: tests/initfini.cpp
===================================================================
--- tests/initfini.cpp	(revision 158327)
+++ tests/initfini.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    initfini.cpp
     @author  Zack Weinberg
     @date    2005-01-20
Index: tests/replicated_map.cpp
===================================================================
--- tests/replicated_map.cpp	(revision 158327)
+++ tests/replicated_map.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/replicated_map.cpp
     @author  Jules Bergmann
     @date    2006-03-09
Index: tests/diag_eval.cpp
===================================================================
--- tests/diag_eval.cpp	(revision 158327)
+++ tests/diag_eval.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/diag_eval.cpp
     @author  Jules Bergmann
     @date    2006-11-13
Index: tests/fns_scalar.cpp
===================================================================
--- tests/fns_scalar.cpp	(revision 158327)
+++ tests/fns_scalar.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/fns_scalar.cpp
     @author  Jules Bergmann
     @date    2005-06-18
Index: tests/scalar-view.cpp
===================================================================
--- tests/scalar-view.cpp	(revision 158327)
+++ tests/scalar-view.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/scalar-view.cpp
     @author  Jules Bergmann
     @date    2005-12-19
Index: tests/map.cpp
===================================================================
--- tests/map.cpp	(revision 158327)
+++ tests/map.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/map.cpp
     @author  Jules Bergmann
     @date    2005-02-16
Index: tests/fftshift.cpp
===================================================================
--- tests/fftshift.cpp	(revision 158327)
+++ tests/fftshift.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/fftshift.cpp
     @author  Jules Bergmann
     @date    2006-12-08
Index: tests/fft_ext/fft_ext.cpp
===================================================================
--- tests/fft_ext/fft_ext.cpp	(revision 158327)
+++ tests/fft_ext/fft_ext.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/fft_ext.cpp
     @author  Don McCoy
     @date    2005-08-25
Index: tests/matrix-transpose.cpp
===================================================================
--- tests/matrix-transpose.cpp	(revision 158327)
+++ tests/matrix-transpose.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/matrix-transpose.cpp
     @author  Jules Bergmann
     @date    2005-08-18
Index: tests/regressions/fft_temp_view.cpp
===================================================================
--- tests/regressions/fft_temp_view.cpp	(revision 158327)
+++ tests/regressions/fft_temp_view.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/regr_fft_temp_view.cpp
     @author  Jules Bergmann
     @date    2005-09-17
Index: tests/regressions/view_index.cpp
===================================================================
--- tests/regressions/view_index.cpp	(revision 158327)
+++ tests/regressions/view_index.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/regr_view_index.cpp
     @author  Jules Bergmann
     @date    2005-07-14
Index: tests/regressions/const_view_at_op.cpp
===================================================================
--- tests/regressions/const_view_at_op.cpp	(revision 158327)
+++ tests/regressions/const_view_at_op.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/reg_const_view_at_op.cpp
     @author  Jules Bergmann
     @date    2005-09-13
Index: tests/regressions/subview_exprs.cpp
===================================================================
--- tests/regressions/subview_exprs.cpp	(revision 158327)
+++ tests/regressions/subview_exprs.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/regr_subview_exprs.cpp
     @author  Jules Bergmann
     @date    2005-09-13
Index: tests/regressions/transpose-nonunit.cpp
===================================================================
--- tests/regressions/transpose-nonunit.cpp	(revision 158327)
+++ tests/regressions/transpose-nonunit.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/transpose-nonunit.cpp
     @author  Jules Bergmann
     @date    2006-04-20
Index: tests/regressions/fft_expr_arg.cpp
===================================================================
--- tests/regressions/fft_expr_arg.cpp	(revision 158327)
+++ tests/regressions/fft_expr_arg.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/fft_expr_arg.cpp
     @author  Jules Bergmann
     @date    2006-05-10
Index: tests/regressions/complex_proxy.cpp
===================================================================
--- tests/regressions/complex_proxy.cpp	(revision 158327)
+++ tests/regressions/complex_proxy.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/regr_complex_proxy.hpp
     @author  Jules Bergmann
     @date    2006-02-02
Index: tests/regressions/conv_to_subview.cpp
===================================================================
--- tests/regressions/conv_to_subview.cpp	(revision 158327)
+++ tests/regressions/conv_to_subview.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    convolution.cpp
     @author  Jules Bergmann
     @date    2005-06-09
Index: tests/regressions/proxy_lvalue_conv.cpp
===================================================================
--- tests/regressions/proxy_lvalue_conv.cpp	(revision 158327)
+++ tests/regressions/proxy_lvalue_conv.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/reg_proxy_lvalue_conv.cpp
     @author  Jules Bergmann
     @date    2005-08-08
Index: tests/regressions/transpose.cpp
===================================================================
--- tests/regressions/transpose.cpp	(revision 158327)
+++ tests/regressions/transpose.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/regr_transpose.cpp
     @author  Jules Bergmann
     @date    2006-02-24
Index: tests/regressions/ext_subview_split.cpp
===================================================================
--- tests/regressions/ext_subview_split.cpp	(revision 158327)
+++ tests/regressions/ext_subview_split.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/regr_ext_subview_split.cpp
     @author  Jules Bergmann
     @date    2005-09-01
Index: tests/regressions/transpose_assign.cpp
===================================================================
--- tests/regressions/transpose_assign.cpp	(revision 158327)
+++ tests/regressions/transpose_assign.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/regressions/transpose_assign.cpp
     @author  Jules Bergmann
     @date    2006-09-14
Index: tests/regressions/col_mat_scale.cpp
===================================================================
--- tests/regressions/col_mat_scale.cpp	(revision 158327)
+++ tests/regressions/col_mat_scale.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/col_mat_scale.cpp
     @author  Jules Bergmann
     @date    2006-09-11
Index: tests/regressions/transpose-mirror.cpp
===================================================================
--- tests/regressions/transpose-mirror.cpp	(revision 158327)
+++ tests/regressions/transpose-mirror.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/regressions/transpose-mirror.cpp
     @author  Jules Bergmann
     @date    2006-04-20
Index: tests/regressions/localview_of_slice.cpp
===================================================================
--- tests/regressions/localview_of_slice.cpp	(revision 158327)
+++ tests/regressions/localview_of_slice.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/regressions/localview_of_slice.cpp
     @author  Jules Bergmann
     @date    2006-03-24
Index: tests/view_lvalue.cpp
===================================================================
--- tests/view_lvalue.cpp	(revision 158327)
+++ tests/view_lvalue.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/view_lvalue.hpp
     @author  Zack Weinberg
     @date    2005-05-04
Index: tests/iir.cpp
===================================================================
--- tests/iir.cpp	(revision 158327)
+++ tests/iir.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    iir.cpp
     @author  Jules Bergmann
     @date    2005-12-19
Index: tests/fft_be.cpp
===================================================================
--- tests/fft_be.cpp	(revision 158327)
+++ tests/fft_be.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/fft_be.cpp
     @author  Stefan Seefeld
     @date    2006-05-03
Index: tests/matlab_bin_file.cpp
===================================================================
--- tests/matlab_bin_file.cpp	(revision 158327)
+++ tests/matlab_bin_file.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/matlab_bin_file_test.cpp
     @author  Assem Salama
     @date    2006-07-18
Index: tests/fns_userelt.cpp
===================================================================
--- tests/fns_userelt.cpp	(revision 158327)
+++ tests/fns_userelt.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/fns_userelt.cpp
     @author  Stefan Seefeld
     @date    2005-07-26
Index: tests/solver-qr.cpp
===================================================================
--- tests/solver-qr.cpp	(revision 158327)
+++ tests/solver-qr.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/solver-qr.cpp
     @author  Jules Bergmann
     @date    2005-08-19
Index: tests/test_common.hpp
===================================================================
--- tests/test_common.hpp	(revision 158327)
+++ tests/test_common.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/test_common.cpp
     @author  Jules Bergmann
     @date    2006-08-21
Index: tests/threshold.cpp
===================================================================
--- tests/threshold.cpp	(revision 158327)
+++ tests/threshold.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/threshold.cpp
     @author  Jules Bergmann
     @date    2006-10-16
Index: tests/solver-toepsol.cpp
===================================================================
--- tests/solver-toepsol.cpp	(revision 158327)
+++ tests/solver-toepsol.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/solver-toepsol.cpp
     @author  Jules Bergmann
     @date    2005-09-28
Index: tests/histogram.cpp
===================================================================
--- tests/histogram.cpp	(revision 158327)
+++ tests/histogram.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/histogram.cpp
     @author  Don McCoy
     @date    2005-12-05
Index: tests/coverage_ternary.cpp
===================================================================
--- tests/coverage_ternary.cpp	(revision 158327)
+++ tests/coverage_ternary.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/coverage_ternary.hpp
     @author  Jules Bergmann
     @date    2005-09-13
Index: tests/dispatch.cpp
===================================================================
--- tests/dispatch.cpp	(revision 158327)
+++ tests/dispatch.cpp	(working copy)
@@ -1,3 +1,9 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 #include <vsip/opt/dispatch.hpp>
 #include <vsip_csl/test.hpp>
 
Index: tests/solver-llsqsol.cpp
===================================================================
--- tests/solver-llsqsol.cpp	(revision 158327)
+++ tests/solver-llsqsol.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/solver-llsqsol.cpp
     @author  Jules Bergmann
     @date    2005-09-07
Index: tests/check_config.cpp
===================================================================
--- tests/check_config.cpp	(revision 158327)
+++ tests/check_config.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/x-fft.cpp
     @author  Jules Bergmann
     @date    2006-10-04
Index: tests/complex.cpp
===================================================================
--- tests/complex.cpp	(revision 158327)
+++ tests/complex.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    complex.cpp
     @author  Jules Bergmann
     @date    2005-03-17
Index: tests/domain.cpp
===================================================================
--- tests/domain.cpp	(revision 158327)
+++ tests/domain.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/domain.cpp
     @author  Stefan Seefeld
     @date    2005-01-22
Index: tests/reductions-bool.cpp
===================================================================
--- tests/reductions-bool.cpp	(revision 158327)
+++ tests/reductions-bool.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/reductions-bool.cpp
     @author  Jules Bergmann
     @date    2005-07-11
Index: tests/view_operators.cpp
===================================================================
--- tests/view_operators.cpp	(revision 158327)
+++ tests/view_operators.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/view_operators.cpp
     @author  Stefan Seefeld
     @date    2005-03-16
Index: tests/selgen.cpp
===================================================================
--- tests/selgen.cpp	(revision 158327)
+++ tests/selgen.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/selgen.cpp
     @author  Stefan Seefeld
     @date    2005-09-26
Index: tests/matvec.cpp
===================================================================
--- tests/matvec.cpp	(revision 158327)
+++ tests/matvec.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/matvec.cpp
     @author  Don McCoy
     @date    2005-09-19
Index: tests/extdata-matadd.cpp
===================================================================
--- tests/extdata-matadd.cpp	(revision 158327)
+++ tests/extdata-matadd.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/extdata-matadd.cpp
     @author  Jules Bergmann
     @date    2005-02-14
Index: tests/refcount.cpp
===================================================================
--- tests/refcount.cpp	(revision 158327)
+++ tests/refcount.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    refcount.cpp
     @author  Jules Bergmann
     @date    2005-01-24
Index: tests/tensor-transpose.cpp
===================================================================
--- tests/tensor-transpose.cpp	(revision 158327)
+++ tests/tensor-transpose.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/tensor-transpose.cpp
     @author  Jules Bergmann
     @date    2005-08-18
Index: tests/freqswap.cpp
===================================================================
--- tests/freqswap.cpp	(revision 158327)
+++ tests/freqswap.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/freqswap.cpp
     @author  Don McCoy
     @date    2005-12-01
Index: tests/segment_size.cpp
===================================================================
--- tests/segment_size.cpp	(revision 158327)
+++ tests/segment_size.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/segment_size.cpp
     @author  Jules Bergmann
     @date    2006-08-24
Index: tests/dense.cpp
===================================================================
--- tests/dense.cpp	(revision 158327)
+++ tests/dense.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/dense.cpp
     @author  Jules Bergmann
     @date    2005-01-24
Index: tests/expression.cpp
===================================================================
--- tests/expression.cpp	(revision 158327)
+++ tests/expression.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/expression.cpp
     @author  Stefan Seefeld
     @date    2005-01-31
Index: tests/vsip_csl/load_view.cpp
===================================================================
--- tests/vsip_csl/load_view.cpp	(revision 158327)
+++ tests/vsip_csl/load_view.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/vsip_csl/load_view.hpp
     @author  Jules Bergmann
     @date    2006-09-28
Index: tests/vector.cpp
===================================================================
--- tests/vector.cpp	(revision 158327)
+++ tests/vector.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/vector.cpp
     @author  Jules Bergmann
     @date    2005-03-05
Index: tests/view_functions.cpp
===================================================================
--- tests/view_functions.cpp	(revision 158327)
+++ tests/view_functions.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/view_operators.cpp
     @author  Stefan Seefeld
     @date    2005-03-16
Index: tests/matrix.cpp
===================================================================
--- tests/matrix.cpp	(revision 158327)
+++ tests/matrix.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/matrix.cpp
     @author  Stefan Seefeld
     @date    2005-04-20
Index: tests/solver-common.hpp
===================================================================
--- tests/solver-common.hpp	(revision 158327)
+++ tests/solver-common.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/solver-common.cpp
     @author  Jules Bergmann
     @date    2005-09-07
Index: tests/lvalue-proxy.cpp
===================================================================
--- tests/lvalue-proxy.cpp	(revision 158327)
+++ tests/lvalue-proxy.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/lvalue_proxy.hpp
     @author  Zack Weinberg
     @date    2005-05-04
Index: tests/corr-2d.cpp
===================================================================
--- tests/corr-2d.cpp	(revision 158327)
+++ tests/corr-2d.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    corr-2d.cpp
     @author  Jules Bergmann
     @date    2005-12-09
Index: tests/conv-2d.cpp
===================================================================
--- tests/conv-2d.cpp	(revision 158327)
+++ tests/conv-2d.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    conv-2d.cpp
     @author  Jules Bergmann
     @date    2005-12-02
Index: tests/static_assert.cpp
===================================================================
--- tests/static_assert.cpp	(revision 158327)
+++ tests/static_assert.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/static_assert.cpp
     @author  Jules Bergmann
     @date    2005-02-08
Index: tests/matlab_iterator.cpp
===================================================================
--- tests/matlab_iterator.cpp	(revision 158327)
+++ tests/matlab_iterator.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/matlab_bin_file_test.cpp
     @author  Assem Salama
     @date    2006-07-18
Index: tests/expr_ops_info.cpp
===================================================================
--- tests/expr_ops_info.cpp	(revision 158327)
+++ tests/expr_ops_info.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/expr_ops_info.cpp
     @author  Jules Bergmann
     @date    2006-08-04
Index: tests/view.cpp
===================================================================
--- tests/view.cpp	(revision 158327)
+++ tests/view.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/view.cpp
     @author  Jules Bergmann
     @date    2005-03-22
Index: tests/block_interface.hpp
===================================================================
--- tests/block_interface.hpp	(revision 158327)
+++ tests/block_interface.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/block_interface.cpp
     @author  Stefan Seefeld
     @date    2005-02-15
Index: tests/random.cpp
===================================================================
--- tests/random.cpp	(revision 158327)
+++ tests/random.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    random.cpp
     @author  Don McCoy
     @date    2005-09-07
Index: tests/fir.cpp
===================================================================
--- tests/fir.cpp	(revision 158327)
+++ tests/fir.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/fft.cpp
     @author  Nathan Myers
     @date    2005-10-03
Index: tests/correlation.cpp
===================================================================
--- tests/correlation.cpp	(revision 158327)
+++ tests/correlation.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    correlation.cpp
     @author  Jules Bergmann
     @date    2005-10-05
Index: tests/domain_utils.cpp
===================================================================
--- tests/domain_utils.cpp	(revision 158327)
+++ tests/domain_utils.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/domain_utils.cpp
     @author  Jules Bergmann
     @date    2006-12-12
Index: tests/index_traversal.cpp
===================================================================
--- tests/index_traversal.cpp	(revision 158327)
+++ tests/index_traversal.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/index_traversal.cpp
     @author  Jules Bergmann
     @date    2006-06-12
Index: tests/extdata.cpp
===================================================================
--- tests/extdata.cpp	(revision 158327)
+++ tests/extdata.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/extdata.cpp
     @author  Jules Bergmann
     @date    2005-02-11
Index: tests/fftm.cpp
===================================================================
--- tests/fftm.cpp	(revision 158327)
+++ tests/fftm.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/fft.cpp
     @author  Nathan Myers
     @date    2005-08-12
Index: tests/extdata-output.hpp
===================================================================
--- tests/extdata-output.hpp	(revision 158327)
+++ tests/extdata-output.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/extdata-output.cpp
     @author  Jules Bergmann
     @date    04/13/2005
Index: tests/coverage_binary.cpp
===================================================================
--- tests/coverage_binary.cpp	(revision 158327)
+++ tests/coverage_binary.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/coverage_binary.hpp
     @author  Jules Bergmann
     @date    2005-09-13
Index: tests/vmmul.cpp
===================================================================
--- tests/vmmul.cpp	(revision 158327)
+++ tests/vmmul.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/vmmul.cpp
     @author  Jules Bergmann
     @date    2005-08-15
Index: tests/test-random.hpp
===================================================================
--- tests/test-random.hpp	(revision 158327)
+++ tests/test-random.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/test-random.cpp
     @author  Jules Bergmann
     @date    2005-09-07
Index: tests/util-par.hpp
===================================================================
--- tests/util-par.hpp	(revision 158327)
+++ tests/util-par.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/util-par.hpp
     @author  Jules Bergmann
     @date    2005-05-10
Index: tests/matvec-dot.cpp
===================================================================
--- tests/matvec-dot.cpp	(revision 158327)
+++ tests/matvec-dot.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/matvec-dot.cpp
     @author  Jules Bergmann
     @date    2005-10-11
Index: tests/solver-svd.cpp
===================================================================
--- tests/solver-svd.cpp	(revision 158327)
+++ tests/solver-svd.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/solver-svd.cpp
     @author  Jules Bergmann
     @date    2005-09-12
Index: tests/index.cpp
===================================================================
--- tests/index.cpp	(revision 158327)
+++ tests/index.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/index.cpp
     @author  Stefan Seefeld
     @date    2005-01-21
Index: tests/extdata-fft.cpp
===================================================================
--- tests/extdata-fft.cpp	(revision 158327)
+++ tests/extdata-fft.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/extdata_fft.cpp
     @author  Jules Bergmann
     @date    2005-04-05
Index: tests/coverage_unary.cpp
===================================================================
--- tests/coverage_unary.cpp	(revision 158327)
+++ tests/coverage_unary.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/coverage_unary.hpp
     @author  Jules Bergmann
     @date    2005-09-13
Index: tests/selgen-ramp.cpp
===================================================================
--- tests/selgen-ramp.cpp	(revision 158327)
+++ tests/selgen-ramp.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/selgen-ramp.cpp
     @author  Jules Bergmann
     @date    2005-08-15
Index: tests/tensor.cpp
===================================================================
--- tests/tensor.cpp	(revision 158327)
+++ tests/tensor.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/tensor.cpp
     @author  Stefan Seefeld
     @date    2005-04-26
Index: tests/parallel/corner-turn.cpp
===================================================================
--- tests/parallel/corner-turn.cpp	(revision 158327)
+++ tests/parallel/corner-turn.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/corner-turn.cpp
     @author  Jules Bergmann
     @date    2006-02-14
Index: tests/parallel/expr.cpp
===================================================================
--- tests/parallel/expr.cpp	(revision 158327)
+++ tests/parallel/expr.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/parallel/expr.cpp
     @author  Jules Bergmann
     @date    2005-05-18
Index: tests/parallel/user-storage.cpp
===================================================================
--- tests/parallel/user-storage.cpp	(revision 158327)
+++ tests/parallel/user-storage.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/parallel/user-storage.cpp
     @author  Jules Bergmann
     @date    2005-09-14
Index: tests/parallel/subset_map.cpp
===================================================================
--- tests/parallel/subset_map.cpp	(revision 158327)
+++ tests/parallel/subset_map.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/parallel/subset_map.cpp
     @author  Jules Bergmann
     @date    2006-12-08
Index: tests/parallel/replicated_data.cpp
===================================================================
--- tests/parallel/replicated_data.cpp	(revision 158327)
+++ tests/parallel/replicated_data.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/parallel/replicated_data.cpp
     @author  Jules Bergmann
     @date    2006-03-10
Index: tests/parallel/subviews.cpp
===================================================================
--- tests/parallel/subviews.cpp	(revision 158327)
+++ tests/parallel/subviews.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/parallel/subviews.cpp
     @author  Jules Bergmann
     @date    2005-07-07
Index: tests/parallel/getput.cpp
===================================================================
--- tests/parallel/getput.cpp	(revision 158327)
+++ tests/parallel/getput.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/parallel/getput.cpp
     @author  Jules Bergmann
     @date    2005-12-24
Index: tests/parallel/block.cpp
===================================================================
--- tests/parallel/block.cpp	(revision 158327)
+++ tests/parallel/block.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/parallel/block.cpp
     @author  Jules Bergmann
     @date    2005-03-22
Index: tests/parallel/matrix_subviews.cpp
===================================================================
--- tests/parallel/matrix_subviews.cpp	(revision 158327)
+++ tests/parallel/matrix_subviews.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/parallel/matrix_subviews.cpp
     @author  Jules Bergmann
     @date    2006-10-10
Index: tests/parallel/fftm.cpp
===================================================================
--- tests/parallel/fftm.cpp	(revision 158327)
+++ tests/parallel/fftm.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/parallel/fftm.cpp
     @author  Nathan Myers
     @date    2005-08-12
Index: tests/extdata-runtime.cpp
===================================================================
--- tests/extdata-runtime.cpp	(revision 158327)
+++ tests/extdata-runtime.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/extdata-runtime.cpp
     @author  Jules Bergmann
     @date    2005-07-26
Index: tests/support.cpp
===================================================================
--- tests/support.cpp	(revision 158327)
+++ tests/support.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    support.cpp
     @author  Jules Bergmann
     @date    2005-01-19
Index: tests/solver-covsol.cpp
===================================================================
--- tests/solver-covsol.cpp	(revision 158327)
+++ tests/solver-covsol.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/solver-covsol.cpp
     @author  Jules Bergmann
     @date    2005-09-06
Index: tests/extdata_dist.cpp
===================================================================
--- tests/extdata_dist.cpp	(revision 158327)
+++ tests/extdata_dist.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    extdata_dist.cpp
     @author  Jules Bergmann
     @date    2006-01-31
Index: tests/appmap.cpp
===================================================================
--- tests/appmap.cpp	(revision 158327)
+++ tests/appmap.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/appmap.cpp
     @author  Jules Bergmann
     @date    2005-03-22
Index: tests/tensor_subview.cpp
===================================================================
--- tests/tensor_subview.cpp	(revision 158327)
+++ tests/tensor_subview.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/tensor_subview.cpp
     @author  Jules Bergmann
     @date    2005-07-01
Index: tests/reductions.cpp
===================================================================
--- tests/reductions.cpp	(revision 158327)
+++ tests/reductions.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/reductions.cpp
     @author  Jules Bergmann
     @date    2005-07-11
Index: tests/fft.cpp
===================================================================
--- tests/fft.cpp	(revision 158327)
+++ tests/fft.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/fft.cpp
     @author  Jules Bergmann
     @date    2005-06-17
Index: tests/counter.cpp
===================================================================
--- tests/counter.cpp	(revision 158327)
+++ tests/counter.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 CodeSourcery, LLC.  All rights reserved.  */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    impl/counter.hpp
     @author  Zack Weinberg
     @date    2005-01-21
Index: tests/convolution.cpp
===================================================================
--- tests/convolution.cpp	(revision 158327)
+++ tests/convolution.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    convolution.cpp
     @author  Jules Bergmann
     @date    2005-06-09
Index: tests/us-block.cpp
===================================================================
--- tests/us-block.cpp	(revision 158327)
+++ tests/us-block.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/us-block.cpp
     @author  Jules Bergmann
     @date    2006-01-31
Index: tests/matvec-prod.cpp
===================================================================
--- tests/matvec-prod.cpp	(revision 158327)
+++ tests/matvec-prod.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/matvec-prod.cpp
     @author  Jules Bergmann
     @date    2005-09-12
Index: tests/elementwise.cpp
===================================================================
--- tests/elementwise.cpp	(revision 158327)
+++ tests/elementwise.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/elementwise.cpp
     @author  Don McCoy
     @date    2005-10-12
Index: tests/util.hpp
===================================================================
--- tests/util.hpp	(revision 158327)
+++ tests/util.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/util.hpp
     @author  Jules Bergmann
     @date    2005-05-10
Index: tests/view_cast.cpp
===================================================================
--- tests/view_cast.cpp	(revision 158327)
+++ tests/view_cast.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/view_cast.cpp
     @author  Jules Bergmann
     @date    2006-10-31
Index: tests/fast-block.cpp
===================================================================
--- tests/fast-block.cpp	(revision 158327)
+++ tests/fast-block.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/fast-block.cpp
     @author  Jules Bergmann
     @date    2005-04-12
Index: tests/coverage_comparison.cpp
===================================================================
--- tests/coverage_comparison.cpp	(revision 158327)
+++ tests/coverage_comparison.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/coverage_comparison.hpp
     @author  Jules Bergmann
     @date    2006-06-01
Index: tests/solver-lu.cpp
===================================================================
--- tests/solver-lu.cpp	(revision 158327)
+++ tests/solver-lu.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/solver-lu.cpp
     @author  Jules Bergmann
     @date    2005-09-30
Index: tests/solver-cholesky.cpp
===================================================================
--- tests/solver-cholesky.cpp	(revision 158327)
+++ tests/solver-cholesky.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/solver-cholesky.cpp
     @author  Jules Bergmann
     @date    2005-08-19
Index: tests/expr-test.cpp
===================================================================
--- tests/expr-test.cpp	(revision 158327)
+++ tests/expr-test.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    tests/expr-test.cpp
     @author  Jules Bergmann
     @date    2005-03-18
Index: scripting/png.cpp
===================================================================
--- scripting/png.cpp	(revision 158327)
+++ scripting/png.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, Inc.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    scripting/png.cpp
     @author  Stefan Seefeld
     @date    2006-09-20
Index: scripting/_base.cpp
===================================================================
--- scripting/_base.cpp	(revision 158327)
+++ scripting/_base.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, Inc.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    scripting/_base.cpp
     @author  Stefan Seefeld
     @date    2006-09-20
Index: scripting/math.cpp
===================================================================
--- scripting/math.cpp	(revision 158327)
+++ scripting/math.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, Inc.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    scripting/math.cpp
     @author  Stefan Seefeld
     @date    2006-09-20
Index: scripting/types.hpp
===================================================================
--- scripting/types.hpp	(revision 158327)
+++ scripting/types.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, Inc.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    scripting/types.hpp
     @author  Stefan Seefeld
     @date    2006-09-20
Index: scripting/signal.cpp
===================================================================
--- scripting/signal.cpp	(revision 158327)
+++ scripting/signal.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, Inc.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    scripting/signal.cpp
     @author  Stefan Seefeld
     @date    2006-09-20
Index: apps/ssar/diffview.cpp
===================================================================
--- apps/ssar/diffview.cpp	(revision 158327)
+++ apps/ssar/diffview.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    diffview.cpp
     @author  Don McCoy
     @date    2006-10-29
Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 158327)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    kernel.hpp
     @author  Don McCoy
     @date    2006-10-26
Index: apps/ssar/viewtoraw.cpp
===================================================================
--- apps/ssar/viewtoraw.cpp	(revision 158327)
+++ apps/ssar/viewtoraw.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    viewtoraw.cpp
     @author  Don McCoy
     @date    2006-10-28
Index: apps/ssar/ssar.cpp
===================================================================
--- apps/ssar/ssar.cpp	(revision 158327)
+++ apps/ssar/ssar.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    ssar.cpp
     @author  Don McCoy
     @date    2006-10-26
Index: apps/ssar/README
===================================================================
--- apps/ssar/README	(revision 158327)
+++ apps/ssar/README	(working copy)
@@ -1,6 +1,10 @@
 =============================================================================
 Scalable SAR (SSAR) Application Benchmark
 Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+
+This file is available for license from CodeSourcery, Inc. under the terms
+of a commercial license and under the GPL.  It is not part of the VSIPL++
+reference implementation and is not available under the BSD license.
 =============================================================================
 
 This directory contains the Sourcery VSIPL++ implementation of the
Index: apps/sarsim/sarsim.cpp
===================================================================
--- apps/sarsim/sarsim.cpp	(revision 158327)
+++ apps/sarsim/sarsim.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    sarsim.cpp
     @author  Jules Bergmann
     @date    03/02/2005
Index: apps/sarsim/sarsim.hpp
===================================================================
--- apps/sarsim/sarsim.hpp	(revision 158327)
+++ apps/sarsim/sarsim.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    sarsim.cpp
     @author  Jules Bergmann
     @date    03/02/2005
Index: apps/sarsim/fft-common.hpp
===================================================================
--- apps/sarsim/fft-common.hpp	(revision 158327)
+++ apps/sarsim/fft-common.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    fft-common.hpp
     @author  Jules Bergmann
     @date    15 Jun 2005
Index: apps/sarsim/loadview.hpp
===================================================================
--- apps/sarsim/loadview.hpp	(revision 158327)
+++ apps/sarsim/loadview.hpp	(working copy)
@@ -1,3 +1,16 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    loadview.hpp
+    @author  Jules Bergmann
+    @date    16 Jun 2005
+    @brief   VSIPL++ Library: Load views from file.
+*/
+
+
 // -------------------------------------------------------------------- //
 template <typename T>
 struct LoadViewTraits
Index: apps/sarsim/mit-sarsim.cpp
===================================================================
--- apps/sarsim/mit-sarsim.cpp	(revision 158327)
+++ apps/sarsim/mit-sarsim.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    sarsim.cpp
     @author  Jules Bergmann
     @date    03/02/2005
Index: apps/sarsim/cast-block.hpp
===================================================================
--- apps/sarsim/cast-block.hpp	(revision 158327)
+++ apps/sarsim/cast-block.hpp	(working copy)
@@ -1,6 +1,10 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
-/** @file    vsip/impl/cast-block.hpp
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    cast-block.hpp
     @author  Jules Bergmann
     @date    06/15/2005
     @brief   VSIPL++ Library: Cast block class.
Index: apps/sarsim/read_tbv.h
===================================================================
--- apps/sarsim/read_tbv.h	(revision 158327)
+++ apps/sarsim/read_tbv.h	(working copy)
@@ -1,3 +1,9 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 // Header file for read_tbv.c
 // Jules Bergmann, 2 Mar 05
 
Index: apps/sarsim/saveview.hpp
===================================================================
--- apps/sarsim/saveview.hpp	(revision 158327)
+++ apps/sarsim/saveview.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    example/common/saveview.hpp
     @author  Jules Bergmann
     @date    03/02/2005
Index: apps/sarsim/util_io.c
===================================================================
--- apps/sarsim/util_io.c	(revision 158327)
+++ apps/sarsim/util_io.c	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    util_io.c
     @author  Jules Bergmann
     @date    02/22/2005
Index: apps/sarsim/util_io.h
===================================================================
--- apps/sarsim/util_io.h	(revision 158327)
+++ apps/sarsim/util_io.h	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    util_io.h
     @author  Jules Bergmann
     @date    02/22/2005
Index: apps/sarsim/fft.hpp
===================================================================
--- apps/sarsim/fft.hpp	(revision 158327)
+++ apps/sarsim/fft.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    fft.hpp
     @author  Jules Bergmann
     @date    30 Mar 2005
Index: apps/sarsim/read_adts.h
===================================================================
--- apps/sarsim/read_adts.h	(revision 158327)
+++ apps/sarsim/read_adts.h	(working copy)
@@ -1,3 +1,9 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 // Header file for read_adts.c
 // Jules Bergmann, 2 Mar 05
 
Index: benchmarks/vmagsq.cpp
===================================================================
--- benchmarks/vmagsq.cpp	(revision 158327)
+++ benchmarks/vmagsq.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/vmul.cpp
     @author  Jules Bergmann
     @date    2006-06-01
Index: benchmarks/prod.cpp
===================================================================
--- benchmarks/prod.cpp	(revision 158327)
+++ benchmarks/prod.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/prod.cpp
     @author  Jules Bergmann
     @date    2005-10-11
Index: benchmarks/mpi/alltoall.cpp
===================================================================
--- benchmarks/mpi/alltoall.cpp	(revision 158327)
+++ benchmarks/mpi/alltoall.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/alltoall_mpi.cpp
     @author  Jules Bergmann
     @date    2005-11-06
Index: benchmarks/mpi/copy.cpp
===================================================================
--- benchmarks/mpi/copy.cpp	(revision 158327)
+++ benchmarks/mpi/copy.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/copy_mpi.cpp
     @author  Jules Bergmann
     @date    2006-07-23
Index: benchmarks/conv.cpp
===================================================================
--- benchmarks/conv.cpp	(revision 158327)
+++ benchmarks/conv.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/conv.cpp
     @author  Jules Bergmann
     @date    2005-07-11
Index: benchmarks/corr.cpp
===================================================================
--- benchmarks/corr.cpp	(revision 158327)
+++ benchmarks/corr.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/corr.cpp
     @author  Jules Bergmann
     @date    2005-10-06
Index: benchmarks/create_map.hpp
===================================================================
--- benchmarks/create_map.hpp	(revision 158327)
+++ benchmarks/create_map.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/create_map.hpp
     @author  Jules Bergmann
     @date    2006-07-26
Index: benchmarks/dist_vmul.cpp
===================================================================
--- benchmarks/dist_vmul.cpp	(revision 158327)
+++ benchmarks/dist_vmul.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/dist_vmul.cpp
     @author  Jules Bergmann
     @date    2006-07-21
Index: benchmarks/ipp/fft.cpp
===================================================================
--- benchmarks/ipp/fft.cpp	(revision 158327)
+++ benchmarks/ipp/fft.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/fft_ipp.cpp
     @author  Jules Bergmann
     @date    2005-08-24
Index: benchmarks/ipp/fft_ext.cpp
===================================================================
--- benchmarks/ipp/fft_ext.cpp	(revision 158327)
+++ benchmarks/ipp/fft_ext.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/fft_ext_ipp.cpp
     @author  Jules Bergmann
     @date    2005-09-01
Index: benchmarks/ipp/vmul.cpp
===================================================================
--- benchmarks/ipp/vmul.cpp	(revision 158327)
+++ benchmarks/ipp/vmul.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/vmul_ipp.cpp
     @author  Jules Bergmann
     @date    2005-08-24
Index: benchmarks/ipp/conv.cpp
===================================================================
--- benchmarks/ipp/conv.cpp	(revision 158327)
+++ benchmarks/ipp/conv.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/conv_ipp.cpp
     @author  Jules Bergmann
     @date    2005-08-24
Index: benchmarks/ipp/mcopy.cpp
===================================================================
--- benchmarks/ipp/mcopy.cpp	(revision 158327)
+++ benchmarks/ipp/mcopy.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/mcopy_ipp.cpp
     @author  Jules Bergmann
     @date    2005-02-06
Index: benchmarks/vdiv.cpp
===================================================================
--- benchmarks/vdiv.cpp	(revision 158327)
+++ benchmarks/vdiv.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/vdiv.cpp
     @author  Don McCoy
     @date    2006-04-30
Index: benchmarks/copy.cpp
===================================================================
--- benchmarks/copy.cpp	(revision 158327)
+++ benchmarks/copy.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/copy.cpp
     @author  Jules Bergmann
     @date    2005-08-27
Index: benchmarks/lapack/qrd.cpp
===================================================================
--- benchmarks/lapack/qrd.cpp	(revision 158327)
+++ benchmarks/lapack/qrd.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/qrd.cpp
     @author  Jules Bergmann
     @date    2005-07-11
Index: benchmarks/loop.hpp
===================================================================
--- benchmarks/loop.hpp	(revision 158327)
+++ benchmarks/loop.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    loop.hpp
     @author  Jules Bergmann
     @date    2005-07-11
Index: benchmarks/fir.cpp
===================================================================
--- benchmarks/fir.cpp	(revision 158327)
+++ benchmarks/fir.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/fir.cpp
     @author  Jules Bergmann, Nathan Myers
     @date    2005-08-13
Index: benchmarks/benchmarks.hpp
===================================================================
--- benchmarks/benchmarks.hpp	(revision 158327)
+++ benchmarks/benchmarks.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/benchmarks.hpp
     @author  Don McCoy
     @date    2006-03-16
Index: benchmarks/fastconv.cpp
===================================================================
--- benchmarks/fastconv.cpp	(revision 158327)
+++ benchmarks/fastconv.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/fastconv.cpp
     @author  Jules Bergmann
     @date    2005-10-28
Index: benchmarks/vma.cpp
===================================================================
--- benchmarks/vma.cpp	(revision 158327)
+++ benchmarks/vma.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/vma.cpp
     @author  Jules Bergmann
     @date    2006-05-25
Index: benchmarks/vmul.cpp
===================================================================
--- benchmarks/vmul.cpp	(revision 158327)
+++ benchmarks/vmul.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/vmul.cpp
     @author  Jules Bergmann
     @date    2005-07-11
Index: benchmarks/main.cpp
===================================================================
--- benchmarks/main.cpp	(revision 158327)
+++ benchmarks/main.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/main.cpp
     @author  Jules Bergmann
     @date    2005-08-10
Index: benchmarks/dot.cpp
===================================================================
--- benchmarks/dot.cpp	(revision 158327)
+++ benchmarks/dot.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/dot.cpp
     @author  Jules Bergmann
     @date    2005-10-11
Index: benchmarks/vmul.hpp
===================================================================
--- benchmarks/vmul.hpp	(revision 158327)
+++ benchmarks/vmul.hpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/vmul.hpp
     @author  Jules Bergmann
     @date    2005-07-11
Index: benchmarks/memwrite.cpp
===================================================================
--- benchmarks/memwrite.cpp	(revision 158327)
+++ benchmarks/memwrite.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/memwrite.cpp
     @author  Jules Bergmann
     @date    2006-10-12
Index: benchmarks/fftm.cpp
===================================================================
--- benchmarks/fftm.cpp	(revision 158327)
+++ benchmarks/fftm.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/fftm.cpp
     @author  Jules Bergmann
     @date    2005-12-14
Index: benchmarks/sal/fft.cpp
===================================================================
--- benchmarks/sal/fft.cpp	(revision 158327)
+++ benchmarks/sal/fft.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/fft_sal.cpp
     @author  Jules Bergmann
     @date    2006-08-02
Index: benchmarks/sal/fastconv.cpp
===================================================================
--- benchmarks/sal/fastconv.cpp	(revision 158327)
+++ benchmarks/sal/fastconv.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/fastconv_sal.cpp
     @author  Jules Bergmann, Don McCoy
     @date    2005-10-28
Index: benchmarks/sal/vma.cpp
===================================================================
--- benchmarks/sal/vma.cpp	(revision 158327)
+++ benchmarks/sal/vma.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/vma_sal.cpp
     @author  Jules Bergmann
     @date    2006-06-01
Index: benchmarks/sal/vmul.cpp
===================================================================
--- benchmarks/sal/vmul.cpp	(revision 158327)
+++ benchmarks/sal/vmul.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/vmul_sal.cpp
     @author  Don McCoy
     @date    2005-01-23
Index: benchmarks/sal/memwrite.cpp
===================================================================
--- benchmarks/sal/memwrite.cpp	(revision 158327)
+++ benchmarks/sal/memwrite.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/memwrite_sal.cpp
     @author  Jules Bergmann
     @date    2006-10-12
Index: benchmarks/hpec_kernel/cfar.cpp
===================================================================
--- benchmarks/hpec_kernel/cfar.cpp	(revision 158327)
+++ benchmarks/hpec_kernel/cfar.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/hpec-kernel/cfar.cpp
     @author  Don McCoy
     @date    2006-04-21
Index: benchmarks/hpec_kernel/firbank.cpp
===================================================================
--- benchmarks/hpec_kernel/firbank.cpp	(revision 158327)
+++ benchmarks/hpec_kernel/firbank.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    firbank.cpp
     @author  Don McCoy
     @date    2006-01-26
Index: benchmarks/hpec_kernel/svd.cpp
===================================================================
--- benchmarks/hpec_kernel/svd.cpp	(revision 158327)
+++ benchmarks/hpec_kernel/svd.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/hpec-kernel/svd.cpp
     @author  Don McCoy
     @date    2006-04-06
@@ -194,7 +198,7 @@
   int svd_ops(length_type m, length_type n, length_type s)
   {
     // Workload calculations are taken from from impl_decompose()
-    // in impl/solver-svd.hpp:
+    // in opt/lapack/svd.hpp:
 
     // step 1
     int step_one_ops = ((m >= n) ?
Index: benchmarks/hpec_kernel/cfar_c.cpp
===================================================================
--- benchmarks/hpec_kernel/cfar_c.cpp	(revision 158327)
+++ benchmarks/hpec_kernel/cfar_c.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/hpec-kernel/cfar_c.cpp
     @author  Don McCoy, Jules Bergmann
     @date    2006-06-07
Index: benchmarks/vmmul.cpp
===================================================================
--- benchmarks/vmmul.cpp	(revision 158327)
+++ benchmarks/vmmul.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/vmmul.cpp
     @author  Jules Bergmann
     @date    2005-12-14
Index: benchmarks/memwrite_simd.cpp
===================================================================
--- benchmarks/memwrite_simd.cpp	(revision 158327)
+++ benchmarks/memwrite_simd.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/memwrite_simd.cpp
     @author  Jules Bergmann
     @date    2006-10-13
Index: benchmarks/sumval.cpp
===================================================================
--- benchmarks/sumval.cpp	(revision 158327)
+++ benchmarks/sumval.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/sumval.cpp
     @author  Jules Bergmann
     @date    2005-07-11
Index: benchmarks/prod_var.cpp
===================================================================
--- benchmarks/prod_var.cpp	(revision 158327)
+++ benchmarks/prod_var.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/prod_var.cpp
     @author  Jules Bergmann
     @date    2005-11-07
Index: benchmarks/fft.cpp
===================================================================
--- benchmarks/fft.cpp	(revision 158327)
+++ benchmarks/fft.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/fft.cpp
     @author  Jules Bergmann
     @date    2005-08-24
Index: benchmarks/sumval_simd.cpp
===================================================================
--- benchmarks/sumval_simd.cpp	(revision 158327)
+++ benchmarks/sumval_simd.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/sumval_simd.cpp
     @author  Jules Bergmann
     @date    2006-10-13
Index: benchmarks/vmul_c.cpp
===================================================================
--- benchmarks/vmul_c.cpp	(revision 158327)
+++ benchmarks/vmul_c.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/vmul.cpp
     @author  Jules Bergmann
     @date    2006-01-23
Index: benchmarks/vmul_par.cpp
===================================================================
--- benchmarks/vmul_par.cpp	(revision 158327)
+++ benchmarks/vmul_par.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/vmul_par.cpp
     @author  Jules Bergmann
     @date    2006-10-12
Index: benchmarks/mcopy.cpp
===================================================================
--- benchmarks/mcopy.cpp	(revision 158327)
+++ benchmarks/mcopy.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/mcopy.cpp
     @author  Jules Bergmann
     @date    2005-10-14
Index: benchmarks/maxval.cpp
===================================================================
--- benchmarks/maxval.cpp	(revision 158327)
+++ benchmarks/maxval.cpp	(working copy)
@@ -1,5 +1,9 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
 
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
 /** @file    benchmarks/maxval.cpp
     @author  Jules Bergmann
     @date    2006-06-01
