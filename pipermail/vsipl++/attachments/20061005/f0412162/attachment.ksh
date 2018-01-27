Index: src/vsip/impl/signal-conv-ipp.hpp
===================================================================
--- src/vsip/impl/signal-conv-ipp.hpp	(revision 150673)
+++ src/vsip/impl/signal-conv-ipp.hpp	(working copy)
@@ -120,6 +120,8 @@
     {
       return pm_non_opt_calls_;
     }
+#else
+    (void)what;
 #endif
     return 0.f;
   }
Index: src/vsip/impl/pas/par_assign_eb.hpp
===================================================================
--- src/vsip/impl/pas/par_assign_eb.hpp	(revision 0)
+++ src/vsip/impl/pas/par_assign_eb.hpp	(revision 0)
@@ -0,0 +1,266 @@
+/* Copyright (c)  2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/par_assign_pas_eb.hpp
+    @author  Jules Bergmann
+    @date    2005-06-22
+    @brief   VSIPL++ Library: Parallel assignment algorithm for PAS.
+                              (with early binding).
+*/
+
+#ifndef VSIP_IMPL_PAR_ASSIGN_PAS_EB_HPP
+#define VSIP_IMPL_PAR_ASSIGN_PAS_EB_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/impl/par-services.hpp>
+#include <vsip/impl/profile.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/impl/view_traits.hpp>
+#include <vsip/impl/par_assign.hpp>
+#include <vsip/impl/pas/param.hpp>
+
+#define VERBOSE 0
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
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+class Par_assign<Dim, T1, T2, Block1, Block2, Pas_assign_eb>
+  : Compile_time_assert<Is_split_block<Block1>::value ==
+                        Is_split_block<Block2>::value>
+{
+  static dimension_type const dim = Dim;
+
+  typedef typename Distributed_local_block<Block1>::type dst_local_block;
+  typedef typename Distributed_local_block<Block2>::type src_local_block;
+
+  typedef typename View_of_dim<dim, T1, dst_local_block>::type
+		dst_lview_type;
+
+  typedef typename View_of_dim<dim, T2, src_local_block>::const_type
+		src_lview_type;
+
+
+  // Constructor.
+public:
+  Par_assign(
+    typename View_of_dim<Dim, T1, Block1>::type       dst,
+    typename View_of_dim<Dim, T2, Block2>::const_type src)
+    : dst_      (dst),
+      src_      (src.block()),
+      ready_sem_index_(0),
+      done_sem_index_ (0)
+  {
+    long rc;
+    long const reserved_flags = 0;
+    impl::profile::Scope_event ev("Par_assign<Pas_assign_eb>-cons");
+
+    PAS_id src_pset = src_.block().map().impl_ll_pset();
+    PAS_id dst_pset = dst_.block().map().impl_ll_pset();
+    PAS_id all_pset;
+
+    long* src_pnums;
+    long* dst_pnums;
+    long* all_pnums;
+    long  src_npnums;
+    long  dst_npnums;
+    unsigned long  all_npnums;
+
+    long  max_components = Block1::components > Block2::components ?
+                           Block1::components : Block2::components;
+
+    pas_pset_get_pnums_list(src_pset, &src_pnums, &src_npnums);
+    pas_pset_get_pnums_list(dst_pset, &dst_pnums, &dst_npnums);
+    all_pnums = pas_pset_combine(src_pnums, dst_pnums, PAS_PSET_UNION,
+				 &all_npnums);
+    pas_pset_create(all_pnums, 0, &all_pset);
+
+    free(src_pnums);
+    free(dst_pnums);
+    free(all_pnums);
+
+
+    // Set default values if temporary buffer is not necessary
+    // Either not in pset, or local_nbytes == 0
+    move_desc_ = NULL;
+    pull_flags_ = 0;
+
+
+    // Setup tmp buffer
+    if (pas_pset_is_member(all_pset))
+    {
+      long                 local_nbytes;
+
+      rc = pas_distribution_calc_tmp_local_nbytes(
+	src_.block().impl_ll_dist(),
+	dst_.block().impl_ll_dist(),
+	pas::Pas_datatype<T1>::value(),
+	0,
+	&local_nbytes);
+      assert(rc == CE_SUCCESS);
+#if VERBOSE
+      std::cout << "[" << local_processor() << "] "
+		<< "local_nbytes = " << local_nbytes << std::endl;
+#endif
+
+      if (local_nbytes > 0)
+      {
+	rc = pas_pbuf_create(
+	  0, 
+	  all_pset,
+	  local_nbytes,
+	  0,			// Default alignment
+	  max_components,
+	  PAS_ZERO,
+	  &tmp_pbuf_);
+	assert(rc == CE_SUCCESS);
+	
+	rc = pas_move_desc_create(reserved_flags, &move_desc_);
+	assert(rc == CE_SUCCESS);
+
+	rc = pas_move_desc_set_tmp_pbuf(move_desc_, tmp_pbuf_, 0);
+	assert(rc == CE_SUCCESS);
+
+	pull_flags_ = PAS_WAIT;
+      }
+    }
+
+    // Setup transfer
+    if (pas_pset_is_member(src_pset))
+    {
+      rc = pas_push_setup(
+		    move_desc_,
+		    src_.block().impl_ll_pbuf(),
+		    src_.block().impl_ll_dist(),
+		    dst_.block().impl_ll_pbuf(),
+		    dst_.block().impl_ll_dist(),
+		    pas::Pas_datatype<T1>::value(),
+		    done_sem_index_,
+		    pull_flags_ | VSIP_IMPL_PAS_XFER_ENGINE |
+		    VSIP_IMPL_PAS_SEM_GIVE_AFTER,
+		    &xfer_handle_); 
+      assert(rc == CE_SUCCESS);
+    }
+  }
+
+  ~Par_assign()
+  {
+    long const reserved_flags = 0;
+    long rc;
+
+    PAS_id src_pset = src_.block().map().impl_ll_pset();
+
+    if (pas_pset_is_member(src_pset))
+    {
+      rc = pas_xfer_free(xfer_handle_);
+      assert(rc == CE_SUCCESS);
+    }
+
+    if (move_desc_ != NULL)
+    {
+      rc = pas_move_desc_destroy(move_desc_, reserved_flags);
+      assert(rc == CE_SUCCESS);
+      
+      rc = pas_pbuf_destroy(tmp_pbuf_, reserved_flags);
+      assert(rc == CE_SUCCESS);
+    }
+  }
+
+
+  // Invoke the parallel assignment
+public:
+  void operator()()
+  {
+    long rc;
+
+    PAS_id src_pset = src_.block().map().impl_ll_pset();
+    PAS_id dst_pset = dst_.block().map().impl_ll_pset();
+
+    // -------------------------------------------------------------------
+    // Tell source that dst is ready
+    if (pas_pset_is_member(dst_pset))
+    {
+      // assert that subblock is not emtpy
+#if VERBOSE
+      std::cout << "[" << local_processor() << "] "
+		<< "give start" << std::endl << std::flush;
+#endif
+
+      pas::semaphore_give(src_pset, ready_sem_index_);
+
+#if VERBOSE
+      std::cout << "[" << local_processor() << "] "
+		<< "give done" << std::endl << std::flush;
+#endif
+    }
+
+
+    // -------------------------------------------------------------------
+    // Push when dst is ready
+    if (pas_pset_is_member(src_pset))
+    {
+      pas::semaphore_take(dst_pset, ready_sem_index_);
+
+#if VERBOSE
+      std::cout << "[" << local_processor() << "] "
+		<< "push start" << std::endl << std::flush;
+#endif
+      rc = pas_xfer_start(
+		    xfer_handle_,
+		    PAS_WAIT,
+		    NULL);
+      assert(rc == CE_SUCCESS);
+#if VERBOSE
+      std::cout << "[" << local_processor() << "] "
+		<< "push done" << std::endl << std::flush;
+#endif
+    }
+
+    // -------------------------------------------------------------------
+    // Wait for push to complete.
+    if (pas_pset_is_member(dst_pset))
+      pas::semaphore_take(src_pset, done_sem_index_);
+  }
+
+
+  // Private member data.
+private:
+  typename View_of_dim<Dim, T1, Block1>::type       dst_;
+  typename View_of_dim<Dim, T2, Block2>::const_type src_;
+
+  PAS_move_desc_handle  move_desc_;
+  PAS_pbuf_handle       tmp_pbuf_;
+  PAS_xfer_setup_handle xfer_handle_;
+  long                  pull_flags_;
+  long                  ready_sem_index_;
+  long                  done_sem_index_;
+};
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+
+#undef VERBOSE
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_IMPL_PAR_ASSIGN_PAS_EB_HPP
Index: src/vsip/impl/choose_par_assign_impl.hpp
===================================================================
--- src/vsip/impl/choose_par_assign_impl.hpp	(revision 150673)
+++ src/vsip/impl/choose_par_assign_impl.hpp	(working copy)
@@ -60,7 +60,7 @@
                                     Is_pas_block<Block2>::value;
 
   typedef typename
-  ITE_Type<is_pas_assign, As_type<Pas_assign>,
+  ITE_Type<is_pas_assign, As_type<Pas_assign_eb>,
                           As_type<Direct_pas_assign>
           >::type type;
 };
