Index: ChangeLog
===================================================================
--- ChangeLog	(revision 207599)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2008-05-13  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/opt/cbe/ppu/alf.hpp: Initialize ALF through CML if
+	  available (according to VSIP_IMPL_HAVE_CML).
+
 2008-05-05  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* m4/cbe.m4: Fix handling of with_cbe_sdk_sysroot.
Index: src/vsip/opt/cbe/ppu/alf.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/alf.hpp	(revision 207599)
+++ src/vsip/opt/cbe/ppu/alf.hpp	(working copy)
@@ -17,6 +17,10 @@
 # error "vsip/opt files cannot be used as part of the reference impl."
 #endif
 
+#ifdef VSIP_IMPL_HAVE_CML
+#include <cml/ppu/cml.h>
+#endif
+
 #include <vsip/core/config.hpp>
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/support.hpp>
@@ -137,6 +141,9 @@
   ALF(unsigned int num_accelerators)
     : num_accelerators_(num_accelerators)
   {
+#ifdef VSIP_IMPL_HAVE_CML
+    cml_init();
+#else
     int status = alf_init(0, &alf_);
     assert(status >= 0);
     if (num_accelerators) 
@@ -144,8 +151,16 @@
       set_num_accelerators(num_accelerators);
       assert(status >= 0);
     }
+#endif
   }
-  ~ALF() { alf_exit(&alf_, ALF_EXIT_POLICY_WAIT, -1);}
+  ~ALF() 
+  { 
+#ifdef VSIP_IMPL_HAVE_CML
+    cml_fini();
+#else
+    alf_exit(&alf_, ALF_EXIT_POLICY_WAIT, -1);
+#endif
+  }
   void set_num_accelerators(unsigned int n) { alf_num_instances_set(alf_, n);}
   unsigned int num_accelerators() const { return num_accelerators_;}
 
