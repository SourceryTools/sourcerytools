Index: ChangeLog
===================================================================
--- ChangeLog	(revision 149249)
+++ ChangeLog	(working copy)
@@ -1,5 +1,15 @@
 2006-09-15  Jules Bergmann  <jules@codesourcery.com>
 
+	* benchmarks/vmul.cpp: Avoid using rand for potentially
+	  distributed data, optimized check of distributed data.
+	* benchmarks/vma.cpp: New cases for V = s*V+s.
+	* benchmarks/fftm.cpp: Add Impl_pop case: psuedo OP FFTM
+	  using OP FFT.  Add Impl_bv case for by-value Fftm.
+	  Renumber.
+	* benchmarks/fft.cpp: Add by-value case.
+	
+2006-09-15  Jules Bergmann  <jules@codesourcery.com>
+
 	* configure.ac (--enable-ipp=win): New option to configure for
 	  IPP on windows.
 	  (--with-lapack=mkl_win): New option to configure for MKL on
Index: benchmarks/vmul.cpp
===================================================================
--- benchmarks/vmul.cpp	(revision 149244)
+++ benchmarks/vmul.cpp	(working copy)
@@ -158,9 +158,12 @@
     Vector<T, block_type> C(size,      map);
 
     Rand<T> gen(0, 0);
-    A = gen.randu(size);
-    B = gen.randu(size);
-
+    // A, B, and C have the same map.
+    for (index_type i=0; i<C.local().size(); ++i)
+    {
+      A.local().put(i, gen.randu());
+      B.local().put(i, gen.randu());
+    }
     A.put(0, T(3));
     B.put(0, T(4));
 
@@ -174,8 +177,9 @@
     sp.sync();
     t1.stop();
     
-    for (index_type i=0; i<size; ++i)
-      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    for (index_type i=0; i<C.local().size(); ++i)
+      test_assert(equal(C.local().get(i),
+			A.local().get(i) * B.local().get(i)));
     
     time = t1.delta();
   }
Index: benchmarks/vma.cpp
===================================================================
--- benchmarks/vma.cpp	(revision 149244)
+++ benchmarks/vma.cpp	(working copy)
@@ -123,9 +123,11 @@
   {
   case  1: loop(t_vma<float, 1, 1, 1>()); break;
   case  2: loop(t_vma<float, 0, 1, 1>()); break;
+  case  3: loop(t_vma<float, 0, 1, 0>()); break;
 
   case 11: loop(t_vma<complex<float>, 1, 1, 1>()); break;
   case 12: loop(t_vma<complex<float>, 0, 1, 1>()); break;
+  case 13: loop(t_vma<complex<float>, 0, 1, 0>()); break;
 
   case 21: loop(t_vma_ip<float, 1, 1>()); break;
   case 22: loop(t_vma_ip<float, 0, 1>()); break;
Index: benchmarks/fftm.cpp
===================================================================
--- benchmarks/fftm.cpp	(revision 149244)
+++ benchmarks/fftm.cpp	(working copy)
@@ -54,10 +54,12 @@
 	  int      SD>
 struct t_fftm;
 
-struct Impl_op;
-struct Impl_ip;
-struct Impl_pip1;
-struct Impl_pip2;
+struct Impl_op;		// out-of-place
+struct Impl_ip;		// in-place
+struct Impl_pop;	// psuedo out-of-place (using OP FFT).
+struct Impl_pip1;	// psuedo in-place (using in-place FFT).
+struct Impl_pip2;	// psuedo in-place (using out-of-place FFT).
+struct Impl_bv;		// by-value Fftm
 
 
 
@@ -83,8 +85,10 @@
     typedef Fftm<T, T, SD, fft_fwd, by_reference, no_times, alg_time>
       fftm_type;
 
-    fftm_type fftm(Domain<2>(rows, cols), 1.f);
+    length_type size = SD == row ? cols : rows;
 
+    fftm_type fftm(Domain<2>(rows, cols), scale_ ? (1.f/size) : 1.f);
+
     A = T(1);
     
     vsip::impl::profile::Timer t1;
@@ -94,7 +98,7 @@
       fftm(A, Z);
     t1.stop();
     
-    if (!equal(Z(0, 0), T(SD == row ? cols : rows)))
+    if (!equal(Z(0, 0), T(scale_ ? 1.0 : SD == row ? cols : rows)))
     {
       std::cout << "t_fftm<T, Impl_op, SD>: ERROR" << std::endl;
       abort();
@@ -102,6 +106,11 @@
     
     time = t1.delta();
   }
+
+  t_fftm(bool scale) : scale_(scale) {}
+
+  // Member data
+  bool scale_;
 };
 
 
