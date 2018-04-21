Index: ChangeLog
===================================================================
--- ChangeLog	(revision 192554)
+++ ChangeLog	(working copy)
@@ -1,3 +1,49 @@
+2008-03-18  Jules Bergmann  <jules@codesourcery.com>
+
+	Merge 1.4 MCOE updates.
+	* configure.ac (CXXDEP): Update for ccmc++.
+	* m4/fft.m4 (--with-fftw3-cfg-opts): New option, passes options
+	  directly to FFTW3 configure.
+	* src/vsip/core/fns_scalar.hpp: Handle missing hypot decl.
+	* src/vsip/opt/sal/conv.hpp: Loosen threshold on SAL td convolution.
+	* vendor/GNUmakefile.inc.in: Use LIBEXT for FFTW3.
+	* tests/matvec.cpp: Fill in macros missing from MCOE GCC's cmath.
+	* examples/mercury/mcoe-setup.sh: Update.
+	
+	Merge 1.4 SIMD unaligned loop fusion changes.
+	* src/vsip/opt/simd/expr_evaluator.hpp: Move Proxy_factory ...
+	* src/vsip/opt/simd/proxy_factory.hpp: New file, ... to here.
+	* src/vsip/opt/simd/eval_unaligned.hpp: New file, unaligned SIMD
+	  loop-fusion evaluator from expr_evaluator.hpp.
+	* src/vsip/opt/simd/expr_iterator.hpp (Simd_unaligned_loader): Move
+	  loads around to avoid second load past end of vector
+	  (first load inevitable).
+	* src/vsip/opt/expr/serial_dispatch.hpp: Include eval_unaligned.hpp.
+	* configure.ac (--enable-simd-unaligned-loop-fusion): Allow SIMD
+	  unaligned loop fusion to be controlled independently of aligned
+	  loop fusion.
+	* doc/quickstart/quickstart.xml: Document --enable-simd-loop-fusion
+	  and --enable-simd-unaligned-loop-fusion.
+
+	Merge 1.4 bugfix for builtin SIMD routine unaligned handling.
+	* src/vsip/opt/simd/rscvmul.hpp: Fix bug in handling unalignment.
+	* src/vsip/opt/simd/threshold.hpp: Likewise.
+	* src/vsip/opt/simd/vgt.hpp: Likewise.
+	* src/vsip/opt/simd/vma_ip_csc.hpp: Likewise.
+	* src/vsip/opt/simd/vaxpy.hpp: Likewise.
+	* src/vsip/opt/simd/vadd.hpp: Likewise.
+	* src/vsip/opt/simd/vlogic.hpp: Likewise.
+	* src/vsip/opt/simd/vmul.hpp: Likewise.
+	* tests/regressions/view_offset.cpp: New test, regression coverage
+	  for unalignment handling bug.
+
+	Merge 1.4 pwarp and misc changes.
+	* src/vsip_csl/img/impl/pwarp_simd.hpp: Clear u/v if out of bounds,
+	  add error checking.
+	* tests/vsip_csl/pwarp.cpp: Merge from afrl branch.
+	* tests/regressions/transpose_assign.cpp: Add runtime verbosity.
+	* tests/threshold.cpp: Add debug output.
+
 2008-02-04  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac (EMBED_SPU): Include -m32/-m64 option.
Index: m4/fft.m4
===================================================================
--- m4/fft.m4	(revision 191870)
+++ m4/fft.m4	(working copy)
@@ -41,6 +41,11 @@
                  [Specify CFLAGS to use when building built-in FFTW3.
 		  Only used if --with-fft=builtin.]))
 
+AC_ARG_WITH(fftw3_cfg_opts,
+  AS_HELP_STRING([--with-fftw3-cfg-opts=OPTS],
+                 [Specify additional options to use when configuring built-in
+                  FFTW3. Only used if --with-fft=builtin.]))
+
 AC_ARG_ENABLE(fftw3_simd,
   AS_HELP_STRING([--disable-fftw3-simd],
                  [Disable use of SIMD instructions by FFTW3.  Useful
@@ -265,7 +270,7 @@
       mkdir -p vendor/fftw3f
       AC_MSG_NOTICE([Configuring fftw3f (float).])
       AC_MSG_NOTICE([extra config options: '$fftw3_f_simd'.])
-      (cd vendor/fftw3f; $fftw3_configure CC="$fftw_CC" $fftw3_f_simd $fftw3_opts --enable-float)
+      (cd vendor/fftw3f; $fftw3_configure CC="$fftw_CC" $fftw3_f_simd $fftw3_opts $with_fftw3_cfg_opts --enable-float)
       libs="$libs -lfftw3f"
     fi
     if test "$enable_fft_double" = yes; then
@@ -273,7 +278,7 @@
       mkdir -p vendor/fftw3
       AC_MSG_NOTICE([Configuring fftw3 (double).])
       AC_MSG_NOTICE([extra config options: '$fftw3_d_simd'.])
-      (cd vendor/fftw3; $fftw3_configure CC="$fftw_CC" $fftw3_d_simd $fftw3_opts )
+      (cd vendor/fftw3; $fftw3_configure CC="$fftw_CC" $fftw3_d_simd $fftw3_opts $with_fftw3_cfg_opts )
       libs="$libs -lfftw3"
     fi
     if test "$enable_fft_long_double" = yes; then
@@ -282,7 +287,7 @@
       mkdir -p vendor/fftw3l
       AC_MSG_NOTICE([Configuring fftw3l (long double).])
       AC_MSG_NOTICE([extra config options: '$fftw3_l_simd'.])
-      (cd vendor/fftw3l; $fftw3_configure CC="$fftw_CC" $fftw3_l_simd $fftw3_opts --enable-long-double)
+      (cd vendor/fftw3l; $fftw3_configure CC="$fftw_CC" $fftw3_l_simd $fftw3_opts $with_fftw3_cfg_opts --enable-long-double)
       libs="$libs -lfftw3l"
     fi
 
Index: configure.ac
===================================================================
--- configure.ac	(revision 192554)
+++ configure.ac	(working copy)
@@ -303,9 +303,15 @@
 
 AC_ARG_ENABLE([simd_loop_fusion],
   AS_HELP_STRING([--enable-simd-loop-fusion],
-                 [Enable SIMD loop-fusion.]),,
+                 [Enable SIMD loop-fusion (Disable by default).]),,
   [enable_simd_loop_fusion=no])
 
+AC_ARG_ENABLE([simd_unaligned_loop_fusion],
+  AS_HELP_STRING([--enable-simd-unaligned-loop-fusion],
+                 [Enable SIMD loop-fusion for unaligned expressions
+                  (Follows --enable-simd-loop-fusion by default).]),,
+  [enable_simd_unaligned_loop_fusion=default])
+
 AC_ARG_WITH([builtin_simd_routines],
   AS_HELP_STRING([--with-builtin-simd-routines=WHAT],
                  [Use builtin SIMD routines.]),,
@@ -375,6 +381,12 @@
   BOOST_VERSION="1.33"
 )
 
+AC_ARG_ENABLE([huge_page_pool],
+  AS_HELP_STRING([--disable-huge-page-pool],
+                 [Disable support for huge page memory allocator pool
+                  (enabled by default)]),,
+  [enable_huge_page_pool=yes])
+
 #
 # Files to generate.
 #
@@ -455,6 +467,8 @@
   CXXDEP="$CXX /QM"
   INTEL_WIN=1
   cygwin_mount=`cygpath -w /`
+elif test "$CXX" == "ccmc++"; then
+  CXXDEP="$CXX -M"
 else
   CXXDEP="$CXX -M -x c++"
   cygwin_mount=
@@ -864,13 +878,22 @@
 #
 # Configure use of SIMD loop-fusion
 #
+if test "$enable_simd_unaligned_loop_fusion" = "default"; then
+  enable_simd_unaligned_loop_fusion=$enable_simd_loop_fusion
+fi
+
 if test "$enable_simd_loop_fusion" = "yes"; then
   AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SIMD_LOOP_FUSION, 1,
     [Define whether to use SIMD loop-fusion in expr dispatch.])
 fi
 
+if test "$enable_simd_unaligned_loop_fusion" = "yes"; then
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SIMD_UNALIGNED_LOOP_FUSION, 1,
+    [Define whether to use SIMD unaligned loop-fusion in expr dispatch.])
+fi
 
 
+
 #
 # Configure use of builtin SIMD routines
 #
@@ -943,6 +966,18 @@
           [Define to indicate this is CodeSourcery's VSIPL++.])
 
 #
+# Configure huge_page_pool support
+#
+AC_CHECK_HEADERS([sys/mman.h], [], [ enable_huge_page_pool="no"], [])
+if test "$enable_huge_page_pool" = "yes"; then
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_ENABLE_HUGE_PAGE_POOL, 1,
+                     [Define to enable huge page pool support.])
+  AC_SUBST(VSIP_IMPL_HAVE_HUGE_PAGE_POOL, 1)
+else
+  AC_SUBST(VSIP_IMPL_HAVE_HUGE_PAGE_POOL, "")
+fi 
+
+#
 # library
 #
 ARFLAGS="r"
