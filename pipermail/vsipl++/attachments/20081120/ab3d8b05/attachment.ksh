Index: ChangeLog
===================================================================
--- ChangeLog	(revision 228622)
+++ ChangeLog	(working copy)
@@ -1,3 +1,10 @@
+2008-11-20  Jules Bergmann  <jules@codesourcery.com>
+
+	Fix ukernel/interp.cpp 64-bit failure:
+	* src/vsip/opt/ukernel/kernels/host/interp.hpp: Use uint32_t for
+	  matrix of indices (SPE expects integers to be 32-bit).
+	* tests/ukernel/interp.cpp: Likewise.
+	
 2008-11-20  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* tests/cvsip/dda.c: Remove C++isms from C code.
@@ -79,7 +86,7 @@
 	* src/vsip/opt/diag/eval.hpp: Add missing <typeinfo> inclusion.
 	* src/vsip/initfin.cpp: Add missing <cstring> inclusion.
 	* src/vsip/opt/lapack/bindings.hpp: Pass string literals as
-	'char const *'.
+	'char const *'.  Remove xerbla_ decl.
 	* examples/cvsip/fft.c: Remove some C++-isms.
 	
 2008-10-29  Mike LeBlanc  <mike@codesourcery.com>
Index: src/vsip/opt/ukernel/kernels/host/interp.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/host/interp.hpp	(revision 228622)
+++ src/vsip/opt/ukernel/kernels/host/interp.hpp	(working copy)
@@ -101,7 +101,7 @@
 
 DEFINE_UKERNEL_TASK(
   Interp_kernel,
-  void(vsip::index_type*, float*, std::complex<float>*, std::complex<float>*),
+  void(uint32_t*, float*, std::complex<float>*, std::complex<float>*),
   interp_f)
 
 #endif // VSIP_SRC_OPT_UKERNEL_KERNELS_HOST_INTERP_HPP
Index: tests/ukernel/interp.cpp
===================================================================
--- tests/ukernel/interp.cpp	(revision 228622)
+++ tests/ukernel/interp.cpp	(working copy)
@@ -34,14 +34,15 @@
 namespace ref
 {
 
-template <typename T,
+template <typename IT,
+	  typename T,
 	  typename Block1,
 	  typename Block2,
 	  typename Block3,
 	  typename Block4>
 void
 interpolate(
-  const_Matrix<index_type, Block1> indices,  // n x m
+  const_Matrix<IT, Block1>	   indices,  // n x m
   Tensor<T, Block2>                window,   // n x m x I
   const_Matrix<complex<T>, Block3> in,       // n x m
   Matrix<complex<T>, Block4>       out)      // nx x m
@@ -81,7 +82,7 @@
 void
 test_ukernel(length_type rows, length_type cols, length_type depth)
 {
-  typedef vsip::index_type I;
+  typedef uint32_t I;
   typedef std::complex<T>  C;
   typedef tuple<1, 0, 2> order_type;
 
