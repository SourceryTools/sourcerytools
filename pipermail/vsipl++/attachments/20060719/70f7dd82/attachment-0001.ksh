Index: src/vsip/profile.cpp
===================================================================
--- src/vsip/profile.cpp	(revision 145276)
+++ src/vsip/profile.cpp	(working copy)
@@ -128,37 +128,38 @@
 }
 
 
-
 int
-Profiler::event(char* name, int value, int open_id)
+Profiler::event(const char* name, int value, int open_id, stamp_type stamp)
 {
   if (mode_ == pm_trace)
   {
-    stamp_type stamp;
+    // Obtain a stamp if one is not provided.
+    if (stamp == stamp_type())
+      TP::sample(stamp);
 
-    TP::sample(stamp);
-
     count_++;
     data_.push_back(Trace_entry(count_, name, stamp, open_id, value));
     return count_;
   }
   else if (mode_ == pm_accum)
   {
-    stamp_type stamp;
-    TP::sample(stamp);
+    // Obtain a stamp if one is not provided.
+    if (stamp == stamp_type())
+      TP::sample(stamp);
 
     accum_type::iterator pos = accum_.find(name);
     if (pos == accum_.end())
     {
-      accum_.insert(std::make_pair(name, Accum_entry(TP::zero(), 0, value)));
+      accum_.insert(std::make_pair(std::string(name), 
+                      Accum_entry(TP::zero(), 0, value)));
       pos = accum_.find(name);
     }
 
-    // 'open_id' determines if it is entering scope or exiting scope.  This 
-    // allows it to work with the Scope_event class, which calls it with 0
-    // in it's constructor (usually placed at the beginning of a function body)
-    // and with a non-zero value in it's destructor.  The net result is that
-    // it accumulates time when it is alive.
+    // The value of 'open_id' determines if it is entering scope or exiting 
+    // scope.  This allows it to work with the Scope_event class, which calls 
+    // it with 0 in it's constructor (usually placed at the beginning of a 
+    // function body) and with a non-zero value in it's destructor.  The net 
+    // result is that it accumulates time when it is alive.
     if (open_id == 0)
       pos->second.total = TP::sub(pos->second.total, stamp);
     else
@@ -166,7 +167,7 @@
       pos->second.total = TP::add(pos->second.total, stamp);
       pos->second.count++;
     }
-    // a non-zero value is returned for the benefit of the Scope_event class,
+    // A non-zero value is returned for the benefit of the Scope_event class,
     // which turns around and passes it back as the 'open_id' parameter in 
     // order to indicate the event is going out of scope.
     return 1;
@@ -220,7 +221,7 @@
     {
       float mflops = (*cur).second.count * (*cur).second.value /
         (1e6 * TP::seconds((*cur).second.total));
-      file << (*cur).first 
+      file << (*cur).first.c_str()
            << delim << TP::ticks((*cur).second.total)
            << delim << (*cur).second.count
            << delim << (*cur).second.value
Index: src/vsip/impl/fft/util.hpp
===================================================================
--- src/vsip/impl/fft/util.hpp	(revision 145276)
+++ src/vsip/impl/fft/util.hpp	(working copy)
@@ -14,6 +14,9 @@
   Included Files
 ***********************************************************************/
 
+#include <iostream>
+#include <string>
+#include <sstream>
 #include <vsip/support.hpp>
 #include <vsip/impl/fft/backend.hpp>
 #include <vsip/impl/fast-block.hpp>
@@ -68,6 +71,52 @@
   }
 };
 
