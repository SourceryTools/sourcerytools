Index: ChangeLog
===================================================================
--- ChangeLog	(revision 147597)
+++ ChangeLog	(working copy)
@@ -1,3 +1,22 @@
+<<<<<<< .mine
+2006-08-24  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/impl/fft/util.hpp: Moved description to ops_info.hpp.
+	* src/vsip/impl/signal-iir.hpp: Moved ops count to ops_info.hpp.
+	* src/vsip/impl/expr_ops_info.hpp: Added Vmmul specializations.
+	* src/vsip/impl/signal-conv.hpp: Moved ops count to ops_info.hpp.
+	* src/vsip/impl/signal-corr.hpp: Moved ops count to ops_info.hpp.
+	* src/vsip/impl/ops_info.hpp: Added op counts as noted.  Removed
+          leading spaces from sizes in descriptions.  Sizes for 1-D
+          objects no longer show "x1" for the second dimension.  Removed 
+	  dimension from Fft and Fftm descriptions.  
+	* src/vsip/impl/fft.hpp: Moved ops count to ops_info.hpp. Made
+          Fft/Fftm naming explicit instead of inferring it from dimension.
+	* src/vsip/impl/signal-fir.hpp: Moved ops count to ops_info.hpp.
+	* src/vsip/impl/expr_serial_dispatch.hpp: Added include for
+	  impl/profile.hpp.
+
+=======
 2006-08-24  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac: New AC_SUBST for svpp_library: root name
@@ -27,6 +46,7 @@
 	* doc/tutorial/src/par/fc1-parallel.cpp: Likewise.
 	* doc/tutorial/src/par/fc1-serial.cpp: Likewise.
 	
+>>>>>>> .r147597
 2006-08-21  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/complex.hpp: Added functions to provide names for 
Index: src/vsip/impl/fft/util.hpp
===================================================================
--- src/vsip/impl/fft/util.hpp	(revision 147597)
+++ src/vsip/impl/fft/util.hpp	(working copy)
@@ -73,31 +73,6 @@
 };
 
 
-// Create a readable tag from parameters.
-template <int D, typename I, typename O>
-struct Description
-{ 
-  static std::string tag(Domain<D> const &dom, int dir, 
-    return_mechanism_type rm)
-  {
-    std::ostringstream   st;
-    st << (D == 2 ? "Fftm " : "Fft ")
-       << D << "D "
-       << (dir == -1 ? "Inv " : "Fwd ")
-       << Desc_datatype<I>::value() << "-"
-       << Desc_datatype<O>::value() << " "
-       << (rm == vsip::by_reference ? "by_ref " : "by_val ");
-
-    st.width(7);
-    st << dom[0].size();
-    st.width(1);
-    st << "x" << ((D == 2) ? dom[1].size() : 1);
-
-    return st.str();
-  } 
-};
-
-
 template <typename View>
 View
 new_view(vsip::Domain<1> const& dom) { return View(dom.size());} 
Index: src/vsip/impl/signal-iir.hpp
===================================================================
--- src/vsip/impl/signal-iir.hpp	(revision 147597)
+++ src/vsip/impl/signal-iir.hpp	(working copy)
@@ -101,13 +101,6 @@
     return 0.f;
   }
 
-private:
-  length_type impl_op_count()
-  {
-    return ( this->input_size_ * this->a_.size(0) *
-      (5 * impl::Ops_info<T>::mul + 4 * impl::Ops_info<T>::add) );
-  }
-
   // Member data.
 private:
   Matrix<T>   b_;
