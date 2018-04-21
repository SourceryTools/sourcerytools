Index: src/vsip/profile.cpp
===================================================================
--- src/vsip/profile.cpp	(revision 145922)
+++ src/vsip/profile.cpp	(working copy)
@@ -213,19 +213,19 @@
     file << "# clocks_per_sec: " << TP::ticks(TP::clocks_per_sec) << std::endl;
     file << "# " << std::endl;
     file << "# tag" << delim << "total ticks" << delim << "num calls" 
-         << delim << "op count" << delim << "mflops" << std::endl;
+         << delim << "op count" << delim << "mops" << std::endl;
 
     typedef accum_type::iterator iterator;
 
     for (iterator cur = accum_.begin(); cur != accum_.end(); ++cur)
     {
-      float mflops = (*cur).second.count * (*cur).second.value /
+      float mops = (*cur).second.count * (*cur).second.value /
         (1e6 * TP::seconds((*cur).second.total));
       file << (*cur).first
            << delim << TP::ticks((*cur).second.total)
            << delim << (*cur).second.count
            << delim << (*cur).second.value
-           << delim << mflops
+           << delim << mops
            << std::endl;
     }
     accum_.clear();
Index: src/vsip/impl/fft/util.hpp
===================================================================
--- src/vsip/impl/fft/util.hpp	(revision 145922)
+++ src/vsip/impl/fft/util.hpp	(working copy)
@@ -21,6 +21,7 @@
 #include <vsip/impl/fft/backend.hpp>
 #include <vsip/impl/fast-block.hpp>
 #include <vsip/impl/view_traits.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 /***********************************************************************
   Declarations
@@ -73,45 +74,25 @@
 
 
 // Create a readable tag from parameters.
-template <int D> 
-struct desc_dim { static char * value() { return "Fft "; } };
-template <>  
-struct desc_dim<2> { static char * value() { return "Fftm "; } };
-
-typedef float S_type;
-typedef double D_type;
-typedef std::complex<float> C_type;
-typedef std::complex<double> Z_type;
-
-template <typename IO> 
-struct desc_datatype { static char * value() { return "I"; } };
-template <> 
-struct desc_datatype<S_type> { static char * value() { return "S"; } };
-template <> 
-struct desc_datatype<D_type> { static char * value() { return "D"; } };
-template <> 
-struct desc_datatype<C_type> { static char * value() { return "C"; } };
-template <> 
-struct desc_datatype<Z_type> { static char * value() { return "Z"; } };
-
 template <int D, typename I, typename O>
-struct description
+struct Description
 { 
   static std::string tag(Domain<D> const &dom, int dir, 
     return_mechanism_type rm)
   {
-    length_type cols = 1;
-    length_type rows = dom[0].size();
-    if (D == 2) cols = dom[1].size();
-
     std::ostringstream   st;
-    st << (dir == -1 ? "Inv " : "Fwd ")
-       << desc_dim<D>::value()
-       << desc_datatype<I>::value() << "-"
-       << desc_datatype<O>::value() << " "
-       << (dir == vsip::by_reference ? "by_ref " : "by_val ")
-       << rows << "x" << cols;
+    st << (D == 2 ? "Fftm " : "Fft ")
+       << D << "D "
+       << (dir == -1 ? "Inv " : "Fwd ")
+       << Desc_datatype<I>::value() << "-"
+       << Desc_datatype<O>::value() << " "
+       << (rm == vsip::by_reference ? "by_ref " : "by_val ");
 
+    st.width(7);
+    st << dom[0].size();
+    st.width(1);
+    st << "x" << ((D == 2) ? dom[1].size() : 1);
+
     return st.str();
   } 
 };
Index: src/vsip/impl/signal-iir.hpp
===================================================================
--- src/vsip/impl/signal-iir.hpp	(revision 145922)
+++ src/vsip/impl/signal-iir.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/impl/signal-iir.hpp
     @author  Jules Bergmann
@@ -82,12 +82,30 @@
 
   void reset() VSIP_NOTHROW;
 
+public:
+
+  float impl_performance(char* what) const  VSIP_NOTHROW
+  {
+    if      (!strcmp(what, "mops"))     return this->event_.mflops();
+    else if (!strcmp(what, "time"))     return this->event_.total();
+    else if (!strcmp(what, "count"))    return this->event_.count();
+    return 0.f;
+  }
+
+private:
+  length_type impl_op_count()
+  {
+    return ( this->input_size_ * this->a_.size(0) *
+      (5 * impl::Ops_info<T>::mul + 4 * impl::Ops_info<T>::add) );
+  }
+
   // Member data.
 private:
   Matrix<T>   b_;
   Matrix<T>   a_;
   Matrix<T>   w_;
   length_type input_size_;
+  impl::profile::Profile_event event_;
 };
 
 
@@ -110,7 +128,9 @@
   : b_         (B.size(0), B.size(1)),
     a_         (A.size(0), A.size(1)),
     w_         (b_.size(0), 2, T()),
