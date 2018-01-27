Index: src/vsip/initfin.cpp
===================================================================
--- src/vsip/initfin.cpp	(revision 146615)
+++ src/vsip/initfin.cpp	(working copy)
@@ -24,6 +24,7 @@
 /// no matter how many \c vsipl objects are created.
 impl::Checked_counter vsipl::use_count = 0;
 impl::Par_service* vsipl::par_service_ = NULL;
+impl::profile::Profiler_options* vsipl::profiler_opts_ = NULL;
 
 /// If there are no other extant \c vsipl objects, this function
 /// will initialize the library so it can be used.  If other
@@ -122,7 +123,11 @@
   if (use_count++ != 0)
     return;
 
-  // Nothing to do yet.
+  // Profiler options should be called first.  Arguments
+  // are passed by reference, but left intact in order 
+  // to be passed on to Par_service.
+  profiler_opts_ = new impl::profile::Profiler_options(argc, argv);
+
   par_service_ = new impl::Par_service(argc, argv);
 }
 
@@ -136,7 +141,9 @@
   if (--use_count != 0)
     return;
 
-  // Nothing to do yet.
   delete par_service_;
   par_service_ = NULL;
+
+  delete profiler_opts_;
+  profiler_opts_ = NULL;
 }
Index: src/vsip/profile.cpp
===================================================================
--- src/vsip/profile.cpp	(revision 146615)
+++ src/vsip/profile.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
 /** @file    prof.cpp
     @author  Jules Bergmann
@@ -10,7 +10,6 @@
   Included Files
 ***********************************************************************/
 
-#include <iostream>
 #include <fstream>
 
 #include <vsip/impl/profile.hpp>
@@ -238,6 +237,66 @@
 }
 
 
+
+#define MODE_OPTION    "--vsipl++-profile-mode"
+#define MODE_LENGTH    (strlen(MODE_OPTION))
+
+#define OUTPUT_OPTION  "--vsipl++-profile-output"
+#define OUTPUT_LENGTH  (strlen(OUTPUT_OPTION))
+
+Profiler_options::Profiler_options(int const& argc, char** const& argv)
+    : profile_(NULL)
+{
+  int count = argc;
+  char** value = argv;
+  profiler_mode mode = pm_none;
+  char* filename = NULL;
+
+  while (--count)
+  {
+    ++value;
+    if (!strncmp(*value, MODE_OPTION, MODE_LENGTH))
+    {
+      if (strlen(*value) > MODE_LENGTH + 1)
+      {
+        char* mode_str = &(*value)[MODE_LENGTH + 1];
+
+        if (!strcmp(mode_str, "accum"))
+          mode = pm_accum;
+        else
+        if (!strcmp(mode_str, "trace"))
+          mode = pm_trace;
+      }
+    }
+    else
+    if (!strncmp(*value, OUTPUT_OPTION, OUTPUT_LENGTH))
+    {
+      if (strlen(*value) > OUTPUT_LENGTH + 1)
+        filename = &(*value)[OUTPUT_LENGTH + 1];
+    }
+  }
+
+  if (mode != pm_none)
+  {
+    if (filename)
+      this->profile_ = new Profile(filename, mode);
+    else
+      this->profile_ = new Profile("/dev/stdout", mode);
+  }
+}
+
+Profiler_options::~Profiler_options()
+{
+  if (this->profile_)
+    delete this->profile_;
+}
+
+#undef MODE_OPTION
+#undef MODE_LENGTH
+#undef OUTPUT_OPTION
+#undef OUTPUT_LENGTH
+
+
 } // namespace vsip::impl::profile
 } // namespace vsip::impl
 } // namespace vsip
Index: src/vsip/initfin.hpp
===================================================================
--- src/vsip/initfin.hpp	(revision 146615)
+++ src/vsip/initfin.hpp	(working copy)
@@ -32,6 +32,10 @@
 {
 // Forward Declaration
 class Par_service;
+namespace profile
+{
+class Profiler_options;
+} // namespace profile
 } // namespace impl
   
 /// Class for management of library private data structures.
@@ -74,6 +78,8 @@
   /// Parallel Service.
   static impl::Par_service* par_service_;
 
+  /// Profiler.
+  static impl::profile::Profiler_options* profiler_opts_;
 
   // Internal functions:
 private:
Index: src/vsip/impl/profile.hpp
===================================================================
--- src/vsip/impl/profile.hpp	(revision 146615)
+++ src/vsip/impl/profile.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/impl/profile.hpp
     @author  Jules Bergmann
@@ -13,7 +13,6 @@
   Included Files
 ***********************************************************************/
 
-#include <string>
 #include <vector>
 #include <map>
 #include <string>
@@ -367,6 +366,17 @@
   char* const filename_;
 };
 
+class Profiler_options
+{
+  // Constructors.
+public:
+  Profiler_options(int const& argc, char** const& argv);
+  ~Profiler_options();
+
+private:
+  Profile* profile_;
+};
+
 class Profile_event
 {
   typedef DefaultTime    TP;
