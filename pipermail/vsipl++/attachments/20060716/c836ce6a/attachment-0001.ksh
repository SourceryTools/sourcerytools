Index: src/vsip/profile.cpp
===================================================================
--- src/vsip/profile.cpp	(revision 145051)
+++ src/vsip/profile.cpp	(working copy)
@@ -128,9 +128,38 @@
 }
 
 
+Profiler::stamp_type
+Profiler::raw_total(const char *name)
+{
+  if (mode_ == pm_accum)
+  {
+    accum_type::iterator pos = accum_.find(name);
+    if (pos == accum_.end())
+      return stamp_type();
 
+    return pos->second.total;
+  }
+  return stamp_type();
+}
+
+
+int 
+Profiler::count(const char *name)
+{
+  if (mode_ == pm_accum)
+  {
+    accum_type::iterator pos = accum_.find(name);
+    if (pos == accum_.end())
+      return 0;
+
+    return pos->second.count;
+  }
+  return 0;
+}
+
+
 int
-Profiler::event(char* name, int value, int open_id)
+Profiler::event(const char* name, int value, int open_id)
 {
   if (mode_ == pm_trace)
   {
Index: src/vsip/impl/fft/util.hpp
===================================================================
--- src/vsip/impl/fft/util.hpp	(revision 145051)
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
@@ -68,6 +71,45 @@
   }
 };
 
+
+// Create a readable tag from parameters.
+template <int S>
+struct desc_dir     { static char * value() { return "fwd "; } };
+template <>
+struct desc_dir<-1> { static char * value() { return "inv "; } };
+
+template <int D>
+struct desc_dim     { static char * value() { return "fft"; } };
+template <>
+struct desc_dim<2> { static char * value() { return "fftm"; } };
+
+template <typename IO>
+struct desc_datatype { static char * value() { return "real"; } };
+template <typename T>
+struct desc_datatype<std::complex<T> > { static char * value() { return "cplx"; } };
+
+template <return_mechanism_type R> 
+struct desc_rtn { static char * value() { return "rbv"; } };
+template <>
+struct desc_rtn <vsip::by_reference> { static char * value() { return "rbr"; } };
+
+template <int D, typename I, typename O, int S, return_mechanism_type R> 
+struct description
+{ 
+  static std::string tag() 
+  {
+    std::ostringstream   st;
+    st << desc_dir<S>::value()
+       << desc_dim<D>::value() << ", "
+       << desc_datatype<I>::value() << "-"
+       << desc_datatype<O>::value() << ", "
+       << desc_rtn<R>::value();
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
--- src/vsip/impl/fft.hpp	(revision 145051)
+++ src/vsip/impl/fft.hpp	(working copy)
@@ -73,7 +73,7 @@
   typedef typename impl::Scalar_of<I>::type scalar_type;
 
   length_type
-  op_count(length_type len)
+  op_count(length_type len) const
   { 
     length_type ops = 
       static_cast<length_type>(5 * len * std::log((float)len) / std::log(2.f)); 
@@ -81,11 +81,14 @@
     return ops;
   }
 
-  base_interface(Domain<D> const &dom, scalar_type scale)
+  base_interface(Domain<D> const &dom, scalar_type scale, std::string event_tag)
     : input_size_(io_size<D, I, O, A>::size(dom)),
       output_size_(io_size<D, O, I, A>::size(dom)),
-      scale_(scale)
-  {}
+      scale_(scale), event_(event_tag)
+  {
+    // Pre-compute the FLOP count.  Used for event profiling (if enabled).
+    event_.ops(op_count(this->input_size_.size()));
+  }
 
   Domain<dim> const& 
   input_size() const VSIP_NOTHROW 
@@ -107,15 +110,11 @@
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
@@ -124,7 +123,7 @@
   Domain<dim> input_size_;
   Domain<dim> output_size_;
   scalar_type scale_;
-  impl::profile::Acc_timer timer_;
+  impl::profile::Profile_event event_;
 };
 
 } // namespace vsip::impl::fft
@@ -160,7 +159,7 @@
 
   fft_facade(Domain<D> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale),
+    : base(dom, scale, fft::description<1, I, O, S, vsip::by_value>::tag()),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
@@ -170,9 +169,7 @@
   operator()(ViewT in)
     VSIP_THROW((std::bad_alloc))
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fft_by_value", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_event scope_event(this->event_);
     typedef fft::result<O, typename ViewT::block_type> traits;
     typename traits::view_type out(traits::create(this->output_size(),
 						  in.block().map()));
@@ -206,7 +203,7 @@
 
   fft_facade(Domain<D> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale),
+    : base(dom, scale, fft::description<1, I, O, S, vsip::by_reference>::tag()),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
@@ -218,9 +215,7 @@
   operator()(View0<I,Block0> in, View1<O,Block1> out)
     VSIP_NOTHROW
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fft_by_reference", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_event scope_event(this->event_);
     VSIP_IMPL_STATIC_ASSERT((View0<I,Block0>::dim == View1<O,Block1>::dim));
     workspace_.by_reference(this->backend_.get(), in, out);
     return out;
