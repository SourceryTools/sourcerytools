Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.473
diff -u -r1.473 ChangeLog
--- ChangeLog	11 May 2006 19:39:12 -0000	1.473
+++ ChangeLog	12 May 2006 19:23:37 -0000
@@ -1,3 +1,40 @@
+2006-05-12  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (--with-lapack): Make default to probe.
+	  (--with-test-level): New option, sets VSIP_IMPL_TEST_LEVEL.
+	* src/vsip/matrix.hpp: Dispatch scalar-view operations as
+	  expressions, instead of with explicit for loop.
+	* src/vsip/signal-window.cpp: Add instantiate pragmas for GreenHills.
+	* src/vsip/vector.hpp (VSIP_IMPL_ELEMENTWISE_SCALAR_NOFWD): Undefine
+	  macro after use.
+	* src/vsip/impl/aligned_allocator.hpp: Include acconfig.hpp.
+	* src/vsip/impl/distributed-block.hpp (Block_layout): Specialize
+	  for Distributed_block.
+	* src/vsip/impl/equal.hpp (almost_equal): Inline function.
+	* src/vsip/impl/expr_scalar_block.hpp (Is_par_same_map): Fix
+	  specialization for Scalar_blocks to not require const. Unlike
+	  other expression blocks, scalar blocks are usually not const.
+	* src/vsip/impl/extdata.hpp (is_aligned_to): Inline function.
+	* src/vsip/impl/par-expr.hpp (Par_expr_block): Have layout of
+	  reorg block better match source block (complex format in
+	  particular).
+	* src/vsip/impl/solver-covsol.hpp: Use qrd_nosaveq since Q is
+	  not needed.
+	* src/vsip/impl/solver-llsqsol.hpp: Use Qrd::covsol by default
+	  since not all Qrd_impl's do full QR (qrd_saveq).
+	* src/vsip/impl/sal/solver_lu.hpp: Use new SAL LUD functions by
+	  default.
+	* src/vsip/impl/sal/solver_svd.hpp: Fix order of member initializers.
+	  Add missing return statements.
+	* tests/extdata-output.hpp: Handle Scalar_block.
+	* tests/solver-covsol.cpp: Disable tests for unsupported types.
+	* tests/solver-llsqsol.cpp: Likewise.
+	* tests/solver-lu.cpp: Disable tests for types not supported by
+	  SVD since it is used to check LU.
+	* tests/solver-qr.cpp: Remove default argument values.
+	* tests/solver-svd.cpp: Disable tests for unsupported types and
+	  shapes.
+	
 2006-05-11  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* tests/fft_be.cpp: Conditionalize the use of the backends on
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.102
diff -u -r1.102 configure.ac
--- configure.ac	10 May 2006 19:26:34 -0000	1.102
+++ configure.ac	12 May 2006 19:23:37 -0000
@@ -168,12 +168,17 @@
 
 AC_ARG_WITH([lapack],
   AS_HELP_STRING([--with-lapack\[=PKG\]],
-                 [enable use of LAPACK if found
-                  (default is to not search for it).  Optionally, the
-		  specific LAPACK library (mkl7, mkl5, atlas, generic,
-		  builtin, or fortran-builtin) to use can be specified
-		  with PKG]),,
-  [with_lapack=no])
+                 [select one or more LAPACK libraries to search for
+                  (default is to probe for atlas, generic, and builtin,
+	          using the first one found).  Sourcery VSIPL++ understands the
+		  following LAPACK library selections: mkl (Intel Math Kernel
+		  Library), acml (AMD Core Math Library), atlas (system
+		  ATLAS/LAPACK installation), generic (system generic
+		  LAPACK installation), builtin (Sourcery VSIPL++'s
+		  builtin ATLAS/C-LAPACK), and fortran-builtin (Sourcery
+		  VSIPL++'s builtin ATLAS/Fortran-LAPACK). 
+		  Specifying 'no' disables search for a LAPACK library.]),,
+  [with_lapack=probe])
 
 AC_ARG_WITH(atlas_prefix,
   AS_HELP_STRING([--with-atlas-prefix=PATH],
@@ -267,6 +272,14 @@
                  [set SIMD extensions]),,
   [with_simd=none])
 
+AC_ARG_WITH([test_level],
+  AS_HELP_STRING([--with-test-level=WHAT],
+                 [set effort level for test-suite.  0 for low-level
+		  (avoids long-running and long-compiling tests),
+		  1 for regular effort, 2 for high-level (enables
+		  long-running tests).  Default value is 1.]),,
+  [with_test_level=1])
+
 
 #
 # Files to generate.
@@ -1186,21 +1199,30 @@
 #
 # Check to see if any options have implied with_lapack
 #