@@ -149,11 +158,83 @@
     
     time = t1.delta();
   }
+
+  t_fftm(bool scale) : scale_(scale) {}
+
+  // Member data
+  bool scale_;
 };
 
 
 
 /***********************************************************************
+  Impl_pop: Pseudo out-of-place Fftm (using out-of-place Fft)
+***********************************************************************/
+
+template <typename T,
+	  int      SD>
+struct t_fftm<T, Impl_pop, SD>
+{
+  static int const elem_per_point = 1;
+
+  char* what() { return "t_fftm<T, Impl_pop, SD>"; }
+  int ops(length_type rows, length_type cols)
+    { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
+
+  void fftm(length_type rows, length_type cols, length_type loop, float& time)
+  {
+    Matrix<T>   A(rows, cols, T());
+    Matrix<T>   Z(rows, cols);
+    Vector<T>   tmp(SD == row ? cols : rows);
+
+    typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
+      fft_type;
+
+    fft_type fft(Domain<1>(SD == row ? cols : rows), 1.f);
+
+    A = T(1);
+    
+    vsip::impl::profile::Timer t1;
+    
+    if (SD == row)
+    {
+      t1.start();
+      for (index_type l=0; l<loop; ++l)
+	for (index_type i=0; i<rows; ++i)
+	{
+	  fft(A.row(i), Z.row(i));
+	}
+      t1.stop();
+    }
+    else
+    {
+      t1.start();
+      for (index_type l=0; l<loop; ++l)
+	for (index_type i=0; i<cols; ++i)
+	{
+	  fft(A.col(i), Z.col(i));
+	}
+      t1.stop();
+    }
+
+    if (!equal(Z(0, 0), T(SD == row ? cols : rows)))
+    {
+      std::cout << "t_fftm<T, Impl_pop, SD>: ERROR" << std::endl;
+      abort();
+    }
+    
+    time = t1.delta();
+  }
+
+  t_fftm(bool scale) : scale_(scale) {}
+
+  // Member data
+  bool scale_;
+};
+
+
+
+/***********************************************************************
   Impl_pip1: Pseudo In-place Fftm (using in-place Fft)
 ***********************************************************************/
 
@@ -213,6 +294,11 @@
     
     time = t1.delta();
   }
+
+  t_fftm(bool scale) : scale_(scale) {}
+
+  // Member data
+  bool scale_;
 };
 
 
@@ -290,11 +376,64 @@
     
     time = t1.delta();
   }
+
+  t_fftm(bool scale) : scale_(scale) {}
+
+  // Member data
+  bool scale_;
 };
 
 
 
 /***********************************************************************
+  Impl_bv: By-value Fftm
+***********************************************************************/
+
+template <typename T,
+	  int      SD>
+struct t_fftm<T, Impl_bv, SD>
+{
+  static int const elem_per_point = 2;
+
+  char* what() { return "t_fftm<T, Impl_bv, SD>"; }
+  int ops(length_type rows, length_type cols)
+    { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
+
+  void fftm(length_type rows, length_type cols, length_type loop, float& time)
+  {
+    Matrix<T>   A(rows, cols, T());
+    Matrix<T>   Z(rows, cols);
+
+    typedef Fftm<T, T, SD, fft_fwd, by_value, no_times, alg_time>
+      fftm_type;
+
+    length_type size = SD == row ? cols : rows;
+
+    fftm_type fftm(Domain<2>(rows, cols), scale_ ? (1.f/size) : 1.f);
+
+    A = T(1);
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      Z = fftm(A);
+    t1.stop();
+    
+    test_assert(equal(Z.get(0, 0), T(scale_ ? 1.0 : SD == row ? cols : rows)));
+    
+    time = t1.delta();
+  }
+
+  t_fftm(bool scale) : scale_(scale) {}
+
+  // Member data
+  bool scale_;
+};
+
+
+
+/***********************************************************************
   Fixed rows driver
 ***********************************************************************/
 
@@ -316,7 +455,9 @@
     this->fftm(rows_, cols, loop, time);
   }
 
