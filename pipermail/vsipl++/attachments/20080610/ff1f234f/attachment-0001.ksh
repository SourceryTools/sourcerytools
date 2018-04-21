Index: src/vsip/core/signal/fir.hpp
===================================================================
--- src/vsip/core/signal/fir.hpp	(revision 211164)
+++ src/vsip/core/signal/fir.hpp	(working copy)
@@ -22,6 +22,9 @@
 # ifdef VSIP_IMPL_HAVE_IPP
 #  include <vsip/opt/ipp/fir.hpp>
 # endif
+# ifdef VSIP_IMPL_CBE_SDK
+#  include <vsip/opt/cbe/cml/fir.hpp>
+# endif
 #endif
 #if VSIP_IMPL_HAVE_CVSIP
 # include <vsip/core/cvsip/fir.hpp>
@@ -38,7 +41,7 @@
 template<>
 struct List<Fir_tag>
 {
-  typedef Make_type_list<Intel_ipp_tag, Opt_tag, Cvsip_tag>::type type;
+  typedef Make_type_list<Intel_ipp_tag, Cml_tag, Opt_tag, Cvsip_tag>::type type;
 };
 } // namespace vsip::impl::dispatcher
 } // namespace vsip::impl
Index: src/vsip/core/signal/fir_backend.hpp
===================================================================
--- src/vsip/core/signal/fir_backend.hpp	(revision 211164)
+++ src/vsip/core/signal/fir_backend.hpp	(working copy)
@@ -56,8 +56,8 @@
   length_type output_size() const VSIP_NOTHROW { return output_size_;}
   vsip::length_type decimation() const VSIP_NOTHROW { return decimation_;}
 
-  virtual length_type apply(T *in, length_type in_stride, length_type in_length,
-                            T *out, length_type out_stride, length_type out_length) = 0;
+  virtual length_type apply(T *in, stride_type in_stride, length_type in_length,
+                            T *out, stride_type out_stride, length_type out_length) = 0;
   virtual void reset() VSIP_NOTHROW = 0;
 
 protected:
Index: src/vsip/core/cvsip/fir.hpp
===================================================================
--- src/vsip/core/cvsip/fir.hpp	(revision 211164)
+++ src/vsip/core/cvsip/fir.hpp	(working copy)
@@ -192,8 +192,8 @@
   }
   virtual Fir_impl *clone() { return new Fir_impl(*this);}
 
-  length_type apply(T *in, length_type in_stride, length_type in_length,
-                    T *out, length_type out_stride, length_type out_length)
+  length_type apply(T *in, stride_type in_stride, length_type in_length,
+                    T *out, stride_type out_stride, length_type out_length)
   {
     View<1, T> input(in, 0, in_stride, in_length);
     View<1, T> output(out, 0, out_stride, out_length);
@@ -237,7 +237,8 @@
   static return_type exec(aligned_array<T> k, length_type ks,
                           length_type is, length_type d,
                           unsigned n, alg_hint_type h)
-  { return return_type(new cvsip::Fir_impl<T, S, C>(k, ks, is, d, n, h));}
+  { return return_type(new cvsip::Fir_impl<T, S, C>(k, ks, is, d, n, h), 
+                       noincrement);}
 };
 } // namespace vsip::impl::dispatcher
 
Index: src/vsip/opt/ipp/fir.hpp
===================================================================
--- src/vsip/opt/ipp/fir.hpp	(revision 211164)
+++ src/vsip/opt/ipp/fir.hpp	(working copy)
@@ -222,7 +222,7 @@
   static return_type exec(aligned_array<T> k, length_type ks,
                           length_type is, length_type d,
                           unsigned int, alg_hint_type)
-  { return return_type(new ipp::Fir_impl<T, S, C>(k, ks, is, d));}
+  { return return_type(new ipp::Fir_impl<T, S, C>(k, ks, is, d), noincrement);}
 };
 } // namespace vsip::impl::dispatcher
 } // namespace vsip::impl
