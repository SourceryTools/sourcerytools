Index: configure.ac
===================================================================
--- configure.ac	(revision 230136)
+++ configure.ac	(working copy)
@@ -690,7 +690,7 @@
 # On GCC 3.4.4/Mercury, hypot is not provided
 #
 AC_CHECK_FUNCS([acosh hypotf hypot], [], [], [#include <cmath>])
-AC_CHECK_DECLS([hypotf], [], [], [#include <cmath>])
+AC_CHECK_DECLS([hypotf, hypot], [], [], [#include <cmath>])
 
 #
 # Check for std::isfinite, std::isnan, and std::isnormal