@@ -1063,6 +1098,8 @@
 else
   AC_MSG_RESULT([Complex storage format:                  interleaved])
 fi
+AC_MSG_RESULT([Using SIMD aligned loop-fusion           ${enable_simd_loop_fusion}])
+AC_MSG_RESULT([Using SIMD unaligned loop-fusion         ${enable_simd_unaligned_loop_fusion}])
 AC_MSG_RESULT([Timer:                                   ${enable_timer}])
 AC_MSG_RESULT([With Python bindings:                    ${enable_scripting}])
 
Index: src/vsip/core/fns_scalar.hpp
===================================================================
--- src/vsip/core/fns_scalar.hpp	(revision 191870)
+++ src/vsip/core/fns_scalar.hpp	(working copy)
@@ -23,10 +23,15 @@
 #include <complex>
 
 #if !HAVE_DECL_HYPOTF
-#if HAVE_HYPOTF
+# if HAVE_HYPOTF
 extern "C" float hypotf(float, float);
 # endif
 #endif
+#if !HAVE_DECL_HYPOT
+# if HAVE_HYPOT
+extern "C" double hypot(double, double);
+# endif
+#endif
 
 namespace vsip
 {
Index: src/vsip/opt/sal/conv.hpp
===================================================================
--- src/vsip/opt/sal/conv.hpp	(revision 191870)
+++ src/vsip/opt/sal/conv.hpp	(working copy)
@@ -144,8 +144,11 @@
   Definitions
 ***********************************************************************/
 
-// These help enforce limits on the length of the kernel
-// when using SAL, which differ for complex values
+// 080313: These kernel sizes represent cross-over points where
+//   frequency domain convolution may be more efficient.  Currently
+//   we ignore them because we don't use SAL's frequency domain
+//   convolution, and SAL's time-domain convolution is faster than
+//   a generic time-domain convolution.
 template <typename T>
 struct Max_kernel_length
 {
@@ -297,7 +300,8 @@
   stride_type s_coeff = coeff_.block().impl_stride(1, 0);
 
   assert( Max_kernel_length<T>::value != 0 );
-  if ( (M <= Max_kernel_length<T>::value) && (decimation_ == 1) ) 
+  // See note above on Max_kernel_length defn.
+  if ( /*(M <= Max_kernel_length<T>::value) &&*/ (decimation_ == 1) ) 
   {
     // SAL only does the minimum convolution
     if (Supp == support_full)
Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 192095)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -203,7 +203,7 @@
 
 vpath %.h src:$(srcdir)
 
-lib/libfftw3f.a: vendor/fftw3f/.libs/libfftw3f.a
+lib/libfftw3f.$(LIBEXT): vendor/fftw3f/.libs/libfftw3f.a
 	cp $< $@
 
 vendor/fftw3f/.libs/libfftw3f.a:
@@ -214,7 +214,7 @@
 	done
 	@$(MAKE) -C vendor/fftw3f all-am >> fftw-f.build.log 2>&1
 
-lib/libfftw3.a: vendor/fftw3/.libs/libfftw3.a
+lib/libfftw3.$(LIBEXT): vendor/fftw3/.libs/libfftw3.a
 	cp $< $@
 
 vendor/fftw3/.libs/libfftw3.a:
@@ -225,7 +225,7 @@
 	done
 	@$(MAKE) -C vendor/fftw3 all-am >> fftw-d.build.log 2>&1
 
-lib/libfftw3l.a: vendor/fftw3l/.libs/libfftw3l.a
+lib/libfftw3l.$(LIBEXT): vendor/fftw3l/.libs/libfftw3l.a
 	cp $< $@
 
 vendor/fftw3l/.libs/libfftw3l.a:
@@ -238,13 +238,13 @@
 
 ifdef USE_BUILTIN_FFTW
   ifdef USE_BUILTIN_FFTW_FLOAT
-    vendor_FFTW_LIBS += lib/libfftw3f.a
+    vendor_FFTW_LIBS += lib/libfftw3f.$(LIBEXT)
   endif
   ifdef USE_BUILTIN_FFTW_DOUBLE
-    vendor_FFTW_LIBS += lib/libfftw3.a
+    vendor_FFTW_LIBS += lib/libfftw3.$(LIBEXT)
   endif
   ifdef USE_BUILTIN_FFTW_LONG_DOUBLE
-    vendor_FFTW_LIBS += lib/libfftw3l.a
+    vendor_FFTW_LIBS += lib/libfftw3l.$(LIBEXT)
   endif
 
 libs += $(vendor_FFTW_LIBS) 
@@ -255,7 +255,7 @@
 	@for ldir in $(subst .a,,$(subst lib/lib,,$(vendor_FFTW_LIBS))); do \
 	  $(MAKE) -C vendor/$$ldir clean >> fftw.clean.log 2>&1; \
 	  echo "$(MAKE) -C vendor/$$ldir clean "; done
-	rm -f lib/libfftw3.a lib/libfftw3f.a lib/libfftw3l.a
+	rm -f lib/libfftw3.$(LIBEXT) lib/libfftw3f.$(LIBEXT) lib/libfftw3l.$(LIBEXT)
 
 install:: $(vendor_FFTW_LIBS)
 	@echo "Installing FFTW"
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 191870)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -138,18 +138,18 @@
   ex_off_flags="--no_exceptions"
   ex_on_flags="--exceptions"
 
-  fftw3_cflags="-Ospeed $toolset_flag"
+  fftw3_cflags="-Ospeed $pflags $toolset_flag"
 else
-  toolset_flag="-compiler GCC"
+  toolset_flag="-compiler GNU"
   cxxflags="$pflags $toolset_flag"
 
-  opt_flags="-Ospeed -OI -DNDEBUG"
+  opt_flags="-Otime -DNDEBUG -w"
   dbg_flags="-g"
 
   ex_off_flags="-fno-exceptions"
   ex_o_flags=""				# exceptions enabled by default.
 
-  fftw3_cflags="-Ospeed $toolset_flag"
+  fftw3_cflags="-Otime $pflags $toolset_flag"
 fi
 
 if test $opt = "y"; then
@@ -169,7 +169,7 @@
 fi
 
 if test $sal = "y"; then
-  cfg_flags="$cfg_flags --enable-sal"
+  cfg_flags="$cfg_flags --with-sal"
 fi
 
 if test $exceptions = "n"; then
@@ -215,13 +215,14 @@
 # run configure
 
 echo "$dir/configure"
-$dir/configure					\
-	--prefix=$prefix			\
-	--host=powerpc				\
-	--enable-fft=$fft			\
-	--with-fftw3-cflags="$fftw3_cflags"	\
-	--with-complex=$fmt			\
-	--with-lapack=no			\
-	$cfg_flags				\
-	--with-test-level=$testlevel		\
+$dir/configure						\
+	--prefix=$prefix				\
+	--host=powerpc					\
+	--enable-fft=$fft				\
+	--with-fftw3-cflags="$fftw3_cflags"		\
+	--with-fftw3-cfg-opts="--with-our-malloc16"	\
+	--with-complex=$fmt				\
+	--with-lapack=no				\
+	$cfg_flags					\
+	--with-test-level=$testlevel			\
 	--enable-timer=$timer
Index: src/vsip/opt/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/opt/simd/expr_evaluator.hpp	(revision 191870)
+++ src/vsip/opt/simd/expr_evaluator.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -31,6 +31,7 @@
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/extdata.hpp>
 #include <vsip/opt/expr/serial_evaluator.hpp>
+#include <vsip/opt/simd/proxy_factory.hpp>
 
 /***********************************************************************
   Definitions
@@ -40,213 +41,9 @@
 {
 namespace impl
 {
-namespace simd
-{
 
-template <typename BlockT, bool A>
-struct Proxy_factory
-{
-  typedef Direct_access_traits<typename BlockT::value_type> access_traits;
-  typedef Proxy<access_traits, A> proxy_type;
-  typedef typename Adjust_layout_dim<
-                     1, typename Block_layout<BlockT>::layout_type>::type
-		layout_type;
+// SIMD Loop Fusion evaluator for aligned expressions.
 
-  static bool const ct_valid = Ext_data_cost<BlockT>::value == 0 &&
-    !Is_split_block<BlockT>::value;
-
-  static bool 
-  rt_valid(BlockT const &b, int alignment)
-  {
-    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
-    return dda.stride(0) == 1 && 
-      (!A ||
-       Simd_traits<typename BlockT::value_type>::alignment_of(dda.data()) ==
-       alignment);
-  }
-
-  static int
-  alignment(BlockT const &b)
-  {
-    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
-    return Simd_traits<typename BlockT::value_type>::alignment_of(dda.data());
-  }
-
-  static proxy_type
-  create(BlockT const &b) 
-  {
-    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
-    return proxy_type(dda.data());
-  }
-};
-
-template <typename T, bool A>
-struct Proxy_factory<Scalar_block<1, T>, A>
-{
-  typedef Scalar_access_traits<T> access_traits;
-  typedef Proxy<access_traits, A> proxy_type;
-  static bool const ct_valid = true;
-
-  static bool 
-  rt_valid(Scalar_block<1, T> const &, int) {return true;}
-
-  static proxy_type
-  create(Scalar_block<1, T> const &b) 
-  {
-    return proxy_type(b.value());
-  }
-};
-
-template <dimension_type D,
-	  template <typename> class O,
-	  typename B,
-	  typename T,
-	  bool A>
-struct Proxy_factory<Unary_expr_block<D, O, B, T> const, A>
-{
-  typedef 
-    Unary_access_traits<typename Proxy_factory<B,A>::proxy_type, O>
-    access_traits;
-  typedef Proxy<access_traits,A> proxy_type;
-
-  static bool const ct_valid =
-    Unary_operator_map<T, O>::is_supported &&
-    Type_equal<typename B::value_type, T>::value &&
-    Proxy_factory<B, A>::ct_valid;
-
-  static bool 
-  rt_valid(Unary_expr_block<D, O, B, T> const &b, int alignment)
-  {
-    return Proxy_factory<B, A>::rt_valid(b.op(), alignment);
-  }
-
-  static proxy_type
-  create(Unary_expr_block<D, O, B, T> const &b)
-  {
-    return proxy_type(Proxy_factory<B, A>::create(b.op()));
-  }
-};
-
-// This proxy is specialized for unaligned blocks. If the user specifies
-// ualigned(block), this is a hint to switch to an unaligned proxy.
-template <dimension_type D,
-	  typename B,
-	  typename T,
-	  bool A>
-struct Proxy_factory<Unary_expr_block<D, unaligned_functor, B, T> const, A>
-{
-  typedef typename Proxy_factory<B, false>::access_traits access_traits;
-  typedef Proxy<access_traits,false> proxy_type;
-  static bool const ct_valid = Proxy_factory<B,false>::ct_valid;
-
-
-  static bool 
-  rt_valid(Unary_expr_block<D, unaligned_functor, B, T> const &b, int alignment)
-  {
-    return Proxy_factory<B, false>::rt_valid(b.op(), alignment);
-  }
-
-  static proxy_type
-  create(Unary_expr_block<D, unaligned_functor, B, T> const &b)
-  {
-    return proxy_type(Proxy_factory<B, false>::create(b.op()));
-  }
-};
-
-template <dimension_type                D,
-	  template <typename, typename> class O,
-	  typename                      LB,
-	  typename                      LT,
-	  typename                      RB,
-	  typename                      RT,
-	  bool A>
-struct Proxy_factory<Binary_expr_block<D, O, LB, LT, RB, RT> const, A>
-{
-  typedef
-    Binary_access_traits<typename Proxy_factory<LB, A>::proxy_type,
-			 typename Proxy_factory<RB, A>::proxy_type, O> 
-    access_traits;
-  typedef Proxy<access_traits, A> proxy_type;
-  static bool const ct_valid = 
-    Type_equal<typename LB::value_type, LT>::value &&
-    Type_equal<typename RB::value_type, RT>::value &&
-    Type_equal<LT, RT>::value &&
-    Binary_operator_map<LT, O>::is_supported &&
-    Proxy_factory<LB, A>::ct_valid &&
-    Proxy_factory<RB, A>::ct_valid;
-
-  static bool 
-  rt_valid(Binary_expr_block<D, O, LB, LT, RB, RT> const &b, int alignment)
-  {
-    return Proxy_factory<LB, A>::rt_valid(b.left(), alignment) &&
-           Proxy_factory<RB, A>::rt_valid(b.right(), alignment);
-  }
-
-  static proxy_type
-  create(Binary_expr_block<D, O, LB, LT, RB, RT> const &b)
-  {
-    typename Proxy_factory<LB, A>::proxy_type lp =
-      Proxy_factory<LB, A>::create(b.left());
-    typename Proxy_factory<RB, A>::proxy_type rp =
-      Proxy_factory<RB, A>::create(b.right());
-
-    return proxy_type(lp, rp);
-  }
-};
-
-template <dimension_type                         D,
-	  template <typename, typename,typename> class O,
-	  typename                               Block1, typename Type1,
-	  typename                               Block2, typename Type2,
-	  typename                               Block3, typename Type3,
-	  bool A>
-struct Proxy_factory<Ternary_expr_block<D, O,
-  Block1,Type1,Block2,Type2,Block3,Type3> const, A>
-{
-  typedef Ternary_access_traits<typename Proxy_factory<Block1, A>::proxy_type,
-                                typename Proxy_factory<Block2, A>::proxy_type,
-                                typename Proxy_factory<Block3, A>::proxy_type,
-		 	        O> 
-    access_traits;
-
-  typedef Ternary_expr_block<D, O, Block1,Type1,Block2,Type2,Block3,Type3>
-    SrcBlock;
-
-  typedef Proxy<access_traits, A> proxy_type;
-  static bool const ct_valid = 
-    Ternary_operator_map<Type1, O>::is_supported &&
-    Proxy_factory<Block1, A>::ct_valid &&
-    Proxy_factory<Block2, A>::ct_valid &&
-    Proxy_factory<Block3, A>::ct_valid;
-
-  static bool 
-  rt_valid(SrcBlock const &b, int alignment)
-  {
-    return Proxy_factory<Block1, A>::rt_valid(b.first(), alignment) &&
-           Proxy_factory<Block2, A>::rt_valid(b.second(), alignment) &&
-           Proxy_factory<Block3, A>::rt_valid(b.third(), alignment);
-  }
-
-  static proxy_type
-  create(SrcBlock const &b)
-  {
-    typename Proxy_factory<Block1, A>::proxy_type
-      b1p = Proxy_factory<Block1, A>::create(b.first());
-    typename Proxy_factory<Block2, A>::proxy_type
-      b2p = Proxy_factory<Block2, A>::create(b.second());
-    typename Proxy_factory<Block3, A>::proxy_type
-      b3p = Proxy_factory<Block3, A>::create(b.third());
-
-    return proxy_type(b1p,b2p,b3p);
-  }
-};
-
-
-} // namespace vsip::impl::simd
-
-
-// This evaluator is for aligned data only.
-// Look at Simd_unaligned_loop_fusion_tag for unaligned data.
 template <typename LB,
 	  typename RB>
 struct Serial_expr_evaluator<1, LB, RB, Simd_loop_fusion_tag>
@@ -326,78 +123,6 @@
   }
 };
 
-// This evaluator is for unaligned data. Any time any of the blocks are
-// unaligned, we use this evalutator. Basically, in the evaluator list, this
-// evaluator is right after the aligned evaluator and rt_valid determines
-// which one to use.
-template <typename LB,
-	  typename RB>
-struct Serial_expr_evaluator<1, LB, RB, Simd_unaligned_loop_fusion_tag>
-{
-  typedef typename Adjust_layout_dim<
-                     1, typename Block_layout<LB>::layout_type>::type
-		layout_type;
-
-  static char const* name() { return "Expr_SIMD_Unaligned_Loop"; }
-  
-  static bool const ct_valid =
-    // Is SIMD supported at all ?
-    simd::Simd_traits<typename LB::value_type>::is_accel &&
-    // Check that direct access is possible.
-    Ext_data_cost<LB>::value == 0 &&
-    simd::Proxy_factory<RB, false>::ct_valid &&
-    // Only allow float, double, complex<float>,
-    // and complex<double> at this time.
-    (Type_equal<typename Scalar_of<typename LB::value_type>::type, float>::value ||
-     Type_equal<typename Scalar_of<typename LB::value_type>::type, double>::value) &&
-    // Make sure both sides have the same type.
-    Type_equal<typename LB::value_type, typename RB::value_type>::value &&
-    // Make sure the left side is not a complex split block.
-    !Is_split_block<LB>::value;
-
-
-  static bool rt_valid(LB& lhs, RB const& rhs)
-  {
-    Ext_data<LB, layout_type> dda(lhs, SYNC_OUT);
-    return (dda.stride(0) == 1 &&
-	    simd::Simd_traits<typename LB::value_type>::
-	      alignment_of(dda.data()) == 0 &&
-	    simd::Proxy_factory<RB, false>::rt_valid(rhs, 0));
-  }
-
-  static void exec(LB& lhs, RB const& rhs)
-  {
-    typedef typename simd::LValue_access_traits<typename LB::value_type> WAT;
-    typedef typename simd::Proxy_factory<RB, false>::access_traits EAT;
-
-    length_type const vec_size =
-      simd::Simd_traits<typename LB::value_type>::vec_size;
-    Ext_data<LB, layout_type> dda(lhs, SYNC_OUT);
-
-    simd::Proxy<WAT,true>  lp(dda.data());
-    simd::Proxy<EAT,false> rp(simd::Proxy_factory<RB,false>::create(rhs));
-
-    length_type const size = dda.size(0);
-    length_type n = size;
-
-    // loop using proxy interface. This generates the best code
-    // with gcc 3.4 (with gcc 4.1 the difference to the first case
-    // above is negligible).
-
-    while (n >= vec_size)
-    {
-      lp.store(rp.load());
-      n -= vec_size;
-      lp.increment();
-      rp.increment();
-    }
-
-    // Process the remainder, using simple loop fusion.
-    for (index_type i = size - n; i != size; ++i) lhs.put(i, rhs.get(i));
-  }
-};
-
-
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/opt/simd/proxy_factory.hpp
===================================================================
--- src/vsip/opt/simd/proxy_factory.hpp	(revision 0)
+++ src/vsip/opt/simd/proxy_factory.hpp	(revision 0)
@@ -0,0 +1,249 @@
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/simd/expr_evaluator.hpp
+    @author  Stefan Seefeld
+    @date    2006-07-25
+    @brief   VSIPL++ Library: SIMD expression evaluator proxy factory.
+
+*/
+
+#ifndef VSIP_IMPL_SIMD_PROXY_FACTORY_HPP
+#define VSIP_IMPL_SIMD_PROXY_FACTORY_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/opt/simd/expr_iterator.hpp>
+#include <vsip/core/expr/operations.hpp>
+#include <vsip/core/expr/unary_block.hpp>
+#include <vsip/core/expr/binary_block.hpp>
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/opt/expr/serial_evaluator.hpp>
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+template <typename BlockT, bool A>
+struct Proxy_factory
+{
+  typedef Direct_access_traits<typename BlockT::value_type> access_traits;
+  typedef Proxy<access_traits, A> proxy_type;
+  typedef typename Adjust_layout_dim<
+                     1, typename Block_layout<BlockT>::layout_type>::type
+		layout_type;
+
+  static bool const ct_valid = Ext_data_cost<BlockT>::value == 0 &&
+    !Is_split_block<BlockT>::value;
+
+  static bool 
+  rt_valid(BlockT const &b, int alignment)
+  {
+    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
+    return dda.stride(0) == 1 && 
+      (!A ||
+       Simd_traits<typename BlockT::value_type>::alignment_of(dda.data()) ==
+       alignment);
+  }
+
+  static int
+  alignment(BlockT const &b)
+  {
+    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
+    return Simd_traits<typename BlockT::value_type>::alignment_of(dda.data());
+  }
+
+  static proxy_type
+  create(BlockT const &b) 
+  {
+    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
+    return proxy_type(dda.data());
+  }
+};
+
+template <typename T, bool A>
+struct Proxy_factory<Scalar_block<1, T>, A>
+{
+  typedef Scalar_access_traits<T> access_traits;
+  typedef Proxy<access_traits, A> proxy_type;
+  static bool const ct_valid = true;
+
+  static bool 
+  rt_valid(Scalar_block<1, T> const &, int) {return true;}
+
+  static proxy_type
+  create(Scalar_block<1, T> const &b) 
+  {
+    return proxy_type(b.value());
+  }
+};
+
+template <dimension_type D,
+	  template <typename> class O,
+	  typename B,
+	  typename T,
+	  bool A>
+struct Proxy_factory<Unary_expr_block<D, O, B, T> const, A>
+{
+  typedef 
+    Unary_access_traits<typename Proxy_factory<B,A>::proxy_type, O>
+    access_traits;
+  typedef Proxy<access_traits,A> proxy_type;
+
+  static bool const ct_valid =
+    Unary_operator_map<T, O>::is_supported &&
+    Type_equal<typename B::value_type, T>::value &&
+    Proxy_factory<B, A>::ct_valid;
+
+  static bool 
+  rt_valid(Unary_expr_block<D, O, B, T> const &b, int alignment)
+  {
+    return Proxy_factory<B, A>::rt_valid(b.op(), alignment);
+  }
+
+  static proxy_type
+  create(Unary_expr_block<D, O, B, T> const &b)
+  {
+    return proxy_type(Proxy_factory<B, A>::create(b.op()));
+  }
+};
+
+// This proxy is specialized for unaligned blocks. If the user specifies
+// ualigned(block), this is a hint to switch to an unaligned proxy.
+template <dimension_type D,
+	  typename B,
+	  typename T,
+	  bool A>
+struct Proxy_factory<Unary_expr_block<D, unaligned_functor, B, T> const, A>
+{
+  typedef typename Proxy_factory<B, false>::access_traits access_traits;
+  typedef Proxy<access_traits,false> proxy_type;
+  static bool const ct_valid = Proxy_factory<B,false>::ct_valid;
+
+
+  static bool 
+  rt_valid(Unary_expr_block<D, unaligned_functor, B, T> const &b, int alignment)
+  {
+    return Proxy_factory<B, false>::rt_valid(b.op(), alignment);
+  }
+
+  static proxy_type
+  create(Unary_expr_block<D, unaligned_functor, B, T> const &b)
+  {
+    return proxy_type(Proxy_factory<B, false>::create(b.op()));
+  }
+};
+
+template <dimension_type                D,
+	  template <typename, typename> class O,
+	  typename                      LB,
+	  typename                      LT,
+	  typename                      RB,
+	  typename                      RT,
+	  bool A>
+struct Proxy_factory<Binary_expr_block<D, O, LB, LT, RB, RT> const, A>
+{
+  typedef
+    Binary_access_traits<typename Proxy_factory<LB, A>::proxy_type,
+			 typename Proxy_factory<RB, A>::proxy_type, O> 
+    access_traits;
+  typedef Proxy<access_traits, A> proxy_type;
+  static bool const ct_valid = 
+    Type_equal<typename LB::value_type, LT>::value &&
+    Type_equal<typename RB::value_type, RT>::value &&
+    Type_equal<LT, RT>::value &&
+    Binary_operator_map<LT, O>::is_supported &&
+    Proxy_factory<LB, A>::ct_valid &&
+    Proxy_factory<RB, A>::ct_valid;
+
+  static bool 
+  rt_valid(Binary_expr_block<D, O, LB, LT, RB, RT> const &b, int alignment)
+  {
+    return Proxy_factory<LB, A>::rt_valid(b.left(), alignment) &&
+           Proxy_factory<RB, A>::rt_valid(b.right(), alignment);
+  }
+
+  static proxy_type
+  create(Binary_expr_block<D, O, LB, LT, RB, RT> const &b)
+  {
+    typename Proxy_factory<LB, A>::proxy_type lp =
+      Proxy_factory<LB, A>::create(b.left());
+    typename Proxy_factory<RB, A>::proxy_type rp =
+      Proxy_factory<RB, A>::create(b.right());
+
+    return proxy_type(lp, rp);
+  }
+};
+
+template <dimension_type                         D,
+	  template <typename, typename,typename> class O,
+	  typename                               Block1, typename Type1,
+	  typename                               Block2, typename Type2,
+	  typename                               Block3, typename Type3,
+	  bool A>
+struct Proxy_factory<Ternary_expr_block<D, O,
+  Block1,Type1,Block2,Type2,Block3,Type3> const, A>
+{
+  typedef Ternary_access_traits<typename Proxy_factory<Block1, A>::proxy_type,
+                                typename Proxy_factory<Block2, A>::proxy_type,
+                                typename Proxy_factory<Block3, A>::proxy_type,
+		 	        O> 
+    access_traits;
+
+  typedef Ternary_expr_block<D, O, Block1,Type1,Block2,Type2,Block3,Type3>
+    SrcBlock;
+
+  typedef Proxy<access_traits, A> proxy_type;
+  static bool const ct_valid = 
+    Ternary_operator_map<Type1, O>::is_supported &&
+    Proxy_factory<Block1, A>::ct_valid &&
+    Proxy_factory<Block2, A>::ct_valid &&
+    Proxy_factory<Block3, A>::ct_valid;
+
+  static bool 
+  rt_valid(SrcBlock const &b, int alignment)
+  {
+    return Proxy_factory<Block1, A>::rt_valid(b.first(), alignment) &&
+           Proxy_factory<Block2, A>::rt_valid(b.second(), alignment) &&
+           Proxy_factory<Block3, A>::rt_valid(b.third(), alignment);
+  }
+
+  static proxy_type
+  create(SrcBlock const &b)
+  {
+    typename Proxy_factory<Block1, A>::proxy_type
+      b1p = Proxy_factory<Block1, A>::create(b.first());
+    typename Proxy_factory<Block2, A>::proxy_type
+      b2p = Proxy_factory<Block2, A>::create(b.second());
+    typename Proxy_factory<Block3, A>::proxy_type
+      b3p = Proxy_factory<Block3, A>::create(b.third());
+
+    return proxy_type(b1p,b2p,b3p);
+  }
+};
+
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SIMD_PROXY_FACTORY_HPP
Index: src/vsip/opt/simd/eval_unaligned.hpp
===================================================================
--- src/vsip/opt/simd/eval_unaligned.hpp	(revision 0)
+++ src/vsip/opt/simd/eval_unaligned.hpp	(revision 0)
@@ -0,0 +1,121 @@
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/simd/eval_unaligned.hpp
+    @author  Stefan Seefeld
+    @date    2006-07-25
+    @brief   VSIPL++ Library: SIMD expression evaluator logic.
+
+*/
+
+#ifndef VSIP_IMPL_SIMD_EVAL_UNALIGNED_HPP
+#define VSIP_IMPL_SIMD_EVAL_UNALIGNED_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/opt/simd/expr_iterator.hpp>
+#include <vsip/core/expr/operations.hpp>
+#include <vsip/core/expr/unary_block.hpp>
+#include <vsip/core/expr/binary_block.hpp>
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/opt/expr/serial_evaluator.hpp>
+#include <vsip/opt/simd/proxy_factory.hpp>
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+
+// SIMD Loop Fusion evaluator for unaligned expressions.
+//
+// Handles expressions where the result is aligned, but the operands
+// are unaligned.
+
+template <typename LB,
+	  typename RB>
+struct Serial_expr_evaluator<1, LB, RB, Simd_unaligned_loop_fusion_tag>
+{
+  typedef typename Adjust_layout_dim<
+                     1, typename Block_layout<LB>::layout_type>::type
+		layout_type;
+
+  static char const* name() { return "Expr_SIMD_Unaligned_Loop"; }
+  
+  static bool const ct_valid =
+    // Is SIMD supported at all ?
+    simd::Simd_traits<typename LB::value_type>::is_accel &&
+    // Check that direct access is possible.
+    Ext_data_cost<LB>::value == 0 &&
+    simd::Proxy_factory<RB, false>::ct_valid &&
+    // Only allow float, double, complex<float>,
+    // and complex<double> at this time.
+    (Type_equal<typename Scalar_of<typename LB::value_type>::type, float>::value ||
+     Type_equal<typename Scalar_of<typename LB::value_type>::type, double>::value) &&
+    // Make sure both sides have the same type.
+    Type_equal<typename LB::value_type, typename RB::value_type>::value &&
+    // Make sure the left side is not a complex split block.
+    !Is_split_block<LB>::value;
+
+
+  static bool rt_valid(LB& lhs, RB const& rhs)
+  {
+    Ext_data<LB, layout_type> dda(lhs, SYNC_OUT);
+    return (dda.stride(0) == 1 &&
+	    simd::Simd_traits<typename LB::value_type>::
+	      alignment_of(dda.data()) == 0 &&
+	    simd::Proxy_factory<RB, false>::rt_valid(rhs, 0));
+  }
+
+  static void exec(LB& lhs, RB const& rhs)
+  {
+    typedef typename simd::LValue_access_traits<typename LB::value_type> WAT;
+    typedef typename simd::Proxy_factory<RB, false>::access_traits EAT;
+
+    length_type const vec_size =
+      simd::Simd_traits<typename LB::value_type>::vec_size;
+    Ext_data<LB, layout_type> dda(lhs, SYNC_OUT);
+
+    simd::Proxy<WAT,true>  lp(dda.data());
+    simd::Proxy<EAT,false> rp(simd::Proxy_factory<RB,false>::create(rhs));
+
+    length_type const size = dda.size(0);
+    length_type n = size;
+
+    // loop using proxy interface. This generates the best code
+    // with gcc 3.4 (with gcc 4.1 the difference to the first case
+    // above is negligible).
+
+    while (n >= vec_size)
+    {
+      lp.store(rp.load());
+      n -= vec_size;
+      lp.increment();
+      rp.increment();
+    }
+
+    // Process the remainder, using simple loop fusion.
+    for (index_type i = size - n; i != size; ++i) lhs.put(i, rhs.get(i));
+  }
+};
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SIMD_EVAL_UNALIGNED_HPP
Index: src/vsip/opt/simd/expr_iterator.hpp
===================================================================
--- src/vsip/opt/simd/expr_iterator.hpp	(revision 191870)
+++ src/vsip/opt/simd/expr_iterator.hpp	(working copy)
@@ -327,34 +327,34 @@
   typedef typename simd::perm_simd_type  perm_simd_type;
   typedef typename simd::value_type      value_type;
 
-  Simd_unaligned_loader(value_type const* ptr) : ptr_unaligned_(ptr) 
+  Simd_unaligned_loader(value_type const* ptr)
   {
     ptr_aligned_    = (value_type*)((intptr_t)ptr & ~(simd::alignment-1));
 
     x0_  = simd::load((value_type*)ptr_aligned_);
-    x1_  = simd::load((value_type*)(ptr_aligned_+simd::vec_size));
-    sh_  = simd::shift_for_addr(ptr_unaligned_);
+    sh_  = simd::shift_for_addr(ptr);
   }
 
   simd_type load() const
-  { return simd::perm(x0_, x1_, sh_); }
+  {
+    x1_  = simd::load((value_type*)(ptr_aligned_+simd::vec_size));
+    return simd::perm(x0_, x1_, sh_);
+  }
 
   void increment(length_type n = 1)
   {
-    ptr_unaligned_ += n * simd::vec_size;
     ptr_aligned_   += n * simd::vec_size;
   
-    // update x0
+    // Update x0.
+    //
+    // Note: this requires load() to be called at least once before each
+    //       call to increment().
     x0_ = (n == 1) ? x1_ : simd::load((value_type*)ptr_aligned_);
-
-    // update x1
-    x1_ = simd::load((value_type*)(ptr_aligned_+simd::vec_size));
   }
 
-  value_type const*            ptr_unaligned_;
   value_type const*            ptr_aligned_;
   simd_type                    x0_;
-  simd_type                    x1_;
+  mutable simd_type            x1_;
   perm_simd_type               sh_;
 
 };
