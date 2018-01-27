? benchmarks/simd.h
? benchmarks/sse.h
? benchmarks/vmul_simd.cpp
? benchmarks/vmul_sse.cpp
Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.405
diff -u -r1.405 ChangeLog
--- ChangeLog	7 Mar 2006 12:18:49 -0000	1.405
+++ ChangeLog	7 Mar 2006 20:07:02 -0000
@@ -1,3 +1,19 @@
+2006-03-07  Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmarks/corr.cpp: Remove unused function/classes.  Add
+	  mem_per_points() function.
+	* benchmarks/dot.cpp: Add mem_per_points() function.
+	* benchmarks/fastconv.cpp: Likewise.
+	* benchmarks/fft_ext_ipp.cpp: Likewise.
+	* benchmarks/fftm.cpp: Likewise.
+	* benchmarks/fir.cpp: Likewise.
+	* benchmarks/mcopy_ipp.cpp: Likewise.
+	* benchmarks/prod.cpp: Likewise.
+	* benchmarks/prod_var.cpp: Likewise.
+	* benchmarks/sumval.cpp: Likewise.
+	* benchmarks/vmmul.cpp: Likewise.
+	* benchmarks/vmul_sal.cpp: Likewise.
+	
 2006-03-06  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac (--with-alignment): New option to set
Index: benchmarks/corr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/corr.cpp,v
retrieving revision 1.1
diff -u -r1.1 corr.cpp
--- benchmarks/corr.cpp	7 Oct 2005 13:46:46 -0000	1.1
+++ benchmarks/corr.cpp	7 Mar 2006 20:07:02 -0000
@@ -27,38 +27,10 @@
 using namespace vsip;
 
 
-/// Return a random value between -0.5 and +0.5
-
-template <typename T>
-struct Random
-{
-  static T value() { return T(1.f * rand()/(RAND_MAX+1.0)) - T(0.5); }
-};
-
-/// Specialization for random complex value.
-
-template <typename T>
-struct Random<complex<T> >
-{
-  static complex<T> value() {
-    return complex<T>(Random<T>::value(), Random<T>::value());
-  }
-};
-
-
-
-/// Fill a matrix with random values.
-
-template <typename T,
-	  typename Block>
-void
-randm(Matrix<T, Block> m)
-{
-  for (index_type r=0; r<m.size(0); ++r)
-    for (index_type c=0; c<m.size(1); ++c)
-      m(r, c) = Random<T>::value();
-}
 
+/***********************************************************************
+  Definitions
+***********************************************************************/
 
 template <support_region_type Supp,
 	  typename            T>
@@ -74,8 +46,9 @@
     return ops / size;
   }
 