-  t_fftm_fix_rows(length_type rows) : rows_(rows) {}
+  t_fftm_fix_rows(length_type rows, bool scale)
+    : base_type(scale), rows_(rows)
+  {}
 
 // Member data
   length_type rows_;
@@ -346,7 +487,9 @@
     this->fftm(rows, cols_, loop, time);
   }
 
-  t_fftm_fix_cols(length_type cols) : cols_(cols) {}
+  t_fftm_fix_cols(length_type cols, bool scale)
+    : base_type(scale), cols_(cols)
+  {}
 
 // Member data
   length_type cols_;
@@ -365,7 +508,7 @@
   loop.start_      = 4;
   loop.stop_       = 16;
   loop.loop_start_ = 10;
-  loop.user_param_ = 256;
+  loop.user_param_ = 64;
 }
 
 
@@ -375,17 +518,24 @@
 {
   length_type p = loop.user_param_;
 
+  typedef complex<float> Cf;
+
   switch (what)
   {
-  case  1: loop(t_fftm_fix_rows<complex<float>, Impl_op,   row>(p)); break;
-  case  2: loop(t_fftm_fix_rows<complex<float>, Impl_ip,   row>(p)); break;
-  case  3: loop(t_fftm_fix_rows<complex<float>, Impl_pip1, row>(p)); break;
-  case  4: loop(t_fftm_fix_rows<complex<float>, Impl_pip2, row>(p)); break;
-  case  5: loop(t_fftm_fix_cols<complex<float>, Impl_op,   row>(p)); break;
-  case  6: loop(t_fftm_fix_cols<complex<float>, Impl_ip,   row>(p)); break;
-  case  7: loop(t_fftm_fix_cols<complex<float>, Impl_pip1, row>(p)); break;
-  case  8: loop(t_fftm_fix_cols<complex<float>, Impl_pip2, row>(p)); break;
+  case  1: loop(t_fftm_fix_rows<Cf, Impl_op,   row>(p, false)); break;
+  case  2: loop(t_fftm_fix_rows<Cf, Impl_ip,   row>(p, false)); break;
+  case  3: loop(t_fftm_fix_rows<Cf, Impl_pop,  row>(p, false)); break;
+  case  4: loop(t_fftm_fix_rows<Cf, Impl_pip1, row>(p, false)); break;
+  case  5: loop(t_fftm_fix_rows<Cf, Impl_pip2, row>(p, false)); break;
+  case  6: loop(t_fftm_fix_rows<Cf, Impl_bv,   row>(p, false)); break;
 
+  case 11: loop(t_fftm_fix_cols<Cf, Impl_op,   row>(p, false)); break;
+  case 12: loop(t_fftm_fix_cols<Cf, Impl_ip,   row>(p, false)); break;
+  case 13: loop(t_fftm_fix_cols<Cf, Impl_pop,  row>(p, false)); break;
+  case 14: loop(t_fftm_fix_cols<Cf, Impl_pip1, row>(p, false)); break;
+  case 15: loop(t_fftm_fix_cols<Cf, Impl_pip2, row>(p, false)); break;
+  case 16: loop(t_fftm_fix_cols<Cf, Impl_bv,   row>(p, false)); break;
+
 #if 0
   case 11: loop(t_fftm_fix_rows<complex<float>, Impl_op,   col>(p)); break;
   case 12: loop(t_fftm_fix_rows<complex<float>, Impl_ip,   col>(p)); break;
@@ -397,6 +547,8 @@
   case 18: loop(t_fftm_fix_cols<complex<float>, Impl_pip2, col>(p)); break;
 #endif
 
+  case 21: loop(t_fftm_fix_rows<Cf, Impl_op,   row>(p, true)); break;
+
   default: return 0;
   }
   return 1;
Index: benchmarks/fft.cpp
===================================================================
--- benchmarks/fft.cpp	(revision 149244)
+++ benchmarks/fft.cpp	(working copy)
@@ -30,6 +30,11 @@
 }
 
 
