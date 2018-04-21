Index: ChangeLog
===================================================================
--- ChangeLog	(revision 212863)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2008-06-27  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/profile.hpp: Add macros for profile masks.
+	* src/vsip/core/matvec.hpp: Use macros to disable profiling Scopes.
+
 2008-06-25  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* cvsip/iir_api.hpp: New file.
Index: src/vsip/core/profile.hpp
===================================================================
--- src/vsip/core/profile.hpp	(revision 212863)
+++ src/vsip/core/profile.hpp	(working copy)
@@ -34,6 +34,13 @@
 #endif
   ;
 
+#define VSIP_IMPL_PROFILE_MASK_SIGNAL  1
+#define VSIP_IMPL_PROFILE_MASK_MATVEC  2
+#define VSIP_IMPL_PROFILE_MASK_FNS     4
+#define VSIP_IMPL_PROFILE_MASK_USER    8
+#define VSIP_IMPL_PROFILE_MASK_PAR     16
+#define VSIP_IMPL_PROFILE_MASK_FNS_INT 32
+
 #ifndef VSIP_IMPL_PROFILE
 # define VSIP_IMPL_PROFILE(X)
 #endif
@@ -41,12 +48,12 @@
 /// Different operations that may be profiled, each is referred to
 /// as a 'feature'.
 enum Feature {
-  signal  = 1,	// signal processing (FFT, FIR, etc)
-  matvec  = 2,	// matrix-vector (prod, qr, etc)
-  fns     = 4,	// user-level serial-dispatch (+, -, etc)
-  user    = 8,	// user defined tag
-  par     = 16,	// parallel comms
-  fns_int = 32	// internal serial_dispatch
+  signal  = VSIP_IMPL_PROFILE_MASK_SIGNAL, // signal processing (FFT, FIR, etc)
+  matvec  = VSIP_IMPL_PROFILE_MASK_MATVEC, // matrix-vector (prod, qr, etc)
+  fns     = VSIP_IMPL_PROFILE_MASK_FNS,    // elementwise dispatch (+, -, etc)
+  user    = VSIP_IMPL_PROFILE_MASK_USER,   // user defined tag
+  par     = VSIP_IMPL_PROFILE_MASK_PAR,    // parallel comms
+  fns_int = VSIP_IMPL_PROFILE_MASK_FNS_INT // internal serial_dispatch
 };
 
 #if defined(VSIP_IMPL_REF_IMPL)
Index: src/vsip/core/matvec.hpp
===================================================================
--- src/vsip/core/matvec.hpp	(revision 212863)
+++ src/vsip/core/matvec.hpp	(working copy)
@@ -590,9 +590,11 @@
   const_Vector<T1, Block1> w) VSIP_NOTHROW
 {
   typedef typename Promotion<T0, T1>::type result_type;
+#if VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILE_MASK_MATVEC
   impl::profile::Scope<impl::profile::matvec> scope
     (impl::matvec::Description<result_type>::tag("dot", impl::extent(v)),
      impl::matvec::Op_count_dot<result_type>::value(impl::extent(v)) );
+#endif
   return impl::impl_dot(v, w);
 }
 
@@ -606,9 +608,11 @@
   const_Vector<complex<T1>, Block1> w) VSIP_NOTHROW
 {
   typedef typename Promotion<T0, T1>::type result_type;
+#if VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILE_MASK_MATVEC
   impl::profile::Scope<impl::profile::matvec> scope
     (impl::matvec::Description<result_type>::tag("cvjdot", impl::extent(v)),
      impl::matvec::Op_count_cvjdot<result_type>::value(impl::extent(v)));
+#endif
   return impl::impl_dot(v, conj(w));
 }
 
@@ -621,8 +625,10 @@
 typename const_Matrix<T, Block>::transpose_type
 trans(const_Matrix<T, Block> m) VSIP_NOTHROW
 {
+#if VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILE_MASK_MATVEC
   impl::profile::Scope<impl::profile::matvec> scope
     (impl::matvec::Description<T>::tag("trans", impl::extent(m)));
+#endif
   return m.transpose();
 }
 
