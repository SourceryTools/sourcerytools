Index: ChangeLog
===================================================================
--- ChangeLog	(revision 166047)
+++ ChangeLog	(working copy)
@@ -1,7 +1,18 @@
+2007-03-16  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/initfin.cpp: Parse vsipl++ options from SVPP_OPT
+	  environment variables.
+	* src/vsip/core/block_copy.hpp: Call loop fusion init/fini
+	  before copy.
+	* src/vsip/opt/cbe/ppu/bindings.hpp (Serial_evaluator_base):
+	  Check that value type is supported (float or complex<float>).
+	* tests/GNUmakefile.inc.in (tests_cxx_sources): Add tests in
+	  parallel and regressions subdirs.
+	
 2007-03-15  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip/opt/cbe/ppu/fastconv.hpp: Add Fastconv_traits.
-        * src/vsip/opt/cbe/ppu/fastconv.cpp: Assert valid sizes.
+	* src/vsip/opt/cbe/ppu/fastconv.cpp: Assert valid sizes.
 	* src/vsip/opt/cbe/ppu/eval_fastconv.hpp: Various fixes.
 	* src/vsip/opt/cbe/common.h: Add transform_kernel flag.
 	* src/vsip/opt/cbe/spu/alf_fconv_c.c: Only transform kernel if needed.
Index: src/vsip/initfin.cpp
===================================================================
--- src/vsip/initfin.cpp	(revision 166043)
+++ src/vsip/initfin.cpp	(working copy)
@@ -130,21 +130,102 @@
   if (use_count++ != 0)
     return;
 
+  int    use_argc;
+  char** use_argv;
+
+  char*  env = getenv("SVPP_OPT");
+  bool   argv_is_tmp;
+  char const* env_marker = "--svpp-#*%$-env-args-marker";
+
+  if (env)
+  {
+    char* p=env;
+    int env_argc = 0;
+
+    // Skip over inital spaces.
+    while( isspace(*env) && *env) ++env;
+
+    // Count the number of arguments from the environment.
+    p = env;
+    while (*p)
+    {
+      // skip over arg
+      while(!isspace(*p) && *p) ++p;
+      env_argc++;
+      // skip over space after arg
+      while( isspace(*p) && *p) ++p;
+    }
+
+    // Allocate a new argv and copy the existing arguments.
+    use_argc = argc + env_argc + 1;
+    use_argv = new char*[use_argc];
+
+    int i=0;
+    for (; i<argc; ++i)
+      use_argv[i] = argv[i];
+
+    // Insert argument to track start of env args.  This prevents
+    // arguments from environment from propogating back to the application
+    // if they're aren't processed by VSIPL++.
+    use_argv[i++] = const_cast<char*>(env_marker);
+      
+    // Copy the environment arguments.
+    p = env;
+    while (*p)
+    {
+      assert(i < use_argc);
+      use_argv[i++] = p;
+      // skip over arg
+      while(!isspace(*p) && *p) ++p;
+
+      // put 0 after arg
+      if (isspace(*p))
+	*p++ = 0;
+
+      // skip over additional space after arg
+      while( isspace(*p) && *p) ++p;
+    }
+    argv_is_tmp = true;
+  }
+  else
+  {
+    use_argc = argc;
+    use_argv = argv;
+    argv_is_tmp = false;
+  }
+
 #ifndef VSIP_IMPL_REF_IMPL
   // Profiler options are removed as they are processed.  The
   // remaining options are left intact.
-  profiler_opts_ = new impl::profile::Profiler_options(argc, argv);
+  profiler_opts_ = new impl::profile::Profiler_options(use_argc, use_argv);
 
 # if defined(VSIP_IMPL_NUMA)
-  impl::numa::initialize(argc, argv);
+  impl::numa::initialize(use_argc, use_argv);
 # endif
 # if defined(VSIP_IMPL_CBE_SDK)
-  impl::cbe::Task_manager::initialize(argc, argv);
+  impl::cbe::Task_manager::initialize(use_argc, use_argv);
 # endif
 
 #endif
 
-  par_service_ = new impl::Par_service(argc, argv);
+  par_service_ = new impl::Par_service(use_argc, use_argv);
+
+  // Copy argv back if necessary
+  if (argv_is_tmp)
+  {
+    int i;
+    for (i=0; i<use_argc && i<argc && strcmp(use_argv[i], env_marker); ++i)
+      argv[i] = use_argv[i];
+
+    // update use_argc if some of the environment args were not processed.
+    use_argc = i;
+
+    for (; i<argc; ++i)
+      argv[i] = 0;
+
+    delete[] use_argv;
+  }
+  argc = use_argc;
 }
 
 /// Destructor worker function.
Index: src/vsip/core/block_copy.hpp
===================================================================
--- src/vsip/core/block_copy.hpp	(revision 166043)
+++ src/vsip/core/block_copy.hpp	(working copy)
@@ -16,6 +16,7 @@
 #include <vsip/core/layout.hpp>
 #include <vsip/core/block_traits.hpp>
 #include <vsip/core/parallel/map_traits.hpp>
+#include <vsip/opt/expr/lf_initfini.hpp>
 
 
 
@@ -53,10 +54,12 @@
   {
     Length<Dim> ext = extent<Dim>(*block);
 
+    do_loop_fusion_init(*block);
     for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
     {
       storage_type::put(data, layout.index(idx), get(*block, idx));
     }
+    do_loop_fusion_fini(*block);
   }
 };
 
Index: src/vsip/opt/cbe/ppu/bindings.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.hpp	(revision 166043)
+++ src/vsip/opt/cbe/ppu/bindings.hpp	(working copy)
@@ -76,6 +76,9 @@
     !Is_split_block<RBlock>::value &&
      Type_equal<typename DstBlock::value_type, LType>::value &&
      Type_equal<typename DstBlock::value_type, RType>::value &&
+     // check that type is supported.
+     (Type_equal<typename DstBlock::value_type, float>::value ||
+      Type_equal<typename DstBlock::value_type, complex<float> >::value) &&
      // check that direct access is supported
      Ext_data_cost<DstBlock>::value == 0 &&
      Ext_data_cost<LBlock>::value == 0 &&
Index: tests/GNUmakefile.inc.in
===================================================================
--- tests/GNUmakefile.inc.in	(revision 166043)
+++ tests/GNUmakefile.inc.in	(working copy)
@@ -27,7 +27,9 @@
 tests_run_ident :=-a run_id=$(tests_run_id)
 endif
 
-tests_cxx_sources := $(wildcard $(srcdir)/tests/*.cpp)
+tests_cxx_sources := $(wildcard $(srcdir)/tests/*.cpp) \
+                     $(wildcard $(srcdir)/tests/parallel/*.cpp) \
+                     $(wildcard $(srcdir)/tests/regressions/*.cpp)
 
 tests_cxx_exes := \
 	$(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(tests_cxx_sources))