-if test "$with_lapack" == "no"; then
+if test "$with_lapack" == "probe"; then
+  already_prefix=0
   if test "$with_atlas_prefix" != "" -o "$with_atlas_libdir" != ""; then
-    if test "$with_mkl_prefix" != ""; then
-      AC_MSG_ERROR([Prefixes given for both MKL and ATLAS])
-    fi
-    AC_MSG_RESULT([ATLAS prefixes specified, enabling lapack])
+    AC_MSG_RESULT([ATLAS prefixes specified, assume --with-lapack=atlas])
     with_lapack="atlas"
+    already_prefix=1
   fi
   if test "$with_mkl_prefix" != ""; then
-    AC_MSG_RESULT([MKL prefixes specified, enabling lapack])
+    if test "$already_prefix" = "1"; then
+      AC_MSG_ERROR([Multiple prefixes given for LAPACk libraries (i.e.
+		    MKL, ACML, and/or ATLAS])
+    fi
+    AC_MSG_RESULT([MKL prefixes specified, assume --with-lapack=mkl])
     with_lapack="mkl"
+    already_prefix=1
   fi
   if test "$with_acml_prefix" != ""; then
-    AC_MSG_RESULT([ACML prefixes specified, enabling lapack])
+    if test "$already_prefix" = "1"; then
+      AC_MSG_ERROR([Multiple prefixes given for LAPACk libraries (i.e.
+		    MKL, ACML, and/or ATLAS])
+    fi
+    AC_MSG_RESULT([ACML prefixes specified, assume --with-lapack=acml])
     with_lapack="acml"
+    already_prefix=1
   fi
 fi
 
@@ -1226,7 +1248,7 @@
     AC_MSG_RESULT([Using $with_mkl_arch for MKL architecture directory])
 
     lapack_packages="mkl7 mkl5"
-  elif test "$with_lapack" == "yes"; then
+  elif test "$with_lapack" = "yes" -o "$with_lapack" = "probe"; then
     lapack_packages="atlas generic1 generic2 builtin"
   elif test "$with_lapack" == "generic"; then
     lapack_packages="generic1 generic2"
@@ -1663,6 +1685,13 @@
 AC_DEFINE_UNQUOTED(VSIP_IMPL_SIMD_TAG_LIST, $taglist,
           [Define to set whether or not to use Intel's IPP library.])
 
+#
+# Define VSIP_IMPL_TEST_LEVEL
+#
+AC_DEFINE_UNQUOTED(VSIP_IMPL_TEST_LEVEL, $with_test_level,
+          [Define to set test suite effort level (0, 1, or 2).])
+
+
 # Make sure all src directories exist in the build tree, this is
 # necessary for synopsis document generation.
 mkdir -p src/vsip/impl/simd
@@ -1724,6 +1753,11 @@
 AC_MSG_RESULT([With SAL:                                $enable_sal])
 AC_MSG_RESULT([With IPP:                                $enable_ipp])
 AC_MSG_RESULT([Using FFT backends:                      ${enable_fft}])
+if test "$with_complex" == "split"; then
+  AC_MSG_RESULT([Complex storage format:                  split])
+else
+  AC_MSG_RESULT([Complex storage format:                  interleaved])
+fi
 
 #
 # Done.
Index: src/vsip/matrix.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/matrix.hpp,v
retrieving revision 1.31
diff -u -r1.31 matrix.hpp
--- src/vsip/matrix.hpp	4 Apr 2006 02:21:12 -0000	1.31
+++ src/vsip/matrix.hpp	12 May 2006 19:23:37 -0000
@@ -290,13 +290,18 @@
     return diag_type(block);
   }
 
+#define VSIP_IMPL_ELEMENTWISE_SCALAR(op)        			\
+  *this = *this op val
 
-#define VSIP_IMPL_ELEMENTWISE_SCALAR(op)				\
+#define VSIP_IMPL_ELEMENTWISE_SCALAR_NOFWD(op)				\
   for (vsip::index_type r = 0; r < this->size(0); ++r)			\
     for (vsip::index_type c = 0; c < this->size(1); ++c)		\
       this->put(r, c, this->get(r, c) op val)
 
 #define VSIP_IMPL_ELEMENTWISE_MATRIX(op)				\
+  *this = *this op m;
+
+#define VSIP_IMPL_ELEMENTWISE_MATRIX_NOFWD(op)				\
   assert(this->size(0) == m.size(0) && this->size(1) == m.size(1));	\
   for (vsip::index_type r = 0; r < this->size(0); ++r)			\
     for (vsip::index_type c = 0; c < this->size(1); ++c)		\
@@ -313,20 +318,37 @@
   Matrix& operator asop(const Matrix<T0, Block0> m) VSIP_NOTHROW   \
   { VSIP_IMPL_ELEMENTWISE_MATRIX(op); return *this;}
 
+#define VSIP_IMPL_ASSIGN_OP_NOFWD(asop, op)			   	   \
+  template <typename T0>                                           \
+  Matrix& operator asop(T0 const& val) VSIP_NOTHROW                \
+  { VSIP_IMPL_ELEMENTWISE_SCALAR_NOFWD(op); return *this;}               \
+  template <typename T0, typename Block0>                          \
+  Matrix& operator asop(const_Matrix<T0, Block0> m) VSIP_NOTHROW   \
+  { VSIP_IMPL_ELEMENTWISE_MATRIX_NOFWD(op); return *this;}               \
+  template <typename T0, typename Block0>                          \
+  Matrix& operator asop(const Matrix<T0, Block0> m) VSIP_NOTHROW   \
+  { VSIP_IMPL_ELEMENTWISE_MATRIX_NOFWD(op); return *this;}
+
   // [view.matrix.assign]
   VSIP_IMPL_ASSIGN_OP(+=, +)
   VSIP_IMPL_ASSIGN_OP(-=, -)
   VSIP_IMPL_ASSIGN_OP(*=, *)
   VSIP_IMPL_ASSIGN_OP(/=, /)
-  VSIP_IMPL_ASSIGN_OP(&=, &)
-  VSIP_IMPL_ASSIGN_OP(|=, |)
-  VSIP_IMPL_ASSIGN_OP(^=, ^)
+  // For vector, ghs claims the use of operator& in 'view1 & view2' is
+  // ambiguous, thus we implement operator&= in terms of the scalar
+  // operator&.  Likewise for operator=| and operator=^.
+  VSIP_IMPL_ASSIGN_OP_NOFWD(&=, &)
+  VSIP_IMPL_ASSIGN_OP_NOFWD(|=, |)
+  VSIP_IMPL_ASSIGN_OP_NOFWD(^=, ^)
 };
 
 
 #undef VSIP_IMPL_ASSIGN_OP
 #undef VSIP_IMPL_ELEMENTWISE_SCALAR
 #undef VSIP_IMPL_ELEMENTWISE_MATRIX
+#undef VSIP_IMPL_ASSIGN_OP_NOFWD
+#undef VSIP_IMPL_ELEMENTWISE_SCALAR_NOFWD
+#undef VSIP_IMPL_ELEMENTWISE_MATRIX_NOFWD
 
 // [view.matrix.convert]
 template <typename T, typename Block>
Index: src/vsip/signal-window.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/signal-window.cpp,v
retrieving revision 1.6
diff -u -r1.6 signal-window.cpp
--- src/vsip/signal-window.cpp	1 May 2006 19:12:03 -0000	1.6
+++ src/vsip/signal-window.cpp	12 May 2006 19:23:37 -0000
@@ -220,7 +220,11 @@
 
 #pragma instantiate void vsip::impl::acosh<float>(vsip::Vector<float, vsip::Dense<(unsigned int)1, float, vsip::tuple<(unsigned int)0, (unsigned int)1, (unsigned int)2>, vsip::Local_map> > &, vsip::Vector<std::complex<float>, vsip::Dense<(unsigned int)1, std::complex<float>, vsip::tuple<(unsigned int)0, (unsigned int)1, (unsigned int)2>, vsip::Local_map> > &)
 
-#pragma instantiate vsip::impl::Point<1> vsip::impl::extent_old<1, Dense<1, complex<float>, row1_type, Local_map> >(const Dense<1, complex<float>, row1_type, Local_map>  &)
+#pragma instantiate Vector<complex<float>, impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_inter_fmt>, Local_map> > vsip::impl::fft::new_view<Vector<complex<float>, impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_inter_fmt>, Local_map> > >(const Domain<1>&)
+
+#pragma instantiate bool vsip::impl::data_access::is_direct_ok<Dense<1, complex<float>, row1_type, Local_map>, impl::Rt_layout<1> >(const Dense<1, complex<float>, row1_type, Local_map> &, const impl::Rt_layout<1>  &)
+
+#pragma instantiate bool vsip::impl::data_access::is_direct_ok<impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_inter_fmt>, Local_map>, impl::Rt_layout<1> >(const impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_inter_fmt>, Local_map> &, const impl::Rt_layout<1>&)
 #endif
 
 } // namespace vsip
Index: src/vsip/vector.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/vector.hpp,v
retrieving revision 1.39
diff -u -r1.39 vector.hpp
--- src/vsip/vector.hpp	4 Apr 2006 02:21:12 -0000	1.39
+++ src/vsip/vector.hpp	12 May 2006 19:23:37 -0000
@@ -279,6 +279,7 @@
 #undef VSIP_IMPL_ELEMENTWISE_SCALAR
 #undef VSIP_IMPL_ELEMENTWISE_VECTOR
 #undef VSIP_IMPL_ASSIGN_OP_NOFWD
+#undef VSIP_IMPL_ELEMENTWISE_SCALAR_NOFWD
 #undef VSIP_IMPL_ELEMENTWISE_VECTOR_NOFWD
 
 // [view.vector.convert]
Index: src/vsip/impl/aligned_allocator.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/aligned_allocator.hpp,v
retrieving revision 1.7
diff -u -r1.7 aligned_allocator.hpp
--- src/vsip/impl/aligned_allocator.hpp	28 Apr 2006 21:25:27 -0000	1.7
+++ src/vsip/impl/aligned_allocator.hpp	12 May 2006 19:23:37 -0000
@@ -18,6 +18,7 @@
 #include <limits>
 #include <cstdlib>
 
+#include <vsip/impl/acconfig.hpp>
 #include <vsip/impl/allocation.hpp>
 
 
Index: src/vsip/impl/distributed-block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/distributed-block.hpp,v
retrieving revision 1.20
diff -u -r1.20 distributed-block.hpp
--- src/vsip/impl/distributed-block.hpp	27 Mar 2006 23:19:34 -0000	1.20
+++ src/vsip/impl/distributed-block.hpp	12 May 2006 19:23:37 -0000
@@ -310,6 +310,24 @@
 
 
 
+/// Specialize block layout trait for Distributed_blocks.
+
+template <typename BlockT,
+	  typename MapT>
+struct Block_layout<Distributed_block<BlockT, MapT> >
+{
+  static dimension_type const dim = Block_layout<BlockT>::dim;
+
+  typedef typename Block_layout<BlockT>::access_type  access_type;
+  typedef typename Block_layout<BlockT>::order_type   order_type;
+  typedef typename Block_layout<BlockT>::pack_type    pack_type;
+  typedef typename Block_layout<BlockT>::complex_type complex_type;
+
+  typedef Layout<dim, order_type, pack_type, complex_type> layout_type;
+};
+
+
+
 /// Specialize Distributed_local_block traits class for Distributed_block.
 
 template <typename Block,
Index: src/vsip/impl/equal.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/equal.hpp,v
retrieving revision 1.1
diff -u -r1.1 equal.hpp
--- src/vsip/impl/equal.hpp	1 May 2006 19:12:03 -0000	1.1
+++ src/vsip/impl/equal.hpp	12 May 2006 19:23:37 -0000
@@ -22,7 +22,7 @@
 ///    www.cygnus-software.com/papers/comparingfloats/comparingfloats.htm
 
 template <typename T>
-bool
+inline bool
 almost_equal(T A, T B, T rel_epsilon = 1e-4, T abs_epsilon = 1e-6)
 {
   if (fn::mag(A - B) < abs_epsilon)
Index: src/vsip/impl/expr_scalar_block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_scalar_block.hpp,v
retrieving revision 1.14
diff -u -r1.14 expr_scalar_block.hpp
--- src/vsip/impl/expr_scalar_block.hpp	7 Mar 2006 02:15:22 -0000	1.14
+++ src/vsip/impl/expr_scalar_block.hpp	12 May 2006 19:23:37 -0000
@@ -228,11 +228,11 @@
 	  dimension_type D,
 	  typename       Scalar>
 struct Is_par_same_map<MapT,
-		       const Scalar_block<D, Scalar> >
+		       Scalar_block<D, Scalar> >
 {
-  typedef Scalar_block<D, Scalar> const block_type;
+  typedef Scalar_block<D, Scalar> block_type;
 
-  static bool value(MapT const&, block_type&)
+  static bool value(MapT const&, block_type const&)
   {
     return true;
   }
Index: src/vsip/impl/extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/extdata.hpp,v
retrieving revision 1.21
diff -u -r1.21 extdata.hpp
--- src/vsip/impl/extdata.hpp	7 May 2006 19:51:33 -0000	1.21
+++ src/vsip/impl/extdata.hpp	12 May 2006 19:23:37 -0000
@@ -286,13 +286,15 @@
 
 
 template <typename T>
-bool is_aligned_to(T* pointer, size_t align)
+inline bool
+is_aligned_to(T* pointer, size_t align)
 {
   return reinterpret_cast<size_t>(pointer) % align == 0;
 }
 
 template <typename T>
-bool is_aligned_to(std::pair<T*, T*> pointer, size_t align)
+inline bool
+is_aligned_to(std::pair<T*, T*> pointer, size_t align)
 {
   return reinterpret_cast<size_t>(pointer.first)  % align == 0 &&
          reinterpret_cast<size_t>(pointer.second) % align == 0;
Index: src/vsip/impl/par-expr.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-expr.hpp,v
retrieving revision 1.8
diff -u -r1.8 par-expr.hpp
--- src/vsip/impl/par-expr.hpp	11 Jan 2006 16:22:45 -0000	1.8
+++ src/vsip/impl/par-expr.hpp	12 May 2006 19:23:37 -0000
@@ -68,8 +68,17 @@
   typedef typename BlockT::const_reference_type const_reference_type;
   typedef MapT                                  map_type;
 
+  // The layout of the reorg block should have the same dimension-
+  // order and complex format as the source block.  Packing format
+  // should either be unit-stride-dense or unit-stride-aligned.
+  // It should not be taken directly from BlockT since it may have
+  // a non realizable packing format such as Stride_unknown.
+  typedef typename Block_layout<BlockT>::order_type        order_type;
+  typedef Stride_unit_dense                                pack_type;
+  typedef typename Block_layout<BlockT>::complex_type      complex_type;
+  typedef Layout<Dim, order_type, pack_type, complex_type> layout_type;
 
-  typedef Fast_block<Dim, value_type> local_block_type;
+  typedef Fast_block<Dim, value_type, layout_type>  local_block_type;
   typedef Distributed_block<local_block_type, MapT> dst_block_type;
 
   typedef typename View_of_dim<Dim, value_type, dst_block_type>::type
Index: src/vsip/impl/solver-covsol.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-covsol.hpp,v
retrieving revision 1.2
diff -u -r1.2 solver-covsol.hpp
--- src/vsip/impl/solver-covsol.hpp	26 Sep 2005 20:11:05 -0000	1.2
+++ src/vsip/impl/solver-covsol.hpp	12 May 2006 19:23:37 -0000
@@ -59,7 +59,7 @@
   assert(x.size(0) == n);
   assert(x.size(1) == p);
     
-  qrd<T, by_reference> qr(m, n, qrd_saveq);
+  qrd<T, by_reference> qr(m, n, qrd_nosaveq);
     
   if (!qr.decompose(a))
     VSIP_IMPL_THROW(computation_error("covsol - qr.decompose failed"));
Index: src/vsip/impl/solver-llsqsol.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-llsqsol.hpp,v
retrieving revision 1.1
diff -u -r1.1 solver-llsqsol.hpp
--- src/vsip/impl/solver-llsqsol.hpp	7 Sep 2005 15:06:36 -0000	1.1
+++ src/vsip/impl/solver-llsqsol.hpp	12 May 2006 19:23:37 -0000
@@ -18,6 +18,8 @@
 #include <vsip/matrix.hpp>
 #include <vsip/impl/solver-qr.hpp>
 
+#define VSIP_IMPL_USE_QRD_LSQSOL 1
+
 
 
 /***********************************************************************
@@ -57,10 +59,21 @@
   assert(x.size(0) == n);
   assert(x.size(1) == p);
     
-  qrd<T, by_reference> qr(m, n, qrd_saveq);
+
+  // These two methods produce equivalent results.  However, the second
+  // method requires full-QR, which not all backends provide.
+
+#if VSIP_IMPL_USE_QRD_LSQSOL
+  qrd<T, by_reference> qr(m, n, qrd_saveq1);
     
   qr.decompose(a);
+
+  qr.lsqsol(b, x);
+#else
+  qrd<T, by_reference> qr(m, n, qrd_saveq);
     
+  qr.decompose(a);
+
   mat_op_type const tr = impl::Is_complex<T>::value ? mat_herm : mat_trans;
     
   Matrix<T> c(m, p);
@@ -70,6 +83,7 @@
   
   // 2. solve for X:         R X = C
   qr.template rsol<mat_ntrans>(c(Domain<2>(n, p)), T(1), x);
+#endif
   
   return x;
 }
Index: src/vsip/impl/sal/solver_lu.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/solver_lu.hpp,v
retrieving revision 1.3
diff -u -r1.3 solver_lu.hpp
--- src/vsip/impl/sal/solver_lu.hpp	7 May 2006 20:08:02 -0000	1.3
+++ src/vsip/impl/sal/solver_lu.hpp	12 May 2006 19:23:37 -0000
@@ -30,7 +30,7 @@
 // by SAL.  Setting to '1' will select the newer mat_lud_sol/dec() variants 
 // and setting it to '0' will select the older matlud() and matfbs() pair.
 
-#define VSIP_IMPL_SAL_USE_MAT_LUD  0
+#define VSIP_IMPL_SAL_USE_MAT_LUD  1
 
 
 
Index: src/vsip/impl/sal/solver_svd.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/solver_svd.hpp,v
retrieving revision 1.1
diff -u -r1.1 solver_svd.hpp
--- src/vsip/impl/sal/solver_svd.hpp	11 May 2006 03:17:33 -0000	1.1
+++ src/vsip/impl/sal/solver_svd.hpp	12 May 2006 19:23:37 -0000
@@ -185,7 +185,6 @@
   length_type  m_;			// Number of rows.
   length_type  n_;			// Number of cols.
   length_type  p_;			// min(rows, cols)
-  vector_type  d_;                      // The diagonal vector
   storage_type ust_;			// U storage type
   storage_type vst_;			// V storage type
 
@@ -197,7 +196,7 @@
   Matrix<uv_type, cp_data_block_type> v_;	// V matrix
   Matrix<uv_type, cp_data_block_type> ut_;	// U' matrix
   Matrix<uv_type, cp_data_block_type> vt_;	// V' matrix
-
+  vector_type  d_;                      	// The diagonal vector
 };
 
 
@@ -422,11 +421,11 @@
     assert(x.size(0) == prod_m && x.size(1) == prod_n);
     sal_svd_prod_uv(b,((tr == mat_ntrans)? u_:ut_),x);
   }
+  return true;
+}
 
 
 
-}
-
 template <typename T,
 	  bool     Blocked>
 template <mat_op_type       tr,
@@ -473,6 +472,7 @@
     assert(x.size(0) == prod_m && x.size(1) == prod_n);
     sal_svd_prod_uv(b,((tr == mat_ntrans)? v_:vt_),x);
   }
+  return true;
 }
 
 // This helper function is necessary because when we want a submatrix of u or
Index: tests/extdata-output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata-output.hpp,v
retrieving revision 1.8
diff -u -r1.8 extdata-output.hpp
--- tests/extdata-output.hpp	2 Nov 2005 18:44:04 -0000	1.8
+++ tests/extdata-output.hpp	12 May 2006 19:23:37 -0000
@@ -193,6 +193,19 @@
   static std::string name() { return std::string("Unary_expr_block<>"); }
 };
 
+template <vsip::dimension_type D, typename Scalar>
+struct Type_name<vsip::impl::Scalar_block<D, Scalar> >
+{
+  static std::string name()
+  {
+    std::ostringstream s;
+    s << "Scalar_block<" 
+      << D << ", "
+      << Type_name<Scalar>::name() << ">";
+    return s.str();
+ }
+};
+
 
 TYPE_NAME(vsip::Block_dist,  "Block_dist")
 TYPE_NAME(vsip::Cyclic_dist, "Cyclic_dist")
Index: tests/solver-covsol.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-covsol.cpp,v
retrieving revision 1.3
diff -u -r1.3 solver-covsol.cpp
--- tests/solver-covsol.cpp	20 Dec 2005 12:48:41 -0000	1.3
+++ tests/solver-covsol.cpp	12 May 2006 19:23:37 -0000
@@ -145,7 +145,8 @@
 
 template <return_mechanism_type RtM,
 	  typename              T>
-void covsol_cases()
+void
+covsol_cases(vsip::impl::Bool_type<true>)
 {
   test_covsol_diag<RtM, T>(1,   1, 2);
   test_covsol_diag<RtM, T>(5,   5, 2);
@@ -182,6 +183,40 @@
     }
 #endif
 }
+
+
+
+template <return_mechanism_type RtM,
+	  typename              T>
+void
+covsol_cases(vsip::impl::Bool_type<false>)
+{
+}
+
+
+
+// Front-end function for covsol_cases.
+
+// This function dispatches to either real set of tests or an empty
+// function depending on whether the QR backends configured in support
+// value type T.  Covsol is implemented with QR, and not all QR backends
+// support all value types.
+
+template <return_mechanism_type RtM,
+	  typename              T>
+void
+covsol_cases()
+{
+  using vsip::impl::Bool_type;
+  using vsip::impl::Type_equal;
+  using vsip::impl::Choose_qrd_impl;
+  using vsip::impl::None_type;
+  using vsip::impl::Mercury_sal_tag;
+
+  covsol_cases<RtM, T>(
+	Bool_type<!Type_equal<typename Choose_qrd_impl<T>::type,
+                              None_type>::value>());
+}
   
 
 
Index: tests/solver-llsqsol.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-llsqsol.cpp,v
retrieving revision 1.4
diff -u -r1.4 solver-llsqsol.cpp
--- tests/solver-llsqsol.cpp	20 Dec 2005 12:48:41 -0000	1.4
+++ tests/solver-llsqsol.cpp	12 May 2006 19:23:37 -0000
@@ -130,11 +130,25 @@
        << ">(" << m << ", " << n << ", " << p << "): " << err << endl;
 #endif
 
-  if (err > 10.0)
+  typedef typename impl::Scalar_of<T>::type scalar_type;
+#if NORMAL_EPSILON
+  // These are almost_equal()'s normal epsilon.  They work fine for Lapack.
+  scalar_type rel_epsilon = 1e-3;
+  scalar_type abs_epsilon = 1e-5;
+  float       err_bound   = 10.0;
+#else
+  // These are looser bounds.  They are necessary for SAL.
+  scalar_type rel_epsilon = 1e-3;
+  scalar_type abs_epsilon = 1e-5;
+  float       err_bound   = 50.0;
+#endif
+
+  if (err > err_bound)
   {
     for (index_type r=0; r<m; ++r)
       for (index_type c=0; c<p; ++c)
-	test_assert(equal(b(r, c), chk(r, c)));
+	test_assert(almost_equal(b.get(r, c), chk.get(r, c),
+				 rel_epsilon, abs_epsilon));
   }
 }
 
@@ -142,7 +156,8 @@
 
 template <return_mechanism_type RtM,
 	  typename              T>
-void llsqsol_cases()
+void
+llsqsol_cases(vsip::impl::Bool_type<true>)
 {
   test_llsqsol_diag<RtM, T>(1,   1, 2);
   test_llsqsol_diag<RtM, T>(5,   5, 2);
@@ -182,6 +197,40 @@
 
 
 
+template <return_mechanism_type RtM,
+	  typename              T>
+void
+llsqsol_cases(vsip::impl::Bool_type<false>)
+{
+}
+
+
+
+// Front-end function for llsqsol_cases.
+
+// This function dispatches to either real set of tests or an empty
+// function depending on whether the QR backends configured in support
+// value type T.  llsqsol is implemented with QR, and not all QR backends
+// support all value types.
+
+template <return_mechanism_type RtM,
+	  typename              T>
+void
+llsqsol_cases()
+{
+  using vsip::impl::Bool_type;
+  using vsip::impl::Type_equal;
+  using vsip::impl::Choose_qrd_impl;
+  using vsip::impl::None_type;
+  using vsip::impl::Mercury_sal_tag;
+
+  llsqsol_cases<RtM, T>(
+	Bool_type<!Type_equal<typename Choose_qrd_impl<T>::type,
+                              None_type>::value>());
+}
+
+
+
 /***********************************************************************
   Main
 ***********************************************************************/
Index: tests/solver-lu.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-lu.cpp,v
retrieving revision 1.5
diff -u -r1.5 solver-lu.cpp
--- tests/solver-lu.cpp	3 May 2006 18:43:10 -0000	1.5
+++ tests/solver-lu.cpp	12 May 2006 19:23:37 -0000
@@ -484,11 +484,12 @@
   using vsip::impl::Bool_type;
   using vsip::impl::Type_equal;
   using vsip::impl::Choose_lud_impl;
+  using vsip::impl::Choose_svd_impl;
   using vsip::impl::None_type;
 
-  lud_cases<T>(rtm,
-	       Bool_type<!Type_equal<typename Choose_lud_impl<T>::type,
-	                             None_type>::value>());
+  lud_cases<T>(rtm, Bool_type<
+	!Type_equal<typename Choose_lud_impl<T>::type, None_type>::value &&
+	!Type_equal<typename Choose_svd_impl<T>::type, None_type>::value>());
 }
 
 
Index: tests/solver-qr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-qr.cpp,v
retrieving revision 1.8
diff -u -r1.8 solver-qr.cpp
--- tests/solver-qr.cpp	9 May 2006 11:24:49 -0000	1.8
+++ tests/solver-qr.cpp	12 May 2006 19:23:37 -0000
@@ -54,9 +54,9 @@
 template <typename T>
 void
 test_covsol_diag(
-  length_type  m = 5,
-  length_type  n = 5,
-  length_type  p = 2,
+  length_type  m,
+  length_type  n,
+  length_type  p,
   storage_type st
   )
 {
Index: tests/solver-svd.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-svd.cpp,v
retrieving revision 1.2
diff -u -r1.2 solver-svd.cpp
--- tests/solver-svd.cpp	20 Dec 2005 12:48:41 -0000	1.2
+++ tests/solver-svd.cpp	12 May 2006 19:23:37 -0000
@@ -23,7 +23,13 @@
 #include "solver-common.hpp"
 
 #define VERBOSE  0
-#define DO_FULL  0
+#if !defined(DO_FULL)
+#  if VSIP_IMPL_TEST_LEVEL >= 2
+#    define DO_FULL  1
+#  else
+#    define DO_FULL  0
+#  endif
+#endif
 
 #if VERBOSE
 #  include <iostream>
@@ -264,6 +270,24 @@
 		   trans_or_herm(sv_v(Domain<2>(n, p))));
       }
 
+      // When using LAPACK, the error E when computing the
+      // bi-diagonal decomposition Q, B, P
+      //
+      //   A + E = Q B herm(P)
+      //
+      // Is
+      //
+      //   norm-2(E) = c(n) eps norm-2(A)
+      //
+      // Where
+      //
+      //   c(n) is a "modestly increasing function of n", and
+      //   eps is the machine precision.   
+      //
+      // Computing norm-2(A) is expensive, so we use the relationship:
+      //
+      //   norm-2(A) <= sqrt(norm-1(A) norm-inf(A))
+
       Index<2> idx;
       scalar_type err = maxval((mag(chk - a)
 			      / Precision_traits<scalar_type>::eps),
@@ -459,35 +483,93 @@
 
 template <return_mechanism_type RtM,
 	  typename              T>
-void svd_cases(
+void
+svd_cases(
   storage_type ustorage,
   storage_type vstorage,
-  length_type  loop)
+  length_type  loop,
+  bool         m_lt_n,
+  vsip::impl::Bool_type<true>)
 {
   test_svd_ident<RtM, T>(ustorage, vstorage, 1, 1, loop);
-  test_svd_ident<RtM, T>(ustorage, vstorage, 1, 7, loop);
   test_svd_ident<RtM, T>(ustorage, vstorage, 9, 1, loop);
 
   test_svd_ident<RtM, T>(ustorage, vstorage, 5,   5, loop);
   test_svd_ident<RtM, T>(ustorage, vstorage, 16,  5, loop);
-  test_svd_ident<RtM, T>(ustorage, vstorage, 3,  20, loop);
+
+  if (m_lt_n)
+  {
+    test_svd_ident<RtM, T>(ustorage, vstorage, 1, 7, loop);
+    test_svd_ident<RtM, T>(ustorage, vstorage, 3,  20, loop);
+  }
 
   test_svd_rand<RtM, T>(ustorage, vstorage, 5, 5, loop);
   test_svd_rand<RtM, T>(ustorage, vstorage, 5, 3, loop);
-  test_svd_rand<RtM, T>(ustorage, vstorage, 3, 5, loop);
+
+  if (m_lt_n)
+  {
+    test_svd_rand<RtM, T>(ustorage, vstorage, 3, 5, loop);
+  }
+
 #if DO_FULL
   test_svd_rand<RtM, T>(ustorage, vstorage, 17, 5, loop);
-  test_svd_rand<RtM, T>(ustorage, vstorage, 5, 17, loop);
-  test_svd_rand<RtM, T>(ustorage, vstorage, 17, 19, loop);
   test_svd_rand<RtM, T>(ustorage, vstorage, 25, 27, loop);
   test_svd_rand<RtM, T>(ustorage, vstorage, 32, 32, loop);
-  test_svd_rand<RtM, T>(ustorage, vstorage, 8, 32, loop);
   test_svd_rand<RtM, T>(ustorage, vstorage, 32, 10, loop);
+
+  if (m_lt_n)
+  {
+    test_svd_rand<RtM, T>(ustorage, vstorage, 5, 17, loop);
+    test_svd_rand<RtM, T>(ustorage, vstorage, 17, 19, loop);
+    test_svd_rand<RtM, T>(ustorage, vstorage, 8, 32, loop);
+  }
 #endif
 }
 
 
 
+template <return_mechanism_type RtM,
+	  typename              T>
+void
+svd_cases(
+  storage_type,
+  storage_type,
+  length_type,
+  bool,
+  vsip::impl::Bool_type<false>)
+{
+}
+
+
+
+// Front-end function for svd_cases.
+
+template <return_mechanism_type RtM,
+	  typename              T>
+void
+svd_cases(
+  storage_type ustorage,
+  storage_type vstorage,
+  length_type  loop)
+{
+  using vsip::impl::Bool_type;
+  using vsip::impl::Type_equal;
+  using vsip::impl::Choose_svd_impl;
+  using vsip::impl::None_type;
+  using vsip::impl::Mercury_sal_tag;
+
+  // Test m less-than n cases.
+  bool m_lt_n =
+    !Type_equal<typename Choose_svd_impl<T>::type, Mercury_sal_tag>::value;
+
+  svd_cases<RtM, T>(
+	ustorage, vstorage, loop, m_lt_n,
+	Bool_type<!Type_equal<typename Choose_svd_impl<T>::type,
+                              None_type>::value>());
+}
+
+
+
 template <return_mechanism_type RtM>
 void
 svd_types(