-  int riob_per_point(length_type) { return -1*sizeof(T); }
-  int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int mem_per_point(length_type) { return 2*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
   {
@@ -125,7 +98,10 @@
 
 
 
-template <typename            Tag,
+// Benchmark performance of a Correlation_impl object
+// (requires ImplTag to select implementation)
+
+template <typename            ImplTag,
 	  support_region_type Supp,
 	  typename            T>
 struct t_corr2
@@ -140,8 +116,9 @@
     return ops / size;
   }
 
-  int riob_per_point(length_type) { return -1*sizeof(T); }
-  int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int mem_per_point(length_type) { return 2*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
   {
@@ -154,7 +131,7 @@
     ref(0) = T(1);
     ref(1) = T(2);
 
-    typedef impl::Correlation_impl<const_Vector, Supp, T, 0, alg_time, Tag>
+    typedef impl::Correlation_impl<const_Vector, Supp, T, 0, alg_time, ImplTag>
 		corr_type;
 
     corr_type corr((Domain<1>(ref_size_)), Domain<1>(size));
Index: benchmarks/dot.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/dot.cpp,v
retrieving revision 1.2
diff -u -r1.2 dot.cpp
--- benchmarks/dot.cpp	20 Dec 2005 17:10:35 -0000	1.2
+++ benchmarks/dot.cpp	7 Mar 2006 20:07:02 -0000
@@ -49,6 +49,7 @@
 
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 0; }
+  int mem_per_point(length_type) { return 2*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
   {
@@ -95,6 +96,7 @@
 
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 0; }
+  int mem_per_point(length_type) { return 2*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
   {
Index: benchmarks/fastconv.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fastconv.cpp,v
retrieving revision 1.3
diff -u -r1.3 fastconv.cpp
--- benchmarks/fastconv.cpp	3 Mar 2006 14:30:53 -0000	1.3
+++ benchmarks/fastconv.cpp	7 Mar 2006 20:07:02 -0000
@@ -705,7 +705,7 @@
     { return (int)(this->ops(npulse_, size) / size); }
   int riob_per_point(length_type) { return -1*(int)sizeof(T); }
   int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
-  int mem_per_point(length_type size) { return npulse_*sizeof(T); }
+  int mem_per_point(length_type)  { return npulse_*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
   {
@@ -732,7 +732,7 @@
     { return (int)(this->ops(size, nrange_) / size); }
   int riob_per_point(length_type) { return -1*(int)sizeof(T); }
   int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
-  int mem_per_point(length_type size) { return nrange_*sizeof(T); }
+  int mem_per_point(length_type)  { return nrange_*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
   {
Index: benchmarks/fft_ext_ipp.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fft_ext_ipp.cpp,v
retrieving revision 1.1
diff -u -r1.1 fft_ext_ipp.cpp
--- benchmarks/fft_ext_ipp.cpp	7 Sep 2005 12:19:30 -0000	1.1
+++ benchmarks/fft_ext_ipp.cpp	7 Mar 2006 20:07:02 -0000
@@ -26,6 +26,12 @@
 
 using namespace vsip;
 
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
 int
 get_order(length_type size)
 {
@@ -147,6 +153,9 @@
 }
 
 
+
+// Out of place FFT
+
 template <typename T>
 struct t_fft
 {
@@ -154,6 +163,7 @@
   int ops_per_point(length_type len)  { return fft_ops(len); }
   int riob_per_point(length_type) { return -1*sizeof(T); }
   int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int mem_per_point(length_type)  { return  2*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
   {
Index: benchmarks/fftm.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fftm.cpp,v
retrieving revision 1.1
diff -u -r1.1 fftm.cpp
--- benchmarks/fftm.cpp	19 Dec 2005 16:08:55 -0000	1.1
+++ benchmarks/fftm.cpp	7 Mar 2006 20:07:02 -0000
@@ -58,6 +58,8 @@
 	  int      SD>
 struct t_fftm<T, Impl_op, SD>
 {
+  static int const elem_per_point = 2;
+
   char* what() { return "t_fftm<T, Impl_op, SD>"; }
   int ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
@@ -104,6 +106,8 @@
 	  int      SD>
 struct t_fftm<T, Impl_ip, SD>
 {
+  static int const elem_per_point = 1;
+
   char* what() { return "t_fftm<T, Impl_ip, SD>"; }
   int ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
@@ -152,6 +156,8 @@
 	  int      SD>
 struct t_fftm<T, Impl_pip1, SD>
 {
+  static int const elem_per_point = 1;
+
   char* what() { return "t_fftm<T, Impl_ip, SD>"; }
   int ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
@@ -217,6 +223,8 @@
 	  int      SD>
 struct t_fftm<T, Impl_pip2, SD>
 {
+  static int const elem_per_point = 1;
+
   char* what() { return "t_fftm<T, Impl_ip, SD>"; }
   int ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
@@ -295,12 +303,14 @@
 struct t_fftm_fix_rows : public t_fftm<T, ImplTag, SD>
 {
   typedef t_fftm<T, ImplTag, SD> base_type;
+  static int const elem_per_point = base_type::elem_per_point;
 
   char* what() { return "t_fftm_fix_rows"; }
   int ops_per_point(length_type cols)
     { return (int)(this->ops(rows_, cols) / cols); }
-  int riob_per_point(length_type) { return -1*sizeof(T); }
-  int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int mem_per_point(length_type cols) { return cols*elem_per_point*sizeof(T); }
 
   void operator()(length_type cols, length_type loop, float& time)
   {
@@ -323,12 +333,14 @@
 struct t_fftm_fix_cols : public t_fftm<T, ImplTag, SD>
 {
   typedef t_fftm<T, ImplTag, SD> base_type;
+  static int const elem_per_point = base_type::elem_per_point;
 
   char* what() { return "t_fftm_fix_cols"; }
   int ops_per_point(length_type rows)
     { return (int)(this->ops(rows, cols_) / rows); }
   int riob_per_point(length_type) { return -1*sizeof(T); }
   int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int mem_per_point(length_type cols) { return cols*elem_per_point*sizeof(T); }
 
   void operator()(length_type rows, length_type loop, float& time)
   {
@@ -344,7 +356,7 @@
 
 
 /***********************************************************************
-  Fixed cols driver
+  Main definitions
 ***********************************************************************/
 
 
Index: benchmarks/fir.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fir.cpp,v
retrieving revision 1.1
diff -u -r1.1 fir.cpp
--- benchmarks/fir.cpp	24 Oct 2005 13:25:30 -0000	1.1
+++ benchmarks/fir.cpp	7 Mar 2006 20:07:02 -0000
@@ -48,6 +48,9 @@
   int wiob_per_point(length_type)
     { return this->coeff_size_ * sizeof(T); }
 
+  int mem_per_point(length_type)
+    { return 2 * sizeof(T); }
+
   void operator()(length_type size, length_type loop, float& time)
   {
     typedef Fir<T,nonsym,Save> fir_type;
Index: benchmarks/mcopy_ipp.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/mcopy_ipp.cpp,v
retrieving revision 1.1
diff -u -r1.1 mcopy_ipp.cpp
--- benchmarks/mcopy_ipp.cpp	3 Mar 2006 14:30:53 -0000	1.1
+++ benchmarks/mcopy_ipp.cpp	7 Mar 2006 20:07:02 -0000
@@ -123,6 +123,7 @@
   int ops_per_point(length_type size)  { return size; }
   int riob_per_point(length_type size) { return size*sizeof(T); }
   int wiob_per_point(length_type size) { return size*sizeof(T); }
+  int mem_per_point(length_type size)  { return 2*size*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
     VSIP_IMPL_NOINLINE
@@ -196,6 +197,7 @@
   int ops_per_point(length_type size)  { return size; }
   int riob_per_point(length_type size) { return size*sizeof(T); }
   int wiob_per_point(length_type size) { return size*sizeof(T); }
+  int mem_per_point(length_type size)  { return 2*size*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
     VSIP_IMPL_NOINLINE
@@ -284,6 +286,7 @@
   int ops_per_point(length_type size)  { return size; }
   int riob_per_point(length_type size) { return size*sizeof(T); }
   int wiob_per_point(length_type size) { return size*sizeof(T); }
+  int mem_per_point(length_type size)  { return 2*size*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
     VSIP_IMPL_NOINLINE
Index: benchmarks/prod.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/prod.cpp,v
retrieving revision 1.2
diff -u -r1.2 prod.cpp
--- benchmarks/prod.cpp	22 Dec 2005 01:29:25 -0000	1.2
+++ benchmarks/prod.cpp	7 Mar 2006 20:07:02 -0000
@@ -54,6 +54,7 @@
 
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 0; }
+  int mem_per_point(length_type M) { return 3*M*M*sizeof(T); }
 
   void operator()(length_type M, length_type loop, float& time)
   {
@@ -99,6 +100,7 @@
 
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 0; }
+  int mem_per_point(length_type M) { return 3*M*M*sizeof(T); }
 
   void operator()(length_type M, length_type loop, float& time)
   {
@@ -144,6 +146,7 @@
 
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 0; }
+  int mem_per_point(length_type M) { return 3*M*M*sizeof(T); }
 
   void operator()(length_type M, length_type loop, float& time)
   {
@@ -190,6 +193,7 @@
 
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 0; }
+  int mem_per_point(length_type M) { return 3*M*M*sizeof(T); }
 
   void operator()(length_type M, length_type loop, float& time)
   {
@@ -244,6 +248,7 @@
 
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 0; }
+  int mem_per_point(length_type M) { return 3*M*M*sizeof(T); }
 
   void operator()(length_type M, length_type loop, float& time)
   {
Index: benchmarks/prod_var.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/prod_var.cpp,v
retrieving revision 1.2
diff -u -r1.2 prod_var.cpp
--- benchmarks/prod_var.cpp	22 Dec 2005 01:29:25 -0000	1.2
+++ benchmarks/prod_var.cpp	7 Mar 2006 20:07:02 -0000
@@ -332,6 +332,7 @@
 
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 0; }
+  int mem_per_point(length_type M) { return 3*M*M*sizeof(T); }
 
   void operator()(length_type M, length_type loop, float& time)
   {
Index: benchmarks/sumval.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/sumval.cpp,v
retrieving revision 1.2
diff -u -r1.2 sumval.cpp
--- benchmarks/sumval.cpp	7 Sep 2005 12:19:30 -0000	1.2
+++ benchmarks/sumval.cpp	7 Mar 2006 20:07:02 -0000
@@ -30,6 +30,7 @@
   int ops_per_point(length_type)  { return 1; }
   int riob_per_point(length_type) { return sizeof(T); }
   int wiob_per_point(length_type) { return 0; }
+  int mem_per_point(length_type)  { return 1*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
   {
@@ -61,6 +62,7 @@
   int ops_per_point(length_type)  { return 1; }
   int riob_per_point(length_type) { return sizeof(T); }
   int wiob_per_point(length_type) { return 0; }
+  int mem_per_point(length_type)  { return 1*sizeof(T); }
 
   void operator()(length_type size, length_type loop, float& time)
   {
@@ -86,7 +88,7 @@
 
 
 void
-defaults(Loop1P& loop)
+defaults(Loop1P&)
 {
 }
 
Index: benchmarks/vmmul.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/vmmul.cpp,v
retrieving revision 1.1
diff -u -r1.1 vmmul.cpp
--- benchmarks/vmmul.cpp	19 Dec 2005 16:08:55 -0000	1.1
+++ benchmarks/vmmul.cpp	7 Mar 2006 20:07:02 -0000
@@ -147,6 +147,9 @@
     { return (int)(this->ops(rows_, cols) / cols); }
   int riob_per_point(length_type) { return -1*sizeof(T); }
   int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int mem_per_point(length_type cols)
+  { return SD == row ? (2*rows_+1)*sizeof(T)
+                     : (2*rows_+rows_/cols)*sizeof(T); }
 
   void operator()(length_type cols, length_type loop, float& time)
   {
@@ -175,6 +178,9 @@
     { return (int)(this->ops(rows, cols_) / rows); }
   int riob_per_point(length_type) { return -1*sizeof(T); }
   int wiob_per_point(length_type) { return -1*sizeof(T); }
+  int mem_per_point(length_type rows)
+  { return SD == row ? (2*cols_+cols_/rows)*sizeof(T)
+                     : (2*cols_+1)*sizeof(T); }
 
   void operator()(length_type rows, length_type loop, float& time)
   {
Index: benchmarks/vmul_sal.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/vmul_sal.cpp,v
retrieving revision 1.1
diff -u -r1.1 vmul_sal.cpp
--- benchmarks/vmul_sal.cpp	1 Feb 2006 15:47:49 -0000	1.1
+++ benchmarks/vmul_sal.cpp	7 Mar 2006 20:07:02 -0000
@@ -39,6 +39,7 @@
   int ops_per_point(size_t)  { return Ops_info<float>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(float); }
   int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
 
   void operator()(size_t size, size_t loop, float& time)
   {
@@ -87,6 +88,7 @@
   int ops_per_point(size_t)  { return Ops_info<T>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
 
   void operator()(size_t size, size_t loop, float& time)
   {
@@ -137,6 +139,7 @@
   int ops_per_point(size_t)  { return Ops_info<T>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
+  int mem_per_point(size_t)  { return 2*sizeof(float); }
 
   void operator()(size_t size, size_t loop, float& time)
   {
@@ -184,6 +187,7 @@
   int ops_per_point(size_t)  { return Ops_info<T>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
+  int mem_per_point(size_t)  { return 2*sizeof(float); }
 
   void operator()(size_t size, size_t loop, float& time)
   {