+
+// Create a readable tag from parameters.
+template <int D> 
+struct desc_dim { static char * value() { return "FFT "; } };
+template <>  
+struct desc_dim<2> { static char * value() { return "FFTM "; } };
+
+typedef float S_type;
+typedef double D_type;
+typedef std::complex<float> C_type;
+typedef std::complex<double> Z_type;
+
+template <typename IO> 
+struct desc_datatype { static char * value() { return "I"; } };
+template <> 
+struct desc_datatype<S_type> { static char * value() { return "S"; } };
+template <> 
+struct desc_datatype<D_type> { static char * value() { return "D"; } };
+template <> 
+struct desc_datatype<C_type> { static char * value() { return "C"; } };
+template <> 
+struct desc_datatype<Z_type> { static char * value() { return "Z"; } };
+
+template <int D, typename I, typename O>
+struct description
+{ 
+  static std::string tag(Domain<D> const &dom, int dir, 
+    return_mechanism_type rm)
+  {
+    length_type cols = 1;
+    length_type rows = dom[0].size();
+    if (D == 2) cols = dom[1].size();
+
+    std::ostringstream   st;
+    st << (dir == -1 ? "Inv " : "Fwd ")
+       << desc_dim<D>::value()
+       << desc_datatype<I>::value() << "-"
+       << desc_datatype<O>::value() << " "
+       << (dir == vsip::by_reference ? "by_ref " : "by_val ")
+       << rows << "x" << cols;
+
+    return st.str();
+  } 
+};
+
+
 template <typename View>
 View
 new_view(vsip::Domain<1> const& dom) { return View(dom.size());} 
Index: src/vsip/impl/fft.hpp
===================================================================
--- src/vsip/impl/fft.hpp	(revision 145276)
+++ src/vsip/impl/fft.hpp	(working copy)
@@ -73,7 +73,7 @@
   typedef typename impl::Scalar_of<I>::type scalar_type;
 
   length_type
-  op_count(length_type len)
+  op_count(length_type len) const
   { 
     length_type ops = 
       static_cast<length_type>(5 * len * std::log((float)len) / std::log(2.f)); 
@@ -81,10 +81,12 @@
     return ops;
   }
 
-  base_interface(Domain<D> const &dom, scalar_type scale)
+  base_interface(Domain<D> const &dom, scalar_type scale, int dir, return_mechanism_type rm)
     : input_size_(io_size<D, I, O, A>::size(dom)),
       output_size_(io_size<D, O, I, A>::size(dom)),
-      scale_(scale)
+      scale_(scale), 
+      event_( fft::description<D, I, O>::tag(dom, dir, rm),
+              op_count(io_size<D, O, I, A>::size(dom).size()) )
   {}
 
   Domain<dim> const& 
@@ -107,15 +109,11 @@
   {
     if (!strcmp(what, "mflops"))
     {
-      // Compute rough estimate of flop-count.
-      length_type sz = this->input_size_.size();
-      float ops = 5 * sz * std::log((float)sz) / std::log(2.f); 
-      if (sizeof(I) != sizeof(O)) ops /= 2;
-      return (this->timer_.count() * ops) / (1e6 * this->timer_.total());
+      return this->event_.mflops();
     }
     else if (!strcmp(what, "time"))
     {
-      return this->timer_.total();
+      return this->event_.total();
     }
     return 0.f;
   }
@@ -124,7 +122,7 @@
   Domain<dim> input_size_;
   Domain<dim> output_size_;
   scalar_type scale_;
-  impl::profile::Acc_timer timer_;
+  impl::profile::Profile_event event_;
 };
 
 } // namespace vsip::impl::fft
@@ -160,7 +158,7 @@
 
   fft_facade(Domain<D> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale),
+    : base(dom, scale, S, by_value),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
@@ -170,9 +168,7 @@
   operator()(ViewT in)
     VSIP_THROW((std::bad_alloc))
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fft_by_value", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_profile_event scope_event(this->event_);
     typedef fft::result<O, typename ViewT::block_type> traits;
     typename traits::view_type out(traits::create(this->output_size(),
 						  in.block().map()));
@@ -206,7 +202,7 @@
 
   fft_facade(Domain<D> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale),
