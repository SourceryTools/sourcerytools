Index: src/vsip/initfin.cpp
===================================================================
--- src/vsip/initfin.cpp	(revision 148169)
+++ src/vsip/initfin.cpp	(working copy)
@@ -123,9 +123,8 @@
   if (use_count++ != 0)
     return;
 
-  // Profiler options should be called first.  Arguments
-  // are passed by reference, but left intact in order 
-  // to be passed on to Par_service.
+  // Profiler options are removed as they are processed.  The
+  // remaining options are left intact.
   profiler_opts_ = new impl::profile::Profiler_options(argc, argv);
 
   par_service_ = new impl::Par_service(argc, argv);
Index: src/vsip/profile.cpp
===================================================================
--- src/vsip/profile.cpp	(revision 148169)
+++ src/vsip/profile.cpp	(working copy)
@@ -12,6 +12,11 @@
 
 #include <fstream>
 
+// Profiling should be enabled when compiling this module so that
+// these functions are available if the user enables profiling.
+// Setting this to a non-zero value before including the header 
+// is sufficient.
+#define VSIP_IMPL_PROFILER   1
 #include <vsip/impl/profile.hpp>
 
 
@@ -244,7 +249,7 @@
 #define OUTPUT_OPTION  "--vsipl++-profile-output"
 #define OUTPUT_LENGTH  (strlen(OUTPUT_OPTION))
 
-Profiler_options::Profiler_options(int const& argc, char** const& argv)
+Profiler_options::Profiler_options(int& argc, char**& argv)
     : profile_(NULL)
 {
   int count = argc;
@@ -283,14 +288,34 @@
     else
       this->profile_ = new Profile("/dev/stdout", mode);
   }
+
+  this->strip_args(argc, argv);
 }
 
 Profiler_options::~Profiler_options()
 {
-  if (this->profile_)
-    delete this->profile_;
+  delete this->profile_;
 }
 
+void
+Profiler_options::strip_args(int& argc, char**& argv)
+{
+  for (int i = 1; i < argc;)
+  {
+    if ( !strncmp(argv[i], MODE_OPTION, MODE_LENGTH) ||
+         !strncmp(argv[i], OUTPUT_OPTION, OUTPUT_LENGTH) )
+    {
+      for (int j = i; j < argc; ++j)
+        argv[j] = argv[j + 1];
+      --argc;
+    }
+    else
+      ++i;
+  }
+}
+
+
+
 #undef MODE_OPTION
 #undef MODE_LENGTH
 #undef OUTPUT_OPTION
Index: src/vsip/impl/profile.hpp
===================================================================
--- src/vsip/impl/profile.hpp	(revision 148169)
+++ src/vsip/impl/profile.hpp	(working copy)
@@ -28,10 +28,33 @@
 #  include <time.h>
 #endif
 
+/// Different operations that may be profiled, each is referred to
+/// as a 'feature'.
+#define VSIP_IMPL_PROFILER_SIGNAL   1
+#define VSIP_IMPL_PROFILER_MATVEC   2
+#define VSIP_IMPL_PROFILER_FNS      4
+#define VSIP_IMPL_PROFILER_USER     8
 
-/// These macros are used to completely remove profiling code so that it has
-/// zero performance impact when disabled at configuration time.
+// Each may be enabled or disabled by defining a mask on the build 
+// command line that is a combination of the above values.  The absence
+// of this mask causes ALL profiling to be disabled, allowing user code 
+// to run at full speed.
+#ifndef VSIP_IMPL_PROFILER
+#define VSIP_IMPL_PROFILER          0
+#endif
 
+
+/// These macros are used to conditionally compile profiling code
+/// so that it can be easily added or removed from the library 
+/// based on the mask defined above.
+///
+///   VSIP_IMPL_PROFILE_FEATURE     is used on profiling statements for
+///                                 a given operation in a specific module
+///                                 (see fft.hpp for an example).
+///
+///   VSIP_IMPL_PROFILE             is used on statements that are not
+///                                 feature-specific (see this file).
+
 // Enable (or not) for a single statement
 #define VSIP_IMPL_PROFILE_EN_0(X) 
 #define VSIP_IMPL_PROFILE_EN_1(X) X
@@ -47,13 +70,15 @@
      VSIP_IMPL_JOIN(VSIP_IMPL_PROFILE_EN_,		\
                     VSIP_IMPL_PROFILING_FEATURE_ENABLED) 	(STMT)
 
-// This macro may be used when all profiling features are completely disabled.
+// This macro may be used to disable statements that apply to profiling
+// in general.
 #if (VSIP_IMPL_PROFILER)
 #define VSIP_IMPL_PROFILE(STMT)		STMT
 #else
 #define VSIP_IMPL_PROFILE(STMT)
 #endif
 