-    input_size_(input_size)
+    input_size_(input_size),
+    event_(impl::signal::Description<1, T>::tag("Iir", input_size), 
+      this->impl_op_count())
 {
   assert(b_.size(0) == a_.size(0));
   assert(b_.size(1) == 3);
@@ -131,7 +151,8 @@
   : b_         (iir.b_.size(0), 3),
     a_         (iir.a_.size(0), 2),
     w_         (b_.size(0), 2),
-    input_size_(iir.input_size_)
+    input_size_(iir.input_size_),
+    event_(iir.event_)
 {
   b_ = iir.b_;
   a_ = iir.a_;
@@ -155,6 +176,7 @@
   w_ = iir.w_;
 
   input_size_ = iir.input_size_;
+  event_ = iir.event_;
 
   return *this;
 }
@@ -173,6 +195,7 @@
   Vector<T, Block1>       out)
   VSIP_NOTHROW
 {
+  impl::profile::Scope_profile_event scope_event(this->event_);
   index_type const A1 = 0;
   index_type const A2 = 1;
 
Index: src/vsip/impl/signal-conv.hpp
===================================================================
--- src/vsip/impl/signal-conv.hpp	(revision 145922)
+++ src/vsip/impl/signal-conv.hpp	(working copy)
@@ -79,13 +79,6 @@
 				 typename impl::Choose_conv_impl<dim, T>::type>
 		base_type;
 
-  length_type
-  op_count(length_type kernel_len, length_type output_len)
-  {
-    return kernel_len * output_len *
-      (impl::Ops_info<T>::mul + impl::Ops_info<T>::add);
-  }
-
   // Constructors, copies, assignments, and destructors.
 public:
   template <typename Block>
@@ -93,7 +86,12 @@
 	      Domain<dim> const&   input_size,
 	      length_type          decimation = 1)
     VSIP_THROW((std::bad_alloc))