+    : base(dom, scale, S, by_reference),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
@@ -218,9 +214,7 @@
   operator()(View0<I,Block0> in, View1<O,Block1> out)
     VSIP_NOTHROW
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fft_by_reference", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_profile_event scope_event(this->event_);
     VSIP_IMPL_STATIC_ASSERT((View0<I,Block0>::dim == View1<O,Block1>::dim));
     workspace_.by_reference(this->backend_.get(), in, out);
     return out;
@@ -230,9 +224,7 @@
   View<I,BlockT>
   operator()(View<I,BlockT> inout) VSIP_NOTHROW
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fft_by_reference_in_place", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_profile_event scope_event(this->event_);
     workspace_.in_place(this->backend_.get(), inout);
     return inout;
   }
@@ -270,7 +262,7 @@
 public:
   fftm_facade(Domain<2> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale),
+    : base(dom, scale, D, by_value),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
@@ -279,9 +271,7 @@
   operator()(const_Matrix<I,BlockT> in)
     VSIP_THROW((std::bad_alloc))
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fftm_by_value", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_profile_event scope_event(this->event_);
     typedef fft::result<O,BlockT> traits;
     typename traits::view_type out(traits::create(this->output_size(),
 						  in.block().map()));
@@ -317,7 +307,7 @@
 public:
   fftm_facade(Domain<2> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale),
