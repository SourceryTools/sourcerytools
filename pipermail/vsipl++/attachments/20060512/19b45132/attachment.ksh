Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.473
diff -u -r1.473 ChangeLog
--- ChangeLog	11 May 2006 19:39:12 -0000	1.473
+++ ChangeLog	12 May 2006 12:09:25 -0000
@@ -1,3 +1,15 @@
+2006-05-12  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (--with-lapack): Make default to probe.
+	  (--with-test-level): New option, sets VSIP_IMPL_TEST_LEVEL.
+	* src/vsip/impl/fft.hpp (fftm_facade): Handle distributed
+	  Fftm.  Add error checking for Fftm arguments.
+	* src/vsip/impl/fft/util.hpp (new_view): Add overloads with
+	  map argument.
+	  (result): Distinguish between distributed and local result types.
+	* src/vsip/impl/fftw3/fft_impl.cpp: Handle distributed Fftm, fix
+	  Wall warnings.
+	
 2006-05-11  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* tests/fft_be.cpp: Conditionalize the use of the backends on
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.102
diff -u -r1.102 configure.ac
--- configure.ac	10 May 2006 19:26:34 -0000	1.102
+++ configure.ac	12 May 2006 12:09:25 -0000
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
Index: src/vsip/impl/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft.hpp,v
retrieving revision 1.5
diff -u -r1.5 fft.hpp
--- src/vsip/impl/fft.hpp	11 May 2006 13:06:52 -0000	1.5
+++ src/vsip/impl/fft.hpp	12 May 2006 12:09:25 -0000
@@ -143,7 +143,8 @@
     VSIP_THROW((std::bad_alloc))
   {
     typedef fft::result<O, typename ViewT::block_type> traits;
-    typename traits::view_type out(traits::create(this->output_size()));
+    typename traits::view_type out(traits::create(this->output_size(),
+						  in.block().map()));
     workspace_.by_reference(this->backend_.get(), in, out);
     return out;
   }
@@ -243,8 +244,14 @@
     VSIP_THROW((std::bad_alloc))
   {
     typedef fft::result<O,BlockT> traits;
-    typename traits::view_type out(traits::create(this->output_size()));
-    workspace_.by_reference(this->backend_.get(), in, out);
+    typename traits::view_type out(traits::create(this->output_size(),
+						  in.block().map()));
+    assert(extent(in) == extent(this->input_size()));
+    if (Is_global_map<typename BlockT::map_type>::value &&
+	in.block().map().num_subblocks(A) != 1)
+      VSIP_IMPL_THROW(unimplemented(
+	"Fftm requires dimension along FFT to not be distributed"));
+    workspace_.by_reference(this->backend_.get(), in.local(), out.local());
     return out;
   }
 
@@ -281,7 +288,20 @@
   operator()(const_Matrix<I,Block0> in, Matrix<O,Block1> out)
     VSIP_NOTHROW
   {
-    workspace_.by_reference(this->backend_.get(), in, out);
+    assert(extent(in)  == extent(this->input_size()));
+    assert(extent(out) == extent(this->output_size()));
+    if (Is_global_map<typename Block0::map_type>::value ||
+	Is_global_map<typename Block1::map_type>::value)
+    {
+      if (in.block().map().num_subblocks(A) != 1 ||
+	  out.block().map().num_subblocks(A) != 1)
+	VSIP_IMPL_THROW(unimplemented(
+	  "Fftm requires dimension along FFT to not be distributed"));
+      if (global_domain(in) != global_domain(out))
+	VSIP_IMPL_THROW(unimplemented(
+	  "Fftm requires input and output to have same mapping"));
+    }
+    workspace_.by_reference(this->backend_.get(), in.local(), out.local());
     return out;
   }
 
@@ -289,7 +309,12 @@
   Matrix<O,BlockT>
   operator()(Matrix<O,BlockT> inout) VSIP_NOTHROW
   {
-    workspace_.in_place(this->backend_.get(), inout);
+    assert(extent(inout) == extent(this->input_size()));
+    if (Is_global_map<typename BlockT::map_type>::value &&
+	inout.block().map().num_subblocks(A) != 1)
+      VSIP_IMPL_THROW(unimplemented(
+	"Fftm requires dimension along FFT to not be distributed"));
+    workspace_.in_place(this->backend_.get(), inout.local());
     return inout;
   }
 
Index: src/vsip/impl/fft/util.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/util.hpp,v
retrieving revision 1.2
diff -u -r1.2 util.hpp
--- src/vsip/impl/fft/util.hpp	6 May 2006 22:09:27 -0000	1.2
+++ src/vsip/impl/fft/util.hpp	12 May 2006 12:09:25 -0000
@@ -85,13 +85,55 @@
 
 
 
