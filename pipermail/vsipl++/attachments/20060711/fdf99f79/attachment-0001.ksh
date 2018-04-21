Index: src/vsip/profile.cpp
===================================================================
--- src/vsip/profile.cpp	(revision 144413)
+++ src/vsip/profile.cpp	(working copy)
@@ -150,10 +150,15 @@
     accum_type::iterator pos = accum_.find(name);
     if (pos == accum_.end())
     {
-      accum_.insert(std::make_pair(name, Accum_entry(TP::zero(), 0)));
+      accum_.insert(std::make_pair(name, Accum_entry(TP::zero(), 0, value)));
       pos = accum_.find(name);
     }
 
+    // 'open_id' determines if it is entering scope or exiting scope.  This 
+    // allows it to work with the Scope_event class, which calls it with 0
+    // in it's constructor (usually placed at the beginning of a function body)
+    // and with a non-zero value in it's destructor.  The net result is that
+    // it accumulates time when it is alive.
     if (open_id == 0)
       pos->second.total = TP::sub(pos->second.total, stamp);
     else
@@ -161,7 +166,10 @@
       pos->second.total = TP::add(pos->second.total, stamp);
       pos->second.count++;
     }
-    return 0;
+    // a non-zero value is returned for the benefit of the Scope_event class,
+    // which turns around and passes it back as the 'open_id' parameter in 
+    // order to indicate the event is going out of scope.
+    return 1;
   }
   return 0;
 }
@@ -171,6 +179,7 @@
 Profiler::dump(char* filename, char /*mode*/)
 {
   std::ofstream    file;
+  const char delim[] = " : ";
 
   file.open(filename);
 
@@ -179,16 +188,20 @@
     file << "# mode: pm_trace" << std::endl;
     file << "# timer: " << TP::name() << std::endl;
     file << "# clocks_per_sec: " << TP::ticks(TP::clocks_per_sec) << std::endl;
+    file << "# " << std::endl;
+    file << "# index" << delim << "tag" << delim << "ticks" << delim << "open id" 
+         << delim << "op count" << std::endl;
 
     typedef trace_type::iterator iterator;
 
     for (iterator cur = data_.begin(); cur != data_.end(); ++cur)
     {
-      file << (*cur).idx << ":"
-	   << (*cur).name << ":"
-	   << TP::ticks((*cur).stamp) << ":"
-	   << (*cur).end << ":"
-	   << (*cur).value << std::endl;
+      file << (*cur).idx
+	   << delim << (*cur).name
+	   << delim << TP::ticks((*cur).stamp)
+	   << delim << (*cur).end
+	   << delim << (*cur).value 
+           << std::endl;
     }
     data_.clear();
   }
@@ -197,18 +210,24 @@
     file << "# mode: pm_accum" << std::endl;
     file << "# timer: " << TP::name() << std::endl;
     file << "# clocks_per_sec: " << TP::ticks(TP::clocks_per_sec) << std::endl;
+    file << "# " << std::endl;
+    file << "# tag" << delim << "total ticks" << delim << "num calls" 
+         << delim << "op count" << delim << "mflops" << std::endl;
 
     typedef accum_type::iterator iterator;
 
     for (iterator cur = accum_.begin(); cur != accum_.end(); ++cur)
     {
-      file << (*cur).first << ":"
-	   << TP::ticks((*cur).second.total) << ":"
-	   << (*cur).second.count << std::endl;
-      cur->second.total = TP::zero();
-      cur->second.count = 0;
+      float mflops = (*cur).second.count * (*cur).second.value /
+        (1e6 * TP::seconds((*cur).second.total));
+      file << (*cur).first 
+           << delim << TP::ticks((*cur).second.total)
+           << delim << (*cur).second.count
+           << delim << (*cur).second.value
+           << delim << mflops
+           << std::endl;
     }
