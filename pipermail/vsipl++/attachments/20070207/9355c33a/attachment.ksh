Index: ChangeLog
===================================================================
--- ChangeLog	(revision 161699)
+++ ChangeLog	(working copy)
@@ -1,3 +1,76 @@
+2007-02-07  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/view_traits.hpp: Include get_local_view.hpp.
+	* src/vsip/core/signal/fir.hpp: Force extdata layout to interleaved
+	  complex.
+	* src/vsip/core/extdata_dist.hpp (Ext_data_dist): Comment member
+	  variables.
+	* src/vsip/core/working_view.hpp (Assign_local): Comment
+	  specializations.
+	* src/vsip/core/parallel/subset_map_decl.hpp (parent_subblock):
+	  Fix Wall warnings.
+	* src/vsip/core/parallel/expr.hpp: Include parallel/block.hpp
+	  instead of parallel/distributed_block.hpp.
+	* src/vsip/opt/parallel/foreach.hpp: Likewise.
+	* src/vsip/map.hpp: Likewise.  Fix reference counting leak for
+	  Map_data.
+	* src/vsip/opt/sal/cholesky.hpp (Chold_impl): Remove
+	  Compile_time_assert using Blas_traits.  Not applicable
+	  because blas may not be included, and not necessary since
+	  Chold dispatch already checks Is_chold_avail.
+	* src/vsip/opt/pas/assign_direct.hpp (build_copy_list): Update
+	  intersection to handle strides.
+	* src/vsip/opt/pas/param.hpp (VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER):
+	  Move to ..
+	* configure.ac (-enable-pas-share-dynamic-xfer): ... here.
+	* src/vsip/opt/pas/services.hpp (Pas_datatype): Additional
+	  specializations.
+	* src/vsip/opt/pas/assign.hpp: Include initfin.hpp.
+	* src/vsip/opt/signal/fir_opt.hpp: Add missing admit/release.
+	* tests/iir.cpp: Add VERBOSE output for debugging.
+	* tests/threshold.cpp: Disable double precision tests with
+	  VSIP_IMPL_TEST_DOUBLE
+	* tests/matvec.cpp: Likewise.
+	* tests/fir.cpp: Likewise.
+	* tests/matvec-dot.cpp: Likewise.
+	* tests/parallel/fftm.cpp: Likewise.
+	* tests/fft.cpp: Likewise.
+	* tests/matvec-prod.cpp: Likewise
+	* tests/parallel/subset_map.cpp: Avoid long running tests when
+	  TEST_LEVEL <= 1.
+
+	* tests/ref-impl/dense.cpp: Pass argc/argv to vsipl object.
+	* tests/ref-impl/admitrelease.cpp: Likewise.
+	* tests/ref-impl/vector.cpp: Likewise.
+	* tests/ref-impl/matrix.cpp: Likewise.
+	* tests/ref-impl/signal-histogram.cpp: Likewise.
+	* tests/ref-impl/solvers-qr.cpp: Likewise.
+	* tests/ref-impl/signal.cpp: Likewise.
+	* tests/ref-impl/random.cpp: Likewise.
+	* tests/ref-impl/dim-order.cpp: Likewise.
+	* tests/ref-impl/math-scalarview.cpp: Likewise.
+	* tests/ref-impl/vector-math.cpp: Likewise.
+	* tests/ref-impl/signal-fft.cpp: Likewise.
+	* tests/ref-impl/signal-convolution.cpp: Likewise.
+	* tests/ref-impl/matrix-math.cpp: Likewise.
+	* tests/ref-impl/solvers-covsol.cpp: Likewise.
+	* tests/ref-impl/view-math.cpp: Likewise.
+	* tests/ref-impl/signal-windows.cpp: Likewise.
+	* tests/ref-impl/math-reductions.cpp: Likewise.
+	* tests/ref-impl/math-matvec.cpp: Likewise.
+	* tests/ref-impl/complex.cpp: Likewise.
+	* tests/ref-impl/fft-coverage.cpp: Likewise.
+	* tests/ref-impl/solvers-lu.cpp: Likewise.
+	* tests/ref-impl/selgen.cpp: Likewise.
+	* tests/ref-impl/solvers-chol.cpp: Likewise.
+	* tests/ref-impl/vector-const.cpp: Likewise.
+	* tests/ref-impl/matrix-const.cpp: Likewise.
+	* tests/ref-impl/math.cpp: Likewise.
+	* tests/ref-impl/signal-fir.cpp: Likewise.
+	* tests/ref-impl/signal-correlation.cpp: Likewise.
+	* tests/ref-impl/ortho.cpp: New file.  Tests for orthogonality
+	  issues.
+	
 2007-02-01  Jules Bergmann  <jules@codesourcery.com>
 	
 	* doc/quickstart/quickstart.xml: Revise section on ref-impl cfg.
Index: src/vsip/core/view_traits.hpp
===================================================================
--- src/vsip/core/view_traits.hpp	(revision 161463)
+++ src/vsip/core/view_traits.hpp	(working copy)
@@ -17,6 +17,7 @@
 #include <vsip/support.hpp>
 #include <vsip/core/view_fwd.hpp>
 #include <vsip/core/subblock.hpp>
+#include <vsip/core/parallel/get_local_view.hpp>
 #include <complex>
 
 
Index: src/vsip/core/signal/fir.hpp
===================================================================
--- src/vsip/core/signal/fir.hpp	(revision 161463)
+++ src/vsip/core/signal/fir.hpp	(working copy)
@@ -109,12 +109,21 @@
   length_type
   operator()(const_Vector<T, Block0> in, Vector<T, Block1> out) VSIP_NOTHROW
   {
+    using vsip::impl::Block_layout;
+    using vsip::impl::Adjust_layout_complex;
+    using vsip::impl::Cmplx_inter_fmt;
+
     typename accumulator_type::Scope scope(*this);
     assert(in.size() == backend_->input_size());
     assert(out.size() == backend_->output_size());
 
-    impl::Ext_data<Block0> ext_in(in.block());
-    impl::Ext_data<Block1> ext_out(out.block());
+    typedef typename Block_layout<Block0>::layout_type LP0;
+    typedef typename Block_layout<Block1>::layout_type LP1;
+    typedef typename Adjust_layout_complex<Cmplx_inter_fmt, LP0>::type use_LP0;
+    typedef typename Adjust_layout_complex<Cmplx_inter_fmt, LP1>::type use_LP1;
+
+    impl::Ext_data<Block0, use_LP0> ext_in(in.block());
+    impl::Ext_data<Block1, use_LP1> ext_out(out.block());
     return backend_->apply(ext_in.data(), ext_in.stride(0), ext_in.size(0),
                            ext_out.data(), ext_out.stride(0), ext_out.size(0));
   }
Index: src/vsip/core/extdata_dist.hpp
===================================================================
--- src/vsip/core/extdata_dist.hpp	(revision 161553)
+++ src/vsip/core/extdata_dist.hpp	(working copy)
@@ -297,9 +297,9 @@
   int           cost  ()                 { return 2; }
 
 private:
