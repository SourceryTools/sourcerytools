Index: ChangeLog
===================================================================
--- ChangeLog	(revision 157545)
+++ ChangeLog	(working copy)
@@ -1,3 +1,13 @@
+2006-12-19  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/profile.hpp (Power_tb_time): New timer policy
+	  to use PowerPC timebase timer.
+	* src/vsip/opt/profile.cpp (read_timebase): New function, read
+	  timebase from cpuinfo.  Use to determine Power_tb_time
+	  clocks_per_sec.
+	* configure.ac (--enable-timer=power_tb): Allow selection of
+	  PowerPC timebase timer.
+	
 2006-12-14  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip_csl/load_view.hpp (load_view_as): Extend to work
@@ -326,11 +336,11 @@
 
 2006-11-26  Don McCoy  <don@codesourcery.com>
 
-        * apps/ssar/kernel1.hpp: Made some data members in constructors local as
+	* apps/ssar/kernel1.hpp: Made some data members in constructors local as
           they did not need to be retained.  Some minor renaming and comment-
           fixing for consistency.  Fixed the two asserts in interpolate to
           check for the correct size.
-        * apps/ssar/ssar.cpp: Added display of setup time, plus max, min and
+	* apps/ssar/ssar.cpp: Added display of setup time, plus max, min and
           std-dev for the mean compute time.
 
 2006-11-22  Don McCoy  <don@codesourcery.com>
Index: src/vsip/opt/profile.hpp
===================================================================
--- src/vsip/opt/profile.hpp	(revision 157392)
+++ src/vsip/opt/profile.hpp	(working copy)
@@ -101,6 +101,7 @@
 ///  - Pentium_tsc_time - pentium timestamp counter (ia32 asm)
 ///  - X86_64_tsc_time  - pentium timestamp counter (x86_64 asm)
 ///  - Mcoe_tmr_time    - MCOE tmr timer.
+///  - Power_tb_time    - PowerPC timebase timer
 
 struct No_time
 {
@@ -316,9 +317,49 @@
 };
 #endif // (VSIP_IMPL_PROFILE_TIMER == 5)
 
+#if (VSIP_IMPL_PROFILE_TIMER == 6)
+struct Power_tb_time
+{
+  static bool const valid = true; 
+  static char* name() { return "Power_tb_time"; }
+  static void init();
 
+  typedef long long stamp_type;
+  static void sample(stamp_type& time)
+  {
+    unsigned int tbl, tbu0, tbu1;
 
+    // Make sure that the upper 32 bits aren't incremented while
+    // reading the lower 32.  Mixing a pre-increment lower 32 value
+    // (FFFF) with a post-increment upper 32 bit value, or a
+    // post-increment lower 32 value with a pre-increment upper 32
+    // would introduce a large measurement error and might result in
+    // non-sensical time deltas.
+    do
+    {
+      __asm__ __volatile__ ("mftbu %0" : "=r"(tbu0));
+      __asm__ __volatile__ ("mftb %0" : "=r"(tbl));
+      __asm__ __volatile__ ("mftbu %0" : "=r"(tbu1));
+    }
+    while (tbu0 != tbu1);
 
+    time = (((unsigned long long)tbu0) << 32) | tbl;
+  }
+  static stamp_type zero() { return stamp_type(); }
+  static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
+  static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
+  static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
+  static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static bool is_zero(stamp_type const& stamp)
+    { return stamp == stamp_type(); }
+
+  static stamp_type clocks_per_sec;
+};
+#endif // (VSIP_IMPL_PROFILE_TIMER == 6)
+
+
+
+
 #if   (VSIP_IMPL_PROFILE_TIMER == 1)
 typedef Posix_time       DefaultTime;
 #elif (VSIP_IMPL_PROFILE_TIMER == 2)
@@ -329,6 +370,8 @@
 typedef X86_64_tsc_time DefaultTime;
 #elif (VSIP_IMPL_PROFILE_TIMER == 5)
 typedef Mcoe_tmr_time DefaultTime;
+#elif (VSIP_IMPL_PROFILE_TIMER == 6)
+typedef Power_tb_time DefaultTime;
 #else // default choice if undefined or zero
 typedef No_time        DefaultTime;
 #endif
Index: src/vsip/opt/profile.cpp
===================================================================
--- src/vsip/opt/profile.cpp	(revision 157392)
+++ src/vsip/opt/profile.cpp	(working copy)
@@ -60,6 +60,29 @@
 }
 
 
+
+long long
+read_timebase()
+{
+  char      buffer[1024];
+  long long timebase = 1000;
+  std::ifstream file;
+
+  file.open("/proc/cpuinfo");
+
+  while(!file.eof()) 
+  {
+    file.getline(buffer, sizeof(buffer));
+    if (sscanf(buffer, "timebase : %lld", &timebase) == 1)
+      break;
+  }
+
+  file.close();
+
+  return timebase;
+}
+
+
 float
 get_cpu_speed()
 {
@@ -110,6 +133,17 @@
 TMR_ts Mcoe_tmr_time::time0;
 #endif // (VSIP_IMPL_PROFILE_TIMER == 5)
 
+#if (VSIP_IMPL_PROFILE_TIMER == 6)
+Power_tb_time::stamp_type Power_tb_time::clocks_per_sec;
+
+void
+Power_tb_time::init()
+{
+  float timebase = read_timebase();
+  clocks_per_sec = static_cast<Power_tb_time::stamp_type>(timebase);
+}
+#endif // (VSIP_IMPL_PROFILE_TIMER == 4)
+
 Profiler* prof;
 
 class SetupProf
Index: configure.ac
===================================================================
--- configure.ac	(revision 157392)
+++ configure.ac	(working copy)
@@ -331,7 +331,7 @@
 
 AC_ARG_ENABLE([timer],
   AS_HELP_STRING([--enable-timer=type],
-                 [Set profile timer type.  Choices include none, posix, realtime, pentiumtsc, x86_64_tsc, mcoe_tmr [[none]].]),,
+                 [Set profile timer type.  Choices include none, posix, realtime, pentiumtsc, x86_64_tsc, mcoe_tmr, power_tb [[none]].]),,
   [enable_timer=none])
 
 AC_ARG_ENABLE([cpu_mhz],
@@ -2145,6 +2145,25 @@
 
   AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILE_TIMER, 5,
     [Profile timer (1: Posix, 2: Posix realtime, 3: ia32 TSC, 4: x86_64 TSC).])
+elif test "$enable_timer" = "power_tb"; then
+  AC_MSG_CHECKING([if PowerPC timebase assembly syntax supported.])
+  AC_LINK_IFELSE(
+    [AC_LANG_PROGRAM([],
+		     [[
+     unsigned int tbl, tbu0, tbu1;
+
+     do {
+	  __asm__ __volatile__ ("mftbu %0" : "=r"(tbu0));
+	  __asm__ __volatile__ ("mftb %0" : "=r"(tbl));
+	  __asm__ __volatile__ ("mftbu %0" : "=r"(tbu1));
+     } while (tbu0 != tbu1);
+		     ]])],
+    [AC_MSG_RESULT(yes)],
+    [AC_MSG_ERROR(GNU in-line assembly for PowerPC timebase not supported.)] )
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILE_TIMER, 6,
+    [Profile timer (1: Posix, 2: Posix realtime, 3: ia32 TSC, 4: x86_64 TSC).])
+else
+  AC_MSG_ERROR([Invalid timer choosen --enable-timer=$enable_timer.])
 fi
 
 