@@ -568,7 +568,7 @@
   AB const &left() const { return left_;}
   C const &right() const { return right_;}
 
-  simd_type load() const 
+  simd_type load() const
   {
     simd_type a = left_.left().load();
     simd_type b = left_.right().load();
Index: src/vsip/opt/expr/serial_dispatch.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch.hpp	(revision 191870)
+++ src/vsip/opt/expr/serial_dispatch.hpp	(working copy)
@@ -47,6 +47,9 @@
 #ifdef VSIP_IMPL_HAVE_SIMD_LOOP_FUSION
 #  include <vsip/opt/simd/expr_evaluator.hpp>
 #endif
+#ifdef VSIP_IMPL_HAVE_SIMD_UNALIGNED_LOOP_FUSION
+#  include <vsip/opt/simd/eval_unaligned.hpp>
+#endif
 #ifdef VSIP_IMPL_HAVE_SIMD_GENERIC
 #  include <vsip/opt/simd/eval_generic.hpp>
 #endif
Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 192274)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -1215,6 +1215,40 @@
      </varlistentry>
 
      <varlistentry>
+      <term><option>--enable-simd-loop-fusion</option></term>
+      <listitem>
+       <para>
+        Enable VSIPL++ to generate SIMD instructions for loop-fusion
+        expressions (containing data that is SIMD aligned).
+
+        This option is useful for increasing performance of many
+        VSIPL++ expressions on platforms with SIMD instruction
+        set extensions (such as Intel SSE, or Power VMX/AltiVec).
+
+        The default is not to generate SIMD instructions.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--enable-simd-unaligned-loop-fusion</option></term>
+      <listitem>
+       <para>
+        Enable VSIPL++ to generate SIMD instructions for loop-fusion
+        expressions, possibly containing data that is SIMD unaligned.
+
+        This option is useful for increasing performance of VSIPL++
+        expressions that work with unaligned data on platforms with
+        SIMD instruction set extensions (such as Intel SSE, or Power
+        VMX/AltiVec).
+
+        The default is to follow the setting of
+        <option>--enable-simd-loop-fusion</option>.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><option>--with-complex=<replaceable>format</replaceable></option></term>
       <listitem>
        <para>