@@ -139,7 +132,8 @@
     w_         (b_.size(0), 2, T()),
     input_size_(input_size),
     event_(impl::signal::Description<1, T>::tag("Iir", input_size), 
-      this->impl_op_count())
+           impl::signal::Op_count_iir<T>::value(this->input_size_, 
+             this->a_.size(0)))
 {
   assert(b_.size(0) == a_.size(0));
   assert(b_.size(1) == 3);
Index: src/vsip/impl/expr_ops_info.hpp
===================================================================
--- src/vsip/impl/expr_ops_info.hpp	(revision 147597)
+++ src/vsip/impl/expr_ops_info.hpp	(working copy)
@@ -35,6 +35,13 @@
 namespace impl
 {
 
+// Forward declaration
+template <dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+class Vmmul_expr_block;
+
+
 /// These generate char tags for given data types, defaulting to int
 /// with specializations for common floating point types.  These use
 /// BLAS/LAPACK convention.
@@ -399,6 +406,17 @@
   };
 
   template <dimension_type                Dim0,
+	    typename                      LBlock,
+	    typename                      RBlock>
+  struct transform<Vmmul_expr_block<Dim0, LBlock, RBlock> >
+  {
+    typedef typename binary_node<Dim0, op::Mult,
+              typename transform<LBlock>::type, typename LBlock::value_type,
+              typename transform<RBlock>::type, typename RBlock::value_type>
+              ::type type;
+  };
+
+  template <dimension_type                Dim0,
 	    template <typename, typename, typename> class Op,
 	    typename                      Block1,
 	    typename                      Type1,
@@ -507,6 +525,19 @@
     } 
   };
 
+  template <dimension_type                Dim0,
+	    typename                      LBlock,
+	    typename                      RBlock>
+  struct transform<Vmmul_expr_block<Dim0, LBlock, RBlock> >
+  {
+    static std::string tag()
+    {
+      return std::string("vmmul") + std::string("(")
+        + transform<LBlock>::tag() + std::string(",")
+        + transform<RBlock>::tag() + std::string(")"); 
+    } 
+  };
+
   template <dimension_type                                Dim0,
 	    template <typename, typename, typename> class Op,
 	    typename                                      Block1,
Index: src/vsip/impl/signal-conv.hpp
===================================================================
--- src/vsip/impl/signal-conv.hpp	(revision 147597)
+++ src/vsip/impl/signal-conv.hpp	(working copy)
@@ -94,11 +94,15 @@
     VSIP_THROW((std::bad_alloc))
       : base_type(filter_coeffs, input_size, decimation),
         event_(impl::signal::Description<dim, T>::tag( "Convolution", 
-                 impl::extent(filter_coeffs),
                  impl::extent(impl::conv_output_size(
                                 Supp, view_domain(filter_coeffs), 
-                                input_size, decimation)) 
-               ), this->impl_op_count())
+                                input_size, decimation)),
+                 impl::extent(filter_coeffs) ),
+               impl::signal::Op_count_conv<dim, T>::value(
+                 impl::extent(impl::conv_output_size(
+                                Supp, view_domain(filter_coeffs), 
+                                input_size, decimation)),
+                 impl::extent(filter_coeffs) ))
   {
     assert(decimation >= 1);
     assert(Symm == nonsym ? (filter_coeffs.size() <=   input_size.size())
@@ -195,17 +199,6 @@
   // Member data.
 private:
 
-  length_type impl_op_count()
-  {
-    length_type   M =  this->kernel_size()[0].size();
-    if (dim == 2) M *= this->kernel_size()[1].size();
-
-    length_type   P =  this->output_size()[0].size();
-    if (dim == 2) P *= this->output_size()[1].size();
-
-    return M * P * (impl::Ops_info<T>::mul + impl::Ops_info<T>::add);
-  }
-
   vsip::impl::profile::Profile_event event_;
 };
 
Index: src/vsip/impl/signal-corr.hpp
===================================================================
--- src/vsip/impl/signal-corr.hpp	(revision 147597)
+++ src/vsip/impl/signal-corr.hpp	(working copy)
@@ -80,8 +80,9 @@
     VSIP_THROW((std::bad_alloc))
       : base_type(ref_size, input_size),
         event_(impl::signal::Description<dim, T>::tag("Correlation", 
-                 impl::extent(ref_size), impl::extent(input_size)), 
-          this->impl_op_count())
+                 impl::extent(input_size), impl::extent(ref_size)),
+               impl::signal::Op_count_corr<dim, T>::value(
+                 impl::extent(input_size), impl::extent(ref_size)))
   {}
 
   Correlation(Correlation const& corr) VSIP_NOTHROW;
