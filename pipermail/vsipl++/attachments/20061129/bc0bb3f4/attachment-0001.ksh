Index: apps/ssar/diffview.cpp
===================================================================
--- apps/ssar/diffview.cpp	(revision 156076)
+++ apps/ssar/diffview.cpp	(working copy)
@@ -7,7 +7,6 @@
 */
 
 #include <iostream>
-#include <stdlib.h>
 
 #include <vsip/initfin.hpp>
 #include <vsip/math.hpp>
Index: apps/ssar/GNUmakefile
===================================================================
--- apps/ssar/GNUmakefile	(revision 156076)
+++ apps/ssar/GNUmakefile	(working copy)
@@ -31,11 +31,11 @@
 precision = single
 
 ifeq ($(precision),double)
-ref_image_base = ref_image_dp
-ssar_type = SSAR_BASE_TYPE=double
+ref_image_base := ref_image_dp
+ssar_type := SSAR_BASE_TYPE=double
 else
-ref_image_base = ref_image_sp
-ssar_type = SSAR_BASE_TYPE=float
+ref_image_base := ref_image_sp
+ssar_type := SSAR_BASE_TYPE=float
 endif
 
 ifeq ($(strip $(prefix)),)