-    // accum_.clear();
+    accum_.clear();
   }
   else
   {
Index: src/vsip/impl/signal-conv.hpp
===================================================================
--- src/vsip/impl/signal-conv.hpp	(revision 144413)
+++ src/vsip/impl/signal-conv.hpp	(working copy)
@@ -22,6 +22,7 @@
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/signal-conv-common.hpp>
 #include <vsip/impl/signal-conv-ext.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #if VSIP_IMPL_HAVE_IPP
 #  include <vsip/impl/signal-conv-ipp.hpp>
@@ -78,6 +79,12 @@
 				 typename impl::Choose_conv_impl<dim, T>::type>
 		base_type;
 
+  length_type
+  op_count(length_type kernel_len, length_type output_len)
+  {
+    return kernel_len * output_len *
+      (impl::Ops_info<T>::mul + impl::Ops_info<T>::add);
+  }
 
   // Constructors, copies, assignments, and destructors.
 public:
@@ -110,7 +117,15 @@
     impl_View<V2, Block2, T, dim>       out)
     VSIP_NOTHROW
   {
-    timer_.start();
+    length_type M = this->kernel_size()[0].size();
+    length_type P = this->output_size()[0].size();
+    for (dimension_type d=1; d<dim; ++d)
+      M *= this->kernel_size()[d].size();
+    for (dimension_type d=1; d<dim; ++d)
+      P *= this->output_size()[d].size();
+    int ops = op_count(M, P);
+    impl::profile::Scope_event scope_event("convolve_impl_view", ops);
+    impl::profile::Time_in_scope scope(this->timer_);
     for (dimension_type d=0; d<dim; ++d)
       assert(in.size(d) == this->input_size()[d].size());
 
@@ -119,7 +134,6 @@
 
     convolve(in.impl_view(), out.impl_view());
 
-    timer_.stop();
     return out;
   }
 #else
@@ -131,7 +145,11 @@
     Vector<T, Block2>       out)
     VSIP_NOTHROW
   {
-    timer_.start();
+    length_type const M = this->kernel_size()[0].size();
+    length_type const P = this->output_size()[0].size();
+    int ops = op_count(M, P);
+    impl::profile::Scope_event scope_event("convolve_vector", ops);
+    impl::profile::Time_in_scope scope(this->timer_);
     for (dimension_type d=0; d<dim; ++d)
       assert(in.size(d) == this->input_size()[d].size());
 
@@ -139,7 +157,6 @@
       assert(out.size(d) == this->output_size()[d].size());
 
     convolve(in, out);
-    timer_.stop();
 
     return out;
   }
@@ -152,7 +169,13 @@
     Matrix<T, Block2>       out)
     VSIP_NOTHROW
   {
-    timer_.start();
+    length_type const M = this->kernel_size()[0].size()
+                        * this->kernel_size()[1].size();
+    length_type const P = this->output_size()[0].size()
+                        * this->output_size()[1].size();
+    int ops = op_count(M, P);
+    impl::profile::Scope_event scope_event("convolve_matrix", ops);
+    impl::profile::Time_in_scope scope(this->timer_);
     for (dimension_type d=0; d<dim; ++d)
       assert(in.size(d) == this->input_size()[d].size());
 
@@ -160,7 +183,6 @@
       assert(out.size(d) == this->output_size()[d].size());
 
     convolve(in, out);
-    timer_.stop();
 
     return out;
   }
