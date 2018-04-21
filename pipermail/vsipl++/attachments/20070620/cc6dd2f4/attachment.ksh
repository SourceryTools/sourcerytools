Index: ChangeLog
===================================================================
--- ChangeLog	(revision 174589)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2007-06-20  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/core/mpi/services.hpp: Fix typo for systems having
+	  their MPI header files in the mpi/ subdirectory.
+
 2007-06-18  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/expr/scalar_block.hpp (Scalar_block_base): Add
Index: src/vsip/core/mpi/services.hpp
===================================================================
--- src/vsip/core/mpi/services.hpp	(revision 174589)
+++ src/vsip/core/mpi/services.hpp	(working copy)
@@ -31,7 +31,7 @@
 #include <vsip/core/config.hpp>
 #if VSIP_IMPL_MPI_H_TYPE == 1
 #  include <mpi.h>
-#elif VSIP_IMPL_MPI_H_TYPE == 1
+#elif VSIP_IMPL_MPI_H_TYPE == 2
 #  include <mpi/mpi.h>
 #endif
 #include <vsip/support.hpp>