@@ -230,9 +225,7 @@
   View<I,BlockT>
   operator()(View<I,BlockT> inout) VSIP_NOTHROW
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fft_by_reference_in_place", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_event scope_event(this->event_);
     workspace_.in_place(this->backend_.get(), inout);
     return inout;
   }
@@ -270,7 +263,7 @@
 public:
   fftm_facade(Domain<2> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale),
+    : base(dom, scale, fft::description<2, I, O, D, vsip::by_value>::tag()),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
@@ -279,9 +272,7 @@
   operator()(const_Matrix<I,BlockT> in)
     VSIP_THROW((std::bad_alloc))
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fftm_by_value", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_event scope_event(this->event_);
     typedef fft::result<O,BlockT> traits;
     typename traits::view_type out(traits::create(this->output_size(),
 						  in.block().map()));
@@ -317,7 +308,7 @@
 public:
   fftm_facade(Domain<2> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale),
+    : base(dom, scale, fft::description<2, I, O, D, vsip::by_reference>::tag()),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
@@ -327,9 +318,7 @@
   operator()(const_Matrix<I,Block0> in, Matrix<O,Block1> out)
     VSIP_NOTHROW
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fftm_by_reference", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_event scope_event(this->event_);
     assert(extent(in)  == extent(this->input_size()));
     assert(extent(out) == extent(this->output_size()));
     if (Is_global_map<typename Block0::map_type>::value ||
@@ -351,9 +340,7 @@
   Matrix<O,BlockT>
   operator()(Matrix<O,BlockT> inout) VSIP_NOTHROW
   {
-    int ops = op_count(this->input_size_.size());
-    impl::profile::Scope_event scope_event("fftm_by_reference_in_place", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_event scope_event(this->event_);
     assert(extent(inout) == extent(this->input_size()));
     if (Is_global_map<typename BlockT::map_type>::value &&
 	inout.block().map().num_subblocks(A) != 1)
Index: src/vsip/impl/profile.hpp
===================================================================
--- src/vsip/impl/profile.hpp	(revision 145051)
+++ src/vsip/impl/profile.hpp	(working copy)
@@ -13,6 +13,7 @@
   Included Files
 ***********************************************************************/
 
+#include <string>
 #include <vector>
 #include <map>
 
@@ -298,12 +299,12 @@
   struct Trace_entry
   {
     int        idx;
-    char*      name;
+    const char* name;
     stamp_type stamp;
     int        end;
     int        value;
     
-    Trace_entry(int i, char* n, stamp_type s, int e, int v)
+    Trace_entry(int i, const char* n, stamp_type s, int e, int v)
       : idx(i), name(n), stamp(s), end(e), value(v) {}
   };
 
@@ -322,12 +323,14 @@
   Profiler();
   ~Profiler();
 
-  int event(char* name, int value, int id);
+  stamp_type raw_total(const char* name);
+  int count(const char* name);
+  int event(const char* name, int value, int id);
   void dump(char* filename, char mode='w');
   void set_mode(profiler_mode mode) { mode_ = mode; }
 
 private:
-  typedef std::map<char*, Accum_entry> accum_type;
+  typedef std::map<const char*, Accum_entry> accum_type;
   typedef std::vector<Trace_entry> trace_type;
 
   profiler_mode              mode_;
@@ -352,18 +355,49 @@
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
+  float total() const { return TP::seconds(prof->raw_total(this->name_.c_str())); }
+  int count() const { return prof->count(this->name_.c_str()); }
+  float mflops() const { return (prof->count(this->name_.c_str()) * this->ops_) / 
+                         (1e6 * this->total()); }
+
+private:
+  std::string name_;
+  unsigned int ops_;
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
 
+  Scope_event(Profile_event info)
+    : name_(info.name()),
+      id_  (prof->event(info.name(), info.ops(), 0))
+  {}
+
   ~Scope_event() { prof->event(name_, 0, id_); }
 
 private:
-  char* name_;
+  const char* name_;
   int   id_;
 };
 
Index: examples/fft.cpp
===================================================================
--- examples/fft.cpp	(revision 145051)
+++ examples/fft.cpp	(working copy)
@@ -10,6 +10,7 @@
   Included Files
 ***********************************************************************/
 
+#include <iostream>
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/signal.hpp>
@@ -63,6 +64,9 @@
   // Validate the results (allowing for small numerical errors)
   test_assert(error_db(ref, out) < -100);
   test_assert(error_db(inv, in) < -100);
+
+  std::cout << f_fft.impl_performance("mflops") << std::endl;
+  std::cout << i_fft.impl_performance("mflops") << std::endl;
 }
 
 