+    : base(dom, scale, D, by_reference),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
@@ -327,9 +317,7 @@
   operator()(const_Matrix<I,Block0> in, Matrix<O,Block1> out)
     VSIP_NOTHROW
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fftm_by_reference", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_profile_event scope_event(this->event_);
     assert(extent(in)  == extent(this->input_size()));
     assert(extent(out) == extent(this->output_size()));
     if (Is_global_map<typename Block0::map_type>::value ||
@@ -351,9 +339,7 @@
   Matrix<O,BlockT>
   operator()(Matrix<O,BlockT> inout) VSIP_NOTHROW
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fftm_by_reference_in_place", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_profile_event scope_event(this->event_);
     assert(extent(inout) == extent(this->input_size()));
     if (Is_global_map<typename BlockT::map_type>::value &&
 	inout.block().map().num_subblocks(A) != 1)
Index: src/vsip/impl/profile.hpp
===================================================================
--- src/vsip/impl/profile.hpp	(revision 145276)
+++ src/vsip/impl/profile.hpp	(working copy)
@@ -13,6 +13,7 @@
   Included Files
 ***********************************************************************/
 
+#include <string>
 #include <vector>
 #include <map>
 
@@ -261,12 +262,13 @@
 public:
   P_acc_timer() { total_ = stamp_type(); count_ = 0; }
 
-  void start() { TP::sample(start_); }
-  void stop()
+  stamp_type start() { TP::sample(start_); return start_; }
+  stamp_type stop()
   {
     TP::sample(stop_);
     total_ = TP::add(total_, TP::sub(stop_, start_));
     count_ += 1;
+    return stop_;
   }
 
   stamp_type raw_delta() const { return TP::sub(stop_, start_); }
@@ -297,13 +299,13 @@
 
   struct Trace_entry
   {
-    int        idx;
-    char*      name;
-    stamp_type stamp;
-    int        end;
-    int        value;
+    int         idx;
+    std::string name;
+    stamp_type  stamp;
+    int         end;
+    int         value;
     
-    Trace_entry(int i, char* n, stamp_type s, int e, int v)
+    Trace_entry(int i, const char* n, stamp_type s, int e, int v)
       : idx(i), name(n), stamp(s), end(e), value(v) {}
   };
 
@@ -322,12 +324,13 @@
   Profiler();
   ~Profiler();
 
-  int event(char* name, int value, int id);
+  int event(const char* name, int value, int id, 
+    stamp_type stamp = stamp_type());
   void dump(char* filename, char mode='w');
   void set_mode(profiler_mode mode) { mode_ = mode; }
 
 private:
-  typedef std::map<char*, Accum_entry> accum_type;
+  typedef std::map<std::string, Accum_entry> accum_type;
   typedef std::vector<Trace_entry> trace_type;
 
   profiler_mode              mode_;
@@ -342,20 +345,67 @@
 class Profile
 {
 public:
-  Profile(char *filename)
+  Profile(char *filename, profiler_mode mode = pm_accum)
     : filename_(filename)
-  { prof->set_mode( pm_accum ); }
+  { prof->set_mode( mode ); }
 
-  ~ Profile() { prof->dump( this->filename_ ); }
+  ~Profile() { prof->dump( this->filename_ ); }
 
 private:
   char* const filename_;
 };
 
+class Profile_event
+{
+  typedef DefaultTime    TP;
+
+public:
+  Profile_event(std::string name, unsigned int ops_count = 0)
+    : name_(name), ops_(ops_count)
+  {}
+
+  ~Profile_event() {}
+
+  void ops(unsigned int ops_count) { ops_ = ops_count; }
+
+  const char* name() const { return name_.c_str(); }
+  unsigned int ops() const { return ops_; }
+
+  float  total() const { return this->timer_.total(); }
+  int    count() const { return this->timer_.count(); }
+  float mflops() const { return (count() * ops()) / (1e6 * total()); }
+
+  TP::stamp_type start() { return this->timer_.start(); }
+  TP::stamp_type  stop() { return this->timer_.stop(); }
+
+private:
+  std::string name_;
+  unsigned int ops_;
+  Acc_timer timer_;
+};
+
+
+
+class Scope_profile_event
+{
+public:
+  Scope_profile_event(Profile_event& event)
+    : id_(prof->event(event.name(), event.ops(), 0, event.start())),
+      event_(event)
+  {}
+
+  ~Scope_profile_event() { prof->event(event_.name(), 0, id_, event_.stop()); }
+
+private:
+  int id_;
+  Profile_event& event_;
+};
+
+
 class Scope_event
 {
 public:
-  Scope_event(char* name, int value=0)
+  Scope_event(const char* name, int value=0)
     : name_(name),
       id_  (prof->event(name, value, 0))
   {}
@@ -363,7 +413,7 @@
   ~Scope_event() { prof->event(name_, 0, id_); }
 
 private:
-  char* name_;
+  const char* name_;
   int   id_;
 };
 
Index: examples/fft.cpp
===================================================================
--- examples/fft.cpp	(revision 145276)
+++ examples/fft.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
 /** @file    examples/fft.cpp
     @author  Jules Bergmann, Don McCoy
@@ -10,6 +10,7 @@
   Included Files
 ***********************************************************************/
 
+#include <iostream>
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/signal.hpp>
@@ -26,6 +27,7 @@
 
 using namespace vsip;
 using namespace vsip_csl;
+using namespace impl::profile;
 
 
 /***********************************************************************
@@ -39,9 +41,9 @@
   typedef Fft<const_Vector, cscalar_f, cscalar_f, fft_inv> i_fft_type;
 
   // Create FFT objects
-  vsip::length_type N = 1024;
+  vsip::length_type N = 2048;
   f_fft_type f_fft(Domain<1>(N), 1.0);
-  i_fft_type i_fft(Domain<1>(N), 1.0/N);
+  i_fft_type i_fft(Domain<1>(N), 1.0 / N);
 
   // Allocate input and output buffers
   Vector<cscalar_f> in(N);
@@ -63,6 +65,9 @@
   // Validate the results (allowing for small numerical errors)
   test_assert(error_db(ref, out) < -100);
   test_assert(error_db(inv, in) < -100);
+
+  std::cout << f_fft.impl_performance("mflops") << std::endl;
+  std::cout << i_fft.impl_performance("mflops") << std::endl;
 }
 
 
@@ -71,7 +76,7 @@
 {
   vsipl init;
   
-  impl::profile::Profile profile("/dev/stdout");
+  Profile profile("/dev/stdout", pm_accum);
 
   fft_example();
 