Index: src/vsip/impl/check_config.cpp
===================================================================
--- src/vsip/impl/check_config.cpp	(revision 0)
+++ src/vsip/impl/check_config.cpp	(revision 0)
@@ -0,0 +1,99 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/check_config.cpp
+    @author  Jules Bergmann
+    @date    2006-10-04
+    @brief   VSIPL++ Library: Check library configuration.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <string>
+#include <sstream>
+
+#include <vsip/impl/config.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+std::string
+library_config()
+{
+  std::ostringstream   cfg;
+
+  cfg << "Sourcery VSIPL++ Library Configuration\n";
+
+#if VSIP_IMPL_PAR_SERVICE == 0
+  cfg << "  VSIP_IMPL_PAR_SERVICE           - 0 (Serial)\n";
+#elif VSIP_IMPL_PAR_SERVICE == 1
+  cfg << "  VSIP_IMPL_PAR_SERVICE           - 1 (MPI)\n";
+#elif VSIP_IMPL_PAR_SERVICE == 2
+  cfg << "  VSIP_IMPL_PAR_SERVICE           - 2 (PAS)\n";
+#else
+  cfg << "  VSIP_IMPL_HAVE_SIMD_LOOP_FUSION - Unknown\n";
+#endif
+
+#if VSIP_IMPL_HAVE_IPP
+  cfg << "  VSIP_IMPL_IPP                   - 1\n";
+#else
+  cfg << "  VSIP_IMPL_IPP                   - 0\n";
+#endif
+
+#if VSIP_IMPL_HAVE_SAL
+  cfg << "  VSIP_IMPL_SAL                   - 1\n";
+#else
+  cfg << "  VSIP_IMPL_SAL                   - 0\n";
+#endif
+
+#if VSIP_IMPL_HAVE_SIMD_LOOP_FUSION
+  cfg << "  VSIP_IMPL_HAVE_SIMD_LOOP_FUSION - 1\n";
+#else
+  cfg << "  VSIP_IMPL_HAVE_SIMD_LOOP_FUSION - 0\n";
+#endif
+
+#if VSIP_IMPL_HAVE_SIMD_GENERIC
+  cfg << "  VSIP_IMPL_HAVE_SIMD_GENERIC     - 1\n";
+#else
+  cfg << "  VSIP_IMPL_HAVE_SIMD_GENERIC     - 0\n";
+#endif
+
+#if __SSE__
+  cfg << "  __SSE__                         - 1\n";
+#else
+  cfg << "  __SSE__                         - 0\n";
+#endif
+
+#if __SSE2__
+  cfg << "  __SSE2__                        - 1\n";
+#else
+  cfg << "  __SSE2__                        - 0\n";
+#endif
+
+#if __VEC__
+  cfg << "  __VEC__                         - 1\n";
+#else
+  cfg << "  __VEC__                         - 0\n";
+#endif
+
+#if _MC_EXEC
+  cfg << "  _MC_EXEC                        - 1\n";
+#else
+  cfg << "  _MC_EXEC                        - 0\n";
+#endif
+
+  return cfg.str();
+}
+
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/impl/simd/eval-generic.hpp
===================================================================
--- src/vsip/impl/simd/eval-generic.hpp	(revision 150673)
+++ src/vsip/impl/simd/eval-generic.hpp	(working copy)
@@ -300,6 +300,66 @@
 
 
 
+template <typename DstBlock,
+	  typename LBlock,
+	  typename RBlock,
+	  typename LType,
+	  typename RType>
+struct Serial_expr_evaluator<
+  1, DstBlock,
+  const Binary_expr_block<1, lt_functor, LBlock, LType, RBlock, RType>,
+  Simd_builtin_tag>
+{
+  typedef Binary_expr_block<1, lt_functor, LBlock, LType, RBlock, RType>
+    SrcBlock;
+
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<DstBlock>::layout_type>::type
+    dst_lp;
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<LBlock>::layout_type>::type
+    lblock_lp;
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<RBlock>::layout_type>::type
+    rblock_lp;
+
+  static char const* name() { return "Expr_SIMD_VV-simd::vlt_as_gt"; }
+
+  static bool const ct_valid = 
+    !Is_expr_block<LBlock>::value &&
+    !Is_expr_block<RBlock>::value &&
+     Type_equal<typename DstBlock::value_type, bool>::value &&
+     Type_equal<LType, RType>::value &&
+     simd::Is_algorithm_supported<LType, false, simd::Alg_vgt>::value &&
+     // check that direct access is supported
+     Ext_data_cost<DstBlock>::value == 0 &&
+     Ext_data_cost<LBlock>::value == 0 &&
+     Ext_data_cost<RBlock>::value == 0;
+
+  
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    // check if all data is unit stride
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,         SYNC_OUT);
+    Ext_data<LBlock, lblock_lp> ext_l  (src.left(),  SYNC_IN);
+    Ext_data<RBlock, rblock_lp> ext_r  (src.right(), SYNC_IN);
+    return (ext_dst.stride(0) == 1 &&
+	    ext_l.stride(0) == 1 &&
+	    ext_r.stride(0) == 1);
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,         SYNC_OUT);
+    Ext_data<LBlock, lblock_lp> ext_l  (src.left(),  SYNC_IN);
+    Ext_data<RBlock, rblock_lp> ext_r  (src.right(), SYNC_IN);
+    // Swap left and right arguments to vgt
+    simd::vgt(ext_r.data(), ext_l.data(), ext_dst.data(), dst.size());
+  }
+};
+
+
+
 /***********************************************************************
   vector logical operators
 ***********************************************************************/
Index: src/vsip/impl/par_assign.hpp
===================================================================
--- src/vsip/impl/par_assign.hpp	(revision 150673)
+++ src/vsip/impl/par_assign.hpp	(working copy)
@@ -24,6 +24,7 @@
 #  include <vsip/impl/par_assign_blkvec.hpp>
 #elif VSIP_IMPL_PAR_SERVICE == 2
 #  include <vsip/impl/pas/par_assign.hpp>
+#  include <vsip/impl/pas/par_assign_eb.hpp>
 #  include <vsip/impl/pas/par_assign_direct.hpp>
 #endif
 
Index: src/vsip/impl/par_assign_fwd.hpp
===================================================================
--- src/vsip/impl/par_assign_fwd.hpp	(revision 150673)
+++ src/vsip/impl/par_assign_fwd.hpp	(working copy)
@@ -31,6 +31,7 @@
 struct Chained_assign;
 struct Blkvec_assign;
 struct Pas_assign;
+struct Pas_assign_eb;
 struct Direct_pas_assign;
 
 // Parallel assignment.
Index: src/vsip/impl/check_config.hpp
===================================================================
--- src/vsip/impl/check_config.hpp	(revision 0)
+++ src/vsip/impl/check_config.hpp	(revision 0)
@@ -0,0 +1,35 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/check_config.hpp
+    @author  Jules Bergmann
+    @date    2006-10-04
+    @brief   VSIPL++ Library: Check library configuration.
+*/
+
+#ifndef VSIP_IMPL_CHECK_CONFIG_HPP
+#define VSIP_IMPL_CHECK_CONFIG_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <string>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+std::string library_config();
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_CHECK_CONFIG_HPP
Index: src/vsip/support.hpp
===================================================================
--- src/vsip/support.hpp	(revision 150673)
+++ src/vsip/support.hpp	(working copy)
@@ -61,6 +61,18 @@
 #endif
 
 