-  src_view_type    src_;
-  storage_type     storage_;
-  block_type       block_;
+  src_view_type    src_;	// view of source block
+  storage_type     storage_;	// buffer
+  block_type       block_;	// Us_block referring to storage_ buffer.
   view_type        view_;
   ext_type         ext_;
 };
Index: src/vsip/core/working_view.hpp
===================================================================
--- src/vsip/core/working_view.hpp	(revision 161549)
+++ src/vsip/core/working_view.hpp	(working copy)
@@ -119,6 +119,8 @@
 	           = Is_local_map<typename View2::block_type::map_type>::value>
 struct Assign_local {};
 
+// Local to local case.  Both views are local, just copy the data.
+
 template <typename View1,
 	  typename View2>
 struct Assign_local<View1, View2, true, true>
@@ -129,6 +131,9 @@
   }
 };
 
+// Global to local case.  Destination is local, so copy source into
+// replicated view, then copy from local view.
+
 template <typename View1,
 	  typename View2>
 struct Assign_local<View1, View2, true, false>
@@ -151,6 +156,9 @@
   }
 };
 
+// Local to global case.  Source is local, so copy source into
+// replicated view, then copy to destination view.
+
 template <typename View1,
 	  typename View2>
 struct Assign_local<View1, View2, false, true>
