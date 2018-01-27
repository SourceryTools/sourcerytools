Index: ChangeLog
===================================================================
--- ChangeLog	(revision 192266)
+++ ChangeLog	(working copy)
@@ -1,3 +1,12 @@
+2008-01-30  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/check_config_body.hpp: New file, body of
+	  {app,library}_config function.
+	* src/vsip/core/check_config.cpp: Use check_config_body.hpp.
+	* src/vsip/core/check_config.hpp (app_config): New function to
+	  check configuration at application build time.
+	* tests/check_config.cpp: Test app_config.
+
 2008-01-29  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* synopsis.py.in: Cleanup.
Index: src/vsip/core/check_config.cpp
===================================================================
--- src/vsip/core/check_config.cpp	(revision 191870)
+++ src/vsip/core/check_config.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/check_config.cpp
     @author  Jules Bergmann
@@ -14,6 +14,7 @@
 #include <sstream>
 
 #include <vsip/core/config.hpp>
+#include <vsip/core/check_config.hpp>
 
 
 
@@ -32,120 +33,8 @@
 {
   std::ostringstream   cfg;
 
-  cfg << "Sourcery VSIPL++ Library Configuration\n";
+#include <vsip/core/check_config_body.hpp>
 
-#if VSIP_IMPL_PAR_SERVICE == 0
-  cfg << "  VSIP_IMPL_PAR_SERVICE           - 0 (Serial)\n";
-#elif VSIP_IMPL_PAR_SERVICE == 1
-  cfg << "  VSIP_IMPL_PAR_SERVICE           - 1 (MPI)\n";
-#elif VSIP_IMPL_PAR_SERVICE == 2
-  cfg << "  VSIP_IMPL_PAR_SERVICE           - 2 (PAS)\n";
-#else
-  cfg << "  VSIP_IMPL_HAVE_SIMD_LOOP_FUSION - Unknown\n";
-#endif
-
-#if VSIP_IMPL_HAVE_IPP
-  cfg << "  VSIP_IMPL_IPP                   - 1\n";
-#else
-  cfg << "  VSIP_IMPL_IPP                   - 0\n";
-#endif
-
-#if VSIP_IMPL_HAVE_SAL
-  cfg << "  VSIP_IMPL_SAL                   - 1\n";
-#else
-  cfg << "  VSIP_IMPL_SAL                   - 0\n";
-#endif
-
-#if VSIP_IMPL_CBE_SDK
-  cfg << "  VSIP_IMPL_CBE_SDK               - 1\n";
-#else
-  cfg << "  VSIP_IMPL_CBE_SDK               - 0\n";
-#endif
-
-#if VSIP_IMPL_HAVE_SIMD_LOOP_FUSION
-  cfg << "  VSIP_IMPL_HAVE_SIMD_LOOP_FUSION - 1\n";
-#else
-  cfg << "  VSIP_IMPL_HAVE_SIMD_LOOP_FUSION - 0\n";
-#endif
-
-#if VSIP_IMPL_HAVE_SIMD_GENERIC
-  cfg << "  VSIP_IMPL_HAVE_SIMD_GENERIC     - 1\n";
-#else
-  cfg << "  VSIP_IMPL_HAVE_SIMD_GENERIC     - 0\n";
-#endif
-
-#if VSIP_IMPL_PREFER_SPLIT_COMPLEX
-  cfg << "  VSIP_IMPL_PREFER_SPLIT_COMPLEX  - 1\n";
-#else
-  cfg << "  VSIP_IMPL_PREFER_SPLIT_COMPLEX  - 0\n";
-#endif
-
-#if VSIP_IMPL_HAS_EXCEPTIONS
-  cfg << "  VSIP_IMPL_HAS_EXCEPTIONS        - 1\n";
-#else
-  cfg << "  VSIP_IMPL_HAS_EXCEPTIONS        - 0\n";
-#endif
-
-  cfg << "  VSIP_IMPL_ALLOC_ALIGNMENT       - "
-      << VSIP_IMPL_ALLOC_ALIGNMENT << "\n";
-
-#if VSIP_IMPL_AVOID_POSIX_MEMALIGN
-  cfg << "  VSIP_IMPL_AVOID_POSIX_MEMALIGN  - 1\n";
-#else
-  cfg << "  VSIP_IMPL_AVOID_POSIX_MEMALIGN  - 0\n";
-#endif
-
-#if HAVE_POSIX_MEMALIGN
-  cfg << "  HAVE_POSIX_MEMALIGN             - 1\n";
-#else
-  cfg << "  HAVE_POSIX_MEMALIGN             - 0\n";
-#endif
-
-#if HAVE_MEMALIGN
-  cfg << "  HAVE_MEMALIGN                   - 1\n";
-#else
-  cfg << "  HAVE_MEMALIGN                   - 0\n";
-#endif
-
-#if __SSE__
-  cfg << "  __SSE__                         - 1\n";
-#else
-  cfg << "  __SSE__                         - 0\n";
-#endif
-
-#if __SSE2__
-  cfg << "  __SSE2__                        - 1\n";
-#else
-  cfg << "  __SSE2__                        - 0\n";
-#endif
-
-#if __VEC__
-  cfg << "  __VEC__                         - 1\n";
-#else
-  cfg << "  __VEC__                         - 0\n";
-#endif
-
-#if _MC_EXEC
-  cfg << "  _MC_EXEC                        - 1\n";
-#else
-  cfg << "  _MC_EXEC                        - 0\n";
-#endif
-
-
-  cfg << "Sourcery VSIPL++ Compiler Configuration\n";
-
-#if __GNUC__
-  cfg << "  __GNUC__                        - " << __GNUC__ << "\n";
-#endif
-
-#if __ghs__
-  cfg << "  __ghs__                         - " << __ghs__ << "\n";
-#endif
-
-#if __ICL
-  cfg << "  __ICL                           - " << __ICL << "\n";
-#endif
-
   return cfg.str();
 }
 
