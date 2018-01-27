Index: ChangeLog
===================================================================
--- ChangeLog	(revision 198067)
+++ ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2008-03-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/sal/svd.hpp: Remove extaneous scalar_type defn.
+
 2008-03-27  Jules Bergmann  <jules@codesourcery.com>
 
 	* scripts/datasheet.pl: Add support for w_mb_s metric.  Allow lists
Index: src/vsip/opt/sal/svd.hpp
===================================================================
--- src/vsip/opt/sal/svd.hpp	(revision 191870)
+++ src/vsip/opt/sal/svd.hpp	(working copy)
@@ -181,7 +181,6 @@
 
   // Member data.
 private:
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
   typedef std::vector<float, Aligned_allocator<float> > vector_type;
   typedef std::vector<scalar_type, Aligned_allocator<scalar_type> >
 		svector_type;
Index: tests/matvec.cpp
===================================================================
--- tests/matvec.cpp	(revision 191870)
+++ tests/matvec.cpp	(working copy)
@@ -15,6 +15,7 @@
 ***********************************************************************/
 
 #include <cassert>
+#include <math.h>
 
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
@@ -31,7 +32,25 @@
 using namespace vsip_csl;
 
 
+
 /***********************************************************************
+  Macros
+***********************************************************************/
+
+// 080314: For MCOE csr1610, these macros are not defined by GCC
+//         math.h/cmath (but are defined by GHS math.h/cmath).
+
+#if _MC_EXEC && __GNUC__
+#  define M_E        2.718281828459045235360
+#  define M_LN2      0.69314718055994530942
+#  define M_SQRT2    1.41421356237309504880
+#  define M_LN10     2.30258509299404568402
+#  define M_LOG2E    1.442695040888963407
+#endif
+
+
+
+/***********************************************************************
   Definitions
 ***********************************************************************/
 