@@ -638,9 +644,11 @@
   typedef impl::Unary_func_view<impl::conj_functor, transpose_type> 
     functor_type;
 
+#if VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILE_MASK_MATVEC
   impl::profile::Scope<impl::profile::matvec> scope
     (impl::matvec::Description<complex<T> >::tag("herm", impl::extent(m)),
      impl::matvec::Op_count_herm<complex<T> >::value(impl::extent(m)));
+#endif
   return functor_type::apply(m.transpose());
 } 
 
@@ -660,11 +668,13 @@
 {
   typedef typename Promotion<T0, typename Promotion<T1, T2>::type
     >::type result_type;
+#if VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILE_MASK_MATVEC
   impl::profile::Scope<impl::profile::matvec> scope
     (impl::matvec::Description<result_type>::tag("kron", impl::extent(v), 
                                                  impl::extent(w)),
      impl::matvec::Op_count_kron<impl::Dim_of_view<const_View>::dim, 
      result_type>::value(impl::extent(v), impl::extent(w)));
+#endif
   return impl::impl_kron( alpha, v, w );
 }
 
@@ -682,11 +692,13 @@
     VSIP_NOTHROW
 {
   typedef typename Promotion<T1, T2>::type return_type;
+#if VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILE_MASK_MATVEC
   impl::profile::Scope<impl::profile::matvec> scope
     (impl::matvec::Description<return_type>::tag("outer", impl::extent(v), 
                                                  impl::extent(w)),
      impl::matvec::Op_count_outer<return_type>::value(impl::extent(v), 
                                                       impl::extent(w)));
+#endif
 
   Matrix<return_type> r(v.size(), w.size(), return_type());
 
@@ -718,11 +730,13 @@
     Matrix<T4, Block4> C)
      VSIP_NOTHROW
 {
+#if VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILE_MASK_MATVEC
   impl::profile::Scope<impl::profile::matvec> scope
     (impl::matvec::Description<T4>::tag("gemp", impl::extent(A), 
                                         impl::extent(B)),
      impl::matvec::Op_count_gemp<T4>::value(impl::extent(A), 
                                             impl::extent(B), OpA, OpB));
+#endif
 
   // equivalent to C = alpha * OpA(A) * OpB(B) + beta * C
   impl::gemp( alpha, 
@@ -749,9 +763,11 @@
   Matrix<T4, Block4> C) 
     VSIP_NOTHROW
 {
+#if VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILE_MASK_MATVEC
   impl::profile::Scope<impl::profile::matvec> scope
     (impl::matvec::Description<T4>::tag("gems", impl::extent(A)),
      impl::matvec::Op_count_gems<T4>::value(impl::extent(A), OpA));
+#endif
   impl::gems(alpha, impl::apply_mat_op<OpA>(A), beta, C);
 }
 
@@ -773,9 +789,11 @@
     VSIP_NOTHROW
 {
   dimension_type const dim = impl::Dim_of_view<const_View>::dim;
+#if VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILE_MASK_MATVEC
   impl::profile::Scope<impl::profile::matvec> scope
     (impl::matvec::Description<T0>::tag("cumsum", impl::extent(v)),
      impl::matvec::Op_count_cumsum<dim, T0>::value(impl::extent(v)));
+#endif
 
   impl::cumsum<d>(v, w);
 }
@@ -795,9 +813,11 @@
   Vector<complex<T3>, Block1> w)
     VSIP_NOTHROW
 {
+#if VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILE_MASK_MATVEC
   impl::profile::Scope<impl::profile::matvec> scope
     (impl::matvec::Description<T0>::tag("modulate", impl::extent(v)),
      impl::matvec::Op_count_modulate<T0>::value(impl::extent(v)));
+#endif
   return impl::modulate(v, nu, phi, w);
 }
 