+
+/***********************************************************************
+  Fft, out-of-place
+***********************************************************************/
+
 template <typename T,
 	  int      no_times>
 struct t_fft_op
@@ -76,6 +81,10 @@
 
 
 
+/***********************************************************************
+  Fft, in-place
+***********************************************************************/
+
 template <typename T,
 	  int      no_times>
 struct t_fft_ip
@@ -119,6 +128,52 @@
 
 
 
+/***********************************************************************
+  Fft, by-value
+***********************************************************************/
+
+template <typename T,
+	  int      no_times>
+struct t_fft_bv
+{
+  char* what() { return "t_fft_bv"; }
+  int ops_per_point (length_type len) { return fft_ops(len); }
+  int riob_per_point(length_type)     { return -1*(int)sizeof(T); }
+  int wiob_per_point(length_type)     { return -1*(int)sizeof(T); }
+  int mem_per_point (length_type)     { return 1*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    Vector<T>   A(size, T());
+    Vector<T>   Z(size);
+
+    typedef Fft<const_Vector, T, T, fft_fwd, by_value, no_times, alg_time>
+      fft_type;
+
+    fft_type fft(Domain<1>(size), scale_ ? (1.f/size) : 1.f);
+
+    A = T(1);
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      Z = fft(A);
+    t1.stop();
+    
+    test_assert(equal(Z.get(0), T(scale_ ? 1 : size)));
+    
+    time = t1.delta();
+  }
+
+  t_fft_bv(bool scale) : scale_(scale) {}
+
+  // Member data
+  bool scale_;
+};
+
+
+
 void
 defaults(Loop1P& loop)
 {
@@ -138,18 +193,24 @@
   {
   case  1: loop(t_fft_op<complex<float>, estimate>(false)); break;
   case  2: loop(t_fft_ip<complex<float>, estimate>(false)); break;
+  case  3: loop(t_fft_bv<complex<float>, estimate>(false)); break;
   case  5: loop(t_fft_op<complex<float>, estimate>(true)); break;
   case  6: loop(t_fft_ip<complex<float>, estimate>(true)); break;
+  case  7: loop(t_fft_bv<complex<float>, estimate>(true)); break;
 
   case 11: loop(t_fft_op<complex<float>, measure>(false)); break;
   case 12: loop(t_fft_ip<complex<float>, measure>(false)); break;
+  case 13: loop(t_fft_bv<complex<float>, measure>(false)); break;
   case 15: loop(t_fft_op<complex<float>, measure>(true)); break;
   case 16: loop(t_fft_ip<complex<float>, measure>(true)); break;
+  case 17: loop(t_fft_bv<complex<float>, measure>(true)); break;
 
   case 21: loop(t_fft_op<complex<float>, patient>(false)); break;
   case 22: loop(t_fft_ip<complex<float>, patient>(false)); break;
+  case 23: loop(t_fft_bv<complex<float>, patient>(false)); break;
   case 25: loop(t_fft_op<complex<float>, patient>(true)); break;
   case 26: loop(t_fft_ip<complex<float>, patient>(true)); break;
+  case 27: loop(t_fft_bv<complex<float>, patient>(true)); break;
 
   default: return 0;
   }
