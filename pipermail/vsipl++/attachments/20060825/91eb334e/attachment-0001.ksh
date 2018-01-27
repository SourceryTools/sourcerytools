Index: src/vsip/impl/par-foreach.hpp
===================================================================
--- src/vsip/impl/par-foreach.hpp	(revision 147666)
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
--- configure.ac	(revision 147666)
+++ configure.ac	(working copy)
@@ -1102,8 +1102,12 @@
     save_LDFLAGS="$LDFLAGS"
     LDFLAGS="$LDFLAGS $IPP_LDFLAGS"
     LIBS="-lpthread $LIBS"
+    # IPP 4.1 uses the first version, 5.0 uses the second.
     AC_SEARCH_LIBS(ippCoreGetCpuType, [$ippcore_search],,
-      [LD_FLAGS="$save_LDFLAGS"])
+      [
+        AC_SEARCH_LIBS(ippGetCpuType, [$ippcore_search],,
+          [LD_FLAGS="$save_LDFLAGS"])
+      ])
     
     save_LDFLAGS="$LDFLAGS"
     LDFLAGS="$LDFLAGS $IPP_LDFLAGS"