@@ -161,17 +162,7 @@
 
   // Member data.
 private:
-  length_type impl_op_count()
-  {
-    length_type   M =  this->reference_size()[0].size();
-    if (dim == 2) M *= this->reference_size()[1].size();
 
-    length_type   P =  this->output_size()[0].size();
-    if (dim == 2) P *= this->output_size()[1].size();
-
-    return M * P * (impl::Ops_info<T>::mul + impl::Ops_info<T>::add);
-  }
-
   vsip::impl::profile::Profile_event event_;
 };
 
Index: src/vsip/impl/ops_info.hpp
===================================================================
--- src/vsip/impl/ops_info.hpp	(revision 147597)
+++ src/vsip/impl/ops_info.hpp	(working copy)
@@ -1,9 +1,10 @@
 /* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/impl/ops_info.cpp
-    @author  Jules Bergmann
+    @author  Jules Bergmann, Don McCoy
     @date    2005-07-11
-    @brief   VSIPL++ Library: Operation
+    @brief   VSIPL++ Library: Operation counts for vector, matrix 
+                              and signal-processing functions.
 
 */
 
@@ -37,56 +38,137 @@
 };
 
 
-typedef float S_type;
-typedef double D_type;
-typedef std::complex<float> C_type;
-typedef std::complex<double> Z_type;
+template <typename T> 
+struct Desc_datatype    { static char * value() { return "I"; } };
 
-template <typename IO> 
-struct Desc_datatype { static char * value() { return "I"; } };
-template <> 
-struct Desc_datatype<S_type> { static char * value() { return "S"; } };
-template <> 
-struct Desc_datatype<D_type> { static char * value() { return "D"; } };
-template <> 
-struct Desc_datatype<C_type> { static char * value() { return "C"; } };
-template <> 
-struct Desc_datatype<Z_type> { static char * value() { return "Z"; } };
+#define VSIP_IMPL_DESC_DATATYPE(T, VALUE)		\
+template <>					\
+struct Desc_datatype<T> { static char * value() { return VALUE; } };
 
+VSIP_IMPL_DESC_DATATYPE(float,                "S");
+VSIP_IMPL_DESC_DATATYPE(double,               "D");
+VSIP_IMPL_DESC_DATATYPE(std::complex<float>,  "C");
+VSIP_IMPL_DESC_DATATYPE(std::complex<double>, "Z");
 
