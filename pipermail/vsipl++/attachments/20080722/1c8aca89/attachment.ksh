Index: ChangeLog
===================================================================
--- ChangeLog	(revision 215407)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2008-07-22  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/cbe/cml/fir.hpp: Use CML FIR state copy.
+
+2008-07-22  Jules Bergmann  <jules@codesourcery.com>
+
 	* tests/regressions/fir_copy_cons.cpp: New regression test,
 	  illustrates FIR copy cons failure w/ CML FIR BE.
 
Index: src/vsip/opt/cbe/cml/fir.hpp
===================================================================
--- src/vsip/opt/cbe/cml/fir.hpp	(revision 215403)
+++ src/vsip/opt/cbe/cml/fir.hpp	(working copy)
@@ -27,6 +27,7 @@
 #include <vsip/opt/dispatch.hpp>
 
 #include <cml/ppu/cml.h>
+#include <cml/ppu/cml_core.h>
 
 
 /***********************************************************************
@@ -62,6 +63,14 @@
 }
 
 inline void
+fir_copy_state(
+  cml_fir_f const* src_fir_obj_handle,
+  cml_fir_f*       dst_fir_obj_handle)
+{
+  cml_impl_fir_copy_state_f(src_fir_obj_handle, dst_fir_obj_handle);
+}
+
+inline void
 fir_apply(
   cml_fir_f*            fir_obj_ptr,
   float const*          A,
@@ -137,6 +146,7 @@
       this->filter_state_,
       this->kernel_size(),
       this->input_size());
+    fir_copy_state(fir.fir_obj_ptr_, fir_obj_ptr_);
   }
 
   ~Fir_impl()