Index: src/vsip/opt/cbe/cml/fir.hpp
===================================================================
--- src/vsip/opt/cbe/cml/fir.hpp	(revision 0)
+++ src/vsip/opt/cbe/cml/fir.hpp	(revision 0)
@@ -0,0 +1,215 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/cml/fir.hpp
+    @author  Don McCoy
+    @date    2008-06-05
+    @brief   VSIPL++ Library: FIR CML backend.
+*/
+
+#ifndef VSIP_OPT_CBE_CML_FIR_HPP
+#define VSIP_OPT_CBE_CML_FIR_HPP
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
+#include <vsip/core/extdata.hpp>
+#include <vsip/core/signal/fir_backend.hpp>
+#include <vsip/opt/dispatch.hpp>
+
+#include <cml/ppu/cml.h>
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace cml
+{
+
+
+// CML wrappers for T == float
+
+inline int
+fir_create(
+  cml_fir_f**         fir_obj_handle,
+  float*              K,
+  ptrdiff_t           K_stride,
+  size_t              d,
+  cml_filter_state    state,
+  size_t              nk,
+  size_t              n)
+{
+  return
+    cml_fir_create_f(
+      fir_obj_handle,
+      K, K_stride,
+      d, state,
+      nk, n);
+}
+
+inline void
+fir_apply(
+  cml_fir_f*            fir_obj_ptr,
+  float const*          A,
+  ptrdiff_t             A_stride,
+  float*                Z,
+  ptrdiff_t             Z_stride)
+{
+  cml_fir_apply_f(
+    fir_obj_ptr,
+    A, A_stride,
+    Z, Z_stride);
+}
+
+inline void
+fir_destroy(cml_fir_f* fir_obj_ptr)
+{
+  cml_fir_destroy_f(fir_obj_ptr);
+}
+
+
+
+// Implementation
+
+template <typename T, symmetry_type S, obj_state C> 
+class Fir_impl : public Fir_backend<T, S, C>
+{
+  typedef Fir_backend<T, S, C> base;
+  typedef Dense<1, T> block_type;
+
+public:
+  Fir_impl(aligned_array<T> kernel, length_type k, length_type i, length_type d)
+    : base(i, k, d),
+      fir_obj_ptr_(NULL),
+      filter_state_(C == state_save ? SAVE_STATE : DONT_SAVE_STATE)
+  {
+    // spec says a nonsym kernel size has to be >1, but symmetric can be ==1:
+    assert(k > (S == nonsym));
+
+    // copy the kernel
+    Dense<1, T> kernel_block(k, kernel.get());
+    kernel_block.admit();
+    Vector<T> tmp(kernel_block);
+    Vector<T> coeffs(this->kernel_size());
+    coeffs(Domain<1>(k)) = tmp;    
+
+    // and expand the second half if symmetric
+    if (S != nonsym) coeffs(Domain<1>(this->order_, -1, k)) = tmp;
+    kernel_block.release(false);
+
+    Ext_data<block_type> ext_coeffs(coeffs.block(), SYNC_OUT);
+
+    fir_create(
+      &fir_obj_ptr_,
+      ext_coeffs.data(),
+      1, // kernel stride
+      this->decimation(),
+      this->filter_state_,
+      this->kernel_size(),
+      this->input_size());
+  }
+
+
+  Fir_impl(Fir_impl const &fir)
+    : base(fir),
+      fir_obj_ptr_(NULL),
+      filter_state_(fir.filter_state_)
+  {
+    fir_create(
+      &fir_obj_ptr_,
+      fir.fir_obj_ptr_->K,
+      1, // kernel stride
+      this->decimation(),
+      this->filter_state_,
+      this->kernel_size(),
+      this->input_size());
+  }
+
+  ~Fir_impl()
+  {
+    fir_destroy(this->fir_obj_ptr_);
+  }
+
+  virtual Fir_impl *clone() { return new Fir_impl(*this); }
+
+  length_type apply(T *in, stride_type in_stride, length_type in_length,
+                    T *out, stride_type out_stride, length_type out_length)
+  {
+    assert(in_length == this->input_size());
+    assert(out_length == this->output_size());
+
+    fir_apply(
+      this->fir_obj_ptr_,
+      in, in_stride,
+      out, out_stride);
+
+    return this->output_size();
+  }
+
+  virtual void reset() VSIP_NOTHROW
+  {
+    cml_fir_reset_f(this->fir_obj_ptr_);
+  }
+
+private:
+  cml_fir_f*            fir_obj_ptr_;
+  cml_filter_state      filter_state_;
+};
+
+} // namespace vsip::impl::cml
+
+
+struct Cml_tag;
+
+namespace dispatcher
+{
+template <typename T, symmetry_type S, obj_state C> 
+struct Evaluator<Fir_tag, Cml_tag,
+                 Ref_counted_ptr<Fir_backend<T, S, C> >
+                 (aligned_array<T>, 
+                  length_type, length_type, length_type,
+                  unsigned, alg_hint_type)>
+{
+  static bool const ct_valid = // false;
+    Type_equal<T, float>::value;
+
+  typedef Ref_counted_ptr<Fir_backend<T, S, C> > return_type;
+  // rt_valid takes the first argument by reference to avoid taking
+  // ownership.
+  static bool rt_valid(aligned_array<T> const &, length_type k,
+                       length_type i, length_type d,
+                       unsigned, alg_hint_type)
+  {
+    length_type o = k * (1 + (S != nonsym)) - (S == sym_even_len_odd) - 1;
+    assert(i > 0); // input size
+    assert(d > 0); // decimation
+    assert(o + 1 > d); // M >= decimation
+    assert(i >= o);    // input_size >= M 
+
+    length_type output_size = (i + d - 1) / d;
+    return i == output_size * d;
+  }
+  static return_type exec(aligned_array<T> k, length_type ks,
+                          length_type is, length_type d,
+                          unsigned int, alg_hint_type)
+  { return return_type(new cml::Fir_impl<T, S, C>(k, ks, is, d), noincrement);}
+};
+} // namespace vsip::impl::dispatcher
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif
Index: src/vsip/opt/signal/fir_opt.hpp
===================================================================
--- src/vsip/opt/signal/fir_opt.hpp	(revision 211164)
+++ src/vsip/opt/signal/fir_opt.hpp	(working copy)
@@ -73,8 +73,8 @@
   {}
   virtual Fir_impl *clone() { return new Fir_impl(*this);}
 
-  length_type apply(T *in, length_type in_stride, length_type in_length,
-                    T *out, length_type out_stride, length_type out_length)
+  length_type apply(T *in, stride_type in_stride, length_type in_length,
+                    T *out, stride_type out_stride, length_type out_length)
   {
     typedef impl::Subset_block<Dense<1, T> > block_type;
     typedef Vector<T, block_type> view_type;
@@ -165,7 +165,7 @@
   static return_type exec(aligned_array<T> k, length_type ks,
                           length_type is, length_type d,
                           unsigned, alg_hint_type)
-  { return return_type(new Fir_impl<T, S, C>(k, ks, is, d));}
+  { return return_type(new Fir_impl<T, S, C>(k, ks, is, d), noincrement);}
 };
 
 }