Index: src/vsip/core/check_config_body.hpp
===================================================================
--- src/vsip/core/check_config_body.hpp	(revision 0)
+++ src/vsip/core/check_config_body.hpp	(revision 0)
@@ -0,0 +1,123 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/check_config_body.hpp
+    @author  Jules Bergmann
+    @date    2008-01-30
+    @brief   VSIPL++ Library: Function body for checking library configuration.
+
+    NOTE: Do not include this file directly.  Instead use check_config.hpp.
+*/
+
+  cfg << "Sourcery VSIPL++ Library Configuration\n";
+
+#if VSIP_IMPL_PAR_SERVICE == 0
+  cfg << "  VSIP_IMPL_PAR_SERVICE           - 0 (Serial)\n";
+#elif VSIP_IMPL_PAR_SERVICE == 1
+  cfg << "  VSIP_IMPL_PAR_SERVICE           - 1 (MPI)\n";
+#elif VSIP_IMPL_PAR_SERVICE == 2
+  cfg << "  VSIP_IMPL_PAR_SERVICE           - 2 (PAS)\n";
+#else
+  cfg << "  VSIP_IMPL_HAVE_SIMD_LOOP_FUSION - Unknown\n";
+#endif
+
+#if VSIP_IMPL_HAVE_IPP
+  cfg << "  VSIP_IMPL_IPP                   - 1\n";
+#else
+  cfg << "  VSIP_IMPL_IPP                   - 0\n";
+#endif
+
+#if VSIP_IMPL_HAVE_SAL
+  cfg << "  VSIP_IMPL_SAL                   - 1\n";
+#else
+  cfg << "  VSIP_IMPL_SAL                   - 0\n";
+#endif
+
+#if VSIP_IMPL_CBE_SDK
+  cfg << "  VSIP_IMPL_CBE_SDK               - 1\n";
+#else
+  cfg << "  VSIP_IMPL_CBE_SDK               - 0\n";
+#endif
+
+#if VSIP_IMPL_HAVE_SIMD_LOOP_FUSION
+  cfg << "  VSIP_IMPL_HAVE_SIMD_LOOP_FUSION - 1\n";
+#else
+  cfg << "  VSIP_IMPL_HAVE_SIMD_LOOP_FUSION - 0\n";
+#endif
+
+#if VSIP_IMPL_HAVE_SIMD_GENERIC
+  cfg << "  VSIP_IMPL_HAVE_SIMD_GENERIC     - 1\n";
+#else
+  cfg << "  VSIP_IMPL_HAVE_SIMD_GENERIC     - 0\n";
+#endif
+
+#if VSIP_IMPL_PREFER_SPLIT_COMPLEX
+  cfg << "  VSIP_IMPL_PREFER_SPLIT_COMPLEX  - 1\n";
+#else
+  cfg << "  VSIP_IMPL_PREFER_SPLIT_COMPLEX  - 0\n";
+#endif
+
+#if VSIP_IMPL_HAS_EXCEPTIONS
+  cfg << "  VSIP_IMPL_HAS_EXCEPTIONS        - 1\n";
+#else
+  cfg << "  VSIP_IMPL_HAS_EXCEPTIONS        - 0\n";
+#endif
+
+  cfg << "  VSIP_IMPL_ALLOC_ALIGNMENT       - "
+      << VSIP_IMPL_ALLOC_ALIGNMENT << "\n";
+
+#if VSIP_IMPL_AVOID_POSIX_MEMALIGN
+  cfg << "  VSIP_IMPL_AVOID_POSIX_MEMALIGN  - 1\n";
+#else
+  cfg << "  VSIP_IMPL_AVOID_POSIX_MEMALIGN  - 0\n";
+#endif
+
+#if HAVE_POSIX_MEMALIGN
+  cfg << "  HAVE_POSIX_MEMALIGN             - 1\n";
+#else
+  cfg << "  HAVE_POSIX_MEMALIGN             - 0\n";
+#endif
+
+#if HAVE_MEMALIGN
+  cfg << "  HAVE_MEMALIGN                   - 1\n";
+#else
+  cfg << "  HAVE_MEMALIGN                   - 0\n";
+#endif
+
+#if __SSE__
+  cfg << "  __SSE__                         - 1\n";
+#else
+  cfg << "  __SSE__                         - 0\n";
+#endif
+
+#if __SSE2__
+  cfg << "  __SSE2__                        - 1\n";
+#else
+  cfg << "  __SSE2__                        - 0\n";
+#endif
+
+#if __VEC__
+  cfg << "  __VEC__                         - 1\n";
+#else
+  cfg << "  __VEC__                         - 0\n";
+#endif
+
+#if _MC_EXEC
+  cfg << "  _MC_EXEC                        - 1\n";
+#else
+  cfg << "  _MC_EXEC                        - 0\n";
+#endif
+
+
+  cfg << "Sourcery VSIPL++ Compiler Configuration\n";
+
+#if __GNUC__
+  cfg << "  __GNUC__                        - " << __GNUC__ << "\n";
+#endif
+
+#if __ghs__
+  cfg << "  __ghs__                         - " << __ghs__ << "\n";
+#endif
+
+#if __ICL
+  cfg << "  __ICL                           - " << __ICL << "\n";
+#endif
Index: src/vsip/core/check_config.hpp
===================================================================
--- src/vsip/core/check_config.hpp	(revision 191870)
+++ src/vsip/core/check_config.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/check_config.hpp
     @author  Jules Bergmann
@@ -14,9 +14,12 @@
 ***********************************************************************/
 
 #include <string>
+#include <sstream>
 
+#include <vsip/core/config.hpp>
 
 
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -27,8 +30,20 @@
 namespace impl
 {
 
+// Configuration when library was built.
 std::string library_config();
 
+// Configuration when application was built.
+std::string
+app_config()
+{
+  std::ostringstream   cfg;
+
+#include <vsip/core/check_config_body.hpp>
+
+  return cfg.str();
+}
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: tests/check_config.cpp
===================================================================
--- tests/check_config.cpp	(revision 191870)
+++ tests/check_config.cpp	(working copy)
@@ -1,10 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    tests/x-fft.cpp
+/** @file    tests/check_config.cpp
     @author  Jules Bergmann
     @date    2006-10-04
     @brief   VSIPL++ Library: Check library configuration
@@ -37,5 +37,7 @@
 
   cout << vsip::impl::library_config();
 
+  test_assert(vsip::impl::app_config() == vsip::impl::library_config());
+
   return 0;
 }