+
+/// If the compiler provides a way to annotate functions that every
+/// call inside the function should be inlined, then VSIP_IMPL_FLATTEN
+/// is defined to that annotation, otherwise it is defined to nothing.
+#if __GNUC__ >= 4
+#  define VSIP_IMPL_FLATTEN __attribute__ ((__flatten__))
+#else
+#  define VSIP_IMPL_FLATTEN
+#endif
+
+
+
 /// Loop vectorization pragmas.
 #if __INTEL_COMPILER && !__ICL
 #  define PRAGMA_IVDEP _Pragma("ivdep")
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 150673)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -16,6 +16,7 @@
 src_vsip_CXXFLAGS := $(src_vsip_CXXINCLUDES)
 
 src_vsip_cxx_sources := $(wildcard $(srcdir)/src/vsip/*.cpp)
+src_vsip_cxx_sources += $(srcdir)/src/vsip/impl/check_config.cpp
 ifdef VSIP_IMPL_HAVE_IPP
 src_vsip_cxx_sources += $(srcdir)/src/vsip/impl/ipp.cpp
 endif
@@ -65,6 +66,7 @@
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/fft
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/lapack
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/sal
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/pas
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/ipp
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/fftw3
 	$(INSTALL_DATA) src/vsip/impl/acconfig.hpp $(DESTDIR)$(includedir)/vsip/impl
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 150674)
+++ ChangeLog	(working copy)
@@ -1,5 +1,48 @@
 2006-10-05  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/impl/signal-conv-ipp.hpp (impl_performance): Sink
+	  what to avoid Wall warning when profiling disabled.
+	* src/vsip/impl/pas/par_assign_eb.hpp: New file, early-binding
+	  version of PAS Par_assign.
+	* src/vsip/impl/choose_par_assign_impl.hpp: Use early-binding
+	  PAS Par_assign.
+	* src/vsip/impl/par_assign.hpp: Include par_assign_eb file.
+	* src/vsip/impl/par_assign_fwd.hpp (Pas_assign_eb): New impl tag
+	  for early-binding PAS Par_assign.
+	* src/vsip/impl/simd/eval-generic.hpp: Add dispatch for lt_functor
+	  using vgt() with reversed arguments.
+	* src/vsip/support.hpp (VSIP_IMPL_FLATTEN): New macro to tell
+	  compiler every call inside function should be inlined.
+	* src/vsip/GNUmakefile.inc.in: Build check_config.  Install
+	  PAS headers.
+	* GNUmakefile.in (hdr): Include PAS headers.
+	* tests/fft_be.cpp: Guard backend tests with ifdef check that
+	  backend is actually available.  Simplifies test compilation. 
+	* tests/coverage_comparison.cpp: Add coverage for less-than,
+	  float value type.
+	* configure.ac (--with-pas-include, --with-pas-lib): New options
+	  to specify PAS paths.  
+	  (LIBEXT): Add heuristic for MCOE.
+	  Update PAS configuration to work without pkg-config file.
+	* benchmarks/create_map.hpp: Use reference for communicator.
+	* benchmarks/dist_vmul.cpp: Likewise.
+	* benchmarks/vmul.cpp: Likewise.
+	* benchmarks/copy.cpp: Avoid MPI specific benchmarks when usiing
+	  PAS.
+	* benchmarks/loop.hpp: Fix printf wall warnings.
+	* benchmarks/fft_sal.cpp: New benchmark for SAL FFT performance.
+	* benchmarks/fastconv_sal.cpp: New benchmark for SAL fast convolution
+	  performance.
+	* benchmarks/mcopy.cpp: Add int benchmark case.
+	* examples/mercury/mcoe-setup.sh: Fix enable/disable flags for
+	  SIMD loop fusion.
+	* src/vsip/impl/check_config.cpp: New file, function library_config
+	  to return library configuration string.
+	* src/vsip/impl/check_config.hpp: New file, header for cpp file.
+	* tests/check_config.cpp: New file, exercise library_config.
+	
+2006-10-05  Jules Bergmann  <jules@codesourcery.com>
+
 	* doc/quickstart/quickstart.xml: Document --with-{obj,lib,exe}-ext
 	  options.
 
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 150673)
+++ GNUmakefile.in	(working copy)
@@ -298,6 +298,8 @@
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/impl/sal/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/impl/pas/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/impl/ipp/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/impl/fftw3/*.hpp))
Index: tests/fft_be.cpp
===================================================================
--- tests/fft_be.cpp	(revision 150673)
+++ tests/fft_be.cpp	(working copy)
@@ -401,27 +401,34 @@
 template <typename T, typename F>
 void test_fft1d()
 {
+#if VSIP_IMPL_FFTW3
   std::cout << "testing fwd in_place fftw...";
   fft_in_place<T, F, -1, fftw>(Domain<1>(16));
   fft_in_place<T, F, -1, fftw>(Domain<1>(0, 2, 8));
   std::cout << "testing inv in_place fftw...";
   fft_in_place<T, F, 1, fftw>(Domain<1>(16));
   fft_in_place<T, F, 1, fftw>(Domain<1>(0, 2, 8));
+#endif
 
+#if VSIP_IMPL_SAL_FFT
   std::cout << "testing fwd in_place sal...";
   fft_in_place<T, F, -1, sal>(Domain<1>(16));
   fft_in_place<T, F, -1, sal>(Domain<1>(0, 2, 8));
   std::cout << "testing inv in_place sal...";
   fft_in_place<T, F, 1, sal>(Domain<1>(16));
   fft_in_place<T, F, 1, sal>(Domain<1>(0, 2, 8));
+#endif
 
+#if VSIP_IMPL_IPP_FFT
   std::cout << "testing fwd in_place ipp...";
   fft_in_place<T, F, -1, ipp>(Domain<1>(16));
   fft_in_place<T, F, -1, ipp>(Domain<1>(0, 2, 8));
   std::cout << "testing inv in_place ipp...";
   fft_in_place<T, F, 1, ipp>(Domain<1>(16));
   fft_in_place<T, F, 1, ipp>(Domain<1>(0, 2, 8));
+#endif
 
+#if VSIP_IMPL_FFTW3
   std::cout << "testing c->c fwd by_ref fftw...";
   fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<1>(16));
   fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<1>(0, 2, 8));
@@ -434,7 +441,9 @@
   std::cout << "testing c->r inv 0 by_ref fftw...";
   fft_by_ref<rfft_type<T, F, 1, 0>, fftw>(Domain<1>(16));
   fft_by_ref<rfft_type<T, F, 1, 0>, fftw>(Domain<1>(0, 2, 8));
+#endif
 
+#if VSIP_IMPL_SAL_FFT
   std::cout << "testing c->c fwd by_ref sal...";
   fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<1>(16));
   fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<1>(0, 2, 8));
@@ -447,7 +456,9 @@
   std::cout << "testing c->r inv 0 by_ref sal...";
   fft_by_ref<rfft_type<T, F, 1, 0>, sal>(Domain<1>(16));
   fft_by_ref<rfft_type<T, F, 1, 0>, sal>(Domain<1>(0, 2, 8));
+#endif
 
+#if VSIP_IMPL_IPP_FFT
   std::cout << "testing c->c fwd by_ref ipp...";
   fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<1>(16));
   fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<1>(0, 2, 8));
@@ -460,11 +471,13 @@
   std::cout << "testing c->r inv 0 by_ref ipp...";
   fft_by_ref<rfft_type<T, F, 1, 0>, ipp>(Domain<1>(16));
   fft_by_ref<rfft_type<T, F, 1, 0>, ipp>(Domain<1>(0, 2, 8));
+#endif
 }
 
 template <typename T, typename F>
 void test_fft2d()
 {
+#if VSIP_IMPL_FFTW3
   std::cout << "testing fwd in_place fftw...";
   fft_in_place<T, F, -1, fftw>(Domain<2>(8, 16));
   fft_in_place<T, F, -1, fftw>(Domain<2>(Domain<1>(0, 2, 8),
@@ -473,6 +486,9 @@
   fft_in_place<T, F, 1, fftw>(Domain<2>(8, 16));
   fft_in_place<T, F, 1, fftw>(Domain<2>(Domain<1>(0, 2, 8),
 					Domain<1>(0, 2, 16)));
+#endif
+
+#if VSIP_IMPL_SAL_FFT
   std::cout << "testing fwd in_place sal...";
   fft_in_place<T, F, -1, sal>(Domain<2>(8, 16));
   fft_in_place<T, F, -1, sal>(Domain<2>(Domain<1>(0, 2, 8),
@@ -481,6 +497,9 @@
   fft_in_place<T, F, 1, sal>(Domain<2>(8, 16));
   fft_in_place<T, F, 1, sal>(Domain<2>(Domain<1>(0, 2, 8),
 				       Domain<1>(0, 2, 16)));
+#endif
+
+#if VSIP_IMPL_IPP_FFT
   std::cout << "testing fwd in_place ipp...";
   fft_in_place<T, F, -1, ipp>(Domain<2>(8, 16));
   fft_in_place<T, F, -1, ipp>(Domain<2>(Domain<1>(0, 2, 8),
@@ -489,7 +508,9 @@
   fft_in_place<T, F, 1, ipp>(Domain<2>(8, 17));
   fft_in_place<T, F, 1, ipp>(Domain<2>(Domain<1>(0, 2, 8),
 				       Domain<1>(0, 2, 16)));
+#endif
 
+#if VSIP_IMPL_FFTW3
   std::cout << "testing c->c fwd by_ref fftw...";
   fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<2>(8, 16));
   fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<2>(Domain<1>(0, 2, 8),
@@ -514,6 +535,9 @@
   fft_by_ref<rfft_type<T, F, 1, 1>, fftw> (Domain<2>(8, 16));
   fft_by_ref<rfft_type<T, F, 1, 1>, fftw> (Domain<2>(Domain<1>(0, 2, 8),
 						     Domain<1>(0, 2, 16)));
+#endif
+
+#if VSIP_IMPL_SAL_FFT
   std::cout << "testing c->c fwd by_ref sal...";
   fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<2>(8, 16));
   fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<2>(Domain<1>(0, 2, 8),
@@ -538,6 +562,9 @@
   fft_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(8, 16));
 //   fft_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(Domain<1>(0, 2, 8),
 // 						    Domain<1>(0, 2, 16)));
+#endif
+
+#if VSIP_IMPL_IPP_FFT
   std::cout << "testing c->c fwd by_ref ipp...";
   fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<2>(8, 16));
   fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<2>(Domain<1>(0, 2, 8),
@@ -562,6 +589,7 @@
   fft_by_ref<rfft_type<T, F, 1, 1>, ipp> (Domain<2>(8, 16));
   fft_by_ref<rfft_type<T, F, 1, 1>, ipp> (Domain<2>(Domain<1>(0, 2, 8),
 						    Domain<1>(0, 2, 16)));
+#endif
 }
 
 template <typename T, typename F>
@@ -623,6 +651,7 @@
 template <typename T, typename F>
 void test_fftm()
 {
+#if VSIP_IMPL_FFTW3
   std::cout << "testing fwd 0 in_place fftw...";
   fftm_in_place<T, F, -1, 0, fftw>(Domain<2>(8, 16));
   std::cout << "testing fwd 1 in_place fftw...";
@@ -631,7 +660,9 @@
   fftm_in_place<T, F, 1, 0, fftw>(Domain<2>(8, 16));
   std::cout << "testing inv 1 in_place fftw...";
   fftm_in_place<T, F, 1, 1, fftw>(Domain<2>(8, 16));
+#endif
 
+#if VSIP_IMPL_SAL_FFT
   std::cout << "testing fwd 0 in_place sal...";
   fftm_in_place<T, F, -1, 0, sal>(Domain<2>(8, 16));
   std::cout << "testing fwd 1 in_place sal...";
@@ -640,7 +671,9 @@
   fftm_in_place<T, F, 1, 0, sal>(Domain<2>(8, 16));
   std::cout << "testing inv 1 in_place sal...";
   fftm_in_place<T, F, 1, 1, sal>(Domain<2>(8, 16));
+#endif
 
+#if VSIP_IMPL_IPP_FFT
   std::cout << "testing fwd 0 in_place ipp...";
   fftm_in_place<T, F, -1, 0, ipp>(Domain<2>(8, 16));
   std::cout << "testing fwd 1 in_place ipp...";
@@ -649,7 +682,9 @@
   fftm_in_place<T, F, 1, 0, ipp>(Domain<2>(8, 16));
   std::cout << "testing inv 1 in_place ipp...";
   fftm_in_place<T, F, 1, 1, ipp>(Domain<2>(8, 16));
+#endif
 
+#if VSIP_IMPL_FFTW3
   std::cout << "testing c->c fwd 0 by_ref fftw...";
   fftm_by_ref<cfft_type<T, F, -1, 0>, fftw>(Domain<2>(8, 16));
   std::cout << "testing c->c fwd 1 by_ref fftw...";
@@ -666,7 +701,9 @@
   fftm_by_ref<rfft_type<T, F, 1, 0>, fftw>(Domain<2>(8, 16));
   std::cout << "testing c->r inv 1 by_ref fftw...";
   fftm_by_ref<rfft_type<T, F, 1, 1>, fftw>(Domain<2>(8, 16));
+#endif
 
+#if VSIP_IMPL_SAL_FFT
   std::cout << "testing c->c fwd 0 by_ref sal...";
   fftm_by_ref<cfft_type<T, F, -1, 0>, sal>(Domain<2>(8, 16));
   std::cout << "testing c->c fwd 1 by_ref sal...";
@@ -683,7 +720,9 @@
   fftm_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(8, 16));
   std::cout << "testing c->r inv 1 by_ref sal...";
   fftm_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(8, 16));
+#endif
 
+#if VSIP_IMPL_IPP_FFT
   std::cout << "testing c->c fwd 0 by_ref ipp...";
   fftm_by_ref<cfft_type<T, F, -1, 0>, ipp>(Domain<2>(8, 16));
   std::cout << "testing c->c fwd 1 by_ref ipp...";
@@ -700,6 +739,7 @@
   fftm_by_ref<rfft_type<T, F, 1, 0>, ipp> (Domain<2>(8, 16));
   std::cout << "testing c->r inv 1 by_ref ipp...";
   fftm_by_ref<rfft_type<T, F, 1, 1>, ipp> (Domain<2>(8, 16));
+#endif
 }
 
 int main(int, char **)
@@ -708,6 +748,7 @@
   test_fft1d<float, inter>();
   std::cout << "testing split float 1D fft" << std::endl;
   test_fft1d<float, split>();
+#if VSIP_IMPL_TEST_LEVEL > 0
   std::cout << "testing interleaved double 1D fft" << std::endl;
   test_fft1d<double, inter>();
   std::cout << "testing split double 1D fft" << std::endl;
@@ -716,25 +757,31 @@
 //   test_fft1d<long double, inter>();
 //   std::cout << "testing split long double 1D fft" << std::endl;
 //   test_fft1d<long double, split>();
+#endif
 
   std::cout << "testing interleaved float 2D fft" << std::endl;
   test_fft2d<float, inter>();
   std::cout << "testing split float 2D fft" << std::endl;
   test_fft2d<float, split>();
+#if VSIP_IMPL_TEST_LEVEL > 0
   std::cout << "testing interleaved double 2D fft" << std::endl;
   test_fft2d<double, inter>();
   std::cout << "testing split double 2D fft" << std::endl;
   test_fft2d<double, split>();
+#endif
 
   std::cout << "testing interleaved float fftm" << std::endl;
   test_fftm<float, inter>();
   std::cout << "testing split float fftm" << std::endl;
   test_fftm<float, split>();
+#if VSIP_IMPL_TEST_LEVEL > 0
   std::cout << "testing interleaved double fftm" << std::endl;
   test_fftm<double, inter>();
   std::cout << "testing split double fftm" << std::endl;
   test_fftm<double, split>();
+#endif
 
+#if VSIP_IMPL_TEST_LEVEL > 0
   std::cout << "testing interleaved float 3D fft" << std::endl;
   test_fft3d<float, inter>();
   std::cout << "testing split float 3D fft" << std::endl;
@@ -743,4 +790,5 @@
   test_fft3d<double, inter>();
   std::cout << "testing split double 3D fft" << std::endl;
   test_fft3d<double, split>();
+#endif
 }
Index: tests/check_config.cpp
===================================================================
--- tests/check_config.cpp	(revision 0)
+++ tests/check_config.cpp	(revision 0)
@@ -0,0 +1,37 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    tests/x-fft.cpp
+    @author  Jules Bergmann
+    @date    2006-10-04
+    @brief   VSIPL++ Library: Check library configuration
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/impl/check_config.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  cout << vsip::impl::library_config();
+
+  return 0;
+}
Index: tests/coverage_comparison.cpp
===================================================================
--- tests/coverage_comparison.cpp	(revision 150673)
+++ tests/coverage_comparison.cpp	(working copy)
@@ -31,6 +31,7 @@
 ***********************************************************************/
 
 TEST_BINARY_FUNC(gt, gt, gt, anyval)
+TEST_BINARY_FUNC(lt, lt, lt, anyval)
 
 
 
@@ -43,5 +44,8 @@
 {
   vsipl init(argc, argv);
 
-  vector_cases3_bool<Test_gt, int, int>();
+  vector_cases3_bool<Test_gt, int,   int>();
+  vector_cases3_bool<Test_gt, float, float>();
+  vector_cases3_bool<Test_lt, int,   int>();
+  vector_cases3_bool<Test_lt, float, float>();
 }
Index: configure.ac
===================================================================
--- configure.ac	(revision 150673)
+++ configure.ac	(working copy)
@@ -111,6 +111,16 @@
   AS_HELP_STRING([--enable-pas],
                  [use PAS if found (default is to not search for it)]),,
   [enable_pas=no])