-//
-template<typename T, typename BlockT>
+template <typename View>
+View
+new_view(
+  vsip::Domain<1> const&                     dom,
+  typename View::block_type::map_type const& map)
+{ return View(dom.size(), map);} 
+
+template <typename View>
+View 
+new_view(
+  vsip::Domain<2> const&                     dom,
+  typename View::block_type::map_type const& map)
+{ return View(dom[0].size(), dom[1].size(), map);}
+
+template <typename View>
+View  
+new_view(
+  vsip::Domain<3> const&                     dom,
+  typename View::block_type::map_type const& map)
+{ return View(dom[0].size(), dom[1].size(), dom[2].size(), map);}
+
+
+
+/// Traits class to determine block type returned by Fft and Fftm
+/// by_value operators.
+
+/// General case: when result is distributed, we use a Dense block
+/// because Fast_blocks do support non-local maps (060512).
+template<typename T,
+	 typename BlockT,
+	 typename MapT = typename BlockT::map_type>
 struct result
 {
   static dimension_type const dim = BlockT::dim;
+  typedef Dense<dim, T, tuple<0,1,2>, MapT> block_type;
+
+  typedef typename View_of_dim<dim, T, block_type>::type view_type;
+
+  static view_type create(Domain<dim> const &dom, MapT const& map)
+  { return new_view<view_type>(dom, map);}
+};
+
+/// Specialization: when result is local, we use a Fast_block,
+/// because it lets us match complex format of the input block.
+template<typename T, typename BlockT>
+struct result<T, BlockT, Local_map>
+{
+  static dimension_type const dim = BlockT::dim;
   typedef typename
-  // FIXME: Allow cmplx_split, to match split input.
   impl::Fast_block<dim, T, 
 		   Layout<dim, tuple<0,1,2>,
 			  impl::Stride_unit_dense,
@@ -100,7 +142,7 @@
 
   typedef typename View_of_dim<dim, T, block_type>::type view_type;
 
-  static view_type create(Domain<dim> const &dom)
+  static view_type create(Domain<dim> const &dom, Local_map const&)
   { return new_view<view_type>(dom);}
 };
 
Index: src/vsip/impl/fftw3/fft_impl.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fftw3/fft_impl.cpp,v
retrieving revision 1.2
diff -u -r1.2 fft_impl.cpp
--- src/vsip/impl/fftw3/fft_impl.cpp	10 May 2006 02:54:09 -0000	1.2
+++ src/vsip/impl/fftw3/fft_impl.cpp	12 May 2006 12:09:25 -0000
@@ -149,7 +149,7 @@
   {}
   virtual void in_place(ctype *inout, stride_type s, length_type l)
   {
-    assert(s == 1 && l == this->size_[0]);
+    assert(s == 1 && static_cast<int>(l) == this->size_[0]);
     FFTW(execute_dft)(plan_in_place_,
 		      reinterpret_cast<FFTW(complex)*>(inout),
 		      reinterpret_cast<FFTW(complex)*>(inout));
@@ -161,7 +161,8 @@
 			    ctype *out, stride_type out_stride,
 			    length_type length)
   {
-    assert(in_stride == 1 && out_stride == 1 && length == this->size_[0]);
+    assert(in_stride == 1 && out_stride == 1 &&
+	   static_cast<int>(length) == this->size_[0]);
     FFTW(execute_dft)(plan_by_reference_,
 		      reinterpret_cast<FFTW(complex)*>(in), 
 		      reinterpret_cast<FFTW(complex)*>(out));
@@ -617,9 +618,10 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    if (A == 1) assert(rows == mult_ && cols == size_[0]);
-    else assert(cols == mult_ && rows == size_[0]);
-    for (int i = 0; i < mult_; ++i)
+    length_type const n_fft = (A == 1) ? rows : cols;
+    if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
+    else assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+    for (index_type i = 0; i < n_fft; ++i)
     {
       FFTW(execute_dft_r2c)(plan_by_reference_, 
 			    in, reinterpret_cast<FFTW(complex)*>(out));
@@ -636,7 +638,7 @@
   }
 
 private:
-  int mult_;
+  length_type mult_;
 };
 
 // complex -> real FFTM
@@ -674,9 +676,10 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    if (A == 1) assert(rows == mult_ && cols == size_[0]);
-    else assert(cols == mult_ && rows == size_[0]);
-    for (int i = 0; i < mult_; ++i)
+    length_type const n_fft = (A == 1) ? rows : cols;
+    if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
+    else assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+    for (index_type i = 0; i < n_fft; ++i)
     {
       FFTW(execute_dft_c2r)(plan_by_reference_, 
 			    reinterpret_cast<FFTW(complex)*>(in), out);
@@ -693,7 +696,7 @@
   }
 
 private:
-  int mult_;
+  length_type mult_;
 };
 
 // complex -> complex FFTM
@@ -725,9 +728,10 @@
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
   {
-    if (A == 1) assert(rows == mult_ && cols == size_[0]);
-    else assert(cols == mult_ && rows == size_[0]);
-    for (int i = 0; i != mult_; ++i)
+    length_type const n_fft = (A == 1) ? rows : cols;
+    if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
+    else assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+    for (index_type i = 0; i != n_fft; ++i)
     {
       FFTW(execute_dft)(this->plan_in_place_, 
  			reinterpret_cast<FFTW(complex)*>(inout),
@@ -748,9 +752,12 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    if (A == 1) assert(rows == mult_ && cols == size_[0]);
-    else assert(cols == mult_ && rows == size_[0]);
-    for (int i = 0; i != mult_; ++i)
+    // If the inputs to the Fftm are distributed, the number of FFTs may
+    // be less than mult_.
+    length_type const n_fft = (A == 1) ? rows : cols;
+    if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
+    else assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+    for (index_type i = 0; i != n_fft; ++i)
     {
       FFTW(execute_dft)(plan_by_reference_, 
 			reinterpret_cast<FFTW(complex)*>(in), 
@@ -768,7 +775,7 @@
   }
 
 private:
-  int mult_;
+  length_type mult_;
 };
 
 #define VSIPL_IMPL_PROVIDE(D, I, O, A, E)	       \