Index: src/vsip/opt/simd/rscvmul.hpp
===================================================================
--- src/vsip/opt/simd/rscvmul.hpp	(revision 191870)
+++ src/vsip/opt/simd/rscvmul.hpp	(working copy)
@@ -113,7 +113,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of((T*)B) != 0)
+    while (n && simd::alignment_of((T*)B) != 0)
     {
       *R = alpha * *B;
       R++; B++;
@@ -196,8 +196,10 @@
     T                        alpha,
     std::pair<T*, T*> const& B,
     std::pair<T*, T*> const& R,
-    int n)
+    int                      n)
   {
+    assert(n >= 0);
+
     typedef Simd_traits<T> simd;
     typedef typename simd::simd_type simd_type;
     
@@ -225,7 +227,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of(pRr) != 0)
+    while (n && simd::alignment_of(pRr) != 0)
     {
       *pRr = alpha * *pBr;
       *pRi = alpha * *pBi;
Index: src/vsip/opt/simd/threshold.hpp
===================================================================
--- src/vsip/opt/simd/threshold.hpp	(revision 191870)
+++ src/vsip/opt/simd/threshold.hpp	(working copy)
@@ -178,7 +178,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of(A) != 0)
+    while (n && simd::alignment_of(A) != 0)
     {
       if(O<T,T>::apply(*A,*B)) *Z = *A;
       else *Z = k;
Index: src/vsip/opt/simd/vgt.hpp
===================================================================
--- src/vsip/opt/simd/vgt.hpp	(revision 191870)
+++ src/vsip/opt/simd/vgt.hpp	(working copy)
@@ -114,7 +114,7 @@
   }
 
   // clean up initial unaligned values
