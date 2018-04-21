Index: ChangeLog
===================================================================
--- ChangeLog	(revision 149394)
+++ ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2006-10-03  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/pas/offset.hpp: New file, necessary for PAS.
+
 2006-09-17  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac (VSIP_IMPL_MPI_H_TYPE): Indicate mpi header to use
@@ -17,7 +21,7 @@
 	  variants.
 	* scripts/release.sh: Bump version.
 	* tests/parallel/fftm.cpp: Fix initialization of distributed
-	  date.
+	  date. (Fixes issues #58).
 	
 2006-09-15  Jules Bergmann  <jules@codesourcery.com>
 
@@ -3716,7 +3720,7 @@
 	  operator^().  Have functor distinguish bxor and lxor cases.
 	* src/vsip/impl/fns_userelt.hpp: For function object overloads of
 	  unary, binary, and ternary functions, determine return values
-	  through helper classes.
+	  through helper classes. (Fixes issue #53).
 
 2005-09-30  Jules Bergmann  <jules@codesourcery.com>
 
Index: src/vsip/impl/pas/offset.hpp
===================================================================
--- src/vsip/impl/pas/offset.hpp	(revision 0)
+++ src/vsip/impl/pas/offset.hpp	(revision 0)
@@ -0,0 +1,84 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/offset.hpp
+    @author  Jules Bergmann
+    @date    2006-09-01
+    @brief   VSIPL++ Library: Offset class.
+*/
+
+#ifndef VSIP_IMPL_OFFSET_HPP
+#define VSIP_IMPL_OFFSET_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/impl/layout.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+template <typename ComplexFmt,
+	  typename T>
+struct Offset
+{
+  typedef stride_type type;
+
+  static type create(length_type)
+  { return type(0); }
+
+  static type offset(type orig, stride_type delta)
+  { return orig + delta; }
+
+  static void check_imag_offset(length_type, stride_type imag_offset)
+  {
+    assert(imag_offset == 0);
+  }
+};
+
+
+
+template <typename T>
+struct Offset<Cmplx_split_fmt, complex<T> >
+{
+  typedef std::pair<stride_type, stride_type> type;
+
+  static type create(length_type size)
+  {
+    // Size of scalar_type must evenly divide the alignment.
+    assert(VSIP_IMPL_PAS_ALIGNMENT % sizeof(T) == 0);
+
+    // Compute the padding and expected offset.
+    size_t t_alignment = (VSIP_IMPL_PAS_ALIGNMENT / sizeof(T));
+    size_t offset      = size;
+    size_t extra       = offset % t_alignment;
+
+    // If not naturally aligned (extra != 0), pad by t_alignment - extra.
+    if (extra) offset += (t_alignment - extra);
+    return type(0, offset);
+  }
+
+  static type offset(type orig, stride_type delta)
+  { return type(orig.first + delta, orig.second + delta); }
+
+  static void check_imag_offset(length_type size, stride_type imag_offset)
+  {
+    type ref = create(size);
+    assert(ref.second == imag_offset);
+  }
+};
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_OFFSET_HPP