Index: src/vsip/core/parallel/subset_map_decl.hpp
===================================================================
--- src/vsip/core/parallel/subset_map_decl.hpp	(revision 161463)
+++ src/vsip/core/parallel/subset_map_decl.hpp	(working copy)
@@ -299,7 +299,7 @@
 
   // Return the parent subblock corresponding to a child subblock.
   static index_type parent_subblock(
-    MapT const&        map,
+    MapT const&        /*map*/,
     Domain<Dim> const& /*dom*/,
     index_type         sb)
   {
@@ -327,7 +327,7 @@
 
   // Return the parent subblock corresponding to a child subblock.
   static index_type parent_subblock(
-    Map<Dist0, Dist1, Dist2> const& map,
+    Map<Dist0, Dist1, Dist2> const& /*map*/,
     Domain<Dim> const&              /*dom*/,
     index_type                      sb)
   {
Index: src/vsip/core/parallel/expr.hpp
===================================================================
--- src/vsip/core/parallel/expr.hpp	(revision 161463)
+++ src/vsip/core/parallel/expr.hpp	(working copy)
@@ -16,7 +16,7 @@
 
 #include <vsip/core/fast_block.hpp>
 #include <vsip/core/domain_utils.hpp>
-#include <vsip/core/parallel/distributed_block.hpp>
+#include <vsip/core/parallel/block.hpp>
 #include <vsip/core/block_traits.hpp>
 #include <vsip/core/parallel/assign.hpp>
 #include <vsip/core/parallel/choose_assign_impl.hpp>
Index: src/vsip/opt/sal/cholesky.hpp
===================================================================
--- src/vsip/opt/sal/cholesky.hpp	(revision 161463)
+++ src/vsip/opt/sal/cholesky.hpp	(working copy)
@@ -121,7 +121,6 @@
 
 template <typename T>
 class Chold_impl<T,Mercury_sal_tag>
-  : impl::Compile_time_assert<blas::Blas_traits<T>::valid>
 {
   // The matrix to be decomposed using SAL must be in ROW major format. The
   // other matrix B will be in COL major format so that we can pass each
Index: src/vsip/opt/pas/assign_direct.hpp
===================================================================
--- src/vsip/opt/pas/assign_direct.hpp	(revision 161463)
+++ src/vsip/opt/pas/assign_direct.hpp	(working copy)
@@ -692,12 +692,8 @@
 
 	  if (intersect(src_dom, dst_dom, intr))
 	  {
-	    Index<dim>  send_offset = first(intr) - first(src_dom);
-	    Domain<dim> send_dom    = domain(first(src_ldom) + send_offset,
-					     extent(intr));
-	    Index<dim>  recv_offset = first(intr) - first(dst_dom);
-	    Domain<dim> recv_dom    = domain(first(dst_ldom) + recv_offset,
-					     extent(intr));
+	    Domain<dim> send_dom = apply_intr(src_ldom, src_dom, intr);
+	    Domain<dim> recv_dom = apply_intr(dst_ldom, dst_dom, intr);
 
 	    copy_list.push_back(Copy_record(src_sb, dst_sb,
 					    send_dom, recv_dom));
Index: src/vsip/opt/pas/param.hpp
===================================================================
--- src/vsip/opt/pas/param.hpp	(revision 161463)
+++ src/vsip/opt/pas/param.hpp	(working copy)
@@ -61,8 +61,6 @@
 #  define VSIP_IMPL_PAS_HEAP_SIZE 0x100000
 #endif
 
-#define VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER 1
-
 #if VSIP_IMPL_PAS_USE_INTERRUPT()
 #  define VSIP_IMPL_PAS_SEM_GIVE_AFTER PAS_SEM_GIVE_INTERRUPT_AFTER
 #else
Index: src/vsip/opt/pas/services.hpp
===================================================================
--- src/vsip/opt/pas/services.hpp	(revision 161463)
+++ src/vsip/opt/pas/services.hpp	(working copy)
@@ -90,10 +90,13 @@
 VSIP_IMPL_PASDATATYPE(bool,                 PAS_DATA_REAL_U8);
 VSIP_IMPL_PASDATATYPE(char,                 PAS_DATA_REAL_S8);
 VSIP_IMPL_PASDATATYPE(unsigned char,        PAS_DATA_REAL_U8);
+VSIP_IMPL_PASDATATYPE(signed char,          PAS_DATA_REAL_S8);
 VSIP_IMPL_PASDATATYPE(short,                PAS_DATA_REAL_S16);
 VSIP_IMPL_PASDATATYPE(unsigned short,       PAS_DATA_REAL_U16);
 VSIP_IMPL_PASDATATYPE(int,                  PAS_DATA_REAL_S32);
 VSIP_IMPL_PASDATATYPE(unsigned int,         PAS_DATA_REAL_U32);
+VSIP_IMPL_PASDATATYPE(long,                 PAS_DATA_REAL_S32);
+VSIP_IMPL_PASDATATYPE(unsigned long,        PAS_DATA_REAL_U32);
 VSIP_IMPL_PASDATATYPE(float,                PAS_DATA_REAL_F32);
 VSIP_IMPL_PASDATATYPE(double,               PAS_DATA_REAL_F64);
 VSIP_IMPL_PASDATATYPE(std::complex<float>,  PAS_DATA_COMPLEX_F32);
Index: src/vsip/opt/pas/assign.hpp
===================================================================
--- src/vsip/opt/pas/assign.hpp	(revision 161549)
+++ src/vsip/opt/pas/assign.hpp	(working copy)
@@ -23,6 +23,7 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
 #include <vsip/core/parallel/services.hpp>
 #include <vsip/core/profile.hpp>
 #include <vsip/domain.hpp>
Index: src/vsip/opt/parallel/foreach.hpp
===================================================================
--- src/vsip/opt/parallel/foreach.hpp	(revision 161463)
+++ src/vsip/opt/parallel/foreach.hpp	(working copy)
@@ -27,7 +27,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
-#include <vsip/core/parallel/distributed_block.hpp>
+#include <vsip/core/parallel/block.hpp>
 #include <vsip/core/parallel/util.hpp>
 
 
Index: src/vsip/opt/signal/fir_opt.hpp
===================================================================
--- src/vsip/opt/signal/fir_opt.hpp	(revision 161463)
+++ src/vsip/opt/signal/fir_opt.hpp	(working copy)
@@ -87,7 +87,6 @@
     block_type sub_out_block(Domain<1>(0, out_stride, out_length), out_block);
     view_type output(sub_out_block);
 
-
     length_type const dec = this->decimation();
     length_type const m = this->order_;
     length_type const skip = this->skip_;
@@ -95,6 +94,9 @@
     length_type oix = 0;
     length_type i = 0;
 
+    in_block.admit(true);
+    out_block.admit(false);
+
     for (; i < m - skip; ++oix, i += dec)
     {
       // Conceptually this comes second, but it's more convenient
@@ -122,6 +124,10 @@
       this->state_saved_ = new_save;
       this->state_(Domain<1>(new_save)) = input(Domain<1>(start, 1, new_save));
     }
+
+    in_block.release(false);
+    out_block.release(true);
+
     return oix;
   }
 
Index: src/vsip/map.hpp
===================================================================
--- src/vsip/map.hpp	(revision 161463)
+++ src/vsip/map.hpp	(working copy)
@@ -31,17 +31,10 @@
 #include <vsip/core/parallel/global_map.hpp>
 #include <vsip/core/parallel/replicated_map.hpp>
 #include <vsip/core/parallel/subset_map.hpp>
+#include <vsip/core/parallel/block.hpp>
 
-#if VSIP_IMPL_PAR_SERVICE == 1
-#  include <vsip/core/parallel/distributed_block.hpp>
-#elif VSIP_IMPL_PAR_SERVICE == 2
-#  include <vsip/opt/pas/block.hpp>
-#else
-// #  include <vsip/impl/distributed-block.hpp>
-#endif
 
 
-
 /***********************************************************************
   Declarations & Class Definitions
 ***********************************************************************/
@@ -379,7 +372,8 @@
   Dist1 const&            dist1,
   Dist2 const&            dist2)
 VSIP_NOTHROW
-: data_      (new Map_data<Dist0, Dist1, Dist2>(dist0, dist1, dist2)),
+: data_      (new Map_data<Dist0, Dist1, Dist2>(dist0, dist1, dist2),
+	      impl::noincrement),
   dim_       (0)
 {
   // It is necessary that the number of subblocks be less than the
@@ -400,7 +394,8 @@
   Dist1 const&                         dist1,
   Dist2 const&                         dist2)
 VSIP_NOTHROW
-: data_     (new Map_data<Dist0, Dist1, Dist2>(pvec, dist0, dist1, dist2)),
+: data_     (new Map_data<Dist0, Dist1, Dist2>(pvec, dist0, dist1, dist2),
+	     impl::noincrement),
   dim_      (0)
 {
   // It is necessary that the number of subblocks be less than the
Index: tests/iir.cpp
===================================================================
--- tests/iir.cpp	(revision 161463)
+++ tests/iir.cpp	(working copy)
@@ -159,6 +159,20 @@
   float error = error_db(out_iir, out_fir);
 
 #if VERBOSE
+  using vsip::impl::Type_equal;
+  std::cout << "error: " << error
+	    << " " << size << "/" << chunk 
+	    << " "
+	    << (Type_equal<T, int>::value ? "int" :
+		Type_equal<T, float>::value ? "float" :
+		Type_equal<T, double>::value ? "double" :
+		Type_equal<T, std::complex<float> >::value ? "complex<float>" :
+		Type_equal<T, std::complex<double> >::value ? "complex<double>" :
+		"*unknown*")
+
+	    << " " << (State == vsip::state_save ? "state_save" :
+		       State == vsip::state_no_save ? "state_no_save" : "*unknown*")
+	    << std::endl;
   if (error >= -150)
   {
     std::cout << "iir =\n" << out_iir;
Index: tests/threshold.cpp
===================================================================
--- tests/threshold.cpp	(revision 161463)
+++ tests/threshold.cpp	(working copy)
@@ -167,7 +167,9 @@
 
   test_type<float>(16);
   test_type<float>(17);
+#if VSIP_IMPL_TEST_DOUBLE
   test_type<double>(19);
+#endif
   test_type<int>(21);
 
   return 0;
Index: tests/matvec.cpp
===================================================================
--- tests/matvec.cpp	(revision 161463)
+++ tests/matvec.cpp	(working copy)
@@ -497,13 +497,15 @@
   // params: alpha, beta
   Test_gem_types<float>( M_E, VSIP_IMPL_PI );
 
-  Test_gem_types<double>( -M_E, -VSIP_IMPL_PI );
-
   Test_gem_types<complex<float> >
     ( complex<float>(M_LN2, -M_SQRT2), complex<float>(M_LOG2E, M_LN10) );
 
+#if VSIP_IMPL_TEST_DOUBLE
+  Test_gem_types<double>( -M_E, -VSIP_IMPL_PI );
+
   Test_gem_types<complex<double> >
     ( complex<float>(M_LN2, -M_SQRT2), complex<float>(M_LOG2E, M_LN10) );
+#endif
 
 
   // misc functions
@@ -511,7 +513,9 @@
   Test_cumsum();
 
   modulate_cases<float>(10);
+#if VSIP_IMPL_TEST_DOUBLE
   modulate_cases<double>(32);
+#endif
 #if VSIP_IMPL_HAVE_COMPLEX_LONG_DOUBLE && VSIP_IMPL_TEST_LONG_DOUBLE
   modulate_cases<long double>(16);
 #endif
@@ -519,15 +523,17 @@
   Test_outer<float>( static_cast<float>(VSIP_IMPL_PI), 3, 3 );
   Test_outer<float>( static_cast<float>(VSIP_IMPL_PI), 5, 7 );
   Test_outer<float>( static_cast<float>(VSIP_IMPL_PI), 7, 5 );
+  Test_outer<complex<float> >( complex<float>(VSIP_IMPL_PI, M_E), 3, 3 );
+  Test_outer<complex<float> >( complex<float>(VSIP_IMPL_PI, M_E), 5, 7 );
+  Test_outer<complex<float> >( complex<float>(VSIP_IMPL_PI, M_E), 7, 5 );
+#if VSIP_IMPL_TEST_DOUBLE
   Test_outer<double>( static_cast<double>(VSIP_IMPL_PI), 3, 3 );
   Test_outer<double>( static_cast<double>(VSIP_IMPL_PI), 5, 7 );
   Test_outer<double>( static_cast<double>(VSIP_IMPL_PI), 7, 5 );
-  Test_outer<complex<float> >( complex<float>(VSIP_IMPL_PI, M_E), 3, 3 );
-  Test_outer<complex<float> >( complex<float>(VSIP_IMPL_PI, M_E), 5, 7 );
-  Test_outer<complex<float> >( complex<float>(VSIP_IMPL_PI, M_E), 7, 5 );
   Test_outer<complex<double> >( complex<double>(VSIP_IMPL_PI, M_E), 3, 3 );
   Test_outer<complex<double> >( complex<double>(VSIP_IMPL_PI, M_E), 5, 7 );
   Test_outer<complex<double> >( complex<double>(VSIP_IMPL_PI, M_E), 7, 5 );
+#endif
 
   return 0;
 }
Index: tests/fir.cpp
===================================================================
--- tests/fir.cpp	(revision 161549)
+++ tests/fir.cpp	(working copy)
@@ -14,8 +14,12 @@
   Included Files
 ***********************************************************************/
 
-#include <iostream>
-#include <iomanip>
+#define VERBOSE 0
+
+#if VERBOSE
+#  include <iostream>
+#  include <iomanip>
+#endif
 #include <cmath>
 
 #include <vsip/initfin.hpp>
@@ -25,7 +29,9 @@
 #include <vsip/matrix.hpp>
 
 #include <vsip_csl/test.hpp>
-#include <vsip_csl/output.hpp>
+#if VERBOSE
+#  include <vsip_csl/output.hpp>
+#endif
 
 using namespace vsip_csl;
 
@@ -153,6 +159,26 @@
 
   test_assert(outsize - got <= 1);
   double error = error_db(result, reference);
+#if VERBOSE
+  using vsip::impl::Type_equal;
+  std::cout << "error: " << error
+	    << " " << D << "/" << M << "/" << N
+	    << " "
+	    << (Type_equal<T, float>::value ? "float" :
+		Type_equal<T, double>::value ? "double" :
+		Type_equal<T, std::complex<float> >::value ? "complex<float>" :
+		Type_equal<T, std::complex<double> >::value ? "complex<double>" :
+		"*unknown*")
+
+	    << " " << (sym == vsip::sym_even_len_even ? "even" :
+		       sym == vsip::sym_even_len_odd ? "odd" : "nonsym")
+	    << std::endl;
+  if (error >= -100)
+  {
+    std::cout << "result: " << result;
+    std::cout << "reference: " << reference;
+  }
+#endif
   test_assert(error < -100);
 
   test_assert(got1b == got2);
@@ -179,11 +205,13 @@
   test_fir<float,vsip::nonsym>(2,23,31);
   test_fir<float,vsip::nonsym>(2,32,1024);
 
+#if VSIP_IMPL_TEST_DOUBLE
   test_fir<double,vsip::nonsym>(2,3,5);
   test_fir<double,vsip::nonsym>(2,3,9);
   test_fir<double,vsip::nonsym>(2,4,8);
   test_fir<double,vsip::nonsym>(2,23,31);
   test_fir<double,vsip::nonsym>(2,32,1024);
+#endif
 
   test_fir<std::complex<float>,vsip::nonsym>(2,3,5);
   test_fir<std::complex<float>,vsip::nonsym>(2,3,9);
@@ -191,11 +219,13 @@
   test_fir<std::complex<float>,vsip::nonsym>(2,23,31);
   test_fir<std::complex<float>,vsip::nonsym>(2,32,1024);
 
+#if VSIP_IMPL_TEST_DOUBLE
   test_fir<std::complex<double>,vsip::nonsym>(2,3,5);
   test_fir<std::complex<double>,vsip::nonsym>(2,3,9);
   test_fir<std::complex<double>,vsip::nonsym>(2,4,8);
   test_fir<std::complex<double>,vsip::nonsym>(2,23,31);
   test_fir<std::complex<double>,vsip::nonsym>(2,32,1024);
+#endif
 
   test_fir<float,vsip::nonsym>(3,4,8);
   test_fir<float,vsip::nonsym>(3,4,21);
Index: tests/matvec-dot.cpp
===================================================================
--- tests/matvec-dot.cpp	(revision 161463)
+++ tests/matvec-dot.cpp	(working copy)
@@ -130,16 +130,20 @@
 dot_types()
 {
   dot_cases<float,  float>();
-  dot_cases<float,  double>();
-  dot_cases<double, float>();
-  dot_cases<double, double>();
 
   dot_cases<complex<float>, complex<float> >();
   dot_cases<float,          complex<float> >();
   dot_cases<complex<float>, float>();
 
   cvjdot_cases<complex<float>,  complex<float> >();
+
+#if VSIP_IMPL_TEST_DOUBLE
+  dot_cases<float,  double>();
+  dot_cases<double, float>();
+  dot_cases<double, double>();
+
   cvjdot_cases<complex<double>, complex<double> >();
+#endif
 }
 
 
Index: tests/parallel/subset_map.cpp
===================================================================
--- tests/parallel/subset_map.cpp	(revision 161463)
+++ tests/parallel/subset_map.cpp	(working copy)
@@ -607,7 +607,7 @@
   Map<> x_map(nr, nc);
 
 
-#if 1
+#if VSIP_IMPL_TEST_LEVEL >= 0
   // examples of simple testcases -- easier to debug
   test_src<float, 2>(root,  r_map, 8, 8,
 		     Domain<2>(Domain<1>(0, 2, 4), Domain<1>(0, 2, 4)));
@@ -617,7 +617,7 @@
 		     Domain<2>(Domain<1>(0, 1, 4), Domain<1>(0, 1, 4)));
 #endif
 
-#if 1
+#if VSIP_IMPL_TEST_LEVEL >= 2
   test_map_combinations<float, SrcTag>();
   test_map_combinations<float, DstTag>();
 
Index: tests/parallel/fftm.cpp
===================================================================
--- tests/parallel/fftm.cpp	(revision 161463)
+++ tests/parallel/fftm.cpp	(working copy)
@@ -527,7 +527,7 @@
   test<float>();
 #endif
 
-#if defined(VSIP_IMPL_FFT_USE_DOUBLE)
+#if defined(VSIP_IMPL_FFT_USE_DOUBLE) && VSIP_IMPL_TEST_DOUBLE
   test<double>();
 #endif
 
Index: tests/fft.cpp
===================================================================
--- tests/fft.cpp	(revision 161463)
+++ tests/fft.cpp	(working copy)
@@ -1082,7 +1082,7 @@
   test_1d<float>();
 #endif 
 
-#if VSIP_IMPL_PROVIDE_FFT_DOUBLE
+#if VSIP_IMPL_PROVIDE_FFT_DOUBLE && VSIP_IMPL_TEST_DOUBLE
   test_1d<double>();
 #endif 
 
@@ -1101,7 +1101,7 @@
   test_nd<float>();
 #endif 
 
-#if VSIP_IMPL_PROVIDE_FFT_DOUBLE
+#if VSIP_IMPL_PROVIDE_FFT_DOUBLE && VSIP_IMPL_TEST_DOUBLE
   test_nd<double>();
 #endif
 
Index: tests/matvec-prod.cpp
===================================================================
--- tests/matvec-prod.cpp	(revision 161463)
+++ tests/matvec-prod.cpp	(working copy)
@@ -663,10 +663,12 @@
 prod_special_cases()
 {
   test_mm_prod_subview<float>(5, 7, 3);
+  test_mm_prod_complex_split<float>(5, 7, 3);
+
+#if VSIP_IMPL_TEST_DOUBLE
   test_mm_prod_subview<double>(5, 7, 3);
-
-  test_mm_prod_complex_split<float>(5, 7, 3);
   test_mm_prod_complex_split<double>(5, 7, 3);
+#endif
 }
 
 
@@ -689,15 +691,19 @@
 
 
   prod_cases<float,  float>();
-  prod_cases<double, double>();
-  prod_cases<float,  double>();
-  prod_cases<double, float>();
+
   prod_cases<complex<float>, complex<float> >();
   prod_cases<float,          complex<float> >();
   prod_cases<complex<float>, float          >();
 
   prod_cases_complex_only<complex<float>, complex<float> >();
 
+#if VSIP_IMPL_TEST_DOUBLE
+  prod_cases<double, double>();
+  prod_cases<float,  double>();
+  prod_cases<double, float>();
+#endif
+
   prod_special_cases();
 
   // Test a large matrix-matrix product (order > 80) to trigger
Index: configure.ac
===================================================================
--- configure.ac	(revision 161566)
+++ configure.ac	(working copy)
@@ -157,6 +157,11 @@
                  [Set PAS heap size.  Default is 0x100000]),,
   [enable_pas_heap_size=0x100000])
 
