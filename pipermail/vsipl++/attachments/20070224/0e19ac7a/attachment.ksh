Index: ChangeLog
===================================================================
--- ChangeLog	(revision 164033)
+++ ChangeLog	(working copy)
@@ -1,3 +1,17 @@
+2007-02-24  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/initfin.cpp: Pass argv/argc to Task_manager::initialize.
+	* src/vsip/core/argv_utils.hpp: New file, contains shift_argv func.
+	* src/vsip/core/parallel/services.hpp: Fix header comment.
+	* src/vsip/opt/pas/services.hpp (shift_argv): Move defn to
+	  argv_utils.hpp.
+	* src/vsip/opt/profile.hpp: Make strings 'char const*'.
+	* src/vsip/opt/cbe/ppu/task_manager.hpp (initialize): Process
+	  argc/argv to determine number of SPEs.
+	* src/vsip/opt/cbe/ppu/task_manager.cpp: Likewise.
+	* src/vsip/opt/cbe/ppu/alf.hpp: Make number of accelerators
+	  a runtime parameter.
+
 2007-02-22  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip/opt/cbe/ppu/alf.hpp: Store more data in Task type.
Index: src/vsip/initfin.cpp
===================================================================
--- src/vsip/initfin.cpp	(revision 164033)
+++ src/vsip/initfin.cpp	(working copy)
@@ -133,7 +133,7 @@
   profiler_opts_ = new impl::profile::Profiler_options(argc, argv);
 
 # if defined(VSIP_IMPL_CBE_SDK)
-  impl::cbe::Task_manager::initialize();
+  impl::cbe::Task_manager::initialize(argc, argv);
 # endif
 
 #endif
