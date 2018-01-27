Index: benchmarks/prod.cpp
===================================================================
--- benchmarks/prod.cpp	(revision 169307)
+++ benchmarks/prod.cpp	(working copy)
@@ -39,7 +39,7 @@
 // Matrix-matrix product benchmark class.
 
 template <typename T>
-struct t_prod1
+struct t_prod1 : Benchmark_base
 {
   static length_type const Dec = 1;
 
@@ -86,7 +86,7 @@
 // Matrix-matrix product (with hermetian) benchmark class.
 
 template <typename T>
-struct t_prodh1
+struct t_prodh1 : Benchmark_base
 {
   static length_type const Dec = 1;
 
@@ -133,7 +133,7 @@
 // Matrix-matrix product (with tranpose) benchmark class.
 
 template <typename T>
-struct t_prodt1
+struct t_prodt1 : Benchmark_base
 {
   static length_type const Dec = 1;
 
@@ -181,7 +181,7 @@
 
 template <typename ImplTag,
 	  typename T>
-struct t_prod2
+struct t_prod2 : Benchmark_base
 {
   static length_type const Dec = 1;
 
@@ -237,7 +237,7 @@
 
 template <typename ImplTag,
 	  typename T>
-struct t_prod2pb
+struct t_prod2pb : Benchmark_base
 {
   static length_type const Dec = 1;
 
Index: benchmarks/conv.cpp
===================================================================
--- benchmarks/conv.cpp	(revision 169307)
+++ benchmarks/conv.cpp	(working copy)
@@ -37,7 +37,7 @@
 
 template <support_region_type Supp,
 	  typename            T>
-struct t_conv1
+struct t_conv1 : Benchmark_base
 {
   static length_type const Dec = 1;
 
Index: benchmarks/corr.cpp
===================================================================
--- benchmarks/corr.cpp	(revision 169307)
+++ benchmarks/corr.cpp	(working copy)
@@ -36,7 +36,7 @@
 
 template <support_region_type Supp,
 	  typename            T>
-struct t_corr1
+struct t_corr1 : Benchmark_base
 {
   char* what() { return "t_corr1"; }
   float ops_per_point(length_type size)
@@ -106,7 +106,7 @@
 template <typename            ImplTag,
 	  support_region_type Supp,
 	  typename            T>
-struct t_corr2
+struct t_corr2 : Benchmark_base
 {
   char* what() { return "t_corr2"; }
   float ops_per_point(length_type size)
Index: benchmarks/dist_vmul.cpp
===================================================================
--- benchmarks/dist_vmul.cpp	(revision 169307)
+++ benchmarks/dist_vmul.cpp	(working copy)
@@ -115,7 +115,7 @@
 template <typename T,
 	  typename MapT,
 	  typename SP>
-struct t_dist_vmul<T, MapT, SP, Impl_assign>
+struct t_dist_vmul<T, MapT, SP, Impl_assign> : Benchmark_base
 {
   char* what() { return "t_vmul"; }
   int ops_per_point(length_type)  { return impl::Ops_info<T>::mul; }
@@ -197,7 +197,7 @@
 template <typename T,
 	  typename MapT,
 	  typename SP>
-struct t_dist_vmul<T, MapT, SP, Impl_sa>
+struct t_dist_vmul<T, MapT, SP, Impl_sa> : Benchmark_base
 {
   char* what() { return "t_vmul"; }
   int ops_per_point(length_type)  { return impl::Ops_info<T>::mul; }
Index: benchmarks/vdiv.cpp
===================================================================
--- benchmarks/vdiv.cpp	(revision 169307)
+++ benchmarks/vdiv.cpp	(working copy)
@@ -31,7 +31,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_vdiv1
+struct t_vdiv1 : Benchmark_base
 {
   char* what() { return "t_vdiv1"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::div; }
@@ -76,7 +76,7 @@
 
 
 template <typename T>
-struct t_vdiv_ip1
+struct t_vdiv_ip1 : Benchmark_base
 {
   char* what() { return "t_vdiv_ip1"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::div; }
@@ -112,7 +112,7 @@
 
 
 template <typename T>
-struct t_vdiv_dom1
+struct t_vdiv_dom1 : Benchmark_base
 {
   char* what() { return "t_vdiv_dom1"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::div; }
@@ -159,7 +159,7 @@
 
 #ifdef VSIP_IMPL_SOURCERY_VPP
 template <typename T, typename ComplexFmt>
-struct t_vdiv2
+struct t_vdiv2 : Benchmark_base
 {
   char* what() { return "t_vdiv2"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::div; }
@@ -205,7 +205,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_rcvdiv1
+struct t_rcvdiv1 : Benchmark_base
 {
   char* what() { return "t_rcvdiv1"; }
   int ops_per_point(length_type)  { return 2*vsip::impl::Ops_info<T>::div; }
@@ -246,7 +246,7 @@
 
 template <typename ScalarT,
 	  typename T>
-struct t_svdiv1
+struct t_svdiv1 : Benchmark_base
 {
   char* what() { return "t_svdiv1"; }
   int ops_per_point(length_type)
@@ -285,7 +285,7 @@
 // Benchmark scalar-view vector divide (Scalar / View)
 
 template <typename T>
-struct t_svdiv2
+struct t_svdiv2 : Benchmark_base
 {
   char* what() { return "t_svdiv2"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::div; }
Index: benchmarks/fir.cpp
===================================================================
--- benchmarks/fir.cpp	(revision 169307)
+++ benchmarks/fir.cpp	(working copy)
@@ -33,7 +33,7 @@
 template <obj_state      Save,
 	  length_type    Dec,
 	  typename       T>
-struct t_fir1
+struct t_fir1 : Benchmark_base
 {
 
   char* what() { return "t_fir1"; }
Index: benchmarks/dot.cpp
===================================================================
--- benchmarks/dot.cpp	(revision 169307)
+++ benchmarks/dot.cpp	(working copy)
@@ -37,7 +37,7 @@
 // Dot-product benchmark class.
 
 template <typename T>
-struct t_dot1
+struct t_dot1 : Benchmark_base
 {
   static length_type const Dec = 1;
 
@@ -84,7 +84,7 @@
 
 template <typename ImplTag,
 	  typename T>
-struct t_dot2
+struct t_dot2 : Benchmark_base
 {
   static length_type const Dec = 1;
 
Index: benchmarks/memwrite.cpp
===================================================================
--- benchmarks/memwrite.cpp	(revision 169307)
+++ benchmarks/memwrite.cpp	(working copy)
@@ -34,7 +34,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_memwrite1
+struct t_memwrite1 : Benchmark_base
 {
   char* what() { return "t_memwrite1"; }
   int ops_per_point(length_type)  { return 1; }
@@ -66,7 +66,7 @@
 // explicit loop
 
 template <typename T>
-struct t_memwrite_expl
+struct t_memwrite_expl : Benchmark_base
 {
   char* what() { return "t_memwrite_expl"; }
   int ops_per_point(length_type)  { return 1; }
Index: benchmarks/memwrite_simd.cpp
===================================================================
--- benchmarks/memwrite_simd.cpp	(revision 169307)
+++ benchmarks/memwrite_simd.cpp	(working copy)
@@ -41,7 +41,7 @@
 
 template <typename T,
 	  typename ComplexFmt = Cmplx_inter_fmt>
-struct t_memwrite_simd
+struct t_memwrite_simd : Benchmark_base
 {
   char* what() { return "t_memwrite_simd"; }
   int ops_per_point(size_t)  { return 1; }
@@ -92,7 +92,7 @@
 
 template <typename T,
 	  typename ComplexFmt = Cmplx_inter_fmt>
-struct t_memwrite_simd_r4
+struct t_memwrite_simd_r4 : Benchmark_base
 {
   char* what() { return "t_memwrite_simd_r4"; }
   int ops_per_point(size_t)  { return 1; }
Index: benchmarks/sumval.cpp
===================================================================
--- benchmarks/sumval.cpp	(revision 169307)
+++ benchmarks/sumval.cpp	(working copy)
@@ -34,7 +34,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_sumval1
+struct t_sumval1 : Benchmark_base
 {
   char* what() { return "t_sumval_vector"; }
   int ops_per_point(length_type)  { return 1; }
@@ -78,7 +78,7 @@
 
 
 template <typename T>
-struct t_sumval2
+struct t_sumval2 : Benchmark_base
 {
   char* what() { return "t_sumval_matrix32"; }
   int ops_per_point(length_type)  { return 1; }
@@ -114,7 +114,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_sumval_gp
+struct t_sumval_gp : Benchmark_base
 {
   char* what() { return "t_sumval_gp"; }
   int ops_per_point(length_type)  { return 1; }
Index: benchmarks/prod_var.cpp
===================================================================
--- benchmarks/prod_var.cpp	(revision 169307)
+++ benchmarks/prod_var.cpp	(working copy)
@@ -319,7 +319,7 @@
 // Matrix-matrix product benchmark class.
 
 template <int ImplI, typename T>
-struct t_prod1
+struct t_prod1 : Benchmark_base
 {
   static length_type const Dec = 1;
 
Index: benchmarks/sumval_simd.cpp
===================================================================
--- benchmarks/sumval_simd.cpp	(revision 169307)
+++ benchmarks/sumval_simd.cpp	(working copy)
@@ -41,7 +41,7 @@
 
 template <typename T,
 	  typename ComplexFmt = Cmplx_inter_fmt>
-struct t_sumval_simd
+struct t_sumval_simd : Benchmark_base
 {
   typedef vsip::impl::simd::Simd_traits<T> S;
   typedef typename S::simd_type            simd_type;
@@ -106,7 +106,7 @@
 
 template <typename T,
 	  typename ComplexFmt = Cmplx_inter_fmt>
-struct t_sumval_simd_no // no-overheads
+struct t_sumval_simd_no : Benchmark_base // no-overheads
 {
   typedef vsip::impl::simd::Simd_traits<T> S;
   typedef typename S::simd_type            simd_type;
@@ -173,7 +173,7 @@
 
 template <typename T,
 	  typename ComplexFmt = Cmplx_inter_fmt>
-struct t_sumval_simd_r4
+struct t_sumval_simd_r4 : Benchmark_base
 {
   char* what() { return "t_sumval_simd_r4"; }
   int ops_per_point(size_t)  { return 1; }
@@ -263,7 +263,7 @@
 
 template <typename T,
 	  typename ComplexFmt = Cmplx_inter_fmt>
-struct t_sumval_simd_r4_no
+struct t_sumval_simd_r4_no : Benchmark_base
 {
   char* what() { return "t_sumval_simd_r4_no"; }
   int ops_per_point(size_t)  { return 1; }