-  while (simd::alignment_of(A) != 0)
+  while (n && simd::alignment_of(A) != 0)
   {
     *R = *A > *B;
     R++; A++; B++;
Index: src/vsip/opt/simd/vma_ip_csc.hpp
===================================================================
--- src/vsip/opt/simd/vma_ip_csc.hpp	(revision 191870)
+++ src/vsip/opt/simd/vma_ip_csc.hpp	(working copy)
@@ -113,7 +113,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of((T*)R) != 0)
+    while (n && simd::alignment_of((T*)R) != 0)
     {
       *R += a * *B;
       R++; B++;
Index: src/vsip/opt/simd/vaxpy.hpp
===================================================================
--- src/vsip/opt/simd/vaxpy.hpp	(revision 191870)
+++ src/vsip/opt/simd/vaxpy.hpp	(working copy)
@@ -116,7 +116,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of((T*)R) != 0)
+    while (n && simd::alignment_of((T*)R) != 0)
     {
       *R = a * *B + *C;
       R++; B++; C++;
Index: src/vsip/opt/simd/vadd.hpp
===================================================================
--- src/vsip/opt/simd/vadd.hpp	(revision 191870)
+++ src/vsip/opt/simd/vadd.hpp	(working copy)
@@ -113,7 +113,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of(A) != 0)
+    while (n && simd::alignment_of(A) != 0)
     {
       *R = *A + *B;
       R++; A++; B++;
Index: src/vsip/opt/simd/vmul.hpp
===================================================================
--- src/vsip/opt/simd/vmul.hpp	(revision 191870)
+++ src/vsip/opt/simd/vmul.hpp	(working copy)
@@ -113,7 +113,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of(A) != 0)
+    while (n && simd::alignment_of(A) != 0)
     {
       *R = *A * *B;
       R++; A++; B++;
@@ -191,7 +191,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of((T*)A) != 0)
+    while (n && simd::alignment_of((T*)A) != 0)
     {
       *R = *A * *B;
       R++; A++; B++;
@@ -329,7 +329,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of(pRr) != 0)
+    while (n && simd::alignment_of(pRr) != 0)
     {
       T rr = *pAr * *pBr - *pAi * *pBi;
       *pRi = *pAr * *pBi + *pAi * *pBr;
Index: src/vsip/opt/simd/vlogic.hpp
===================================================================
--- src/vsip/opt/simd/vlogic.hpp	(revision 191870)
+++ src/vsip/opt/simd/vlogic.hpp	(working copy)
@@ -278,7 +278,7 @@
     }
 
     // clean up initial unaligned values
