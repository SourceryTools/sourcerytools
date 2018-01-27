Index: kernel1.hpp
===================================================================
--- kernel1.hpp	(revision 221524)
+++ kernel1.hpp	(working copy)
@@ -13,6 +13,8 @@
 #include <vsip/selgen.hpp>
 
 #include <vsip/core/profile.hpp>
+#include <vsip_csl/ukernel.hpp>
+#include <vsip/opt/ukernel/kernels/host/interp.hpp>
 
 #include <vsip_csl/matlab_utils.hpp>
 #include <vsip_csl/save_view.hpp>
@@ -39,6 +41,20 @@
 // can be distributed amongst several compute elements and run in parallel.
 #define DIGITAL_SPOTLIGHT_BY_ROW  1
 
+
+// On Cell/B.E. platforms, this may be defined to utilize a user-defined
+// kernel for part of the interpolation stage.
+//
+// Setting it to '1' will utilize the kernel for the range-loop portion
+// of the computation (polar-to-rectangular interpolation) which will 
+// distribute groups of columns of the image to the SPEs.  This processes
+// data in parallel with a corresponding increase in performance.
+//
+// Setting it to '0' will perform the computation entirely on the PPE
+// as it does on x86 processors.
+#define USE_CELL_UKERNEL  0
+
+
 template <typename T>
 class Kernel1_base
 {
@@ -689,6 +705,16 @@
 
   // 86b. begin the range loop
   { Scope<user> scope("range loop", range_loop_ops_);
+#if USE_CELL_UKERNEL
+  Interp_kernel obj;
+  ukernel::Ukernel<Interp_kernel> uk(obj);
+  uk(
+    icKX_.transpose(), 
+    SINC_HAM_.template transpose<1, 0, 2>(), 
+    fsm_t_.transpose(), 
+    F_.transpose());
+
+#else
   for (index_type j = 0; j < m_; ++j)
   {
     for (index_type i = 0; i < n_; ++i)
@@ -709,6 +735,8 @@
       }
     }
   } // 93. end the range loop
+
+#endif
   }
 
   SAVE_VIEW("p92_F.view", F_, this->swap_bytes_);
