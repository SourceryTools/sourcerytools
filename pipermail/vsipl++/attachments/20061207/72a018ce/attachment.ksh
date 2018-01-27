Index: ChangeLog
===================================================================
--- ChangeLog	(revision 156847)
+++ ChangeLog	(working copy)
@@ -1,5 +1,17 @@
 2006-12-07  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/core/fft/workspace.hpp: Move to ...
+	* src/vsip/opt/fft/workspace.hpp: ... here.
+	* src/vsip/opt/block_copy.hpp: Move to ...
+	* src/vsip/core/block_copy.hpp: ... here.
+	* src/vsip/core/extdata.hpp: Adjust includes for moved files.
+	* src/vsip/core/fft.hpp: Likewise.
+	* src/vsip/opt/extdata.hpp: Likewise.
+	* src/vsip/opt/extdata_local.hpp: Likewise.
+	* src/vsip/matrix.hpp: Include block_fill instead of block_copy.
+	
+2006-12-07  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/core/cvsip/solver_lu.hpp (Is_lud_impl_avail): Specialize
 	  for types supported by CVSIP BE.
 	* src/vsip/core/cvsip/solver_cholesky.hpp (Is_chold_immpl_avail):
Index: src/vsip/core/extdata.hpp
===================================================================
--- src/vsip/core/extdata.hpp	(revision 156837)
+++ src/vsip/core/extdata.hpp	(working copy)
@@ -20,11 +20,10 @@
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/layout.hpp>
 #include <vsip/core/domain_utils.hpp>
-
+#include <vsip/core/block_copy.hpp>
 #if !VSIP_IMPL_REF_IMPL
 #  include <vsip/opt/extdata.hpp>
 #endif
-#include <vsip/opt/block_copy.hpp>
 
 
 
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 156837)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -22,7 +22,7 @@
 #include <vsip/core/fft/util.hpp>
 #include <vsip/core/fft/ct_workspace.hpp>
 #ifndef VSIP_IMPL_REF_IMPL
-#  include <vsip/core/fft/workspace.hpp>
+#  include <vsip/opt/fft/workspace.hpp>
 #endif
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/profile.hpp>
Index: src/vsip/matrix.hpp
===================================================================
--- src/vsip/matrix.hpp	(revision 156744)
+++ src/vsip/matrix.hpp	(working copy)
@@ -24,7 +24,7 @@
 #include <vsip/dense.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/core/block_traits.hpp>
-#include <vsip/opt/block_copy.hpp>
+#include <vsip/core/block_fill.hpp>
 #include <vsip/core/subblock.hpp>
 #include <vsip/core/refcount.hpp>
 #include <vsip/core/view_traits.hpp>
Index: src/vsip/opt/extdata.hpp
===================================================================
--- src/vsip/opt/extdata.hpp	(revision 156837)
+++ src/vsip/opt/extdata.hpp	(working copy)
@@ -23,7 +23,7 @@
 
 #include <vsip/core/static_assert.hpp>
 #include <vsip/core/extdata_common.hpp>
-#include <vsip/opt/block_copy.hpp>
+#include <vsip/core/block_copy.hpp>
 #include <vsip/core/block_traits.hpp>
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/layout.hpp>
Index: src/vsip/opt/extdata_local.hpp
===================================================================
--- src/vsip/opt/extdata_local.hpp	(revision 156837)
+++ src/vsip/opt/extdata_local.hpp	(working copy)
@@ -15,7 +15,7 @@
 ***********************************************************************/
 
 #include <vsip/core/static_assert.hpp>
-#include <vsip/opt/block_copy.hpp>
+#include <vsip/core/block_copy.hpp>
 #include <vsip/core/block_traits.hpp>
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/layout.hpp>