Index: src/vsip/core/argv_utils.hpp
===================================================================
--- src/vsip/core/argv_utils.hpp	(revision 0)
+++ src/vsip/core/argv_utils.hpp	(revision 0)
@@ -0,0 +1,34 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+*/
+/** @file    vsip/core/argv_utils.hpp
+    @author  Jules Bergmann
+    @date    2007-02-24
+    @brief   VSIPL++ Library: Utils for mucking with argv.
+
+*/
+
+#ifndef VSIP_CORE_ARGV_UTILS_HPP
+#define VSIP_CORE_ARGV_UTILS_HPP
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+inline void
+shift_argv(int& argc, char**&argv, int pos, int shift)
+{
+  for (int i=pos; i<argc-shift; ++i)
+    argv[i] = argv[i+shift];
+  argc -= shift;
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_CORE_ARGV_UTILS_HPP
Index: src/vsip/core/parallel/services.hpp
===================================================================
--- src/vsip/core/parallel/services.hpp	(revision 164033)
+++ src/vsip/core/parallel/services.hpp	(working copy)
@@ -1,6 +1,6 @@
 /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    vsip/core/parallel.hpp
+/** @file    vsip/core/parallel/services.hpp
     @author  Jules Bergmann
     @date    2005-03-25
     @brief   VSIPL++ Library: Common header for parallel services.
Index: src/vsip/opt/pas/services.hpp
===================================================================
--- src/vsip/opt/pas/services.hpp	(revision 164033)
+++ src/vsip/opt/pas/services.hpp	(working copy)
@@ -46,6 +46,7 @@
 #include <vsip/core/parallel/copy_chain.hpp>
 #include <vsip/core/reductions/types.hpp>
 #include <vsip/core/parallel/assign_fwd.hpp>
+#include <vsip/core/argv_utils.hpp>
 #include <vsip/opt/pas/param.hpp>
 #include <vsip/opt/pas/broadcast.hpp>
 
@@ -357,15 +358,7 @@
 }
 
 
-inline void
-shift_argv(int& argc, char**&argv, int pos, int shift)
-{
-  for (int i=pos; i<argc-shift; ++i)
-    argv[i] = argv[i+shift];
-  argc -= shift;
-}
 
-
 /// Par_service class for when using PAS parallel services.
 
 class Par_service
Index: src/vsip/opt/profile.hpp
===================================================================
--- src/vsip/opt/profile.hpp	(revision 164033)
+++ src/vsip/opt/profile.hpp	(working copy)
@@ -110,7 +110,7 @@
 struct No_time
 {
   static bool const valid = false; 
-  static char* name() { return "No_time"; }
+  static char const* name() { return "No_time"; }
   static void init() {}
 
   typedef int stamp_type;
@@ -133,7 +133,7 @@
 struct Posix_time
 {
   static bool const valid = true; 
-  static char* name() { return "Posix_time"; }
+  static char const* name() { return "Posix_time"; }
   static void init() { clocks_per_sec = CLOCKS_PER_SEC; }
 
   typedef clock_t stamp_type;
@@ -156,7 +156,7 @@
 struct Posix_real_time
 {
   static bool const valid = true; 
-  static char* name() { return "Posix_real_time"; }
+  static char const* name() { return "Posix_real_time"; }
   static void init() { clocks_per_sec.tv_sec = 1; clocks_per_sec.tv_nsec = 0; }
 
   static clockid_t const clock = CLOCK_REALTIME;
@@ -211,7 +211,7 @@
 struct Pentium_tsc_time
 {
   static bool const valid = true; 
-  static char* name() { return "Pentium_tsc_time"; }
+  static char const* name() { return "Pentium_tsc_time"; }
   static void init();
 
   typedef long long stamp_type;
@@ -235,7 +235,7 @@
 struct X86_64_tsc_time
 {
   static bool const valid = true; 
-  static char* name() { return "x86_64_tsc_time"; }
+  static char const* name() { return "x86_64_tsc_time"; }
   static void init();
 
   typedef unsigned long long stamp_type;
@@ -260,7 +260,7 @@
   typedef TMR_timespec stamp_type;
 
   static bool const valid = true; 
-  static char* name() { return "Mcoe_tmr_time"; }
+  static char const* name() { return "Mcoe_tmr_time"; }
   static void init()
   {
     tmr_timestamp(&time0); 
@@ -325,7 +325,7 @@
 struct Power_tb_time
 {
   static bool const valid = true; 
-  static char* name() { return "Power_tb_time"; }
+  static char const* name() { return "Power_tb_time"; }
   static void init();
 
   typedef long long stamp_type;
Index: src/vsip/opt/cbe/ppu/task_manager.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/task_manager.hpp	(revision 164033)
+++ src/vsip/opt/cbe/ppu/task_manager.hpp	(working copy)
@@ -22,6 +22,7 @@
 ***********************************************************************/
 
 #include <vsip/core/expr/operations.hpp>
+#include <vsip/core/argv_utils.hpp>
 #include <vsip/opt/cbe/ppu/alf.hpp>
 extern "C"
 {
@@ -52,7 +53,20 @@
 
   static Task_manager *instance() { return instance_;}
 
-  static void initialize() { instance_ = new Task_manager();}
+  static void initialize(int& argc, char**&argv)
+  {
+    unsigned int num_spes = 8;
+    for (int i=1; i < argc; ++i)
+    {
+      if (!strcmp(argv[i], "--svpp-num-spes"))
+      {
+	num_spes = atoi(argv[i+1]);
+	shift_argv(argc, argv, i, 2);
+      }
+    }
+    
+    instance_ = new Task_manager(num_spes);
+  }
   static void finalize() { delete instance_; instance_ = 0;}
 
   // Return a task for operation O (with signature S).
@@ -78,7 +92,7 @@
   }
 
 private:
-  Task_manager();
+  Task_manager(unsigned int num_spes);
   Task_manager(Task_manager const &);
   ~Task_manager();
   Task_manager &operator= (Task_manager const &);
Index: src/vsip/opt/cbe/ppu/alf.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/alf.hpp	(revision 164033)
+++ src/vsip/opt/cbe/ppu/alf.hpp	(working copy)
@@ -165,12 +165,11 @@
 class ALF
 {
 public:
-  static unsigned int const num_accelerators = 16;
-
-  ALF()// : impl_(ALF_NULL_HANDLE) 
+  ALF(unsigned int num_accelerators)// : impl_(ALF_NULL_HANDLE) 
+    : num_accelerators_(num_accelerators)
   {
     alf_configure(0);
-    if (alf_init(&impl_, num_accelerators, ALF_INIT_PERSIST) <= 0)
+    if (alf_init(&impl_, num_accelerators_, ALF_INIT_PERSIST) <= 0)
       VSIP_IMPL_THROW(std::bad_alloc());
 //     alf_register_error_handler(impl_, error_handler, 0);
   }
@@ -208,7 +207,9 @@
 #endif
   }
 
+  // Member data.
 private:
+  unsigned int const num_accelerators_;
   alf_handle_t impl_;
 };
 
Index: src/vsip/opt/cbe/ppu/task_manager.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/task_manager.cpp	(revision 164033)
+++ src/vsip/opt/cbe/ppu/task_manager.cpp	(working copy)
@@ -25,8 +25,8 @@
 
 Task_manager *Task_manager::instance_ = 0;
 
-Task_manager::Task_manager()
-  : alf_(new ALF())
+Task_manager::Task_manager(unsigned int num_spes)
+  : alf_(new ALF(num_spes))
 {
 }
 