+AC_ARG_ENABLE([pas_share_dynamic_xfer],
+  AS_HELP_STRING([--enable-pas-share-dynamice-xfer],
+                 [Share a PAS dynamic xfer object. Default is not to.]),,
+  [enable_pas_share_dynamic_xfer=no])
+
 ### Mercury Scientific Algorithm (SAL)
 AC_ARG_ENABLE([sal],
   AS_HELP_STRING([--enable-sal],
@@ -1070,7 +1075,16 @@
     vsipl_par_service=2
     PAR_SERVICE=pas
     AC_DEFINE_UNQUOTED(VSIP_IMPL_PAS_HEAP_SIZE, $enable_pas_heap_size,
-    [Define the heap size used inside the PAS backend.])
+       [Define the heap size used inside the PAS backend.])
+
+    if test $enable_pas_share_dynamic_xfer = "yes"; then
+      enable_pas_share_dynamic_xfer=1
+    else
+      enable_pas_share_dynamic_xfer=0
+    fi
+    AC_DEFINE_UNQUOTED(VSIP_IMPL_PAS_SHARE_DYNAMIC_XFER,
+       $enable_pas_share_dynamic_xfer,
+       [Define to 1 to share a dynamic_xfer object, 0 otherwise.])
   fi
 
 elif test "$enable_mpi" != "no"; then
Index: tests/ref-impl/dense.cpp
===================================================================
--- tests/ref-impl/dense.cpp	(revision 161463)
+++ tests/ref-impl/dense.cpp	(working copy)
@@ -77,9 +77,9 @@
 
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	v;
+  vsip::vsipl	init(argc, argv);
 
   test_mutable_refcount();
 
Index: tests/ref-impl/admitrelease.cpp
===================================================================
--- tests/ref-impl/admitrelease.cpp	(revision 161463)
+++ tests/ref-impl/admitrelease.cpp	(working copy)
@@ -412,9 +412,9 @@
 
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	v;
+  vsip::vsipl	init(argc, argv);
 
   test_1_scalar<scalar_f>();
   test_1_scalar<scalar_i>();
Index: tests/ref-impl/vector.cpp
===================================================================
--- tests/ref-impl/vector.cpp	(revision 161463)
+++ tests/ref-impl/vector.cpp	(working copy)
@@ -94,9 +94,9 @@
 
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	ignored;
+  vsip::vsipl	init(argc, argv);
 
   test_real_subview();
   test_imag_subview();
Index: tests/ref-impl/matrix.cpp
===================================================================
--- tests/ref-impl/matrix.cpp	(revision 161463)
+++ tests/ref-impl/matrix.cpp	(working copy)
@@ -75,9 +75,9 @@
 
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	ignored;
+  vsip::vsipl	init(argc, argv);
 
   test_complex_subview();
 
Index: tests/ref-impl/signal-histogram.cpp
===================================================================
--- tests/ref-impl/signal-histogram.cpp	(revision 161463)
+++ tests/ref-impl/signal-histogram.cpp	(working copy)
@@ -40,11 +40,11 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
   using namespace vsip;
 
-  vsipl		v;
+  vsipl		v(argc, argv);
 
   const length_type
 		len = 25;
Index: tests/ref-impl/solvers-qr.cpp
===================================================================
--- tests/ref-impl/solvers-qr.cpp	(revision 161463)
+++ tests/ref-impl/solvers-qr.cpp	(working copy)
@@ -40,11 +40,11 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
   using namespace vsip;
 
-  vsipl v;
+  vsipl	v(argc, argv);
 
   /* Create a matrix to decompose.  */
 
Index: tests/ref-impl/signal.cpp
===================================================================
--- tests/ref-impl/signal.cpp	(revision 161463)
+++ tests/ref-impl/signal.cpp	(working copy)
@@ -41,11 +41,11 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
   using namespace vsip;
 
-  vsipl		v;
+  vsipl	v(argc, argv);
 
 #if 0 /* tvcpp0p8 VSIPL does not implement freqswap.  */
   /* Test freqswap.  */
Index: tests/ref-impl/random.cpp
===================================================================
--- tests/ref-impl/random.cpp	(revision 161463)
+++ tests/ref-impl/random.cpp	(working copy)
@@ -38,11 +38,11 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
   using namespace vsip;
 
-  vsipl v;
+  vsipl		v(argc, argv);
 
   /* Create some random number generators.  */
 
Index: tests/ref-impl/dim-order.cpp
===================================================================
--- tests/ref-impl/dim-order.cpp	(revision 161463)
+++ tests/ref-impl/dim-order.cpp	(working copy)
@@ -193,9 +193,9 @@
 
 // -------------------------------------------------------------------- //
 int
-main ()
+main (int argc, char** argv)
 {
-   vsipl	ignored;
+   vsip::vsipl	init(argc, argv);
 
    test_1<scalar_f, row2_type>();
    test_1<scalar_f, col2_type>();
Index: tests/ref-impl/math-scalarview.cpp
===================================================================
--- tests/ref-impl/math-scalarview.cpp	(revision 161463)
+++ tests/ref-impl/math-scalarview.cpp	(working copy)
@@ -42,11 +42,11 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
   using namespace vsip;
 
-  vsipl	ignored;
+  vsipl		init(argc, argv);
 
   /* Test multiplication.  */
   cscalar_f const
Index: tests/ref-impl/vector-math.cpp
===================================================================
--- tests/ref-impl/vector-math.cpp	(revision 161463)
+++ tests/ref-impl/vector-math.cpp	(working copy)
@@ -45,9 +45,9 @@
 
 // -------------------------------------------------------------------- //
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	ignored;
+  vsip::vsipl	init(argc, argv);
   vsip::Vector<vsip::scalar_f>
 		vector_scalarf (7, 3.4);
   vsip::Vector<vsip::cscalar_f>
Index: tests/ref-impl/signal-fft.cpp
===================================================================
--- tests/ref-impl/signal-fft.cpp	(revision 161463)
+++ tests/ref-impl/signal-fft.cpp	(working copy)
@@ -41,9 +41,9 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	v;
+  vsip::vsipl	v(argc, argv);
 
   /* Begin testing of FFTs.  Check only for compilation and execution,
      not actual values.  */
Index: tests/ref-impl/signal-convolution.cpp
===================================================================
--- tests/ref-impl/signal-convolution.cpp	(revision 161463)
+++ tests/ref-impl/signal-convolution.cpp	(working copy)
@@ -48,10 +48,10 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
   using namespace vsip;
-  vsipl		v;
+  vsipl		v(argc, argv);
 
   /* Begin testing of convolutions.  */
 
Index: tests/ref-impl/ortho.cpp
===================================================================
--- tests/ref-impl/ortho.cpp	(revision 0)
+++ tests/ref-impl/ortho.cpp	(revision 0)
@@ -0,0 +1,354 @@
+/***********************************************************************
+
+  File:   ortho.cpp
+  Author: Jules Bergmann, CodeSourcery, LLC.
+  Date:   12/04/2005
+
+  Contents: Tests for Cottel issues
+
+Copyright 2005 Georgia Tech Research Corporation, all rights reserved.
+
+A non-exclusive, non-royalty bearing license is hereby granted to all
+Persons to copy, distribute and produce derivative works for any
+purpose, provided that this copyright notice and following disclaimer
+appear on All copies: THIS LICENSE INCLUDES NO WARRANTIES, EXPRESSED
+OR IMPLIED, WHETHER ORAL OR WRITTEN, WITH RESPECT TO THE SOFTWARE OR
+OTHER MATERIAL INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES
+OF MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE, OR ARISING
+FROM A COURSE OF PERFORMANCE OR DEALING, OR FROM USAGE OR TRADE, OR OF
+NON-INFRINGEMENT OF ANY PATENTS OF THIRD PARTIES. THE INFORMATION IN
+THIS DOCUMENT SHOULD NOT BE CONSTRUED AS A COMMITMENT OF DEVELOPMENT
+BY ANY OF THE ABOVE PARTIES.
+
+The US Government has a license under these copyrights, and this
+Material may be reproduced by or for the US Government.
+***********************************************************************/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <cstdlib>
+#include <vsip/domain.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+
+#include "test.hpp"
+#include "test-util.hpp"
+
+using namespace vsip;
+
+
+template <dimension_type Dim,
+	  typename       T>
+class ViewOfDim;
+
+template <typename T>
+class ViewOfDim<1, T>
+{
+public:
+   typedef Vector<T> type;
+
+   ViewOfDim(length_type N)        : view(N) {}
+   ViewOfDim(length_type N, T val) : view(N, val) {}
+
+public:
+   type view;
+};
+
+template <typename T>
+class ViewOfDim<2, T>
+{
+public:
+   typedef Matrix<T> type;
+
+   ViewOfDim(length_type N)        : view(N, N) {}
+   ViewOfDim(length_type N, T val) : view(N, N, val) {}
+
+public:
+   type view;
+};
+
+
+/***********************************************************************
+  Function Definitions
+***********************************************************************/
+
+// Test 'view = scalar' assignment (Issue #2)
+
+template <dimension_type Dim,
+	  typename       T>
+void
+test_view_scalar_assn(T const& val1, T const& val2)
+{
+   length_type N = 5;
+
+   ViewOfDim<Dim, T> view(N, val1);
+
+   for (index_type i=0; i<view.view.size(); ++i)
+      insist(equal(get_nth(view.view, i), val1));
+
+   view.view = val2;
+
+   for (index_type i=0; i<view.view.size(); ++i)
+      insist(equal(get_nth(view.view, i), val2));
+}
+
+
+
+// Test 'view op= scalar' assignment (Issue #3)
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2>
+void
+test_view_op_assn(T1 const& val1, T2 const& val2)
+{
+   length_type N = 5;
+
+   ViewOfDim<Dim, T1> view(N, val1);
+
+   for (index_type i=0; i<view.view.size(); ++i)
+      insist(equal(get_nth(view.view, i), val1));
+
+   // test +=
+
+   view.view += val2;
+
+   for (index_type i=0; i<view.view.size(); ++i)
+      insist(equal(get_nth(view.view, i), val1 + val2));
+
+   // test -=
+
+   view.view = val1;
+   view.view -= val2;
+
+   for (index_type i=0; i<view.view.size(); ++i)
+      insist(equal(get_nth(view.view, i), val1 - val2));
+
+   // test *=
+
+   view.view = val1;
+   view.view *= val2;
+
+   for (index_type i=0; i<view.view.size(); ++i)
+      insist(equal(get_nth(view.view, i), val1 * val2));
+
+   // test /=
+
+   view.view = val1;
+   view.view /= val2;
+
+   for (index_type i=0; i<view.view.size(); ++i)
+      insist(equal(get_nth(view.view, i), val1 / val2));
+}
+
+
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2>
+void
+test_add(T1 const& val1, T2 const& val2)
+{
+   typedef typename Promotion<T1, T2>::type RT;
+
+   length_type N = 5;
+
+   ViewOfDim<Dim, T1> view1(N, val1);
+   ViewOfDim<Dim, T2> view2(N, val2);
+   ViewOfDim<Dim, RT> viewR(N, RT());
+
+   RT valR = vsip::add(val1, val2);
+
+   viewR.view = view1.view + view2.view;
+
+   for (index_type i=0; i<viewR.view.size(); ++i)
+      insist(equal(get_nth(viewR.view, i), valR));
+}
+
+
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2>
+void
+test_sub(T1 const& val1, T2 const& val2)
+{
+   typedef typename Promotion<T1, T2>::type RT;
+
+   length_type N = 5;
+
+   ViewOfDim<Dim, T1> view1(N, val1);
+   ViewOfDim<Dim, T2> view2(N, val2);
+   ViewOfDim<Dim, RT> viewR(N, RT());
+
+   RT valR = vsip::sub(val1, val2);
+
+   viewR.view = view1.view - view2.view;
+
+   for (index_type i=0; i<viewR.view.size(); ++i)
+      insist(equal(get_nth(viewR.view, i), valR));
+}
+
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2>
+void
+test_mul(T1 const& val1, T2 const& val2)
+{
+   typedef typename Promotion<T1, T2>::type RT;
+
+   length_type N = 5;
+
+   ViewOfDim<Dim, T1> view1(N, val1);
+   ViewOfDim<Dim, T2> view2(N, val2);
+   ViewOfDim<Dim, RT> viewR(N, RT());
+
+   RT valR = vsip::mul(val1, val2);
+
+   viewR.view = view1.view * view2.view;
+
+   for (index_type i=0; i<viewR.view.size(); ++i)
+      insist(equal(get_nth(viewR.view, i), valR));
+}
+
+
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2>
+void
+test_div(T1 const& val1, T2 const& val2)
+{
+   typedef typename Promotion<T1, T2>::type RT;
+
+   length_type N = 5;
+
+   ViewOfDim<Dim, T1> view1(N, val1);
+   ViewOfDim<Dim, T2> view2(N, val2);
+   ViewOfDim<Dim, RT> viewR(N, RT());
+
+   RT valR = vsip::div(val1, val2);
+
+   viewR.view = view1.view / view2.view;
+
+   for (index_type i=0; i<viewR.view.size(); ++i)
+      insist(equal(get_nth(viewR.view, i), valR));
+}
+
+
+
+template <dimension_type Dim,
+	  typename       T>
+void
+test_neg(T const& val1)
+{
+   length_type N = 5;
+
+   ViewOfDim<Dim, T> view1(N, val1);
+   ViewOfDim<Dim, T> viewR(N, T());
+
+   T valR = vsip::neg(val1);
+
+   viewR.view = -view1.view;
+
+   for (index_type i=0; i<viewR.view.size(); ++i)
+      insist(equal(get_nth(viewR.view, i), valR));
+}
+
+
+
+int
+main (int argc, char** argv)
+{
+  vsip::vsipl	init(argc, argv);
+
+  // Issue #2 ---------------------------------------------------------	//
+  // Pre-existing cases.
+  test_view_scalar_assn<1, scalar_f>(1.f, 2.f);
+  test_view_scalar_assn<1, scalar_i>(1, 2);
+  test_view_scalar_assn<1, cscalar_f>(1.f, 2.f);
+  test_view_scalar_assn<2, scalar_f>(1.f, 2.f);
+  test_view_scalar_assn<2, scalar_i>(1, 2);
+  test_view_scalar_assn<2, cscalar_f>(1.f, 2.f);
+
+  // New, orthoganol functionality.
+  test_view_scalar_assn<1, bool>(true, false);
+  test_view_scalar_assn<1, index_type>(1, 2);
+  test_view_scalar_assn<1, Index<1> >(Index<1>(1), Index<1>(2));
+  test_view_scalar_assn<1, Index<2> >(Index<2>(1, 2), Index<2>(3, 4));
+  test_view_scalar_assn<2, bool>(true, false);
+
+  // Not supported. (tvcpp doesn't provide cscalar_i vector)
+  // test_view_scalar_assn<1, cscalar_i>(); 
+  // test_view_scalar_assn<2, cscalar_i>(); 
+
+
+  // Issue #3 ---------------------------------------------------------	//
+  // Pre-existing cases.
+  // (Note: cscalar_f /= cscalar_f wasn't implemented)
+  test_view_op_assn<1, cscalar_f,  scalar_f>(cscalar_f(1.f, 2.f), 2.f);
+  test_view_op_assn<1, cscalar_f, cscalar_f>(cscalar_f(1.f, 3.f),
+					     cscalar_f(2.f, 0.f));
+  test_view_op_assn<2, cscalar_f,  scalar_f>(cscalar_f(1.f, 2.f), 2.f);
+  test_view_op_assn<2, cscalar_f, cscalar_f>(cscalar_f(1.f, 3.f),
+					     cscalar_f(2.f, 0.f));
+
+  // cscalar_i not supported by tvcpp
+
+  // Issue #X ---------------------------------------------------------	//
+  test_add<1,  scalar_i,  scalar_i>(1, 2);
+  test_add<1,  scalar_f,  scalar_f>(1.f, 2.f);
+  test_add<1,  scalar_f, cscalar_f>(1.f, 2.f);
+  test_add<1, cscalar_f,  scalar_f>(1.f, 2.f);	// New case.
+  test_add<1, cscalar_f, cscalar_f>(1.f, 2.f);
+
+  test_add<2,  scalar_i,  scalar_i>(1, 2);	// New case.
+  test_add<2,  scalar_f,  scalar_f>(1.f, 2.f);
+  test_add<2,  scalar_f, cscalar_f>(1.f, 2.f);
+  test_add<2, cscalar_f,  scalar_f>(1.f, 2.f);	// New case.
+  test_add<2, cscalar_f, cscalar_f>(1.f, 2.f);
+
+  test_sub<1,  scalar_i,  scalar_i>(1, 2);
+  test_sub<1,  scalar_f,  scalar_f>(1.f, 2.f);
+  test_sub<1,  scalar_f, cscalar_f>(1.f, 2.f);
+  test_sub<1, cscalar_f,  scalar_f>(1.f, 2.f);	// New case.
+  test_sub<1, cscalar_f, cscalar_f>(1.f, 2.f);
+
+  test_sub<2,  scalar_i,  scalar_i>(1, 2);	// New case.
+  test_sub<2,  scalar_f,  scalar_f>(1.f, 2.f);
+  test_sub<2,  scalar_f, cscalar_f>(1.f, 2.f);
+  test_sub<2, cscalar_f,  scalar_f>(1.f, 2.f);	// New case.
+  test_sub<2, cscalar_f, cscalar_f>(1.f, 2.f);
+
+  test_mul<1,  scalar_f,  scalar_f>(1.f, 2.f);
+  test_mul<1,  scalar_f, cscalar_f>(1.f, 2.f);
+  test_mul<1, cscalar_f,  scalar_f>(1.f, 2.f);	// New case.
+  test_mul<1, cscalar_f, cscalar_f>(1.f, 2.f);
+
+  test_mul<2,  scalar_f,  scalar_f>(1.f, 2.f);
+  test_mul<2,  scalar_f, cscalar_f>(1.f, 2.f);
+  test_mul<2, cscalar_f,  scalar_f>(1.f, 2.f);	// New case.
+  test_mul<2, cscalar_f, cscalar_f>(1.f, 2.f);
+
+  test_div<1,  scalar_f,  scalar_f>(1.f, 2.f);
+  test_div<1,  scalar_f, cscalar_f>(1.f, 2.f);
+  test_div<1, cscalar_f,  scalar_f>(1.f, 2.f);
+  test_div<1, cscalar_f, cscalar_f>(1.f, 2.f);
+
+  test_div<2,  scalar_f,  scalar_f>(1.f, 2.f);
+  test_div<2,  scalar_f, cscalar_f>(1.f, 2.f);
+  test_div<2, cscalar_f,  scalar_f>(1.f, 2.f);
+  test_div<2, cscalar_f, cscalar_f>(1.f, 2.f);
+
+  test_neg<1,  scalar_i>(1);
+  test_neg<1,  scalar_f>(1.f);
+  test_neg<1, cscalar_f>(1.f);
+  test_neg<2,  scalar_i>(1); // New case.
+  test_neg<2,  scalar_f>(1.f);
+  test_neg<2, cscalar_f>(1.f);
+
+  return EXIT_SUCCESS;
+}
Index: tests/ref-impl/matrix-math.cpp
===================================================================
--- tests/ref-impl/matrix-math.cpp	(revision 161463)
+++ tests/ref-impl/matrix-math.cpp	(working copy)
@@ -41,9 +41,9 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	ignored;
+  vsip::vsipl	init(argc, argv);
   vsip::Matrix<>
 		matrix_scalarf (7, 3, 3.4); 
   check_entry (matrix_scalarf, 1, 1, static_cast<vsip::scalar_f>(3.4));
Index: tests/ref-impl/solvers-covsol.cpp
===================================================================
--- tests/ref-impl/solvers-covsol.cpp	(revision 161463)
+++ tests/ref-impl/solvers-covsol.cpp	(working copy)
@@ -75,10 +75,10 @@
 }
 
 int
-main ()
+main (int argc, char** argv)
 {
 
-  vsip::vsipl v;
+  vsip::vsipl v(argc, argv);
   vsip::Rand<cscalar_f> R(1);
 
   scalar_f w_background = 0.01f;
Index: tests/ref-impl/view-math.cpp
===================================================================
--- tests/ref-impl/view-math.cpp	(revision 161463)
+++ tests/ref-impl/view-math.cpp	(working copy)
@@ -1681,9 +1681,9 @@
 
 // -------------------------------------------------------------------- //
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	ignored;
+  vsip::vsipl	init(argc, argv);
   vsip::Vector<vsip::scalar_f>
 		vector_scalarf (7, 3.4);
   vsip::Vector<vsip::cscalar_f>
Index: tests/ref-impl/signal-windows.cpp
===================================================================
--- tests/ref-impl/signal-windows.cpp	(revision 161463)
+++ tests/ref-impl/signal-windows.cpp	(working copy)
@@ -96,9 +96,9 @@
 
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	v;
+  vsip::vsipl	v(argc, argv);
 
   const vsip::length_type
 		len = 32;
Index: tests/ref-impl/math-matvec.cpp
===================================================================
--- tests/ref-impl/math-matvec.cpp	(revision 161463)
+++ tests/ref-impl/math-matvec.cpp	(working copy)
@@ -66,9 +66,9 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	ignored;
+  vsip::vsipl	init(argc, argv);
 
   vsip::Vector<vsip::cscalar_f>
 		vector_cscalarf (2, vsip::cscalar_f (1.0, 17.0));
Index: tests/ref-impl/math-reductions.cpp
===================================================================
--- tests/ref-impl/math-reductions.cpp	(revision 161463)
+++ tests/ref-impl/math-reductions.cpp	(working copy)
@@ -101,9 +101,9 @@
 
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	ignored;
+  vsip::vsipl	init(argc, argv);
 
 
   vsip::Vector<bool>
Index: tests/ref-impl/complex.cpp
===================================================================
--- tests/ref-impl/complex.cpp	(revision 161463)
+++ tests/ref-impl/complex.cpp	(working copy)
@@ -99,9 +99,9 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	v;
+  vsip::vsipl	init(argc, argv);
 
   // Test the creation of three complex numbers.
   vsip::cscalar_f a (static_cast<vsip::scalar_f>(2.0));
Index: tests/ref-impl/fft-coverage.cpp
===================================================================
--- tests/ref-impl/fft-coverage.cpp	(revision 161551)
+++ tests/ref-impl/fft-coverage.cpp	(working copy)
@@ -677,9 +677,9 @@
 
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	v;
+  vsip::vsipl	init(argc, argv);
 
   // For FFTW, alg_time causes each FFTW plan to MEASURE, which is
   // expensive, esp since we're only doing a small number of FFTs with
Index: tests/ref-impl/solvers-lu.cpp
===================================================================
--- tests/ref-impl/solvers-lu.cpp	(revision 161463)
+++ tests/ref-impl/solvers-lu.cpp	(working copy)
@@ -41,11 +41,11 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
   using namespace vsip;
 
-  vsipl v;
+  vsipl	v(argc, argv);
 
   /* Create a matrix to decompose.  */
 
Index: tests/ref-impl/selgen.cpp
===================================================================
--- tests/ref-impl/selgen.cpp	(revision 161463)
+++ tests/ref-impl/selgen.cpp	(working copy)
@@ -174,9 +174,9 @@
 
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	v;
+  vsip::vsipl	v(argc, argv);
 
   /* Begin testing of first ().  */
 
Index: tests/ref-impl/solvers-chol.cpp
===================================================================
--- tests/ref-impl/solvers-chol.cpp	(revision 161463)
+++ tests/ref-impl/solvers-chol.cpp	(working copy)
@@ -40,11 +40,11 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
   using namespace vsip;
 
-  vsipl v;
+  vsipl	v(argc, argv);
 
   /* Create a matrix to decompose.  */
 
Index: tests/ref-impl/vector-const.cpp
===================================================================
--- tests/ref-impl/vector-const.cpp	(revision 161463)
+++ tests/ref-impl/vector-const.cpp	(working copy)
@@ -532,9 +532,9 @@
 
 // -------------------------------------------------------------------- //
 int
-main ()
+main (int argc, char** argv)
 {
-   vsipl	ignored;
+  vsip::vsipl	init(argc, argv);
 
    test_put_get_Vector();
    test_put_get_const_Vector();
Index: tests/ref-impl/matrix-const.cpp
===================================================================
--- tests/ref-impl/matrix-const.cpp	(revision 161463)
+++ tests/ref-impl/matrix-const.cpp	(working copy)
@@ -554,9 +554,9 @@
 
 // -------------------------------------------------------------------- //
 int
-main ()
+main (int argc, char** argv)
 {
-   vsipl	ignored;
+   vsipl	init(argc, argv);
 
    test_put_get_Matrix();
    test_put_get_const_Matrix();
Index: tests/ref-impl/math.cpp
===================================================================
--- tests/ref-impl/math.cpp	(revision 161463)
+++ tests/ref-impl/math.cpp	(working copy)
@@ -39,9 +39,9 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	ignored;
+  vsip::vsipl	init(argc, argv);
 
   /* Test acos.  */
   insist (equal (vsip::acos (static_cast<vsip::scalar_f>(1.0)),
Index: tests/ref-impl/signal-fir.cpp
===================================================================
--- tests/ref-impl/signal-fir.cpp	(revision 161551)
+++ tests/ref-impl/signal-fir.cpp	(working copy)
@@ -76,9 +76,9 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
-  vsip::vsipl	v;
+  vsip::vsipl	v(argc, argv);
 
   /* Begin testing of Fir.  */
 
Index: tests/ref-impl/signal-correlation.cpp
===================================================================
--- tests/ref-impl/signal-correlation.cpp	(revision 161463)
+++ tests/ref-impl/signal-correlation.cpp	(working copy)
@@ -48,10 +48,10 @@
 ***********************************************************************/
 
 int
-main ()
+main (int argc, char** argv)
 {
   using namespace vsip;
-  vsipl		v;
+  vsipl		v(argc, argv);
 
   /* Begin testing of correlations.  */
 
