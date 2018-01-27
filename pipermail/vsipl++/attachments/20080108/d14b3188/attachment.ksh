Index: ChangeLog
===================================================================
--- ChangeLog	(revision 191006)
+++ ChangeLog	(working copy)
@@ -1,3 +1,12 @@
+2007-01-08  Jules Bergmann  <jules@codesourcery.com>
+
+	* m4/parallel.m4: Add back check to avoid using posix memalign with
+	  LAM.
+	* src/vsip/core/check_config.cpp: Add coverage for memalign macros.
+	* src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp: Fix bug to handle non-zero
+	  column offset.
+	* benchmarks/sal/vthresh.cpp: Handle missing SAL vthrx.
+
 2008-01-08  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* GNUmakefile.in: Add dummy default install-benchmarks target.
Index: m4/parallel.m4
===================================================================
--- m4/parallel.m4	(revision 191006)
+++ m4/parallel.m4	(working copy)
@@ -181,8 +181,11 @@
 
       # If this is open-mpi, we already know (see above).
       # Now test whether it is lam
-      if test "$PAR_SERVICE" = "none";
-      then AC_CHECK_DECL([LAM_MPI], [PAR_SERVICE=lam],,[#include <mpi.h>])
+      if test "$PAR_SERVICE" = "none"; then
+        AC_CHECK_DECL([LAM_MPI],
+                      [PAR_SERVICE=lam
+                       vsip_impl_avoid_posix_memalign=yes],,
+                      [#include <mpi.h>])
       fi
       # Now test whether it is mpich2 or intelmpi (both define the same macros)
       if test "$PAR_SERVICE" = "none";
@@ -305,7 +308,6 @@
   # Second step: Test the found compiler flags and set output variables.
   ############################################################################
 
-  # FIXME: Is there any testable case where we are to include <mpi/mpi.h> ?
   vsipl_mpi_h_type=1
   if test "$neutral_acconfig" = 'y'
   then CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_MPI_H_TYPE=$vsipl_mpi_h_type"
@@ -331,6 +333,16 @@
   LIBS="$LIBS $MPI_LIBS"
   AC_SUBST(PAR_SERVICE)
   AC_SUBST(VSIP_IMPL_HAVE_MPI, 1)
+
+  if test -n "$vsip_impl_avoid_posix_memalign"
+  then if test "$neutral_acconfig" = 'y'
+  then CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_AVOID_POSIX_MEMALIGN=1"
+  else AC_DEFINE_UNQUOTED(VSIP_IMPL_AVOID_POSIX_MEMALIGN, 1,
+  [Set to 1 to avoid using posix_memalign (LAM defines its own malloc,
+  including memalign but not posix_memalign).])
+  fi; AC_MSG_NOTICE(
+  [Avoiding posix_memalign, may not be compatible with LAM-MPI malloc])
+  fi
 fi
 
 if test "$enable_parallel" = "probe" -o "$enable_parallel" = "yes"
Index: src/vsip/core/check_config.cpp
===================================================================
--- src/vsip/core/check_config.cpp	(revision 191006)
+++ src/vsip/core/check_config.cpp	(working copy)
@@ -89,6 +89,24 @@
   cfg << "  VSIP_IMPL_ALLOC_ALIGNMENT       - "
       << VSIP_IMPL_ALLOC_ALIGNMENT << "\n";
 
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
 #if __SSE__
   cfg << "  __SSE__                         - 1\n";
 #else
Index: src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp
===================================================================
--- src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp	(revision 191006)
+++ src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp	(working copy)
@@ -702,8 +702,8 @@
   // Transfer output.
   ALF_DT_LIST_CREATE(list_entries, 0);
   unsigned long length = pwp->out_cols;
-  ea.ull = pwp->ea_out
-    + (cur_iter + pwp->out_row_0) * pwp->out_stride_0 * sizeof(unsigned char);
+  ea.ull = pwp->ea_out + sizeof(unsigned char) *
+           ((cur_iter + pwp->out_row_0) * pwp->out_stride_0 + pwp->out_col_0);
   ALF_DT_LIST_ADD_ENTRY(list_entries, length, ALF_DATA_BYTE, ea);
 
   return 0;
Index: benchmarks/sal/vthresh.cpp
===================================================================
--- benchmarks/sal/vthresh.cpp	(revision 191006)
+++ benchmarks/sal/vthresh.cpp	(working copy)
@@ -99,6 +99,7 @@
 
 
 
+#if VSIP_IMPL_SAL_HAVE_VTHRX
 template <>
 struct t_vthr_sal<float> : Benchmark_base
 {
@@ -150,6 +151,7 @@
     time = t1.delta();
   }
 };
+#endif
 
 
 
@@ -218,13 +220,19 @@
   switch (what)
   {
   case  1: loop(t_vthres_sal<float>()); break;
+#if VSIP_IMPL_SAL_HAVE_VTHRX
   case  2: loop(t_vthr_sal<float>()); break;
+#endif
   case 11: loop(t_vthres_c<float>()); break;
   case  0:
     std::cout
       << "SAL vthres\n"
       << "  -1 -- SAL vthresx (float) Z(i) = A(i) > b ? A(i) : 0\n"
+#if VSIP_IMPL_SAL_HAVE_VTHRX
       << "  -2 -- SAL vthrx   (float) Z(i) = A(i) > b ? A(i) : b\n"
+#else
+      << " (-2 -- SAL vthrx function not available)\n"
+#endif
       << " -11 -- C           (float) Z(i) = A(i) > b ? A(i) : 0\n"
       ;
   }