-    while (traits::alignment_of((SimdValueT*)A) != 0)
+    while (n && traits::alignment_of((SimdValueT*)A) != 0)
     {
       *R = FunctionT::exec(*A);
       R++; A++;
@@ -386,7 +386,7 @@
     }
 
     // clean up initial unaligned values
-    while (traits::alignment_of((SimdValueT*)A) != 0)
+    while (n && traits::alignment_of((SimdValueT*)A) != 0)
     {
       *R = FunctionT::exec(*A, *B);
       R++; A++; B++;
Index: tests/regressions/view_offset.cpp
===================================================================
--- tests/regressions/view_offset.cpp	(revision 0)
+++ tests/regressions/view_offset.cpp	(revision 0)
@@ -0,0 +1,236 @@
+/* Copyright (c) 2008 by CodeSourcery, LLC.  All rights reserved. */
+
+
+/** @file    tests/view_offset.cpp
+    @author  Jules Bergmann
+    @date    2008-02-22
+    @brief   VSIPL++ Library: Regression test for small (less than SIMD
+             width), unaligned element-wise vector operations that triggered
+	     a bug in the built-in generic SIMD routines.
+     
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#define VERBOSE 0
+
+#if VERBOSE
+#  include <iostream>
+#endif
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions - Utility Functions
+***********************************************************************/
+
+template <typename T>
+void
+test_vadd(
+  length_type len,
+  length_type offset1,
+  length_type offset2,
+  length_type offset3)
+{
+  Rand<T> gen(0, 0);
+
+  Vector<T> big_A(len + offset1);
+  Vector<T> big_B(len + offset2);
+  Vector<T> big_Z(len + offset3);
+
+  typename Vector<T>::subview_type A = big_A(Domain<1>(offset1, 1, len));
+  typename Vector<T>::subview_type B = big_B(Domain<1>(offset2, 1, len));
+  typename Vector<T>::subview_type Z = big_Z(Domain<1>(offset3, 1, len));
+
+  A = gen.randu(len);
+  B = gen.randu(len);
+
+  Z = A + B;
+
+  for (index_type i=0; i<len; ++i)
+  {
+    test_assert(Almost_equal<T>::eq(Z.get(i), A.get(i) + B.get(i)));
+  }
+}
+
+
+
+template <typename T>
+void
+test_vma_cSC(
+  length_type len,
+  length_type offset1,
+  length_type offset2,
+  length_type offset3)
+{
+  typedef typename vsip::impl::Scalar_of<T>::type ST;
+
+  Rand<ST> rgen(0, 0);
+  Rand<T>  cgen(0, 0);
+
+  Vector<ST> big_B(len + offset1);
+  Vector<T>  big_C(len + offset2);
+  Vector<T>  big_Z(len + offset3);
+
+  T a = 2.0;
+  typename Vector<ST>::subview_type B = big_B(Domain<1>(offset1, 1, len));
+  typename Vector<T>::subview_type  C = big_C(Domain<1>(offset2, 1, len));
+  typename Vector<T>::subview_type  Z = big_Z(Domain<1>(offset3, 1, len));
+
+  B = rgen.randu(len);
+  C = cgen.randu(len);
+
+  Z = a * B + C;
+
+  for (index_type i=0; i<len; ++i)
+  {
+    test_assert(Almost_equal<T>::eq(Z.get(i), a * B.get(i) + C.get(i)));
+  }
+}
+
+
+
+template <typename T>
+void
+test_vmul(
+  length_type len,
+  length_type offset1,
+  length_type offset2,
+  length_type offset3)
+{
+  Rand<T> gen(0, 0);
+
+  Vector<T> big_A(len + offset1);
+  Vector<T> big_B(len + offset2);
+  Vector<T> big_Z(len + offset3);
+
+  typename Vector<T>::subview_type A = big_A(Domain<1>(offset1, 1, len));
+  typename Vector<T>::subview_type B = big_B(Domain<1>(offset2, 1, len));
+  typename Vector<T>::subview_type Z = big_Z(Domain<1>(offset3, 1, len));
+
+  A = gen.randu(len);
+  B = gen.randu(len);
+
+  Z = A * B;
+
+  for (index_type i=0; i<len; ++i)
+  {
+#if VERBOSE
+    if (!equal(Z.get(i), A.get(i) * B.get(i)))
+    {
+      std::cout << "Z(" << i << ")        = " << Z(i) << std::endl;
+      std::cout << "A(" << i << ") * B(" << i << ") = "
+		<< A(i) * B(i) << std::endl;
+    }
+#endif
+    test_assert(Almost_equal<T>::eq(Z.get(i), A.get(i) * B.get(i)));
+  }
+}
+
+
+
+template <typename T>
+void
+test_vthresh(
+  length_type len,
+  length_type offset1,
+  length_type offset2,
+  length_type offset3)
+{
+  Rand<T> gen(0, 0);
+
+  Vector<T> big_A(len + offset1);
+  Vector<T> big_B(len + offset2);
+  Vector<T> big_Z(len + offset3);
+
+  typename Vector<T>::subview_type A = big_A(Domain<1>(offset1, 1, len));
+  typename Vector<T>::subview_type B = big_B(Domain<1>(offset2, 1, len));
+  typename Vector<T>::subview_type Z = big_Z(Domain<1>(offset3, 1, len));
+  T                                k = 0.5;
+
+  A = gen.randu(len);
+  B = gen.randu(len);
+
+  Z = ite(A > B, A, k);
+
+  for (index_type i=0; i<len; ++i)
+  {
+    test_assert(Almost_equal<T>::eq(Z.get(i), A.get(i) > B.get(i) ? A.get(i) : k));
+  }
+}
+
+
+
+
+template <typename T>
+void
+test_sweep()
+{
+  for (index_type i=1; i<=128; ++i)
+  {
+    // 080222: These broke built-in SIMD functions when i < vector size.
+    test_vmul<T>(i, 1, 1, 1);
+    test_vadd<T>(i, 1, 1, 1);
+
+    // 080222: This would have been broken if it was being dispatched to.
+    test_vma_cSC<T>(i, 1, 1, 1);
+
+    // These work fine.
+    test_vmul<T>(i, 0, 0, 0);
+    test_vmul<T>(i, 1, 0, 0);
+    test_vmul<T>(i, 0, 1, 0);
+    test_vmul<T>(i, 0, 0, 1);
+
+    test_vadd<T>(i, 0, 0, 0);
+    test_vadd<T>(i, 1, 0, 0);
+    test_vadd<T>(i, 0, 1, 0);
+    test_vadd<T>(i, 0, 0, 1);
+
+    test_vma_cSC<T>(i, 0, 0, 0);
+    test_vma_cSC<T>(i, 1, 0, 0);
+    test_vma_cSC<T>(i, 0, 1, 0);
+    test_vma_cSC<T>(i, 0, 0, 1);
+  }
+}
+
+template <typename T>
+void
+test_sweep_real()
+{
+  for (index_type i=1; i<=128; ++i)
+  {
+    test_vthresh<T>(i, 1, 1, 1);
+
+    test_vthresh<T>(i, 0, 0, 0);
+    test_vthresh<T>(i, 1, 0, 0);
+    test_vthresh<T>(i, 0, 1, 0);
+    test_vthresh<T>(i, 0, 0, 1);
+  }
+}
+
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_sweep<float          >();
+  test_sweep<complex<float> >();
+
+  test_sweep_real<float>();
+}
Index: src/vsip_csl/img/impl/pwarp_simd.hpp
===================================================================
--- src/vsip_csl/img/impl/pwarp_simd.hpp	(revision 191870)
+++ src/vsip_csl/img/impl/pwarp_simd.hpp	(working copy)
@@ -408,6 +408,16 @@
 	bool_simd_t vec_1_good  = ui_simd::band(vec_u1_good, vec_v1_good);
 	bool_simd_t vec_2_good  = ui_simd::band(vec_u2_good, vec_v2_good);
 	bool_simd_t vec_3_good  = ui_simd::band(vec_u3_good, vec_v3_good);