-      : base_type(filter_coeffs, input_size, decimation)
+      : base_type(filter_coeffs, input_size, decimation),
+        event_(impl::signal::Description<dim, T>::tag( "Convolution", 
+                 view_domain(filter_coeffs),
+                 impl::conv_output_size(Supp, view_domain(filter_coeffs), 
+                   input_size, decimation) 
+               ), this->impl_op_count())
   {
     assert(decimation >= 1);
     assert(Symm == nonsym ? (filter_coeffs.size() <=   input_size.size())
@@ -117,15 +115,7 @@
     impl_View<V2, Block2, T, dim>       out)
     VSIP_NOTHROW
   {
-    length_type M = this->kernel_size()[0].size();
-    length_type P = this->output_size()[0].size();
-    for (dimension_type d=1; d<dim; ++d)
-      M *= this->kernel_size()[d].size();
-    for (dimension_type d=1; d<dim; ++d)
-      P *= this->output_size()[d].size();
-    int ops = op_count(M, P);
-    impl::profile::Scope_event scope_event("convolve_impl_view", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_profile_event scope_event(this->event_);
     for (dimension_type d=0; d<dim; ++d)
       assert(in.size(d) == this->input_size()[d].size());
 
@@ -145,11 +135,8 @@
     Vector<T, Block2>       out)
     VSIP_NOTHROW
   {
-    length_type const M = this->kernel_size()[0].size();
-    length_type const P = this->output_size()[0].size();
-    int ops = op_count(M, P);
-    impl::profile::Scope_event scope_event("convolve_vector", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_profile_event scope_event(this->event_);
+
     for (dimension_type d=0; d<dim; ++d)
       assert(in.size(d) == this->input_size()[d].size());
 
@@ -169,13 +156,8 @@
     Matrix<T, Block2>       out)
     VSIP_NOTHROW
   {
-    length_type const M = this->kernel_size()[0].size()
-                        * this->kernel_size()[1].size();
-    length_type const P = this->output_size()[0].size()
-                        * this->output_size()[1].size();
-    int ops = op_count(M, P);
-    impl::profile::Scope_event scope_event("convolve_matrix", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_profile_event scope_event(this->event_);
+
     for (dimension_type d=0; d<dim; ++d)
       assert(in.size(d) == this->input_size()[d].size());
 
@@ -190,32 +172,27 @@
 
   float impl_performance(char* what) const
   {
-    if (!strcmp(what, "mflops"))
-    {
-      length_type M = this->kernel_size()[0].size();
-      length_type P = this->output_size()[0].size();
-      for (dimension_type d=1; d<dim; ++d)
-        M *= this->kernel_size()[d].size();
-      for (dimension_type d=1; d<dim; ++d)
-        P *= this->output_size()[d].size();
-      int ops = op_count(M, P);
-      return timer_.count() * ops / (1e6 * timer_.total());
-    }
-    else if (!strcmp(what, "count"))
-    {
-      return timer_.count();
-    }
-    else if (!strcmp(what, "time"))
-    {
-      return timer_.total();
-    }
-    else
-      return base_type::impl_performance(what);
+    if      (!strcmp(what, "mops"))     return this->event_.mflops();
+    else if (!strcmp(what, "time"))     return this->event_.total();
+    else if (!strcmp(what, "count"))    return this->event_.count();
+    else return this->base_type::impl_performance(what);
   }
 
   // Member data.
 private:
-  vsip::impl::profile::Acc_timer timer_;
+
+  length_type impl_op_count()
+  {
+    length_type   M =  this->kernel_size()[0].size();
+    if (dim == 2) M *= this->kernel_size()[1].size();
+
+    length_type   P =  this->output_size()[0].size();
+    if (dim == 2) P *= this->output_size()[1].size();
+
+    return M * P * (impl::Ops_info<T>::mul + impl::Ops_info<T>::add);
+  }
+
+  vsip::impl::profile::Profile_event event_;
 };
 
 } // namespace vsip
Index: src/vsip/impl/signal-corr.hpp
===================================================================
--- src/vsip/impl/signal-corr.hpp	(revision 145922)
+++ src/vsip/impl/signal-corr.hpp	(working copy)
@@ -68,19 +68,16 @@
 				 typename impl::Choose_corr_impl<dim, T>::type>
 		base_type;
 
-  length_type
-  op_count(length_type ref_len, length_type output_len)
-  {
-    return ref_len * output_len * 
-      (impl::Ops_info<T>::mul + impl::Ops_info<T>::add);
-  }
-
   // Constructors, copies, assignments, and destructors.
 public:
   Correlation(Domain<dim> const&   ref_size,
 	      Domain<dim> const&   input_size)
     VSIP_THROW((std::bad_alloc))
-      : base_type(ref_size, input_size)
+      : base_type(ref_size, input_size),
+        event_(impl::signal::Description<dim, T>::tag("Correlation", 
+                 ref_size, input_size), 
+          this->impl_op_count())
+
   {}
 
   Correlation(Correlation const& corr) VSIP_NOTHROW;
@@ -106,11 +103,7 @@
     Vector<T, Block2>       out)
     VSIP_NOTHROW
   {
-    length_type const M = this->reference_size()[0].size();
-    length_type const P = this->output_size()[0].size();
-    int ops = op_count(M, P);
-    impl::profile::Scope_event scope_event("correlate_vector", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_profile_event scope_event(this->event_);
 
     for (dimension_type d=0; d<dim; ++d)
     {
@@ -135,13 +128,7 @@
     Matrix<T, Block2>       out)
     VSIP_NOTHROW
   {
-    length_type const M = this->reference_size()[0].size()
-                        * this->reference_size()[1].size();
-    length_type const P = this->output_size()[0].size()
-                        * this->output_size()[1].size();
-    int ops = op_count(M, P);
-    impl::profile::Scope_event scope_event("correlate_matrix", ops);
-    impl::profile::Time_in_scope scope(this->timer_);
+    impl::profile::Scope_profile_event scope_event(this->event_);
 
     for (dimension_type d=0; d<dim; ++d)
     {
@@ -157,32 +144,26 @@
 
   float impl_performance(char* what) const
   {
-    if (!strcmp(what, "mflops"))
-    {
-      length_type M = this->reference_size()[0].size();
-      length_type P = this->output_size()[0].size();
-      for (dimension_type d=1; d<dim; ++d)
-        M *= this->reference_size()[d].size();
-      for (dimension_type d=1; d<dim; ++d)
-        P *= this->output_size()[d].size();
-      int ops = op_count(M, P);
-      return timer_.count() * ops / (1e6 * timer_.total());
-    }
-    else if (!strcmp(what, "count"))
-    {
-      return timer_.count();
-    }
-    else if (!strcmp(what, "time"))
-    {
-      return timer_.total();
-    }
-    else
-      return base_type::impl_performance(what);
+    if      (!strcmp(what, "mops"))     return this->event_.mflops();
+    else if (!strcmp(what, "time"))     return this->event_.total();
+    else if (!strcmp(what, "count"))    return this->event_.count();
+    else return this->base_type::impl_performance(what);
   }
 
   // Member data.
 private:
-  vsip::impl::profile::Acc_timer timer_;
+  length_type impl_op_count()
+  {
+    length_type   M =  this->reference_size()[0].size();
+    if (dim == 2) M *= this->reference_size()[1].size();
+
+    length_type   P =  this->output_size()[0].size();
+    if (dim == 2) P *= this->output_size()[1].size();
+
+    return M * P * (impl::Ops_info<T>::mul + impl::Ops_info<T>::add);
+  }
+
+  vsip::impl::profile::Profile_event event_;
 };
 
 } // namespace vsip
Index: src/vsip/impl/ops_info.hpp
===================================================================
--- src/vsip/impl/ops_info.hpp	(revision 145922)
+++ src/vsip/impl/ops_info.hpp	(working copy)
@@ -11,6 +11,7 @@
 #define VSIP_IMPL_OPS_INFO_HPP
 
 #include <complex>
+#include <vsip/impl/math-enum.hpp>
 
 namespace vsip
 {
@@ -35,6 +36,285 @@
   static unsigned int const add = 2;
 };
 
+
+typedef float S_type;
+typedef double D_type;
+typedef std::complex<float> C_type;
+typedef std::complex<double> Z_type;
+
+template <typename IO> 
+struct Desc_datatype { static char * value() { return "I"; } };
+template <> 
+struct Desc_datatype<S_type> { static char * value() { return "S"; } };
+template <> 
+struct Desc_datatype<D_type> { static char * value() { return "D"; } };
+template <> 
+struct Desc_datatype<C_type> { static char * value() { return "C"; } };
+template <> 
+struct Desc_datatype<Z_type> { static char * value() { return "Z"; } };
+
+
+namespace signal
+{
+template <int D, typename T>
+struct Description
+{ 
+  static std::string tag(const char* op, length_type size)
+  {
+    std::ostringstream   st;
+    st << op << " " << Desc_datatype<T>::value() << " ";
+
+    st.width(7);
+    st << size;
+
+    return st.str();
+  } 
+
+  static std::string tag(const char* op, Domain<D> const &dom_kernel, 
+    Domain<D> const &dom_output)
+  {
+    std::ostringstream   st;
+    st << op << " " 
+       << D << "D "
+       << Desc_datatype<T>::value() << " ";
+
+    st.width(4);
+    st << dom_kernel[0].size();
+    st.width(1);
+    st << "x" << (D == 2 ? dom_kernel[1].size() : 1) << " ";
+
+    st.width(7);
+    st << dom_output[0].size();
+    st.width(1);
+    st << "x" << (D == 2 ? dom_output[1].size() : 1);
+
+    return st.str();
+  } 
+};
+
+} // namespace signal
+
+
+namespace matvec
+{
+template <typename T>
+struct Op_count_dot
+{ 
+  static length_type value(Domain<1> const &dom)
+  {
+    length_type count = dom[0].size() * Ops_info<T>::mul;
+    if ( dom[0].size() > 1 )
+      count += (dom[0].size() - 1) * Ops_info<T>::add;
+    return  count;
+  } 
+};
+
+template <typename T>
+struct Op_count_cvjdot
+{ 
+  static length_type value(Domain<1> const &dom)
+  {
+    length_type count = dom[0].size() * Ops_info<T>::mul;
+    if ( dom[0].size() > 1 )
+      count += (dom[0].size() - 1) * Ops_info<T>::add;
+    return  count;
+  } 
+};
+
+template <typename T>
+struct Op_count_cvjdot<std::complex<T> >
+{ 
+  static length_type value(Domain<1> const &dom)
+  {
+    // The conjugate of the second vector adds a scalar multiplication 
+    // to the total.
+    length_type count = dom[0].size() * Ops_info<std::complex<T> >::mul +
+      dom[0].size() * Ops_info<T>::mul;
+    if ( dom[0].size() > 1 )
+      count += (dom[0].size() - 1) * Ops_info<std::complex<T> >::add;
+    return  count;
+  } 
+};
+
+template <typename CT>
+struct Op_count_herm
+{ 
+  static length_type value(Domain<2> const &dom)
+  {
+    // The complex conjugate equals one scalar multiply
+    typedef typename impl::Scalar_of<CT>::type T;
+    return dom[0].size() * dom[1].size() * Ops_info<T>::mul;
+  } 
+};
+  
+template <int D,
+          typename T>
+struct Op_count_kron
+{ 
+  static length_type value(Domain<D> const &dom_v, Domain<D> const &dom_w)
+  {
+    length_type r_size = dom_v[0].size() * dom_w[0].size();
+    if ( D == 2 )
+      r_size *= dom_v[1].size() * dom_w[1].size();
+
+    return r_size * 2 * Ops_info<T>::mul;
+  } 
+};
+
+template <typename T>
+struct Op_count_outer
+{ 
+  static length_type value(Domain<1> const &dom_v, Domain<1> const &dom_w)
+  {
+    // Each element is scaled by alpha, resulting in the factor of 2.
+    return dom_v[0].size() * dom_w[0].size() * 2 * Ops_info<T>::mul;
+  } 
+};
+
+template <typename T>
+struct Op_count_outer<std::complex<T> >
+{ 
+  static length_type value(Domain<1> const &dom_v, Domain<1> const &dom_w)
+  {
+    // The conjugate of the second vector is needed (once), adding a 
+    // scalar multiplication to the total.
+    return dom_v[0].size() * dom_w[0].size() * 2 * Ops_info<complex<T> >::mul +
+      dom_w[0].size() * Ops_info<T>::mul;
+  } 
+};
+
+template <typename T>
+struct Op_count_gemp
+{ 
+  static length_type value(Domain<2> const &dom_a, Domain<2> const &dom_b, 
+    mat_op_type op_a, mat_op_type op_b)
+  {
+    length_type r_size = dom_a[0].size() * dom_b[1].size();
+    Domain<1> dom_r(dom_a[1].size());
+
+    length_type mul_ops = Op_count_dot<T>::value(dom_r) * r_size;
+
+    if ( op_a == mat_herm || op_a == mat_conj )
+      mul_ops += Ops_info<Scalar_of<T> >::mul * dom_a[0].size() * dom_a[1].size();
+    if ( op_b == mat_herm || op_b == mat_conj )
+      mul_ops += Ops_info<Scalar_of<T> >::mul * dom_b[0].size() * dom_b[1].size();
+
+    // C = alpha * OpA(A) * OpB(B) + beta * C
+    return r_size * (2 * Ops_info<T>::mul + Ops_info<T>::add) + mul_ops;
+  } 
+};
+
+template <typename T>
+struct Op_count_gems
+{ 
+  static length_type value(Domain<2> const &dom_a, mat_op_type op_a)
+  {
+    length_type r_size = dom_a[0].size() * dom_a[1].size();
+
+    length_type mat_ops = 0;
+    if ( op_a == mat_herm || op_a == mat_conj )
+      mat_ops += r_size * Ops_info<Scalar_of<T> >::mul;
+
+    // C = alpha * OpA(A) + beta * C
+    return r_size * (2 * Ops_info<T>::mul + Ops_info<T>::add) + mat_ops;
+  } 
+};
+
+template <int D,
+          typename T>
+struct Op_count_cumsum
+{ 
+  static length_type value(Domain<D> const &dom_v)
+  {
+    length_type adds = 0;
+    if ( dom_v[0].size() > 1 )
+      adds += (dom_v[0].size() - 1) * dom_v[0].size() / 2;
+    if ( D == 2 )
+      if ( dom_v[1].size() > 1 )
+        adds += (dom_v[1].size() - 1) * dom_v[1].size() / 2;
+
+    return adds * Ops_info<T>::add;
+  } 
+};
+
+template <typename T>
+struct Op_count_modulate
+{ 
+  static length_type value(Domain<1> const &dom_v)
+  {
+    // w(i) = v(i) * exp(0, i * nu + phi)
+    typedef complex<Scalar_of<T> >  CT;
+    
+    return dom_v[0].size() * Ops_info<T>::mul + Ops_info<T>::add +
+      Ops_info<CT>::mul + Ops_info<CT>::add;
+  } 
+};
+
+  
+template <typename T>
+struct Description
+{ 
+  static std::string tag(const char* op, Domain<1> const &dom)
+  {
+    std::ostringstream   st;
+    st << op << " " << Desc_datatype<T>::value() << " ";
+
+    st.width(4);
+    st << dom[0].size();
+    st.width(1);
+    st << "x" << 1;
+
+    return st.str();
+  } 
+
+  static std::string tag(const char* op, Domain<2> const &dom)
+  {
+    std::ostringstream   st;
+    st << op << " " << Desc_datatype<T>::value() << " ";
+
+    st.width(4);
+    st << dom[0].size();
+    st.width(1);
+    st << "x" << dom[1].size();
+
+    return st.str();
+  } 
+
+  static std::string tag(const char* op, Domain<1> const &dom_v, Domain<1> const &dom_w)
+  {
+    std::ostringstream   st;
+    st << op << " " << Desc_datatype<T>::value() << " ";
+
+    st.width(4);
+    st << dom_v[0].size() << "x1";
+
+    st.width(4);
+    st << dom_w[0].size() << "x1";
+
+    return st.str();
+  } 
+
+  static std::string tag(const char* op, Domain<2> const &dom_v, Domain<2> const &dom_w)
+  {
+    std::ostringstream   st;
+    st << op << " " << Desc_datatype<T>::value() << " ";
+
+    st.width(4);
+    st << dom_v[0].size();
+    st.width(1);
+    st << "x" << dom_v[1].size() << " ";
+
+    st.width(4);
+    st << dom_w[0].size();
+    st.width(1);
+    st << "x" << dom_w[1].size();
+
+    return st.str();
+  } 
+};
+} // namespace matvec
+
+
 } // namespace impl
 } // namespace vsip
 
Index: src/vsip/impl/fft.hpp
===================================================================
--- src/vsip/impl/fft.hpp	(revision 145922)
+++ src/vsip/impl/fft.hpp	(working copy)
@@ -85,7 +85,7 @@
     : input_size_(io_size<D, I, O, A>::size(dom)),
       output_size_(io_size<D, O, I, A>::size(dom)),
       scale_(scale), 
-      event_( fft::description<D, I, O>::tag(dom, dir, rm),
+      event_( fft::Description<D, I, O>::tag(dom, dir, rm),
               op_count(io_size<D, O, I, A>::size(dom).size()) )
   {}
 
@@ -107,9 +107,9 @@
   
   float impl_performance(char* what) const
   {
-    if (!strcmp(what, "mflops"))
+    if (!strcmp(what, "mops"))
     {
-      return this->event_.mflops();
+      return this->event_.mops();
     }
     else if (!strcmp(what, "time"))
     {
Index: src/vsip/impl/signal-fir.hpp
===================================================================
--- src/vsip/impl/signal-fir.hpp	(revision 145922)
+++ src/vsip/impl/signal-fir.hpp	(working copy)
@@ -18,6 +18,7 @@
 #include <vsip/impl/fast-block.hpp>
 #include <vsip/impl/global_map.hpp>
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 namespace vsip
 {
@@ -130,10 +131,11 @@
              (symV == vsip::sym_even_len_odd) - 1)
   , decimation_(decimation)
   , skip_(0)
-  , op_calls_(0)
   , kernel_(this->order_ + 1)
   , state_(2 * (this->order_ + 1), T(0))   // IPP wants 2x.
   , state_saved_(0)
+  , event_(impl::signal::Description<1, T>::tag("Fir", this->input_size_), 
+      this->impl_op_count())
 #if VSIP_IMPL_HAVE_IPP
   , temp_in_(this->input_size_)
   , temp_out_(this->input_size_)
@@ -178,10 +180,10 @@
   , order_(fir.order_)
   , decimation_(fir.decimation_)
   , skip_(fir.skip_)
-  , op_calls_(0)
   , kernel_(fir.kernel_)
   , state_(fir.state_.get(vsip::Domain<1>(fir.state_.size())))  // actual copy
   , state_saved_(fir.state_saved_) 
+  , event_(fir.event_)
 #if VSIP_IMPL_HAVE_IPP
   , temp_in_(this->input_size_)   // allocate
   , temp_out_(this->input_size_)  // allocate
@@ -194,10 +196,10 @@
     assert(this->order_ == fir.order_);
     assert(this->decimation_ = fir.decimation_);
     this->skip_ = fir.skip_;
-    this->op_calls_ = 0;
     this->kernel_ = fir.kernel_;
     this->state_ = fir.state_;
     this->state_saved_ = fir.state_saved_;
+    this->event_ = fir.event_;
     return *this;
   }
 
@@ -225,7 +227,7 @@
     vsip::Vector<T, Block1>  out)
       VSIP_NOTHROW
   {
-    ++ this->op_calls_;
+    impl::profile::Scope_profile_event scope_event(this->event_);
     assert(data.size() == this->input_size_);
     assert(out.size() == this->output_size_);
 
@@ -314,36 +316,32 @@
 
   float impl_performance(char* what) const  VSIP_NOTHROW
   {
-    if (!strcmp(what, "mflops"))
-    {
-      // Compute rough estimate of flop-count.
-      unsigned cxmul = impl::Is_complex<T>::value ? 4 : 1; // *(4*,2+), +(2+)
-      return (this->timer_.count() * cxmul * 2 *  // 1* 1+
-        ((this->order + 1) * this->input_size_ / this->decimation_)) /
-          (1e6 * this->timer_.total());
-    }
-    else if (!strcmp(what, "time"))
-      return this->timer_.total();
-    else if (!strcmp(what, "count"))
-      return this->op_calls_;
+    if      (!strcmp(what, "mops"))     return this->event_.mflops();
+    else if (!strcmp(what, "time"))     return this->event_.total();
+    else if (!strcmp(what, "count"))    return this->event_.count();
     return 0.f;
   }
 
 private:
+  length_type impl_op_count()
+  {
+    return (impl::Ops_info<T>::mul + impl::Ops_info<T>::add) *
+      ((this->order_ + 1) * this->input_size_ / this->decimation_);
+  }
+
   vsip::length_type  input_size_;
   vsip::length_type  output_size_; 
   vsip::length_type  order_;         // M in the spec
   vsip::length_type  decimation_;
   vsip::length_type  skip_;          // how much of next input to skip
-  unsigned long  op_calls_;
   vsip::Vector<T,typename impl::Fir_aligned<T>::block_type>  kernel_; 
   vsip::Vector<T,typename impl::Fir_aligned<T>::block_type>  state_;
   vsip::length_type  state_saved_;   // number of elements saved
+  impl::profile::Profile_event event_;
 #if VSIP_IMPL_HAVE_IPP
   vsip::Vector<T,typename impl::Fir_aligned<T>::block_type>  temp_in_;
   vsip::Vector<T,typename impl::Fir_aligned<T>::block_type>  temp_out_;
 #endif
-  impl::profile::Acc_timer timer_;
 };
 
 } // namespace vsip
Index: src/vsip/impl/profile.hpp
===================================================================
--- src/vsip/impl/profile.hpp	(revision 145922)
+++ src/vsip/impl/profile.hpp	(working copy)
@@ -373,9 +373,9 @@
   const char* name() const { return name_.c_str(); }
   unsigned int ops() const { return ops_; }
 
-  float  total() const { return this->timer_.total(); }
-  int    count() const { return this->timer_.count(); }
-  float mflops() const { return (count() * ops()) / (1e6 * total()); }
+  float total() const { return this->timer_.total(); }
+  int   count() const { return this->timer_.count(); }
+  float  mops() const { return (count() * ops()) / (1e6 * total()); }
 
   TP::stamp_type start() { return this->timer_.start(); }
   TP::stamp_type  stop() { return this->timer_.stop(); }
@@ -406,16 +406,23 @@
 
 class Scope_event : Non_copyable
 {
+  typedef DefaultTime    TP;
+
 public:
   Scope_event(const char* name, int value=0)
     : name_(name),
-      id_  (prof->event(name, value, 0))
+      id_  (prof->event(name, value, 0, TP::stamp_type()))
   {}
 
-  ~Scope_event() { prof->event(name_, 0, id_); }
+  Scope_event(std::string name, int value=0)
+    : name_(name),
+      id_  (prof->event(name.c_str(), value, 0))
+  {}
 
+  ~Scope_event() { prof->event(name_.c_str(), 0, id_, TP::stamp_type()); }
+
 private:
-  const char* name_;
+  std::string name_;
   int   id_;
 };
 
Index: src/vsip/impl/matvec.hpp
===================================================================
--- src/vsip/impl/matvec.hpp	(revision 145922)
+++ src/vsip/impl/matvec.hpp	(working copy)
@@ -23,6 +23,8 @@
 #include <vsip/impl/eval-blas.hpp>
 #include <vsip/impl/eval-sal.hpp>
 #include <vsip/impl/math-enum.hpp>
+#include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 
 namespace vsip
@@ -85,7 +87,7 @@
 };
 
 
-/// Outer product
+// Outer product dispatch
 
 template <typename T0,
 	  typename T1,
@@ -135,7 +137,32 @@
 };
 
 