+AC_ARG_WITH(pas_include,
+  AS_HELP_STRING([--with-pas-include=PATH],
+                 [Specify the path to the PAS include directory.]),
+  dnl If the user specified --with-pas-include, they mean to use PAS for sure.
+  [enable_pas=yes])
+AC_ARG_WITH(pas_lib,
+  AS_HELP_STRING([--with-pas-lib=PATH],
+                 [Specify the installation path of the PAS library.]),
+  dnl If the user specified --with-pas-lib, they mean to use PAS for sure.
+  [enable_pas=yes])
 
 ### Mercury Scientific Algorithm (SAL)
 AC_ARG_ENABLE([sal],
@@ -411,6 +421,10 @@
 AC_SUBST(CXXDEP)
 AC_SUBST(INTEL_WIN, $INTEL_WIN)
 
+#
+# Determine library extension
+#
+
 if test "x$lib_ext" != "x"; then
   LIBEXT="$lib_ext"
 else
@@ -419,10 +433,23 @@
       LIBEXT="lib"
       ;;
     *)
+      # Default is to use .a as the library archive extension.
       LIBEXT="a"
+
+      # However, when cross-compiling for Mercury PowerPC systems,
+      # .appc/.appc_le is preferred for big- and little- endian
+      # systems.
+      if test "$host" = "powerpc-unknown-none"; then
+        if test "$OBJEXT" = "oppc"; then
+          LIBEXT="appc"
+        elif test "$OBJEXT" = "oppc_le"; then
+          LIBEXT="appc_le"
+        fi
+      fi
       ;;
   esac
 fi
+
 AC_SUBST(LIBEXT)
 
 AC_LANG(C++)
@@ -871,14 +898,69 @@
   fi
 fi
 
+
+
+######################################################################
+# parallel service: PAS
+######################################################################
+
 if test "$enable_pas" = "yes"; then
-  vsipl_par_service=2
+  save_CPPFLAGS="$CPPFLAGS"
+  save_LDFLAGS="$LDFLAGS"
+  save_LIBS="$LIBS"
 