+
+	// Clear u/v if out of bounds.
+	vec_u0 = simd::band(vec_0_good, vec_u0);
+	vec_u1 = simd::band(vec_1_good, vec_u1);
+	vec_u2 = simd::band(vec_2_good, vec_u2);
+	vec_u3 = simd::band(vec_3_good, vec_u3);
+	vec_v0 = simd::band(vec_0_good, vec_v0);
+	vec_v1 = simd::band(vec_1_good, vec_v1);
+	vec_v2 = simd::band(vec_2_good, vec_v2);
+	vec_v3 = simd::band(vec_3_good, vec_v3);
 	
 #if __PPU__
 	us_simd_t vec_s01_good = (us_simd_t)vec_pack(vec_0_good, vec_1_good);
@@ -518,22 +528,22 @@
 	ui_simd::extract_all(vec_2_offset, off_20, off_21, off_22, off_23);
 	ui_simd::extract_all(vec_3_offset, off_30, off_31, off_32, off_33);
 	
-	T* p_00 = p_in + off_00;
-	T* p_01 = p_in + off_01;
-	T* p_02 = p_in + off_02;
-	T* p_03 = p_in + off_03;
-	T* p_10 = p_in + off_10;
-	T* p_11 = p_in + off_11;
-	T* p_12 = p_in + off_12;
-	T* p_13 = p_in + off_13;
-	T* p_20 = p_in + off_20;
-	T* p_21 = p_in + off_21;
-	T* p_22 = p_in + off_22;
-	T* p_23 = p_in + off_23;
-	T* p_30 = p_in + off_30;
-	T* p_31 = p_in + off_31;
-	T* p_32 = p_in + off_32;
-	T* p_33 = p_in + off_33;
+	T* p_00 = p_in + off_00; assert(off_00 <= rows*cols);
+	T* p_01 = p_in + off_01; assert(off_01 <= rows*cols);
+	T* p_02 = p_in + off_02; assert(off_02 <= rows*cols);
+	T* p_03 = p_in + off_03; assert(off_03 <= rows*cols);
+	T* p_10 = p_in + off_10; assert(off_10 <= rows*cols);
+	T* p_11 = p_in + off_11; assert(off_11 <= rows*cols);
+	T* p_12 = p_in + off_12; assert(off_12 <= rows*cols);
+	T* p_13 = p_in + off_13; assert(off_13 <= rows*cols);
+	T* p_20 = p_in + off_20; assert(off_20 <= rows*cols);
+	T* p_21 = p_in + off_21; assert(off_21 <= rows*cols);
+	T* p_22 = p_in + off_22; assert(off_22 <= rows*cols);
+	T* p_23 = p_in + off_23; assert(off_23 <= rows*cols);
+	T* p_30 = p_in + off_30; assert(off_30 <= rows*cols);
+	T* p_31 = p_in + off_31; assert(off_31 <= rows*cols);
+	T* p_32 = p_in + off_32; assert(off_32 <= rows*cols);
+	T* p_33 = p_in + off_33; assert(off_33 <= rows*cols);
 
 	T z00_00 =  *p_00;
 	T z10_00 = *(p_00 + in_stride_0);
Index: tests/vsip_csl/pwarp.cpp
===================================================================
--- tests/vsip_csl/pwarp.cpp	(revision 191870)
+++ tests/vsip_csl/pwarp.cpp	(working copy)
@@ -12,14 +12,16 @@
 
 #define VERBOSE 1
 #define SAVE_IMAGES 0
-#define DO_CHECK 1
+#define DO_CHECK 0
+#define TEST_TYPES 1
 
-#define NUM_TCS 4
+#define NUM_TCS 6
 
 #if VERBOSE
 #  include <iostream>
 #endif
 #include <string>
+#include <sstream>
 
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
@@ -177,6 +179,36 @@
     P(1, 0) = 0; P(1, 1) = 1; P(1, 2) = 0;
     P(2, 0) = 0; P(2, 1) = 0; P(2, 2) = 1;
     break;
+
+  case 4: // Random projection #3, extracted from example application.
+          // Broke SPU input streaming for VGA images.
+    P(0, 0) = 1.00202;
+    P(0, 1) = 0.00603114;
+    P(0, 2) = 1.03277;
+
+    P(1, 0) = 0.000532397;
+    P(1, 1) = 1.01655;
+    P(1, 2) = 1.66292;
+
+    P(2, 0) = 1.40122e-06;
+    P(2, 1) = 1.05832e-05;
+    P(2, 2) = 1.00002;
+    break;
+
+  case 5: // Random projection #4, extracted from example application.
+          // Broke SIMD for VGA images.
+    P(0, 0) = 1.00504661;
+    P(0, 1) = 0.0150403921;
+    P(0, 2) = 9.60451126;
+
+    P(1, 0) = 0.00317225;
+    P(1, 1) = 1.04547524;
+    P(1, 2) = 16.1063614;
+
+    P(2, 0) = 2.21413484e-06;
+    P(2, 1) = 2.5766507e-05;
+    P(2, 2) = 1.00024176;
+    break;
   }
 }
 
@@ -449,7 +481,8 @@
   typedef typename Perspective_warp<CoeffT, T, interp_linear, forward>
     ::impl_tag impl_tag;
   std::cout << f_prefix
-	    << " (" << Dispatch_name<impl_tag>::name() << ")"
+	    << " (" << Dispatch_name<impl_tag>::name() << ") "
+	    << rows << " x " << cols << " "
 	    << " tc: " << tc 
 	    << "  error: " << error1 << ", " << error2 << std::endl;
 #else
