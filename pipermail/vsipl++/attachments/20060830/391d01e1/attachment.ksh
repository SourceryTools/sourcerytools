Index: ChangeLog
===================================================================
--- ChangeLog	(revision 147996)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2006-08-30  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/impl/par-foreach.hpp: Added missing header.
+	* configure.ac: Made minor change to allow configure to
+	  work with either IPP 4.1 or 5.0.
+
 2006-08-29  Don McCoy  <don@codesourcery.com>
 
 	* tests/extdata-subviews.cpp: Added command-line arguments.
Index: src/vsip/impl/par-foreach.hpp
===================================================================
--- src/vsip/impl/par-foreach.hpp	(revision 147996)
+++ src/vsip/impl/par-foreach.hpp	(working copy)
@@ -18,6 +18,7 @@
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
+#include <vsip/tensor.hpp>
 #include <vsip/impl/distributed-block.hpp>
 #include <vsip/impl/par-util.hpp>
 
Index: configure.ac
===================================================================
--- configure.ac	(revision 147996)
+++ configure.ac	(working copy)
@@ -1102,7 +1102,7 @@
     save_LDFLAGS="$LDFLAGS"
     LDFLAGS="$LDFLAGS $IPP_LDFLAGS"
     LIBS="-lpthread $LIBS"
-    AC_SEARCH_LIBS(ippCoreGetCpuType, [$ippcore_search],,
+    AC_SEARCH_LIBS(ippGetLibVersion, [$ippcore_search],,
       [LD_FLAGS="$save_LDFLAGS"])
     
     save_LDFLAGS="$LDFLAGS"