+// Dot product dispatch.  This is intentionally not named 'dot' to avoid
+// conflicting with vsip::dot, which shares the same signature, forcing
+// the user to resolve the call themselves.
 
+template <typename T0, typename T1, typename Block0, typename Block1>
+typename Promotion<T0, T1>::type
+impl_dot(
+  const_Vector<T0, Block0> v,
+  const_Vector<T1, Block1> w) VSIP_NOTHROW
+{
+  typedef typename Promotion<T0, T1>::type return_type;
+
+  return_type r(0);
+
+  r = impl::General_dispatch<
+		impl::Op_prod_vv_dot,
+                impl::Return_scalar<return_type>,
+                impl::Op_list_2<Block0, Block1>,
+                typename impl::Dispatch_order<impl::Op_prod_vv_dot>::type >
+	::exec(v.block(), w.block());
+
+  return r;
+};
+
+
+
 // vector-vector kron
 template <typename T0,
           typename T1,
@@ -143,7 +170,7 @@
           typename Block1,
           typename Block2>
 const_Matrix<typename Promotion<T0, typename Promotion<T1, T2>::type>::type>
-kron( T0 alpha, Vector<T1, Block1> v, Vector<T2, Block2> w)
+impl_kron( T0 alpha, Vector<T1, Block1> v, Vector<T2, Block2> w)
     VSIP_NOTHROW
 {
   typedef Matrix<typename Promotion<T0, 
@@ -164,7 +191,7 @@
           typename Block1,
           typename Block2>
 const_Matrix<typename Promotion<T0, typename Promotion<T1, T2>::type>::type>
-kron( T0 alpha, Matrix<T1, Block1> v, Matrix<T2, Block2> w)
+impl_kron( T0 alpha, Matrix<T1, Block1> v, Matrix<T2, Block2> w)
     VSIP_NOTHROW
 {
   typedef Matrix<typename Promotion<T0, 
@@ -176,7 +203,8 @@
   for ( index_type i = v.size(0); i-- > 0; )
     for ( index_type j = w.size(0); j-- > 0; )
       for ( index_type k = v.size(1); k-- > 0; )
-        for ( index_type l = w.size(1); l-- > 0; ) {
+        for ( index_type l = w.size(1); l-- > 0; ) 
+        {
           T0 val = alpha * v.get(i,k) * w.get(j,l);
           r.put( j + (i * w.size(0)), l + (k * w.size(1)), val );
         }
@@ -545,18 +573,13 @@
   const_Vector<T0, Block0> v,
   const_Vector<T1, Block1> w) VSIP_NOTHROW
 {
-  typedef typename Promotion<T0, T1>::type return_type;
+  typedef typename Promotion<T0, T1>::type result_type;
+  Domain<1> dom_v( view_domain(v) );
+  impl::profile::Scope_event event( 
+    impl::matvec::Description<result_type>::tag("dot", dom_v),
+    impl::matvec::Op_count_dot<result_type>::value(dom_v) );
 
-  return_type r(0);
-
-  r = impl::General_dispatch<
-		impl::Op_prod_vv_dot,
-                impl::Return_scalar<return_type>,
-                impl::Op_list_2<Block0, Block1>,
-                typename impl::Dispatch_order<impl::Op_prod_vv_dot>::type >
-	::exec(v.block(), w.block());
-
-  return r;
+  return impl::impl_dot(v, w);
 }
 
 
@@ -568,7 +591,13 @@
   const_Vector<complex<T0>, Block0> v,
   const_Vector<complex<T1>, Block1> w) VSIP_NOTHROW
 {
-  return dot(v, conj(w));
+  typedef typename Promotion<T0, T1>::type result_type;
+  Domain<1> dom_v( view_domain(v) );
+  impl::profile::Scope_event event( 
+    impl::matvec::Description<result_type>::tag("cvjdot", dom_v),
+    impl::matvec::Op_count_cvjdot<result_type>::value(dom_v) );
+
+  return impl::impl_dot(v, conj(w));
 }
 
  
@@ -580,6 +609,9 @@
 typename const_Matrix<T, Block>::transpose_type
 trans(const_Matrix<T, Block> m) VSIP_NOTHROW
 {
+  impl::profile::Scope_event event( 
+    impl::matvec::Description<T>::tag("trans", impl::view_domain(m)) );
+
   return m.transpose();
 }
 
@@ -590,6 +622,11 @@
   Block>::transpose_type>::result_type
 herm(const_Matrix<complex<T>, Block> m) VSIP_NOTHROW
 {
+  Domain<2> dom( impl::view_domain(m) );
+  impl::profile::Scope_event event( 
+    impl::matvec::Description<complex<T> >::tag("herm", dom),
+    impl::matvec::Op_count_herm<complex<T> >::value(dom) );
+
   typedef typename const_Matrix<complex<T>, Block>::transpose_type 
     transpose_type;
   typedef impl::Unary_func_view<impl::conj_functor, transpose_type> 
@@ -612,7 +649,16 @@
 kron( T0 alpha, const_View<T1, Block1> v, const_View<T2, Block2> w )
     VSIP_NOTHROW
 {
-  return impl::kron( alpha, v, w );
+  dimension_type const dim = impl::Dim_of_view<const_View>::dim;
+  typedef typename Promotion<T0, typename Promotion<T1, T2>::type
+    >::type result_type;
+  Domain<dim> dom_v = impl::view_domain(v);
+  Domain<dim> dom_w = impl::view_domain(w);
+  impl::profile::Scope_event event( 
+    impl::matvec::Description<result_type>::tag("kron", dom_v, dom_w),
+    impl::matvec::Op_count_kron<dim, result_type>::value(dom_v, dom_w) );
+
+  return impl::impl_kron( alpha, v, w );
 }
 
 
@@ -629,6 +675,12 @@
     VSIP_NOTHROW
 {
   typedef typename Promotion<T1, T2>::type return_type;
+  Domain<1> dom_v( view_domain(v) );
+  Domain<1> dom_w( view_domain(w) );
+  impl::profile::Scope_event event( 
+    impl::matvec::Description<return_type>::tag("outer", dom_v, dom_w),
+    impl::matvec::Op_count_outer<return_type>::value(dom_v, dom_w) );
+
   Matrix<return_type> r(v.size(), w.size(), return_type());
 
   impl::outer(alpha, v, w, r);
@@ -659,6 +711,12 @@
     Matrix<T4, Block4> C)
      VSIP_NOTHROW
 {
+  Domain<2> dom_a( view_domain(A) );
+  Domain<2> dom_b( view_domain(B) );
+  impl::profile::Scope_event event( 
+    impl::matvec::Description<T4>::tag("gemp", dom_a, dom_b),
+    impl::matvec::Op_count_gemp<T4>::value(dom_a, dom_b, OpA, OpB) );
+
   // equivalent to C = alpha * OpA(A) * OpB(B) + beta * C
   impl::gemp( alpha, 
               impl::apply_mat_op<OpA>(A), 
@@ -684,6 +742,11 @@
   Matrix<T4, Block4> C) 
     VSIP_NOTHROW
 {
+  Domain<2> dom_a( view_domain(A) );
+  impl::profile::Scope_event event( 
+    impl::matvec::Description<T4>::tag("gems", dom_a),
+    impl::matvec::Op_count_gems<T4>::value(dom_a, OpA) );
+
   impl::gems( alpha,
               impl::apply_mat_op<OpA>(A),
               beta,
@@ -707,6 +770,12 @@
   View<T1, Block1> w) 
     VSIP_NOTHROW
 {
+  dimension_type const dim = impl::Dim_of_view<const_View>::dim;
+  Domain<dim> dom_v( view_domain(v) );
+  impl::profile::Scope_event event( 
+    impl::matvec::Description<T0>::tag("cumsum", dom_v),
+    impl::matvec::Op_count_cumsum<dim, T0>::value(dom_v) );
+
   impl::cumsum<d>(v, w);
 }
 
@@ -725,6 +794,11 @@
   Vector<complex<T3>, Block1> w)
     VSIP_NOTHROW
 {
+  Domain<1> dom_v( view_domain(v) );
+  impl::profile::Scope_event event( 
+    impl::matvec::Description<T0>::tag("modulate", dom_v),
+    impl::matvec::Op_count_modulate<T0>::value(dom_v) );
+
   return impl::modulate(v, nu, phi, w);
 }
 
Index: apps/sarsim/sarsim.hpp
===================================================================
--- apps/sarsim/sarsim.hpp	(revision 145922)
+++ apps/sarsim/sarsim.hpp	(working copy)
@@ -526,21 +526,21 @@
   printf("Range Processing  : %7.2f mflops (%6.2f s)\n",
 	 rp_mflops, rp_time_.total());
   printf("   range fft      : %7.2f mflops (%6.2f s)\n",
-	 range_fft_.impl_performance("mflops"),
+	 range_fft_.impl_performance("mops"),
 	 range_fft_.impl_performance("time"));
   printf("   iconv          : %7.2f mflops (%6.2f s)\n",
-	 iconv_.impl_performance("mflops"),
+	 iconv_.impl_performance("mops"),
 	 iconv_.impl_performance("time"));
   printf("   qconv          : %7.2f mflops (%6.2f s)\n",
-	 qconv_.impl_performance("mflops"),
+	 qconv_.impl_performance("mops"),
 	 qconv_.impl_performance("time"));
 
   printf("Azimuth Processing: %7.2f mflops (%6.2f s)\n",
 	 ap_mflops, ap_time_.total());
   printf("   az for fft     : %7.2f mflops (%6.2f s)\n",
-	 az_for_fft_.impl_performance("mflops"),
+	 az_for_fft_.impl_performance("mops"),
 	 az_for_fft_.impl_performance("time"));
   printf("   az inv fft     : %7.2f mflops (%6.2f s)\n",
-	 az_inv_fft_.impl_performance("mflops"),
+	 az_inv_fft_.impl_performance("mops"),
 	 az_inv_fft_.impl_performance("time"));
 }
Index: benchmarks/dist_vmul.cpp
===================================================================
--- benchmarks/dist_vmul.cpp	(revision 145922)
+++ benchmarks/dist_vmul.cpp	(working copy)
@@ -114,7 +114,7 @@
 struct t_dist_vmul<T, MapT, SP, Impl_assign>
 {
   char* what() { return "t_vmul"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -196,7 +196,7 @@
 struct t_dist_vmul<T, MapT, SP, Impl_sa>
 {
   char* what() { return "t_vmul"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
Index: benchmarks/GNUmakefile.inc.in
===================================================================
--- benchmarks/GNUmakefile.inc.in	(revision 145922)
+++ benchmarks/GNUmakefile.inc.in	(working copy)
@@ -41,6 +41,7 @@
                                          $(srcdir)/benchmarks/qrd.cpp
 benchmarks_cxx_srcs_ipp    := $(wildcard $(srcdir)/benchmarks/*_ipp.cpp) 
 benchmarks_cxx_srcs_sal    := $(wildcard $(srcdir)/benchmarks/*_sal.cpp) 
+benchmarks_cxx_srcs_mpi    := $(wildcard $(srcdir)/benchmarks/mpi_*.cpp) 
 
 benchmarks_cxx_exes_lapack := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT),  \
                                 $(benchmarks_cxx_srcs_lapack))
@@ -48,6 +49,8 @@
                                 $(benchmarks_cxx_srcs_ipp))
 benchmarks_cxx_exes_sal    := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT),  \
                                 $(benchmarks_cxx_srcs_sal))
+benchmarks_cxx_exes_mpi    := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT),  \
+                                $(benchmarks_cxx_srcs_mpi))
 
 ifndef VSIP_IMPL_HAVE_LAPACK
   benchmarks_cxx_exes_def_build := $(filter-out 	\
@@ -64,6 +67,11 @@
 	$(benchmarks_cxx_exes_sal), $(benchmarks_cxx_exes_def_build)) 
 endif
 
+ifndef VSIP_IMPL_MPI_H
+  benchmarks_cxx_exes_def_build := $(filter-out		\
+	$(benchmarks_cxx_exes_mpi), $(benchmarks_cxx_exes_def_build)) 
+endif
+
 cxx_sources += $(benchmarks_cxx_sources)
 
 benchmarks_cxx_statics_def_build :=				\
Index: examples/fft.cpp
===================================================================
--- examples/fft.cpp	(revision 145922)
+++ examples/fft.cpp	(working copy)
@@ -66,8 +66,8 @@
   test_assert(error_db(ref, out) < -100);
   test_assert(error_db(inv, in) < -100);
 
-  std::cout << f_fft.impl_performance("mflops") << std::endl;
-  std::cout << i_fft.impl_performance("mflops") << std::endl;
+  std::cout << f_fft.impl_performance("mops") << std::endl;
+  std::cout << i_fft.impl_performance("mops") << std::endl;
 }
 
 