@@ -489,13 +522,45 @@
   length_type row_size,
   length_type col_size)
 {
-  test_pwarp_obj<CoeffT, T>(f_prefix + "-0", rows,cols, row_size,col_size, 0);
-  test_pwarp_obj<CoeffT, T>(f_prefix + "-1", rows,cols, row_size,col_size, 1);
-  test_pwarp_obj<CoeffT, T>(f_prefix + "-2", rows,cols, row_size,col_size, 2);
-  test_pwarp_obj<CoeffT, T>(f_prefix + "-3", rows,cols, row_size,col_size, 3);
+  for (index_type i=0; i<NUM_TCS; ++i)
+  {
+    std::ostringstream filename;
+    filename << f_prefix << "-" << i;
+    test_pwarp_obj<CoeffT, T>(filename.str(), rows,cols, row_size,col_size, i);
+  }
 }
 
 
+#if TEST_TYPES
+void
+test_types(
+  length_type rows,
+  length_type cols,
+  length_type r_size,
+  length_type c_size)
+{
+  typedef unsigned char byte_t;
+
+#if TEST_LEVEL >= 2
+  // Cool types, but not that useful in practice.
+  test_perspective_fun<double, double>("double", rows, cols, r_size, c_size);
+  test_perspective_fun<double, float> ("dfloat", rows, cols, r_size, c_size);
+  test_perspective_fun<double, byte_t>("duchar", rows, cols, r_size, c_size);
+
+  test_perspective_obj<double, float> ("obj-dfloat",rows,cols,r_size,c_size);
+  test_perspective_obj<double, double>("obj-double",rows,cols,r_size,c_size);
+  test_perspective_obj<double, byte_t>("obj-duchar",rows,cols,r_size,c_size);
+#endif
+
+  test_perspective_fun<float,  float> ("float",  rows, cols, r_size, c_size);
+  test_perspective_fun<float,  byte_t>("uchar",  rows, cols, r_size, c_size);
+
+  test_perspective_obj<float,  float> ("obj-float", rows,cols, r_size, c_size);
+  test_perspective_obj<float,  byte_t>("obj-uchar", rows,cols, r_size, c_size);
+}
+#endif
+
+
 int
 main(int argc, char** argv)
 {
@@ -503,27 +568,14 @@
 
   test_apply_proj<double>();
 
-#if 0
-  test_perspective_fun<double, double>       ("double", 480, 640, 32, 16);
-  test_perspective_fun<double, float>        ("dfloat", 480, 640, 32, 16);
-  test_perspective_fun<float,  float>        ("float",  480, 640, 32, 16);
-  test_perspective_fun<double, unsigned char>("duchar", 480, 640, 32, 16);
-  test_perspective_fun<float,  unsigned char>("uchar",  480, 640, 32, 16);
-
-  test_perspective_obj<double, float>        ("obj-dfloat", 480, 640, 32, 16);
-  test_perspective_obj<double, double>       ("obj-double", 480, 640, 32, 16);
-  test_perspective_obj<float,  float>        ("obj-float",  480, 640, 32, 16);
-  test_perspective_obj<double, unsigned char>("obj-duchar", 480, 640, 32, 16);
-  test_perspective_obj<float,  unsigned char>("obj-uchar",  480, 640, 32, 16);
+#if TEST_TYPES
+  test_types(1080, 1920, 32, 16);
+  test_types(480,   640, 32, 16);
+  test_types(512,   512, 32, 16);
 #endif
 
-  test_perspective_fun<double, double>      ("fun-double", 512, 512, 32, 16);
-  test_perspective_fun<double, float>       ("fun-dfloat", 512, 512, 32, 16);
-  test_perspective_fun<float, float>        ("fun-float",  512, 512, 32, 16);
-  test_perspective_fun<float, unsigned char>("fun-uchar",  512, 512, 32, 16);
-
-  test_perspective_obj<double, double>      ("obj-double", 512, 512, 32, 16);
-  test_perspective_obj<double, float>       ("obj-dfloat", 512, 512, 32, 16);
-  test_perspective_obj<float, float>        ("obj-float",  512, 512, 32, 16);
-  test_perspective_obj<float, unsigned char>("obj-uchar",  512, 512, 32, 16);
+  // Standalone examples for debugging.
+  // test_perspective_obj<float, byte_t>("obj-uchar", 1080, 1920, 32, 16);
+  // test_pwarp_obj<float, byte_t>("obj-uchar", 480, 640, 32, 16, 5);
+  // test_pwarp_obj<float, byte_t>("obj-uchar", 1080, 1920, 32, 16, 5);
 }
Index: tests/regressions/transpose_assign.cpp
===================================================================
--- tests/regressions/transpose_assign.cpp	(revision 191870)
+++ tests/regressions/transpose_assign.cpp	(working copy)
@@ -19,6 +19,7 @@
 ***********************************************************************/
 
 #include <memory>
+#include <iostream>
 
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
@@ -66,8 +67,9 @@
 	  typename DstOrderT,
 	  typename SrcOrderT>
 void
-cover_hl()
+cover_hl(int verbose)
 {
+  if (verbose >= 1) std::cout << "cover_hl\n";
   // These tests fail for Intel C++ 9.1 for Windows prior
   // to workaround in fast-transpose.hpp:
   test_hl<T, DstOrderT, SrcOrderT>(5, 3);  // known bad case
@@ -78,19 +80,25 @@
     length_type max_rows = 32;
     length_type max_cols = 32;
     for (index_type rows=1; rows<max_rows; ++rows)
+    {
+      if (verbose >= 2) std::cout << " - " << rows << " / " << max_rows << "\n";
       for (index_type cols=1; cols<max_cols; ++cols)
 	test_hl<T, DstOrderT, SrcOrderT>(rows, cols);
+    }
   }
 
   {
     length_type max_rows = 256;
     length_type max_cols = 256;
     for (index_type rows=1; rows<max_rows; rows+=3)
+    {
+      if (verbose >= 2) std::cout << " - " << rows << " / " << max_rows << "\n";
       for (index_type cols=1; cols<max_cols; cols+=5)
       {
 	test_hl<T, DstOrderT, SrcOrderT>(rows, cols);
 	test_hl<T, DstOrderT, SrcOrderT>(cols, rows);
       }
+    }
   }
 }
 
@@ -128,25 +136,32 @@
 
 template <typename T>
 void
-cover_ll()
+cover_ll(int verbose)
 {
+  if (verbose >= 1) std::cout << "cover_ll\n";
   {
     length_type max_rows = 32;
     length_type max_cols = 32;
     for (index_type rows=1; rows<max_rows; ++rows)
+    {
+      if (verbose >= 2) std::cout << " - " << rows << " / " << max_rows << "\n";
       for (index_type cols=1; cols<max_cols; ++cols)
 	test_ll<T>(rows, cols);
+    }
   }
 
   {
     length_type max_rows = 256;
     length_type max_cols = 256;
     for (index_type rows=1; rows<max_rows; rows+=3)
+    {
+      if (verbose >= 2) std::cout << " - " << rows << " / " << max_rows << "\n";
       for (index_type cols=1; cols<max_cols; cols+=5)
       {
 	test_ll<T>(rows, cols);
 	test_ll<T>(cols, rows);
       }
+    }
   }
 }
 
@@ -160,11 +175,15 @@
 
   vsipl init(argc, argv);
 
-  cover_hl<float, row2_type, col2_type>();
-  cover_hl<complex<float>, row2_type, col2_type>();
+  int verbose = 0;
+  if (argc == 2 && argv[1][0] == '1') verbose = 1;
+  if (argc == 2 && argv[1][0] == '2') verbose = 2;
 
-  cover_ll<float>();
-  cover_ll<complex<float> >();
+  cover_hl<float, row2_type, col2_type>(verbose);
+  cover_hl<complex<float>, row2_type, col2_type>(verbose);
 
+  cover_ll<float>(verbose);
+  cover_ll<complex<float> >(verbose);
+
   return 0;
 }
Index: tests/threshold.cpp
===================================================================
--- tests/threshold.cpp	(revision 191870)
+++ tests/threshold.cpp	(working copy)
@@ -14,6 +14,8 @@
   Included Files
 ***********************************************************************/
 
+#include <iostream>
+
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/matrix.hpp>
@@ -127,6 +129,15 @@
 									\
   for (index_type i=0; i<size; ++i)					\
   {									\
+    if (!equal(C.get(i), (A.get(i) OP B.get(i) ? T(1) : T(0))))		\
+    {									\
+      std::cerr << "TEST_LVOP FAILED: i = " << i << std::endl		\
+		<< "  C.get(i): " << C.get(i) << std::endl		\
+		<< "  A.get(i): " << A.get(i) << std::endl		\
+		<< "  B.get(i): " << B.get(i) << std::endl		\
+		<< "  expected: "					\
+		<< (A.get(i) OP B.get(i) ? T(1) : T(0)) << std::endl;	\
+    }									\
     test_assert(equal(C.get(i), (A.get(i) OP B.get(i) ? T(1) : T(0))));	\
   }									\
 }