+
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -400,10 +425,12 @@
 {
   // Constructors.
 public:
-  Profiler_options(int const& argc, char** const& argv);
+  Profiler_options(int& argc, char**& argv);
   ~Profiler_options();
 
 private:
+  void strip_args(int& argc, char**& argv);
+
   Profile* profile_;
 };
 
Index: configure.ac
===================================================================
--- configure.ac	(revision 148169)
+++ configure.ac	(working copy)
@@ -277,12 +277,6 @@
                  [Set CPU speed in MHz.  Only necessary for TSC and if /proc/cpuinfo does not exist or is wrong.]),,
   [enable_cpu_mhz=none])
 
-AC_ARG_ENABLE([profiler],
-  AS_HELP_STRING([--enable-profiler=type],
-                 [Specify list of areas to profile.  Choices include none, all
-		  or a combination of: signal, matvec, fns and user [[none]].]),,
-  [enable_profiler=none])
-
 AC_ARG_ENABLE([simd_loop_fusion],
   AS_HELP_STRING([--enable-simd-loop-fusion],
                  [Enable SIMD loop-fusion.]),,
@@ -1720,59 +1714,6 @@
 
 
 #
-# Configure profiler
-#
-profiler_options=`echo "${enable_profiler}" | \
-                sed -e 's/[[ 	,]][[ 	,]]*/ /g' -e 's/,$//'`
-
-prof_opt_mask=0
-profiler_mode=""
-
-if test "$enable_profiler" != ""; then
-  for prof_opt in ${profiler_options} ; do
-    case ${prof_opt} in
-      no)      profiler_enabled="no";;
-      none)    profiler_enabled="no";;
-      signal)  let prof_opt_mask+=1;;
-      matvec)  let prof_opt_mask+=2;;
-      fns)     let prof_opt_mask+=4;;
-      user)    let prof_opt_mask+=8;;
-      all)     profiler_mode="all";;
-      yes)     profiler_mode="all";;
-      *) AC_MSG_ERROR([Unknown profiler option ${prof_opt}.]);;
-    esac
-  done
-fi
-
-if test "$profiler_enabled" == "no"; then
-   prof_opt_mask=0
-   profiler_options="disabled"
-else
-  if test "$enable_timer" == "none" \
-       -o "$enable_timer" == "no"; then
-    AC_MSG_ERROR([Enable a timer to use the profiler.])
-  fi
-  if test "$profiler_options" == "yes"; then
-     profiler_mode="all"
-  fi
-  if test "$profiler_mode" == "all"; then
-     profiler_options="signal matvec fns user"
-     let prof_opt_mask=1+2+4+8
-  fi	
-fi
-
-AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILER, $prof_opt_mask,
-  [Profiler (None, Signal Processing, Matrix-Vector Math, Functions
-   User Events, All).])
-
-AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILER_SIGNAL,  1, [Profiler event type mask.])
-AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILER_MATVEC,  2, [Profiler event type mask.])
-AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILER_FNS,     4, [Profiler event type mask.])
-AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILER_USER,    8, [Profiler event type mask.])
-
-
-
-#
 # Configure use of SIMD loop-fusion
 #
 if test "$enable_simd_loop_fusion" = "yes"; then
@@ -1914,7 +1855,6 @@
   AC_MSG_RESULT([Complex storage format:                  interleaved])
 fi
 AC_MSG_RESULT([Timer:                                   ${enable_timer}])
-AC_MSG_RESULT([Profiling:                               ${profiler_options}])
 
 #
 # Done.
Index: examples/fft.cpp
===================================================================
--- examples/fft.cpp	(revision 148169)
+++ examples/fft.cpp	(working copy)
@@ -72,11 +72,11 @@
 
 
 int
-main()
+main(int argc, char **argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
   
-  Profile profile("/dev/stdout", pm_accum);
+  Profile profile("fft_profile.txt", pm_accum);
 
   fft_example();
 
Index: examples/png.cpp
===================================================================
--- examples/png.cpp	(revision 148169)
+++ examples/png.cpp	(working copy)
@@ -49,7 +49,7 @@
 
 int main (int argc, char **argv)
 {
-  vsipl v;
+  vsipl init(argc, argv);
 
   if (argc != 2)
   {
Index: examples/example1.cpp
===================================================================
--- examples/example1.cpp	(revision 148169)
+++ examples/example1.cpp	(working copy)
@@ -26,8 +26,10 @@
   Main Program
 ***********************************************************************/
 
-int main () {
-  vsip::vsipl v;
+int 
+main(int argc, char **argv)
+{
+  vsip::vsipl init(argc, argv);
 
   vector_type v1(10);
   // Initialize all values to PI.
