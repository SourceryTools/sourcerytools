Index: src/vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.cpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.cpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.cpp	(revision 0)
@@ -0,0 +1,21 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.hpp
+    @author  Jules Bergmann
+    @date    2008-08-07
+    @brief   VSIPL++ Library: Elementwise vector multiply ukernel.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.hpp>
+
+typedef Zvmul_kernel kernel_type;
+
+#include <vsip/opt/ukernel/cbe_accel/alf_base.hpp>
Index: src/vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.hpp	(revision 219699)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.hpp	(working copy)
@@ -17,9 +17,10 @@
 #include <utility>
 #include <cml/spu/cml.h>
 #include <cml/spu/cml_core.h>
-#include <vsip/opt/cbe/spu/ukernel.hpp>
+#include <vsip/opt/ukernel/cbe_accel/ukernel.hpp>
 
 
+#define DEBUG 0
 
 /***********************************************************************
   Definitions
Index: src/vsip/opt/ukernel/kernels/host/vmul.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/host/vmul.hpp	(revision 219699)
+++ src/vsip/opt/ukernel/kernels/host/vmul.hpp	(working copy)
@@ -82,5 +82,7 @@
 		    void(float*, float*, float*), vmul_f)
 DEFINE_UKERNEL_TASK(Vmul_kernel,
 		    void(std::complex<float>*, std::complex<float>*, std::complex<float>*), cvmul_f)
+DEFINE_UKERNEL_TASK(Vmul_kernel,
+                    void(std::pair<float*, float*>, std::pair<float*, float*>, std::pair<float*, float*>), zvmul_f)
 
 #endif // VSIP_SRC_OPT_UKERNEL_KERNELS_HOST_VMUL_HPP