-  PKG_CHECK_MODULES(PAS, pas)
-  echo "PAS_CFLAGS: $PAS_CFLAGS"
-  echo "PAS_LIBS  : $PAS_LIBS"
-  CPPFLAGS="$CPPFLAGS $PAS_CFLAGS"
-  LIBS="$LIBS $PAS_LIBS"
+  pas_found="no"
+  try_pas="direct pkgconfig"
+
+  for try in $try_pas; do
+    if test $try = "direct"; then
+      AC_MSG_CHECKING([for PAS (direct)])
+      if test -n "$with_pas_include"; then
+        CPPFLAGS="$save_CPPFLAGS -I$with_pas_include"
+      fi
+      if test -n "$with_pas_lib"; then
+        LDFLAGS="$save_LDFLAGS -L$with_pas_lib"
+      fi
+      LIBS="$save_LIBS -lpas"
+    elif test $try = "pkgconfig"; then
+      AC_MSG_CHECKING([for PAS (with pkg-config)])
+      PKG_CHECK_MODULES(PAS, pas)
+      echo "PAS_CFLAGS: $PAS_CFLAGS"
+      echo "PAS_LIBS  : $PAS_LIBS"
+      CPPFLAGS="$save_CPPFLAGS $PAS_CFLAGS"
+      LIBS="$save_LIBS $PAS_LIBS"
+    else
+      AC_MSG_ERROR([Unknown PAS try $try])
+    fi
+
+    AC_LINK_IFELSE(
+      [AC_LANG_PROGRAM(
+	[[#include <pas.h>]],
+	[[PAS_id pset;
+          pas_pset_close(pset, 0);
+        ]]
+        )],
+      [pas_found=$try
+       AC_MSG_RESULT([found])
+       break],
+      [pas_found="no"
+       AC_MSG_RESULT([not found]) ])
+  done
+
+  if test "$pas_found" == "no"; then
+    if test "$with_lapack" != "probe"; then
+      AC_MSG_ERROR([PAS enabled but no library found])
+    fi
+    AC_MSG_RESULT([No PAS library found])
+    CPPFLAGS=$save_CPPFLAGS
+    LDFLAGS=$save_LDFLAGS
+    LIBS=$save_LIBS
+  else
+    AC_MSG_RESULT([Using $pas_found for PAS])
+    vsipl_par_service=2
+    PAR_SERVICE=pas
+  fi
+
 elif test "$enable_mpi" != "no"; then
   vsipl_par_service=1
 
@@ -2107,7 +2189,8 @@
 AC_MSG_RESULT([Using config suffix:                     $suffix])
 AC_MSG_RESULT([Exceptions enabled:                      $enable_exceptions])
 AC_MSG_RESULT([With mpi enabled:                        $enable_mpi])
-if test "$enable_mpi" != "no"; then
+AC_MSG_RESULT([With PAS enabled:                        $enable_pas])
+if test "$PAR_SERVICE" != "none"; then
   AC_MSG_RESULT([With parallel service:                   $PAR_SERVICE])
 fi
 if test "x$lapack_found" = "x"; then
@@ -2135,6 +2218,7 @@
 mkdir -p src/vsip/impl/ipp
 mkdir -p src/vsip/impl/fftw3
 mkdir -p src/vsip/impl/simd
+mkdir -p src/vsip/impl/pas
 
 AC_OUTPUT
 
Index: VERSIONS
===================================================================
--- VERSIONS	(revision 150673)
+++ VERSIONS	(working copy)
@@ -28,3 +28,5 @@
 	Preview release made on 26 Apr 2006.  Initial Solaris support.
 
 V_1_1	1.1 release (May 15, 2006)
+
+V_1_2	1.2 release (Sep, 2006) (SVN reversion 149394)
Index: benchmarks/create_map.hpp
===================================================================
--- benchmarks/create_map.hpp	(revision 150673)
+++ benchmarks/create_map.hpp	(working copy)
@@ -65,7 +65,7 @@
 
   void sync() { BARRIER(comm_); }
 
-  COMMUNICATOR_TYPE comm_;
+  COMMUNICATOR_TYPE& comm_;
 };
 
 
Index: benchmarks/dist_vmul.cpp
===================================================================
--- benchmarks/dist_vmul.cpp	(revision 150673)
+++ benchmarks/dist_vmul.cpp	(working copy)
@@ -73,7 +73,7 @@
 
   void sync() { BARRIER(comm_); }
 
-  COMMUNICATOR_TYPE comm_;
+  COMMUNICATOR_TYPE& comm_;
 };
 
 
Index: benchmarks/copy.cpp
===================================================================
--- benchmarks/copy.cpp	(revision 150673)
+++ benchmarks/copy.cpp	(working copy)
@@ -358,15 +358,26 @@
 int
 test(Loop1P& loop, int what)
 {
+  typedef float F;
+#if VSIP_IMPL_PAR_SERVICE == 1
   typedef vsip::impl::Chained_assign  Ca;
   typedef vsip::impl::Blkvec_assign   Bva;
+#elif VSIP_IMPL_PAR_SERVICE == 2
+  typedef vsip::impl::Pas_assign        Pa;
+  typedef vsip::impl::Pas_assign_eb     Pa_eb;
+  typedef vsip::impl::Direct_pas_assign Pa_d;
+#endif
 
   switch (what)
   {
   case  1: loop(t_vcopy_local<float, Impl_assign>()); break;
   case  2: loop(t_vcopy_root<float, Impl_assign>()); break;
   case  3: loop(t_vcopy_root<float, Impl_sa>()); break;
+#if VSIP_IMPL_PAR_SERVICE == 1
   case  4: loop(t_vcopy_root<float, Impl_pa<Ca> >()); break;
+#elif VSIP_IMPL_PAR_SERVICE == 2
+  case  4: loop(t_vcopy_root<float, Impl_pa<Pa> >()); break;
+#endif
 
   case 10: loop(t_vcopy_redist<float, Impl_assign>('1', '1')); break;
   case 11: loop(t_vcopy_redist<float, Impl_assign>('1', 'a'));  break;
@@ -386,34 +397,82 @@
 
   case 26: loop(t_vcopy_redist<complex<float>, Impl_sa>('1', '2')); break;
 
-  case 30: loop(t_vcopy_redist<float, Impl_pa<Ca> >('1', '1')); break;
-  case 31: loop(t_vcopy_redist<float, Impl_pa<Ca> >('1', 'a')); break;
-  case 32: loop(t_vcopy_redist<float, Impl_pa<Ca> >('a', '1')); break;
-  case 33: loop(t_vcopy_redist<float, Impl_pa<Ca> >('a', 'a')); break;
-  case 34: loop(t_vcopy_redist<float, Impl_pa<Ca> >('1', '2')); break;
-  case 35: loop(t_vcopy_redist<float, Impl_pa<Ca> >('1', 'b')); break;
+#if VSIP_IMPL_PAR_SERVICE == 1
 
-  case 40: loop(t_vcopy_redist<float, Impl_pa<Bva> >('1', '1')); break;
-  case 41: loop(t_vcopy_redist<float, Impl_pa<Bva> >('1', 'a')); break;
-  case 42: loop(t_vcopy_redist<float, Impl_pa<Bva> >('a', '1')); break;
-  case 43: loop(t_vcopy_redist<float, Impl_pa<Bva> >('a', 'a')); break;
-  case 44: loop(t_vcopy_redist<float, Impl_pa<Bva> >('1', '2')); break;
-  case 45: loop(t_vcopy_redist<float, Impl_pa<Bva> >('1', 'b')); break;
+  case 100: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', '1')); break;
+  case 101: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', 'a')); break;
+  case 102: loop(t_vcopy_redist<F, Impl_pa<Ca> >('a', '1')); break;
+  case 103: loop(t_vcopy_redist<F, Impl_pa<Ca> >('a', 'a')); break;
+  case 104: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', '2')); break;
+  case 105: loop(t_vcopy_redist<F, Impl_pa<Ca> >('1', 'b')); break;
 
-  case 50: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('1', '1')); break;
-  case 51: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('1', 'a')); break;
-  case 52: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('a', '1')); break;
-  case 53: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('a', 'a')); break;
-  case 54: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('1', '2')); break;
-  case 55: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('1', 'b')); break;
+  case 110: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', '1')); break;
+  case 111: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', 'a')); break;
+  case 112: loop(t_vcopy_redist<F, Impl_pa<Bva> >('a', '1')); break;
+  case 113: loop(t_vcopy_redist<F, Impl_pa<Bva> >('a', 'a')); break;
+  case 114: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', '2')); break;
+  case 115: loop(t_vcopy_redist<F, Impl_pa<Bva> >('1', 'b')); break;
 
-  case 60: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('1', '1')); break;
-  case 61: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('1', 'a')); break;
-  case 62: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('a', '1')); break;
-  case 63: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('a', 'a')); break;
-  case 64: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('1', '2')); break;
-  case 65: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('1', 'b')); break;
+  case 150: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', '1')); break;
+  case 151: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', 'a')); break;
+  case 152: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('a', '1')); break;
+  case 153: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('a', 'a')); break;
+  case 154: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', '2')); break;
+  case 155: loop(t_vcopy_redist<F, Impl_pa_na<Ca> >('1', 'b')); break;
 
