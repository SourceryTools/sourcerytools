Index: ChangeLog
===================================================================
--- ChangeLog	(revision 162613)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2007-02-08  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/parallel/block.hpp: Include distributed_block.hpp
+	  when PAR_SERVICE == 0.
+
 2007-02-07  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/view_traits.hpp: Include get_local_view.hpp.
Index: src/vsip/core/parallel/block.hpp
===================================================================
--- src/vsip/core/parallel/block.hpp	(revision 162613)
+++ src/vsip/core/parallel/block.hpp	(working copy)
@@ -21,7 +21,8 @@
 #elif VSIP_IMPL_PAR_SERVICE == 2
 #  include <vsip/opt/pas/block.hpp>
 #else
-// #  include <vsip/core/parallel/distributed_block.hpp>
+// If PAR_SERVICE == 0, Distributed_block is used by default.
+#  include <vsip/core/parallel/distributed_block.hpp>
 #endif
 
 #endif // VSIP_CORE_PARALLEL_BLOCK_HPP