@@ -170,11 +192,14 @@
   {
     if (!strcmp(what, "mflops"))
     {
-      int count = timer_.count();
-      length_type const M = this->kernel_size()[0].size();
-      length_type const P = this->output_size()[0].size();
-      float ops = 2.f * count * P * M;
-      return ops / (1e6*timer_.total());
+      length_type M = this->kernel_size()[0].size();
+      length_type P = this->output_size()[0].size();
+      for (dimension_type d=1; d<dim; ++d)
+        M *= this->kernel_size()[d].size();
+      for (dimension_type d=1; d<dim; ++d)
+        P *= this->output_size()[d].size();
+      int ops = op_count(M, P);
+      return timer_.count() * ops / (1e6 * timer_.total());
     }
     else if (!strcmp(what, "count"))
     {
Index: src/vsip/impl/signal-corr.hpp
===================================================================
--- src/vsip/impl/signal-corr.hpp	(revision 144413)
+++ src/vsip/impl/signal-corr.hpp	(working copy)
@@ -68,6 +68,13 @@
 				 typename impl::Choose_corr_impl<dim, T>::type>
 		base_type;
 
+  length_type
+  op_count(length_type ref_len, length_type output_len)
+  {
+    return ref_len * output_len * 
+      (impl::Ops_info<T>::mul + impl::Ops_info<T>::add);
+  }
+
   // Constructors, copies, assignments, and destructors.
 public:
   Correlation(Domain<dim> const&   ref_size,
@@ -99,7 +106,11 @@
     Vector<T, Block2>       out)
     VSIP_NOTHROW
   {
-    impl::profile::Scope_timer t(timer_);
+    length_type const M = this->reference_size()[0].size();
+    length_type const P = this->output_size()[0].size();
+    int ops = op_count(M, P);
+    impl::profile::Scope_event scope_event("correlate_vector", ops);
+    impl::profile::Time_in_scope scope(this->timer_);
 
     for (dimension_type d=0; d<dim; ++d)
     {
@@ -124,7 +135,13 @@
     Matrix<T, Block2>       out)
     VSIP_NOTHROW
   {
-    impl::profile::Scope_timer t(timer_);
+    length_type const M = this->reference_size()[0].size()
+                        * this->reference_size()[1].size();
+    length_type const P = this->output_size()[0].size()
+                        * this->output_size()[1].size();
+    int ops = op_count(M, P);
+    impl::profile::Scope_event scope_event("correlate_matrix", ops);
+    impl::profile::Time_in_scope scope(this->timer_);
 
     for (dimension_type d=0; d<dim; ++d)
     {
@@ -142,11 +159,14 @@
   {
     if (!strcmp(what, "mflops"))
     {
-      int count = timer_.count();
-      length_type const M = this->kernel_size()[0].size();
-      length_type const P = this->output_size()[0].size();
-      float ops = 2.f * count * P * M;
-      return ops / (1e6*timer_.total());
+      length_type M = this->reference_size()[0].size();
+      length_type P = this->output_size()[0].size();
+      for (dimension_type d=1; d<dim; ++d)
+        M *= this->reference_size()[d].size();
+      for (dimension_type d=1; d<dim; ++d)
+        P *= this->output_size()[d].size();
+      int ops = op_count(M, P);
+      return timer_.count() * ops / (1e6 * timer_.total());
     }
     else if (!strcmp(what, "count"))
     {
Index: src/vsip/impl/ops_info.hpp
===================================================================
--- src/vsip/impl/ops_info.hpp	(revision 0)
+++ src/vsip/impl/ops_info.hpp	(revision 0)
@@ -0,0 +1,41 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/ops_info.cpp
+    @author  Jules Bergmann
+    @date    2005-07-11
+    @brief   VSIPL++ Library: Operation
+
+*/
+
+#ifndef VSIP_IMPL_OPS_INFO_HPP
+#define VSIP_IMPL_OPS_INFO_HPP
+
+#include <complex>
+
+namespace vsip
+{
+namespace impl
+{
+
+template <typename T>
+struct Ops_info
+{
+  static unsigned int const div = 1;
+  static unsigned int const sqr = 1;
+  static unsigned int const mul = 1;
+  static unsigned int const add = 1;
+};
+
+template <typename T>
+struct Ops_info<std::complex<T> >
+{
+  static unsigned int const div = 6 + 3 + 2; // mul + add + div
+  static unsigned int const sqr = 2 + 1;     // mul + add
+  static unsigned int const mul = 4 + 2;     // mul + add
+  static unsigned int const add = 2;
+};
+
+} // namespace impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_OPS_INFO_HPP
Index: src/vsip/impl/fft.hpp
===================================================================
--- src/vsip/impl/fft.hpp	(revision 144413)
+++ src/vsip/impl/fft.hpp	(working copy)
@@ -72,6 +72,15 @@
   static dimension_type const dim = D;
   typedef typename impl::Scalar_of<I>::type scalar_type;
 
+  length_type
+  op_count(length_type len)
+  { 
+    length_type ops = 
+      static_cast<length_type>(5 * len * std::log((float)len) / std::log(2.f)); 
+    if (sizeof(I) != sizeof(O)) ops /= 2;
+    return ops;
+  }
+
   base_interface(Domain<D> const &dom, scalar_type scale)
     : input_size_(io_size<D, I, O, A>::size(dom)),
       output_size_(io_size<D, O, I, A>::size(dom)),
@@ -99,9 +108,9 @@
     if (!strcmp(what, "mflops"))
     {
       // Compute rough estimate of flop-count.
-      float sz  = size(this->input_size_);
-      float ops = 5 * sz * log(sz)/log(2.f);
-      if (sizeof(I) != sizeof(O)) ops /= 2.f;
+      length_type sz = this->input_size_.size();
+      float ops = 5 * sz * std::log((float)sz) / std::log(2.f); 
+      if (sizeof(I) != sizeof(O)) ops /= 2;
       return (this->timer_.count() * ops) / (1e6 * this->timer_.total());
     }
     else if (!strcmp(what, "time"))
@@ -161,6 +170,8 @@
   operator()(ViewT in)
     VSIP_THROW((std::bad_alloc))
   {
+    int ops = op_count(this->input_size_.size());
+    impl::profile::Scope_event scope_event("fft_by_value", ops);
     impl::profile::Time_in_scope scope(this->timer_);
     typedef fft::result<O, typename ViewT::block_type> traits;
     typename traits::view_type out(traits::create(this->output_size(),
@@ -207,6 +218,8 @@
   operator()(View0<I,Block0> in, View1<O,Block1> out)
     VSIP_NOTHROW
   {
+    int ops = op_count(this->input_size_.size());
+    impl::profile::Scope_event scope_event("fft_by_reference", ops);
     impl::profile::Time_in_scope scope(this->timer_);
     VSIP_IMPL_STATIC_ASSERT((View0<I,Block0>::dim == View1<O,Block1>::dim));
     workspace_.by_reference(this->backend_.get(), in, out);
@@ -217,6 +230,8 @@
   View<I,BlockT>
   operator()(View<I,BlockT> inout) VSIP_NOTHROW
   {
+    int ops = op_count(this->input_size_.size());
+    impl::profile::Scope_event scope_event("fft_by_reference_in_place", ops);
     impl::profile::Time_in_scope scope(this->timer_);
     workspace_.in_place(this->backend_.get(), inout);
     return inout;
@@ -264,6 +279,8 @@
   operator()(const_Matrix<I,BlockT> in)
     VSIP_THROW((std::bad_alloc))
   {
+    int ops = op_count(this->input_size_.size());
+    impl::profile::Scope_event scope_event("fftm_by_value", ops);
     impl::profile::Time_in_scope scope(this->timer_);
     typedef fft::result<O,BlockT> traits;
     typename traits::view_type out(traits::create(this->output_size(),
@@ -310,6 +327,9 @@
   operator()(const_Matrix<I,Block0> in, Matrix<O,Block1> out)
     VSIP_NOTHROW
   {
+    int ops = op_count(this->input_size_.size());
+    impl::profile::Scope_event scope_event("fftm_by_reference", ops);
+    impl::profile::Time_in_scope scope(this->timer_);
     assert(extent(in)  == extent(this->input_size()));
     assert(extent(out) == extent(this->output_size()));
     if (Is_global_map<typename Block0::map_type>::value ||
@@ -331,6 +351,8 @@
   Matrix<O,BlockT>
   operator()(Matrix<O,BlockT> inout) VSIP_NOTHROW
   {
+    int ops = op_count(this->input_size_.size());
+    impl::profile::Scope_event scope_event("fftm_by_reference_in_place", ops);
     impl::profile::Time_in_scope scope(this->timer_);
     assert(extent(inout) == extent(this->input_size()));
     if (Is_global_map<typename BlockT::map_type>::value &&
Index: src/vsip/impl/profile.hpp
===================================================================
--- src/vsip/impl/profile.hpp	(revision 144413)
+++ src/vsip/impl/profile.hpp	(working copy)
@@ -309,11 +309,12 @@
 
   struct Accum_entry
   {
-    stamp_type total;
-    size_t     count;
+    stamp_type total;  // total time spent
+    size_t     count;  // # times called
+    int        value;  // op count per call
     
-    Accum_entry(stamp_type t, size_t c)
-      : total(t), count(c) {}
+    Accum_entry(stamp_type t, size_t c, int v)
+      : total(t), count(c), value(v) {}
   };
 
 public:
@@ -338,7 +339,19 @@
 
 extern Profiler* prof;
 
+class Scope_enable
+{
+public:
+  Scope_enable(char *filename)
+    : filename_(filename)
+  { prof->set_mode( pm_accum ); }
 
+  ~Scope_enable() { prof->dump( this->filename_ ); }
+
+private:
+  char* const filename_;
+};
+
 class Scope_event
 {
 public:
Index: examples/fft.cpp
===================================================================
--- examples/fft.cpp	(revision 0)
+++ examples/fft.cpp	(revision 0)
@@ -0,0 +1,86 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    examples/fft.cpp
+    @author  Jules Bergmann, Don McCoy
+    @date    2006-07-02
+    @brief   VSIPL++ Library: Simple FFT example
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/math.hpp>
+#include <vsip/impl/profile.hpp>
+
+#include <vsip_csl/error_db.hpp>
+#include <vsip_csl/ref_dft.hpp>
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Functions
+***********************************************************************/
+
+void
+fft_example()
+{
+  typedef Fft<const_Vector, cscalar_f, cscalar_f, fft_fwd, by_value, 1, alg_space>
+	f_fft_type;
+  typedef Fft<const_Vector, cscalar_f, cscalar_f, fft_inv, by_value, 1, alg_space>
+	i_fft_type;
+  typedef impl::Cmplx_inter_fmt Complex_format;
+
+  vsip::length_type N = 1024;
+
+  f_fft_type f_fft(Domain<1>(N), 1.0);
+  i_fft_type i_fft(Domain<1>(N), 1.0/N);
+
+
+  Vector<cscalar_f> in(N, cscalar_f());
+  Vector<cscalar_f> out(N);
+  Vector<cscalar_f> ref(N);
+  Vector<cscalar_f> inv(N);
+
+  for ( int n = 0; n < N; ++n )
+    in(n) = sin( 2 * M_PI * n / N );
+
+  ref::dft(in, ref, -1);
+  
+//  for ( int i = 0; i < 1000; ++i ) {
+  out = f_fft(in);
+//  }
+  inv = i_fft(out);
+  
+  test_assert(error_db(ref, out) < -100);
+//  test_assert(error_db(inv, in) < -100);
+
+  cout << "fwd = " << f_fft.impl_performance("mflops") << " mflops" << endl;
+  cout << "inv = " << i_fft.impl_performance("mflops") << " mflops" << endl;
+}
+
+
+int
+main()
+{
+  vsipl init;
+  
+  impl::profile::prof->set_mode( impl::profile::pm_accum );
+
+  fft_example();
+
+  impl::profile::prof->dump( "/dev/stdout" );
+
+  return 0;
+}
Index: examples/GNUmakefile.inc.in
===================================================================
--- examples/GNUmakefile.inc.in	(revision 144413)
+++ examples/GNUmakefile.inc.in	(working copy)
@@ -20,22 +20,26 @@
 	$(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(examples_cxx_sources))
 cxx_sources += $(examples_cxx_sources)
 
-examples_targets     := examples/example1 examples/png
+examples_cxx_exes := \
+	$(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(examples_cxx_sources))
 
+
 ########################################################################
 # Rules
 ########################################################################
 
-all:: examples/example1$(EXEEXT)
+all:: examples
 
 examples/png: override LIBS += -lvsip_csl -lpng
 
+examples: $(examples_cxx_exes)
+
 install::
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)
 	$(INSTALL_DATA) $(examples_cxx_sources) $(DESTDIR)$(pkgdatadir)
 	$(INSTALL_DATA) examples/makefile.standalone \
 	  $(DESTDIR)$(pkgdatadir)/Makefile
 
-$(examples_targets): %$(EXEEXT): %.$(OBJEXT) $(libs)
+$(examples_cxx_exes): %$(EXEEXT): %.$(OBJEXT) $(libs)
 	$(CXX) $(LDFLAGS) -o $@ $< -Llib -lvsip $(LIBS)
 