+  case 160: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', '1')); break;
+  case 161: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', 'a')); break;
+  case 162: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('a', '1')); break;
+  case 163: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('a', 'a')); break;
+  case 164: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', '2')); break;
+  case 165: loop(t_vcopy_redist<F, Impl_pa_na<Bva> >('1', 'b')); break;
+
+#elif VSIP_IMPL_PAR_SERVICE == 2
+
+  case 200: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', '1')); break;
+  case 201: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', 'a')); break;
+  case 202: loop(t_vcopy_redist<F, Impl_pa<Pa> >('a', '1')); break;
+  case 203: loop(t_vcopy_redist<F, Impl_pa<Pa> >('a', 'a')); break;
+  case 204: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', '2')); break;
+  case 205: loop(t_vcopy_redist<F, Impl_pa<Pa> >('1', 'b')); break;
+
+  case 210: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', '1')); break;
+  case 211: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', 'a')); break;
+  case 212: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('a', '1')); break;
+  case 213: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('a', 'a')); break;
+  case 214: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', '2')); break;
+  case 215: loop(t_vcopy_redist<F, Impl_pa<Pa_eb> >('1', 'b')); break;
+
+  case 220: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', '1')); break;
+  case 221: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', 'a')); break;
+  case 222: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('a', '1')); break;
+  case 223: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('a', 'a')); break;
+  case 224: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', '2')); break;
+  case 225: loop(t_vcopy_redist<F, Impl_pa<Pa_d> >('1', 'b')); break;
+
+  case 250: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', '1')); break;
+  case 251: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', 'a')); break;
+  case 252: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('a', '1')); break;
+  case 253: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('a', 'a')); break;
+  case 254: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', '2')); break;
+  case 255: loop(t_vcopy_redist<F, Impl_pa_na<Pa> >('1', 'b')); break;
+
+  case 260: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', '1')); break;
+  case 261: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', 'a')); break;
+  case 262: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('a', '1')); break;
+  case 263: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('a', 'a')); break;
+  case 264: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', '2')); break;
+  case 265: loop(t_vcopy_redist<F, Impl_pa_na<Pa_eb> >('1', 'b')); break;
+
+  case 270: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', '1')); break;
+  case 271: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', 'a')); break;
+  case 272: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('a', '1')); break;
+  case 273: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('a', 'a')); break;
+  case 274: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', '2')); break;
+  case 275: loop(t_vcopy_redist<F, Impl_pa_na<Pa_d> >('1', 'b')); break;
+#endif
+
+
   case 0:
     std::cout
       << "copy -- vector copy\n"