+#undef VSIP_IMPL_DESC_DATATYPE
+
+
+
+
+namespace fft
+{
+
+template <typename I, typename O>
+struct Op_count
+{ 
+  static length_type value(length_type len)
+  { 
+    length_type ops = static_cast<length_type>(
+      5 * len * std::log((float)len) / std::log(2.f));
+    if (sizeof(I) != sizeof(O)) ops /= 2;
+    return ops;
+  }
+};
+
+
+template <int D, typename I, typename O>
+struct Description
+{ 
+  static std::string tag(const char* op, Domain<D> const &dom, int dir, 
+    return_mechanism_type rm)
+  {
+    std::ostringstream   st;
+    st << op << " "
+       << (dir == -1 ? "Inv " : "Fwd ")
+       << Desc_datatype<I>::value() << "-"
+       << Desc_datatype<O>::value() << " "
+       << (rm == vsip::by_reference ? "by_ref " : "by_val ")
+       << dom[0].size();
+    if (D == 2)
+       st << "x" << dom[1].size();
+
+    return st.str();
+  } 
+};
+
+} // namespace fft
+
+
 namespace signal
 {
+
+template <dimension_type D,
+          typename T>
+struct Op_count_conv
+{ 
+  static length_type value(Length<D> const& len_output, 
+    Length<D> const& len_kernel)
+  {
+    length_type   M =  len_kernel[0];
+    if (D == 2) M *= len_kernel[1];
+
+    length_type   P =  len_output[0];
+    if (D == 2) P *= len_output[1];
+
+    return M * P * (Ops_info<T>::mul + Ops_info<T>::add);
+  }
+};
+
+
+template <dimension_type D,
+          typename T>
+struct Op_count_corr : Op_count_conv<D, T>
+{};
+
+
+template <typename T>
+struct Op_count_fir
+{ 
+  static length_type value(length_type order, length_type size, 
+    length_type decimation)
+  {
+    return (Ops_info<T>::mul + Ops_info<T>::add) *
+      ((order + 1) * size / decimation);
+  } 
+};
+
+template <typename T>
+struct Op_count_iir
+{ 
+  static length_type value(length_type input_size, length_type kernel_size)
+  {
+    return ( input_size * kernel_size *
+      (5 * Ops_info<T>::mul + 4 * Ops_info<T>::add) );
+  }
+};
+
+
 template <dimension_type D, typename T>
 struct Description
 { 
   static std::string tag(const char* op, length_type size)
   {
     std::ostringstream   st;
-    st << op << " " << Desc_datatype<T>::value() << " ";
+    st << op << " " << Desc_datatype<T>::value() << " " << size;
 
-    st.width(7);
-    st << size;
-
     return st.str();
   } 
 
-  static std::string tag(const char* op, Length<D> const& len_kernel,
-    Length<D> const& len_output)
+  static std::string tag(const char* op, Length<D> const& len_output, 
+    Length<D> const& len_kernel)
   {
     std::ostringstream   st;
     st << op << " " 
        << D << "D "
        << Desc_datatype<T>::value() << " ";
 
-    st.width(4);
     st << len_kernel[0];
-    st.width(1);
-    st << "x" << (D == 2 ? len_kernel[1] : 1) << " ";
+    if (D == 2) 
+      st << "x" << len_kernel[1] << " ";
 
-    st.width(7);
     st << len_output[0];
-    st.width(1);
-    st << "x" << (D == 2 ? len_output[1] : 1);
+    if (D == 2) 
+      st << "x" << len_output[1];
 
     return st.str();
   } 
@@ -257,58 +339,38 @@
   static std::string tag(const char* op, Length<1> const& len)
   {
     std::ostringstream   st;
-    st << op << " " << Desc_datatype<T>::value() << " ";
+    st << op << " " << Desc_datatype<T>::value() << " " << len[0];
 
-    st.width(4);
-    st << len[0];
-    st.width(1);
-    st << "x" << 1;
-
     return st.str();
   } 
 
   static std::string tag(const char* op, Length<2> const& len)
   {
     std::ostringstream   st;
-    st << op << " " << Desc_datatype<T>::value() << " ";
+    st << op << " " << Desc_datatype<T>::value() << " " 
+       << len[0] << "x" << len[1];
 
-    st.width(4);
-    st << len[0];
-    st.width(1);
-    st << "x" << len[1];
-
     return st.str();
   } 
 
-  static std::string tag(const char* op, Length<1> const& len_v, Length<1> const& len_w)
+  static std::string tag(const char* op, Length<1> const& len_v, 
+    Length<1> const& len_w)
   {
     std::ostringstream   st;
-    st << op << " " << Desc_datatype<T>::value() << " ";
+    st << op << " " << Desc_datatype<T>::value() << " "
+       << len_v[0] << " " << len_w[0];
 
-    st.width(4);
-    st << len_v[0] << "x1";
-
-    st.width(4);
-    st << len_w[0] << "x1";
-
     return st.str();
   } 
 
-  static std::string tag(const char* op, Length<2> const& len_v, Length<2> const& len_w)
+  static std::string tag(const char* op, Length<2> const& len_v, 
+    Length<2> const& len_w)
   {
     std::ostringstream   st;
-    st << op << " " << Desc_datatype<T>::value() << " ";
+    st << op << " " << Desc_datatype<T>::value() << " "
+       << len_v[0] << "x" << len_v[1] << " "
+       << len_w[0] << "x" << len_w[1];
 
-    st.width(4);
-    st << len_v[0];
-    st.width(1);
-    st << "x" << len_v[1] << " ";
-
-    st.width(4);
-    st << len_w[0];
-    st.width(1);
-    st << "x" << len_w[1];
-
     return st.str();
   } 
 };
Index: src/vsip/impl/fft.hpp
===================================================================
--- src/vsip/impl/fft.hpp	(revision 147597)
+++ src/vsip/impl/fft.hpp	(working copy)
@@ -79,21 +79,13 @@
   static dimension_type const dim = D;
   typedef typename impl::Scalar_of<I>::type scalar_type;
 
-  length_type
-  op_count(length_type len) const
-  { 
-    length_type ops = 
-      static_cast<length_type>(5 * len * std::log((float)len) / std::log(2.f)); 
-    if (sizeof(I) != sizeof(O)) ops /= 2;
-    return ops;
-  }
-
-  base_interface(Domain<D> const &dom, scalar_type scale, int dir, return_mechanism_type rm)
+  base_interface(Domain<D> const &dom, scalar_type scale, 
+    char const* name, int dir, return_mechanism_type rm)
     : input_size_(io_size<D, I, O, A>::size(dom)),
       output_size_(io_size<D, O, I, A>::size(dom)),
       scale_(scale), 
-      event_( fft::Description<D, I, O>::tag(dom, dir, rm),
-              op_count(io_size<D, O, I, A>::size(dom).size()) )
+      event_( fft::Description<D, I, O>::tag(name, dom, dir, rm),
+        fft::Op_count<I, O>::value(io_size<D, O, I, A>::size(dom).size()) )
   {}
 
   Domain<dim> const& 
@@ -163,7 +155,7 @@
 
   fft_facade(Domain<D> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale, S, by_value),
+    : base(dom, scale, "Fft", S, by_value),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
@@ -209,7 +201,7 @@
 
   fft_facade(Domain<D> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale, S, by_reference),
+    : base(dom, scale, "Fft", S, by_reference),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
@@ -273,7 +265,7 @@
 public:
   fftm_facade(Domain<2> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale, D, by_value),
+    : base(dom, scale, "Fftm", D, by_value),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
@@ -320,7 +312,7 @@
 public:
   fftm_facade(Domain<2> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
-    : base(dom, scale, D, by_reference),
+    : base(dom, scale, "Fftm", D, by_reference),
       backend_(factory::create(dom, scale)),
       workspace_(this->input_size(), this->output_size(), scale)
   {}
Index: src/vsip/impl/signal-fir.hpp
===================================================================
--- src/vsip/impl/signal-fir.hpp	(revision 147597)
+++ src/vsip/impl/signal-fir.hpp	(working copy)
@@ -141,7 +141,8 @@
   , state_(2 * (this->order_ + 1), T(0))   // IPP wants 2x.
   , state_saved_(0)
   , event_(impl::signal::Description<1, T>::tag("Fir", this->input_size_), 
-      this->impl_op_count())
+           impl::signal::Op_count_fir<T>::value(this->order_, 
+             this->input_size_, this->decimation_))
 #if VSIP_IMPL_HAVE_IPP
   , temp_in_(this->input_size_)
   , temp_out_(this->input_size_)
@@ -334,12 +335,6 @@
   }
 
 private:
-  length_type impl_op_count()
-  {
-    return (impl::Ops_info<T>::mul + impl::Ops_info<T>::add) *
-      ((this->order_ + 1) * this->input_size_ / this->decimation_);
-  }
-
   vsip::length_type  input_size_;
   vsip::length_type  output_size_; 
   vsip::length_type  order_;         // M in the spec