Index: benchmarks/loop.hpp
===================================================================
--- benchmarks/loop.hpp	(revision 150673)
+++ benchmarks/loop.hpp	(working copy)
@@ -306,7 +306,7 @@
   if (rank == 0)
   {
     printf("# what             : %s (%d)\n", fcn.what(), what_);
-    printf("# nproc            : %d\n", nproc);
+    printf("# nproc            : %d\n", (int)nproc);
     printf("# ops_per_point(1) : %d\n", (int)fcn.ops_per_point(1));
     printf("# riob_per_point(1): %d\n", fcn.riob_per_point(1));
     printf("# wiob_per_point(1): %d\n", fcn.wiob_per_point(1));
@@ -437,7 +437,7 @@
   if (rank == 0)
   {
     printf("# what             : %s (%d)\n", fcn.what(), what_);
-    printf("# nproc            : %d\n", nproc);
+    printf("# nproc            : %d\n", (int)nproc);
     printf("# ops_per_point(1) : %d\n", (int)fcn.ops_per_point(1));
     printf("# riob_per_point(1): %d\n", fcn.riob_per_point(1));
     printf("# wiob_per_point(1): %d\n", fcn.wiob_per_point(1));
Index: benchmarks/fft_sal.cpp
===================================================================
--- benchmarks/fft_sal.cpp	(revision 0)
+++ benchmarks/fft_sal.cpp	(revision 0)
@@ -0,0 +1,244 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    benchmarks/fft_sal.cpp
+    @author  Jules Bergmann
+    @date    2006-08-02
+    @brief   VSIPL++ Library: Benchmark for SAL FFT.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/signal.hpp>
+
+#include "benchmarks.hpp"
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+using namespace vsip;
+
+using vsip::impl::Ext_data;
+using vsip::impl::Cmplx_inter_fmt;
+using vsip::impl::Cmplx_split_fmt;
+using vsip::impl::Stride_unit_dense;
+using vsip::impl::SYNC_IN;
+using vsip::impl::SYNC_OUT;
+
+
+// Wrapper class for SAL FFTs.
+
+template <typename T,
+	  typename ComplexFmt>
+struct sal_fft;
+
+
+
+// SAL FFT for interleaved complex (INCOMPLETE).
+
+template <>
+struct sal_fft<float, Cmplx_inter_fmt>
+{
+  typedef COMPLEX ctype;
+};
+
+
+
+// SAL FFT for split complex.
+
+template <>
+struct sal_fft<complex<float>, Cmplx_split_fmt>
+{
+  typedef COMPLEX_SPLIT type;
+
+  static type to_ptr(std::pair<float*, float*> const& ptr)
+  {
+    type ret = { ptr.first, ptr.second };
+    return ret;
+  }
+
+  static void fftop(
+    FFT_setup& setup,
+    type in,
+    type out,
+    type tmp,
+    int  size,
+    int  dir)
+  {
+    long eflag = 0;  // no caching hints
+    fft_zoptx(&setup, &in, 1, &out, 1, &tmp, size, dir, eflag);
+  }
+
+  static void fftip(
+    FFT_setup& setup,
+    type inout,
+    type tmp,
+    int  size,
+    int  dir)
+  {
+    long eflag = 0;  // no caching hints
+    fft_ziptx(&setup, &inout, 1, &tmp, size, dir, eflag);
+  }
+};
+
+
+
+inline unsigned long
+ilog2(length_type size)    // assume size = 2^n, != 0, return n.
+{
+  unsigned int n = 0;
+  while (size >>= 1) ++n;
+  return n;
+}
+
+
+int
+fft_ops(length_type len)
+{
+  return int(5 * std::log((float)len) / std::log(2.f));
+}
+
+
+template <typename T,
+	  typename ComplexFmt>
+struct t_fft_op
+{
+  char* what() { return "t_fft_op"; }
+  int ops_per_point(length_type len)  { return fft_ops(len); }
+  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int mem_per_point(length_type)  { return 1*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    typedef sal_fft<T, ComplexFmt> traits;
+
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, ComplexFmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A  (size, T());
+    Vector<T, block_type>   tmp(size, T());
+    Vector<T, block_type>   Z  (size);
+
+    unsigned long log2N = ilog2(size);
+
+    FFT_setup     setup;
+    unsigned long nbytes  = 0;
+    long          options = 0;
+    long          dir     = FFT_FORWARD;
+
+    fft_setup(log2N, options, &setup, &nbytes);
+
+    A = T(1);
+    
+    vsip::impl::profile::Timer t1;
+
+    {
+      Ext_data<block_type> ext_A(A.block(), SYNC_IN);
+      Ext_data<block_type> ext_tmp(tmp.block(), SYNC_IN);
+      Ext_data<block_type> ext_Z(Z.block(), SYNC_OUT);
+
+      typename traits::type A_ptr = traits::to_ptr(ext_A.data());
+      typename traits::type tmp_ptr = traits::to_ptr(ext_tmp.data());
+      typename traits::type Z_ptr = traits::to_ptr(ext_Z.data());
+    
+      t1.start();
+      for (index_type l=0; l<loop; ++l)
+	traits::fftop(setup, A_ptr, Z_ptr, tmp_ptr, log2N, dir);
+      t1.stop();
+    }
+    
+    if (!equal(Z.get(0), T(scale_ ? 1 : size)))
+    {
+      std::cout << "t_fft_op: ERROR" << std::endl;
+      std::cout << "  got     : " << Z.get(0) << std::endl;
+      std::cout << "  expected: " << T(scale_ ? 1 : size) << std::endl;
+      abort();
+    }
+    
+    time = t1.delta();
+  }
+
+  t_fft_op(bool scale) : scale_(scale) {}
+
+  // Member data
+  bool scale_;
+};
+
+
+#if 0
+template <typename T,
+	  int      no_times>
+struct t_fft_ip
+{
+  char* what() { return "t_fft_ip"; }
+  int ops_per_point(length_type len)  { return fft_ops(len); }
+  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
+  int mem_per_point(length_type)  { return 1*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    Vector<T>   A(size, T(0));
+
+    typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
+      fft_type;
+
+    fft_type fft(Domain<1>(size), scale_ ? (1.f/size) : 1.f);
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      fft(A);
+    t1.stop();
+    
+    if (!equal(A.get(0), T(0)))
+    {
+      std::cout << "t_fft_ip: ERROR" << std::endl;
+      abort();
+    }
+    
+    time = t1.delta();
+  }
+
+  t_fft_ip(bool scale) : scale_(scale) {}
+
+  // Member data
+  bool scale_;
+};
+#endif
+
+
+
+void
+defaults(Loop1P& loop)
+{
+  loop.start_ = 4;
+}
+
+
+
+int
+test(Loop1P& loop, int what)
+{
+  switch (what)
+  {
+  case  1: loop(t_fft_op<complex<float>, Cmplx_split_fmt>(false)); break;
+    // case  2: loop(t_fft_ip<complex<float>, Cmplx_split_fmt>(false)); break;
+  case  5: loop(t_fft_op<complex<float>, Cmplx_split_fmt>(true)); break;
+      // case  6: loop(t_fft_ip<complex<float>, Cmplx_split_fmt>(true)); break;
+
+  default: return 0;
+  }
+  return 1;
+}
Index: benchmarks/vmul.cpp
===================================================================
--- benchmarks/vmul.cpp	(revision 150673)
+++ benchmarks/vmul.cpp	(working copy)
@@ -66,7 +66,7 @@
 
   void sync() { BARRIER(comm_); }
 
-  COMMUNICATOR_TYPE comm_;
+  COMMUNICATOR_TYPE& comm_;
 };
 
 
Index: benchmarks/fastconv_sal.cpp
===================================================================
--- benchmarks/fastconv_sal.cpp	(revision 0)
+++ benchmarks/fastconv_sal.cpp	(revision 0)
@@ -0,0 +1,508 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    benchmarks/fastconv_sal.cpp
+    @author  Jules Bergmann, Don McCoy
+    @date    2005-10-28
+    @brief   VSIPL++ Library: Benchmark for Fast Convolution.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/impl/profile.hpp>
+
+#include <vsip_csl/test.hpp>
+#include "loop.hpp"
+
+using namespace vsip;
+using namespace vsip_csl;
+
+using impl::Stride_unit_dense;
+using impl::Cmplx_inter_fmt;
+using impl::Cmplx_split_fmt;
+
+
+
+/***********************************************************************
+  Common definitions
+***********************************************************************/
+
+inline unsigned long
+ilog2(length_type size)    // assume size = 2^n, != 0, return n.
+{
+  unsigned int n = 0;
+  while (size >>= 1) ++n;
+  return n;
+}
+
+
+
+template <typename T,
+	  typename ImplTag,
+	  typename ComplexFormat>
+struct t_fastconv_base;
+
+
+struct Impl1ip;		// in-place, phased fast-convolution
+struct Impl2ip;		// out-of-place (tmp), interleaved fast-convolution
+struct Impl2fv;		// foreach_vector, interleaved fast-convolution
+
+struct fastconv_ops
+{
+  float ops(length_type npulse, length_type nrange) 
+  {
+    float fft_ops = 5 * nrange * std::log(float(nrange)) / std::log(float(2));
+    float tot_ops = 2 * npulse * fft_ops + 6 * npulse * nrange;
+    return tot_ops;
+  }
+};
+
+
+
+/***********************************************************************
+  Impl1ip: in-place, phased fast-convolution
+***********************************************************************/
+
+template <>
+struct t_fastconv_base<complex<float>, Impl1ip, Cmplx_inter_fmt> : fastconv_ops
+{
+  typedef complex<float> T;
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP1;
+    typedef impl::Fast_block<1, T, LP1, Local_map> block1_type;
+
+    typedef impl::Layout<2, row2_type, Stride_unit_dense, Cmplx_inter_fmt> LP2;
+    typedef impl::Fast_block<2, T, LP2, Local_map> block2_type;
+    
+    // Create the data cube.
+    Matrix<T, block2_type> data(npulse, nrange);
+    
+    // Create the pulse replica and temporary buffer
+    Vector<T, block1_type> replica(nrange);
+    Vector<T, block1_type> tmp(nrange);
+
+    // Initialize
+    data    = T();
+    replica = T();
+
+    // setup direct access to data buffers
+    impl::Ext_data<block1_type> ext_replica(replica.block(), impl::SYNC_IN);
+    impl::Ext_data<block1_type> ext_tmp(tmp.block(), impl::SYNC_IN);
+
+    // Create weights array
+    unsigned long log2N = ilog2(nrange);
+    long flag = FFT_FAST_CONVOLUTION;
+    FFT_setup setup;
+    unsigned long nbytes = 0;
+    fft_setup( log2N, flag, &setup, &nbytes );
+
+    // Create filter
+    COMPLEX* filter = reinterpret_cast<COMPLEX *>(ext_replica.data());
+    COMPLEX* t = reinterpret_cast<COMPLEX *>(ext_tmp.data());
+    float scale = 1;
+    long f_conv = FFT_INVERSE;  // does not indicate direction, but rather 
+                                // convolution as opposed to correlation
+    long eflag = 0;  // no caching hints
+
+    fcf_ciptx( &setup, filter, t, &scale, log2N, f_conv, eflag );
+
+    
+    // Set up convolution 
+    impl::Ext_data<block2_type> ext_data(data.block(), impl::SYNC_IN);
+    COMPLEX* msignal = reinterpret_cast<COMPLEX *>(ext_data.data());
+    long jr = ext_data.stride(1);
+    long jc = ext_data.stride(0);
+    unsigned long M = npulse;
+    
+    vsip::impl::profile::Timer t1;
+    
+    // Impl1 ip
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      // Perform fast convolution
+      fcsm_ciptx( &setup, filter, msignal, jr, jc, t, 
+		  log2N, M, f_conv, eflag );
+    }
+    t1.stop();
+
+    // CHECK RESULT
+    time = t1.delta();
+    fft_free(&setup);
+  }
+};
+
+
+
+/***********************************************************************
+  Impl1ip: SPLIT in-place, phased fast-convolution
+***********************************************************************/
+
+template <>
+struct t_fastconv_base<complex<float>, Impl1ip, Cmplx_split_fmt> : fastconv_ops
+{
+  typedef complex<float> T;
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_split_fmt> LP1;
+    typedef impl::Fast_block<1, T, LP1, Local_map> block1_type;
+
+    typedef impl::Layout<2, row2_type, Stride_unit_dense, Cmplx_split_fmt> LP2;
+    typedef impl::Fast_block<2, T, LP2, Local_map> block2_type;
+
+    typedef impl::Ext_data<block1_type>::raw_ptr_type ptr_type;
+    
+    // Create the data cube.
+    Matrix<T, block2_type> data(npulse, nrange);
+    
+    // Create the pulse replica and temporary buffer
+    Vector<T, block1_type> replica(nrange);
+    Vector<T, block1_type> tmp(nrange);
+
+    // Initialize
+    data    = T();
+    replica = T();
+
+    // setup direct access to data buffers
+    impl::Ext_data<block1_type> ext_replica(replica.block(), impl::SYNC_IN);
+    impl::Ext_data<block1_type> ext_tmp(tmp.block(), impl::SYNC_IN);
+
+    // Create weights array
+    unsigned long log2N = ilog2(nrange);
+    long flag = FFT_FAST_CONVOLUTION;
+    FFT_setup setup;
+    unsigned long nbytes = 0;
+    fft_setup( log2N, flag, &setup, &nbytes );
+
+    // Create filter
+    // COMPLEX* filter = reinterpret_cast<COMPLEX *>(ext_replica.data());
+    // COMPLEX* t = reinterpret_cast<COMPLEX *>(ext_tmp.data());
+    ptr_type p_replica = ext_replica.data();
+    ptr_type p_tmp     = ext_tmp.data();
+
+    COMPLEX_SPLIT filter;
+    COMPLEX_SPLIT tmpbuf;
+
+    filter.realp = p_replica.first;
+    filter.imagp = p_replica.second;
+    tmpbuf.realp = p_tmp.first;
+    tmpbuf.imagp = p_tmp.second;
+
+    float scale = 1;
+    long f_conv = FFT_INVERSE;  // does not indicate direction, but rather 
+                                // convolution as opposed to correlation
+    long eflag = 0;  // no caching hints
+
+    fcf_ziptx( &setup, &filter, &tmpbuf, &scale, log2N, f_conv, eflag );
+
+    
+    // Set up convolution 
+    impl::Ext_data<block2_type> ext_data(data.block(), impl::SYNC_IN);
+    // COMPLEX* msignal = reinterpret_cast<COMPLEX *>(ext_data.data());
+
+    ptr_type p_data = ext_data.data();
+    COMPLEX_SPLIT msignal;
+    msignal.realp = p_data.first;
+    msignal.imagp = p_data.second;
+
+    long jr = ext_data.stride(1);
+    long jc = ext_data.stride(0);
+    unsigned long M = npulse;
+    
+    vsip::impl::profile::Timer t1;
+    
+    // Impl1 ip
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      // Perform fast convolution
+      fcsm_ziptx( &setup, &filter, &msignal, jr, jc, &tmpbuf, 
+		  log2N, M, f_conv, eflag );
+    }
+    t1.stop();
+
+    // CHECK RESULT
+    time = t1.delta();
+    fft_free(&setup);
+  }
+};
+
+
+
+
+
+/***********************************************************************
+  Impl2ip: out-of-place (tmp), interleaved fast-convolution
+***********************************************************************/
+
+template <>
+struct t_fastconv_base<complex<float>, Impl2ip, Cmplx_inter_fmt> : fastconv_ops
+{
+  typedef complex<float> T;
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+    typedef impl::Layout<2, row2_type, Stride_unit_dense, Cmplx_inter_fmt> LP2;
+    typedef impl::Fast_block<2, T, LP2, Local_map> block2_type;
+    typedef Matrix<T, block2_type>            view_type;
+
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP1;
+    typedef impl::Fast_block<1, T, LP1, Local_map> block1_type;
+    typedef Vector<T, block1_type>          replica_view_type;
+
+    // Create the data cube.
+    view_type data(npulse, nrange);
+    
+    // Create the pulse replica
+    replica_view_type replica(nrange);
+    replica_view_type tmp(nrange);
+
+    // Initialize
+    data    = T();
+    replica = T();
+
+    // setup direct access to data buffers
+    impl::Ext_data<block1_type> ext_replica(replica.block(), impl::SYNC_IN);
+    impl::Ext_data<block1_type> ext_tmp(tmp.block(), impl::SYNC_IN);
+
+    // Create weights array
+    unsigned long log2N = ilog2(nrange);
+    long flag = FFT_FAST_CONVOLUTION;
+    FFT_setup setup = 0;
+    unsigned long nbytes = 0;
+    fft_setup( log2N, flag, &setup, &nbytes );
+
+    // Create filter
+    COMPLEX* filter = reinterpret_cast<COMPLEX *>(ext_replica.data());
+    COMPLEX* t     = reinterpret_cast<COMPLEX *>(ext_tmp.data());
+    float scale = 1;
+    long f_conv = FFT_INVERSE;  // does not indicate direction, but rather 
+                                // convolution as opposed to correlation
+    long eflag = 0;  // no caching hints
+
+    fcf_ciptx( &setup, filter, t, &scale, log2N, f_conv, eflag );
+
+    // Set up convolution 
+    impl::Ext_data<block2_type> ext_data(data.block(), impl::SYNC_IN);
+    COMPLEX* signal    = reinterpret_cast<COMPLEX *>(ext_data.data());
+    long signal_stride = 2*ext_data.stride(1);
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      for (index_type p=0; p<npulse; ++p)
+      {
+	// Perform fast convolution
+	fcs_ciptx( &setup, filter, signal, signal_stride, t, log2N, f_conv, eflag );
+      }
+    }
+    t1.stop();
+
+    // CHECK RESULT
+    time = t1.delta();
+  }
+};
+
+
+
+/***********************************************************************
+  Impl2ip: SPLIT out-of-place (tmp), interleaved fast-convolution
+***********************************************************************/
+
+template <>
+struct t_fastconv_base<complex<float>, Impl2ip, Cmplx_split_fmt> : fastconv_ops
+{
+  typedef complex<float> T;
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+    typedef impl::Layout<2, row2_type, Stride_unit_dense, Cmplx_split_fmt> LP2;
+    typedef impl::Fast_block<2, T, LP2, Local_map> block2_type;
+    typedef Matrix<T, block2_type>            view_type;
+
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_split_fmt> LP1;
+    typedef impl::Fast_block<1, T, LP1, Local_map> block1_type;
+    typedef Vector<T, block1_type>          replica_view_type;
+
+    typedef impl::Ext_data<block1_type>::raw_ptr_type ptr_type;
+
+    // Create the data cube.
+    view_type data(npulse, nrange);
+    
+    // Create the pulse replica
+    replica_view_type replica(nrange);
+    replica_view_type tmp(nrange);
+
+    // Initialize
+    data    = T();
+    replica = T();
+
+    // setup direct access to data buffers
+    impl::Ext_data<block1_type> ext_replica(replica.block(), impl::SYNC_IN);
+    impl::Ext_data<block1_type> ext_tmp(tmp.block(), impl::SYNC_IN);
+
+    // Create weights array
+    unsigned long log2N = ilog2(nrange);
+    long flag = FFT_FAST_CONVOLUTION;
+    FFT_setup setup = 0;
+    unsigned long nbytes = 0;
+    fft_setup( log2N, flag, &setup, &nbytes );
+
+    // Create filter
+    ptr_type p_replica = ext_replica.data();
+    ptr_type p_tmp     = ext_tmp.data();
+
+    COMPLEX_SPLIT filter;
+    COMPLEX_SPLIT tmpbuf;
+
+    filter.realp = p_replica.first;
+    filter.imagp = p_replica.second;
+    tmpbuf.realp = p_tmp.first;
+    tmpbuf.imagp = p_tmp.second;
+
+
+    float scale = 1;
+    long f_conv = FFT_INVERSE;  // does not indicate direction, but rather 
+                                // convolution as opposed to correlation
+    long eflag = 0;  // no caching hints
+
+    fcf_ziptx(&setup, &filter, &tmpbuf, &scale, log2N, f_conv, eflag );
+
+    // Set up convolution 
+    impl::Ext_data<block2_type> ext_data(data.block(), impl::SYNC_IN);
+
+    ptr_type p_data = ext_data.data();
+    COMPLEX_SPLIT signal;
+    signal.realp = p_data.first;
+    signal.imagp = p_data.second;
+
+    long signal_stride = 1*ext_data.stride(1);
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      for (index_type p=0; p<npulse; ++p)
+      {
+	// Perform fast convolution
+	fcs_ziptx(&setup, &filter, &signal, signal_stride, &tmpbuf,
+		  log2N, f_conv, eflag );
+      }
+    }
+    t1.stop();
+
+    // CHECK RESULT
+    time = t1.delta();
+  }
+};
+
+
+
+/***********************************************************************
+  PF driver: (P)ulse (F)ixed
+***********************************************************************/
+
+template <typename T, typename ImplTag, typename ComplexFmt>
+struct t_fastconv_pf : public t_fastconv_base<T, ImplTag, ComplexFmt>
+{
+  char* what() { return "t_fastconv_pf"; }
+  int ops_per_point(length_type size)
+    { return (int)(this->ops(npulse_, size) / size); }
+  int riob_per_point(length_type) { return -1*static_cast<int>(sizeof(T)); }
+  int wiob_per_point(length_type) { return -1*static_cast<int>(sizeof(T)); }
+  int mem_per_point (length_type) { return -1*static_cast<int>(sizeof(T)); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    this->fastconv(npulse_, size, loop, time);
+  }
+
+  t_fastconv_pf(length_type npulse) : npulse_(npulse) {}
+
+// Member data
+  length_type npulse_;
+};
+
+
+
+/***********************************************************************
+  RF driver: (R)ange cells (F)ixed
+***********************************************************************/
+
+template <typename T, typename ImplTag, typename ComplexFmt>
+struct t_fastconv_rf : public t_fastconv_base<T, ImplTag, ComplexFmt>
+{
+  char* what() { return "t_fastconv_rf"; }
+  int ops_per_point(length_type size)
+    { return (int)(this->ops(size, nrange_) / size); }
+  int riob_per_point(length_type) { return -1*static_cast<int>(sizeof(T)); }
+  int wiob_per_point(length_type) { return -1*static_cast<int>(sizeof(T)); }
+  int mem_per_point (length_type) { return -1*static_cast<int>(sizeof(T)); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    this->fastconv(size, nrange_, loop, time);
+  }
+
+  t_fastconv_rf(length_type nrange) : nrange_(nrange) {}
+
+// Member data
+  length_type nrange_;
+};
+
+
+
+void
+defaults(Loop1P& loop)
+{
+  loop.cal_        = 4;
+  loop.start_      = 4;
+  loop.stop_       = 16;
+  loop.loop_start_ = 10;
+  loop.user_param_ = 64;
+}
+
+
+
+int
+test(Loop1P& loop, int what)
+{
+  typedef complex<float> C;
+
+  length_type param1 = loop.user_param_;
+  switch (what)
+  {
+  case   2: loop(t_fastconv_pf<C, Impl1ip, Cmplx_inter_fmt>(param1)); break;
+  case   6: loop(t_fastconv_pf<C, Impl2ip, Cmplx_inter_fmt>(param1)); break;
+
+  case  12: loop(t_fastconv_rf<C, Impl1ip, Cmplx_inter_fmt>(param1)); break;
+  case  16: loop(t_fastconv_rf<C, Impl2ip, Cmplx_inter_fmt>(param1)); break;
+
+  case 102: loop(t_fastconv_pf<C, Impl1ip, Cmplx_split_fmt>(param1)); break;
+  case 106: loop(t_fastconv_pf<C, Impl2ip, Cmplx_split_fmt>(param1)); break;
+   
+  case 112: loop(t_fastconv_rf<C, Impl1ip, Cmplx_split_fmt>(param1)); break;
+  case 116: loop(t_fastconv_rf<C, Impl2ip, Cmplx_split_fmt>(param1)); break;
+
+  default: return 0;
+  }
+  return 1;
+}
Index: benchmarks/mcopy.cpp
===================================================================
--- benchmarks/mcopy.cpp	(revision 150673)
+++ benchmarks/mcopy.cpp	(working copy)
@@ -402,6 +402,8 @@
   case  41: loop(t_mcopy_par<float, 0, 0, Impl_sa>(np, np)); break;
   case  42: loop(t_mcopy_par<float, 0, 1, Impl_sa>(np, np)); break;
 
+  case 102: loop(t_mcopy_local<int, rt, ct, Impl_assign>()); break;
+
   default:
     return 0;
   }
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 150673)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -129,6 +129,8 @@
 
 if test $simd_loop_fusion = "y"; then
   cfg_flags="$cfg_flags --enable-simd-loop-fusion"
+else
+  cfg_flags="$cfg_flags --disable-simd-loop-fusion"
 fi
 
 if test $sal = "y"; then
@@ -157,7 +159,6 @@
 	--with-fftw3-cflags="-O2"		\
 	--with-complex=$fmt			\
 	--with-lapack=no			\
-	--disable-simd-loop-fusion		\
 	$cfg_flags				\
 	--with-test-level=$testlevel		\
 	--enable-timer=realtime
