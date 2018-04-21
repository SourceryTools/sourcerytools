Index: ChangeLog
===================================================================
--- ChangeLog	(revision 145201)
+++ ChangeLog	(working copy)
@@ -1,5 +1,71 @@
 2006-07-18  Jules Bergmann  <jules@codesourcery.com>
 
+	Optimize comparison of maps for equivalence.
+	* src/vsip/impl/block-traits.hpp (Map_equal): Add template
+	  parameter to account for dimension of applied maps being compared.
+	  (map_equal): likewise.
+	  (Is_par_same_map): likewise.
+	* src/vsip/impl/vmmul.hpp (Is_par_same_map): Likewise.
+	* src/vsip/impl/expr_binary_block.hpp (Is_par_same_map): Likewise.
+	* src/vsip/impl/replicated_map.hpp (Map_equal): Likewise.
+	* src/vsip/impl/expr_scalar_block.hpp (Is_par_same_map): Likewise.
+	* src/vsip/impl/par-foreach.hpp (Foreach_vector): Likewise.
+	* src/vsip/impl/local_map.hpp (Map_equal): Likewise.
+	* src/vsip/impl/expr_ternary_block.hpp (Is_par_same_map): Likewise.
+	* src/vsip/impl/global_map.hpp (Map_equal): Likewise.
+	* src/vsip/impl/expr_unary_block.hpp (Is_par_same_map): Likewise.
+	* src/vsip/map.hpp (Map_data): New reference-counted class, used 
+	  by Map to store data.  Allows maps to share common data,
+	  helps optimize equality check for maps (when they are equal
+	  and have the same Map_data).  
+	  (map_equiv): Optimize map equivalence checking.
+	  (Map_equal): Take applied map dimension into account.
+
+	Optimizations for parallel assignment.
+	* src/vsip/impl/par-services.hpp: Return communicator by reference.
+	* src/vsip/impl/dispatch-assign.hpp: Optimize handling of simple
+	  parallel expressions to avoid view creation and reference
+	  counting overhead.
+	* src/vsip/impl/par-expr.hpp (par_expr_simple): Remove empty
+	  subblock check, it isn't necessary and it slows execution
+	  when not empy.
+	* src/vsip/impl/par-chain-assign.hpp: Store communicator by
+	  reference.  Optimize exec_send_list, exec_recv_list to assume
+	  that each processor already has only 1 or 0 entries in
+	  command lists.
+	* src/vsip/impl/par-services-mpi.hpp: Return communicators by
+	  reference.
+	
+	* src/vsip/dense.hpp (get_local_block): Inline.
+	* src/vsip/impl/setup-assign.hpp: Update dispatch to mirror
+	  dispatch-assign.hpp.
+	* src/vsip/impl/sal/fft.cpp (VSIP_IMPL_PROVIDE): Add space before
+	  template closing '>' in macro (work around for ICC bug).
+	* src/vsip/impl/sal/elementwise.hpp: Add synthetic vsadd
+	  (scalar-vector add) and vsmul (scalar-vector multiply)
+	  wrappers for complex<float> and complex<double>.
+	* src/vsip/impl/sal/eval_elementwise.hpp: Use them.
+	* src/vsip/impl/extdata.hpp (mem_required, xfer_required): Fix to
+	  take flexible access into account.
+	  (xfer_required): New helper function.
+	* src/vsip/impl/par-support.hpp (global_from_local_index):
+	  Fix bug, should get subblock from map, not block.
+	* src/vsip/impl/simd/eval-generic.hpp: Fix bug, using wrong
+	  evaluator tag: was Intel_ipp_tag, should be Simd_tag.
+	* src/vsip/impl/subblock.hpp (Sliced2_block_base::impl_data):
+	  Fix syntax error.
+	* src/vsip/impl/fast-transpose.hpp: Avoid using non-portable
+	  GCC vector intrinsics.
+	* src/vsip/impl/ipp.cpp: Guard execution of IPP calls with
+	  (length > 0).  IPP does not like 0 length operations.
+	* tests/extdata-runtime.cpp: Add coverage to test mem_required
+	  and xfer_required for flexible access.
+	* benchmarks/copy.cpp: Extend to cover parallel copy cases.
+	* benchmarks/vmul.cpp: Extend to cover distributed data cases.
+	* benchmarks/vmul_sal.cpp: Fix strides for zvzsmlx.
+	
+2006-07-18  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/impl/layout.hpp: Throw exception if using get_imag_ptr
 	  on a non-complex pointer.
 	* src/vsip_csl/test.hpp: Use YYYY-MM-DD format for date.  
Index: src/vsip/dense.hpp
===================================================================
--- src/vsip/dense.hpp	(revision 145195)
+++ src/vsip/dense.hpp	(working copy)
@@ -1075,7 +1075,7 @@
 	  typename       T,
 	  typename       OrderT,
 	  typename       MapT>
-Dense<Dim, T, OrderT, Local_map>&
+inline Dense<Dim, T, OrderT, Local_map>&
 get_local_block(
   Dense<Dim, T, OrderT, MapT> const& block)
 {
Index: src/vsip/impl/setup-assign.hpp
===================================================================
--- src/vsip/impl/setup-assign.hpp	(revision 145195)
+++ src/vsip/impl/setup-assign.hpp	(working copy)
@@ -18,6 +18,8 @@
 #include <vsip/impl/block-traits.hpp>
 #include <vsip/impl/par-expr.hpp>
 #include <vsip/impl/par-chain-assign.hpp>
+#include <vsip/impl/dispatch-assign.hpp>
+#include <vsip/impl/metaprogramming.hpp>
 #include <vsip/impl/profile.hpp>
 
 
@@ -169,7 +171,6 @@
 
     void exec()
     {
-      impl::profile::Scope_event ev("Ser_expr_holder");
       dst_ = src_;
     }
 
@@ -182,6 +183,96 @@
     typename impl::View_of_dim<Dim, value2_type, SrcBlock>::const_type src_;
   };
 
+  template <dimension_type Dim,
+	    typename       View1,
+	    typename       View2>
+  void
+  create_holder(View1 dst, View2 src, impl::Tag_serial_expr)
+  {
+    typedef typename View1::block_type block1_type;
+    typedef typename View2::block_type block2_type;
+    holder_ = new Ser_expr_holder<Dim, block1_type, block2_type>(dst, src);
+  }
+
+  template <dimension_type Dim,
+	    typename       View1,
+	    typename       View2>
+  void
+  create_holder(View1 dst, View2 src, impl::Tag_par_assign)
+  {
+    typedef typename View1::value_type           value1_type;
+    typedef typename View2::value_type           value2_type;
+    typedef typename View1::block_type           block1_type;
+    typedef typename View2::block_type           block2_type;
+    typedef typename View1::block_type::map_type map1_type;
+    typedef typename View2::block_type::map_type map2_type;
+
+    if (impl::Is_par_same_map<Dim, map1_type, block2_type>::value(
+					dst.block().map(),
+					src.block()))
+    {
+      typedef typename impl::Distributed_local_block<block1_type>::type
+	dst_lblock_type;
+      typedef typename impl::Distributed_local_block<block2_type>::type
+	src_lblock_type;
+
+      typedef typename impl::View_of_dim<Dim, value1_type, dst_lblock_type>::type
+	l_dst_view_type;
+      typedef typename impl::View_of_dim<Dim, value2_type, src_lblock_type>::type
+	l_src_view_type;
+
+      l_dst_view_type l_dst = get_local_view(dst);
+      l_src_view_type l_src = get_local_view(src);
+
+      holder_ = new Ser_expr_holder<Dim, dst_lblock_type, src_lblock_type>
+	(l_dst, l_src);
+    }
+    else
+    {
+      holder_ = new Par_assign_holder<Dim, block1_type, block2_type>(dst, src);
+    }
+  }
+
+  template <dimension_type Dim,
+	    typename       View1,
+	    typename       View2>
+  void
+  create_holder(View1 dst, View2 src, impl::Tag_par_expr)
+  {
+    typedef typename View1::value_type value1_type;
+    typedef typename View2::value_type value2_type;
+    typedef typename View1::block_type block1_type;
+    typedef typename View2::block_type block2_type;
+    typedef typename View1::map_type   map1_type;
+    typedef typename View2::map_type   map2_type;
+
+    if (impl::Is_par_same_map<Dim, map1_type, block2_type>::value(
+					dst.block().map(),
+					src.block()))
+    {
+      typedef typename impl::Distributed_local_block<block1_type>::type
+	dst_lblock_type;
+      typedef typename impl::Distributed_local_block<block2_type>::type
+	src_lblock_type;
+
+      typedef typename impl::View_of_dim<Dim, value1_type, dst_lblock_type>::type
+	l_dst_view_type;
+      typedef typename impl::View_of_dim<Dim, value2_type, src_lblock_type>::type
+	l_src_view_type;
+
+      l_dst_view_type l_dst = get_local_view(dst);
+      l_src_view_type l_src = get_local_view(src);
+
+      holder_ = new Ser_expr_holder<Dim, dst_lblock_type, src_lblock_type>
+	(l_dst, l_src);
+    }
+    else
+    {
+      holder_ = new Par_expr_holder<Dim, block1_type, block2_type>(dst, src);
+    }
+  }
+
+
   // Constructors.
 public:
    template <template <typename, typename> class View1,
@@ -194,43 +285,25 @@
     View1<T1, Block1> dst,
     View2<T2, Block2> src)
   {
+    using vsip::impl::ITE_Type;
+    using vsip::impl::As_type;
+    using vsip::impl::Type_equal;
+
     dimension_type const dim = View1<T1, Block1>::dim;
 
     typedef typename Block1::map_type map1_type;
     typedef typename Block2::map_type map2_type;
 
-    bool const is_local      = !map1_type::impl_global_only &&
-                               !map2_type::impl_global_only;
-    bool const is_rhs_simple = impl::Is_simple_distributed_block<Block2>::value;
+    typedef typename impl::Dispatch_assign_helper<dim, Block1, Block2>::type
+      raw_dispatch_type;
 
-    if (is_local)
-      holder_ = new Ser_expr_holder<View1<T1, Block1>::dim, Block1, Block2>
-	                           (dst, src);
-    else if (impl::Is_par_same_map<map1_type, Block2>::value(dst.block().map(),
-						       src.block()))
-    {
-      if (dst.block().map().subblock() != no_subblock)
-      {
-	typedef typename impl::Distributed_local_block<Block1>::type dst_lblock_type;
-	typedef typename impl::Distributed_local_block<Block2>::type src_lblock_type;
+    typedef typename ITE_Type<Type_equal<raw_dispatch_type,
+                                impl::Tag_serial_assign>::value,
+                     As_type<impl::Tag_serial_expr>,
+                     As_type<raw_dispatch_type> >
+      ::type dispatch_type;
 
-	View1<T1, dst_lblock_type> dst_lview = get_local_view(dst);
-	View2<T2, src_lblock_type> src_lview = get_local_view(src);
-
-	holder_ = new Ser_expr_holder<dim, dst_lblock_type, src_lblock_type>
-	  (dst_lview, src_lview);
-      }
-      else
-	holder_ = new Null_holder();
-    }
-    else if (is_rhs_simple)
-    {
-      holder_ = new Par_assign_holder<View1<T1, Block1>::dim, Block1, Block2>
-	                           (dst, src);
-    }
-    else
-      holder_ = new Par_expr_holder<View1<T1, Block1>::dim, Block1, Block2>
-	                           (dst, src);
+    create_holder<dim>(dst, src, dispatch_type());
   }
 
   ~Setup_assign() 
@@ -238,7 +311,6 @@
 
   void operator()()
   { 
-    impl::profile::Scope_event ev("Setup_assign");
     holder_->exec();
   }
 
Index: src/vsip/impl/sal/fft.cpp
===================================================================
--- src/vsip/impl/sal/fft.cpp	(revision 145195)
+++ src/vsip/impl/sal/fft.cpp	(working copy)
@@ -1284,11 +1284,11 @@
 
 #define VSIPL_IMPL_PROVIDE(I, O, A, E)				  \
 template <>                                                       \
-std::auto_ptr<fft::fftm<I, O, A, E> >				  \
-create(Domain<2> const &dom, impl::Scalar_of<I>::type scale)      \
+std::auto_ptr<fft::fftm<I, O, A, E > >				  \
+create(Domain<2> const &dom, impl::Scalar_of<I >::type scale)      \
 {                                                                 \
-  return std::auto_ptr<fft::fftm<I, O, A, E> >			  \
-    (new Fftm_impl<I, O, A, E>(dom, scale));	                  \
+  return std::auto_ptr<fft::fftm<I, O, A, E > >			  \
+    (new Fftm_impl<I, O, A, E >(dom, scale));	                  \
 }
 
 VSIPL_IMPL_PROVIDE(float, std::complex<float>, 0, -1)
Index: src/vsip/impl/sal/elementwise.hpp
===================================================================
--- src/vsip/impl/sal/elementwise.hpp	(revision 145195)
+++ src/vsip/impl/sal/elementwise.hpp	(working copy)
@@ -1042,7 +1042,41 @@
   SALFCN((T*)B.ptr+1, 2*B.stride, &imag, (T*)Z.ptr+1, 2*Z.stride, len, 0);\
 }
 
+#define VSIP_IMPL_ZVS_SYN(FCN, T, SALFCN, SCALAR_OP)			\
+VSIP_IMPL_SAL_INLINE							\
+void FCN(								\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& A,			\
+  Sal_scalar<complex<T> > const& B,					\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& Z,			\
+  length_type len)							\
+{									\
+  VSIP_IMPL_COVER_FCN("ZVS_SYN", SALFCN)				\
+									\
+  T real = SCALAR_OP B.value.real();					\
+  T imag = SCALAR_OP B.value.imag();					\
+									\
+  SALFCN(A.ptr.first,  A.stride, &real, Z.ptr.first, Z.stride, len,0);\
+  SALFCN(A.ptr.second, A.stride, &imag, Z.ptr.first, Z.stride, len,0);\
+}
 
+#define VSIP_IMPL_ZSV_SYN(FCN, T, SALFCN)				\
+VSIP_IMPL_SAL_INLINE							\
+void FCN(								\
+  Sal_scalar<complex<T> > const&                 A,			\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& B,			\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& Z,			\
+  length_type len)							\
+{									\
+  VSIP_IMPL_COVER_FCN("ZSV_SYN", SALFCN)				\
+									\
+  T real = A.value.real();						\
+  T imag = A.value.imag();						\
+									\
+  SALFCN(B.ptr.first,  B.stride, &real, Z.ptr.first,  Z.stride, len, 0);\
+  SALFCN(B.ptr.second, B.stride, &imag, Z.ptr.second, Z.stride, len, 0);\
+}
+
+
 // complex scalar-vector add
 
 VSIP_IMPL_CVS_SYN(vadd, float, vsaddx, +)
@@ -1053,8 +1087,21 @@
 VSIP_IMPL_CSV_SYN(vadd, double, vsadddx)
 VSIP_IMPL_CVS_SYN(vsub, double, vsadddx, -)
 
+VSIP_IMPL_ZVS_SYN(vadd, float, vsaddx, +)
+VSIP_IMPL_ZSV_SYN(vadd, float, vsaddx)
+VSIP_IMPL_ZVS_SYN(vsub, float, vsaddx, -)
 
+VSIP_IMPL_ZVS_SYN(vadd, double, vsadddx, +)
+VSIP_IMPL_ZSV_SYN(vadd, double, vsadddx)
+VSIP_IMPL_ZVS_SYN(vsub, double, vsadddx, -)
 
+#undef VSIP_IMPL_CVS_SYN
+#undef VSIP_IMPL_CSV_SYN
+#undef VSIP_IMPL_ZVS_SYN
+#undef VSIP_IMPL_ZSV_SYN
+
+
+
 #define VSIP_IMPL_CRVS_ADD_SYN(FCN, T, SALFCN, CPYFCN, SCALAR_OP)	\
 VSIP_IMPL_SAL_INLINE							\
 void FCN(								\
@@ -1129,6 +1176,71 @@
   }									\
 }
 
+
+#define VSIP_IMPL_ZRVS_ADD_SYN(FCN, T, SALFCN, CPYFCN, SCALAR_OP)	\
+VSIP_IMPL_SAL_INLINE							\
+void FCN(								\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& A,			\
+  Sal_scalar<T> const&                           B,			\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& Z,			\
+  length_type len)							\
+{									\
+  VSIP_IMPL_COVER_FCN("ZRVS_ADD_SYN", SALFCN)				\
+									\
+  T real = SCALAR_OP B.value;						\
+									\
+  SALFCN(A.ptr.first,  A.stride, &real, Z.ptr.first,  Z.stride, len, 0);\
+  CPYFCN(A.ptr.second, A.stride,        Z.ptr.second, Z.stride, len, 0);\
+}
+
+#define VSIP_IMPL_ZRSV_ADD_SYN(FCN, T, SALFCN, CPYFCN)			\
+VSIP_IMPL_SAL_INLINE							\
+void FCN(								\
+  Sal_scalar<T> const&                           A,			\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& B,			\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& Z,			\
+  length_type len)							\
+{									\
+  VSIP_IMPL_COVER_FCN("ZRSV_ADD_SYN", SALFCN)				\
+									\
+  T real = A.value;							\
+									\
+  SALFCN(B.ptr.first,  B.stride, &real, Z.ptr.first,  Z.stride, len, 0);\
+  CPYFCN(B.ptr.second, B.stride,        Z.ptr.second, Z.stride, len, 0);\
+}
+
+#define VSIP_IMPL_ZRVS_MUL_SYN(FCN, T, SALFCN)				\
+VSIP_IMPL_SAL_INLINE							\
+void FCN(								\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& A,			\
+  Sal_scalar<T> const&                           B,			\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& Z,			\
+  length_type len)							\
+{									\
+  VSIP_IMPL_COVER_FCN("ZRVS_MUL_SYN", SALFCN)				\
+									\
+  T real = B.value;							\
+									\
+  SALFCN(A.ptr.first,  A.stride, &real, Z.ptr.first,  Z.stride, len, 0);\
+  SALFCN(A.ptr.second, A.stride, &real, Z.ptr.second, Z.stride, len, 0);\
+}
+
+#define VSIP_IMPL_ZRSV_MUL_SYN(FCN, T, SALFCN)				\
+VSIP_IMPL_SAL_INLINE							\
+void FCN(								\
+  Sal_scalar<T> const&                           A,			\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& B,			\
+  Sal_vector<complex<T>, Cmplx_split_fmt> const& Z,			\
+  length_type len)							\
+{									\
+  VSIP_IMPL_COVER_FCN("ZRSV_MUL_SYN", SALFCN)				\
+									\
+  T real = A.value;							\
+									\
+  SALFCN(B.ptr.first,  B.stride, &real, Z.ptr.first,  Z.stride, len, 0);\
+  SALFCN(B.ptr.second, B.stride, &real, Z.ptr.second, Z.stride, len, 0);\
+}
+
 // complex-real scalar-vector add
 
 VSIP_IMPL_CRVS_ADD_SYN(vadd, float, vsaddx, vmovx, +)
@@ -1143,6 +1255,18 @@
 VSIP_IMPL_CRVS_MUL_SYN(vmul, double, vsmuldx)
 VSIP_IMPL_CRSV_MUL_SYN(vmul, double, vsmuldx)
 
+VSIP_IMPL_ZRVS_ADD_SYN(vadd, float, vsaddx, vmovx, +)
+VSIP_IMPL_ZRSV_ADD_SYN(vadd, float, vsaddx, vmovx)
+VSIP_IMPL_ZRVS_ADD_SYN(vsub, float, vsaddx, vmovx, -)
+VSIP_IMPL_ZRVS_MUL_SYN(vmul, float, vsmulx)
+VSIP_IMPL_ZRSV_MUL_SYN(vmul, float, vsmulx)
+
+VSIP_IMPL_ZRVS_ADD_SYN(vadd, double, vsadddx, vmovdx, +)
+VSIP_IMPL_ZRSV_ADD_SYN(vadd, double, vsadddx, vmovdx)
+VSIP_IMPL_ZRVS_ADD_SYN(vsub, double, vsadddx, vmovdx, -)
+VSIP_IMPL_ZRVS_MUL_SYN(vmul, double, vsmuldx)
+VSIP_IMPL_ZRSV_MUL_SYN(vmul, double, vsmuldx)
+
 #undef VSIP_IMPL_SAL_INLINE
 
 } // namespace vsip::impl::sal
Index: src/vsip/impl/sal/eval_elementwise.hpp
===================================================================
--- src/vsip/impl/sal/eval_elementwise.hpp	(revision 145195)
+++ src/vsip/impl/sal/eval_elementwise.hpp	(working copy)
@@ -207,13 +207,22 @@
 VSIP_IMPL_OP2SUP(op::Add, complex<float>*,  complex<float>,  complex<float>*);
 VSIP_IMPL_OP2SUP(op::Add, complex<double>,  complex<double>*,complex<double>*);
 VSIP_IMPL_OP2SUP(op::Add, complex<double>*, complex<double>, complex<double>*);
+VSIP_IMPL_OP2SUP(op::Add, complex<float>,   split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Add, split_float,      complex<float>,  split_float);
+VSIP_IMPL_OP2SUP(op::Add, complex<double>,  split_double,    split_double);
+VSIP_IMPL_OP2SUP(op::Add, split_double,     complex<double>, split_double);
 
 VSIP_IMPL_OP2SUP(op::Add, float,            complex<float>*, complex<float>*);
 VSIP_IMPL_OP2SUP(op::Add, complex<float>*,  float,           complex<float>*);
 VSIP_IMPL_OP2SUP(op::Add, double,           complex<double>*,complex<double>*);
 VSIP_IMPL_OP2SUP(op::Add, complex<double>*, double,          complex<double>*);
 
+VSIP_IMPL_OP2SUP(op::Add, float,            split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Add, split_float,      float,           split_float);
+VSIP_IMPL_OP2SUP(op::Add, double,           split_double,    split_double);
+VSIP_IMPL_OP2SUP(op::Add, split_double,     double,          split_double);
 
+
 // straight-up vector sub
 VSIP_IMPL_OP2SUP(op::Sub, int*,             int*,            int*);
 VSIP_IMPL_OP2SUP(op::Sub, float*,           float*,          float*);
@@ -236,8 +245,17 @@
 VSIP_IMPL_OP2SUP(op::Sub, complex<float>*,  complex<float>,  complex<float>*);
 // not in sal   (op::Sub, complex<double>,  complex<double>*,complex<double>*);
 VSIP_IMPL_OP2SUP(op::Sub, complex<double>*, complex<double>, complex<double>*);
+// not in sal   (op::Sub, complex<float>,   split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Sub, split_float,      complex<float>,  split_float);
+// not in sal   (op::Sub, complex<double>,  split_double,    split_double);
+VSIP_IMPL_OP2SUP(op::Sub, split_double,     complex<double>, split_double);
 
+VSIP_IMPL_OP2SUP(op::Sub, complex<float>*,  float,           complex<float>*);
+VSIP_IMPL_OP2SUP(op::Sub, complex<double>*, double,          complex<double>*);
+VSIP_IMPL_OP2SUP(op::Sub, split_float,      float,           split_float);
+VSIP_IMPL_OP2SUP(op::Sub, split_double,     double,          split_double);
 
+
 // straight-up vector multiply
 VSIP_IMPL_OP2SUP(op::Mult, int*,            int*,            int*);
 VSIP_IMPL_OP2SUP(op::Mult, float*,          float*,          float*);
@@ -258,18 +276,29 @@
 VSIP_IMPL_OP2SUP(op::Mult, int*,            int,             int*);
 VSIP_IMPL_OP2SUP(op::Mult, float,           float*,          float*);
 VSIP_IMPL_OP2SUP(op::Mult, float*,          float,           float*);
+VSIP_IMPL_OP2SUP(op::Mult, double,          double*,         double*);
+VSIP_IMPL_OP2SUP(op::Mult, double*,         double,          double*);
 VSIP_IMPL_OP2SUP(op::Mult, complex<float>,  complex<float>*, complex<float>*);
 VSIP_IMPL_OP2SUP(op::Mult, complex<float>*, complex<float>,  complex<float>*);
-VSIP_IMPL_OP2SUP(op::Mult, double,          double*,         double*);
-VSIP_IMPL_OP2SUP(op::Mult, double*,         double,          double*);
 VSIP_IMPL_OP2SUP(op::Mult, complex<double>, complex<double>*,complex<double>*);
 VSIP_IMPL_OP2SUP(op::Mult, complex<double>*,complex<double>, complex<double>*);
+VSIP_IMPL_OP2SUP(op::Mult, complex<float>,  split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Mult, split_float,     complex<float>,  split_float);
+VSIP_IMPL_OP2SUP(op::Mult, complex<double>, split_double,    split_double);
+VSIP_IMPL_OP2SUP(op::Mult, split_double,    complex<double>, split_double);
 
 VSIP_IMPL_OP2SUP(op::Mult, float,           complex<float>*, complex<float>*);
 VSIP_IMPL_OP2SUP(op::Mult, complex<float>*, float,           complex<float>*);
+VSIP_IMPL_OP2SUP(op::Mult, double,          complex<double>*,complex<double>*);
+VSIP_IMPL_OP2SUP(op::Mult, complex<double>*,double,          complex<double>*);
 
+VSIP_IMPL_OP2SUP(op::Mult, float,           split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Mult, split_float,     float,           split_float);
+VSIP_IMPL_OP2SUP(op::Mult, double,          split_double,    split_double);
+VSIP_IMPL_OP2SUP(op::Mult, split_double,    double,          split_double);
 
 
+
 // straight-up vector division
 VSIP_IMPL_OP2SUP(op::Div, int*,             int*,            int*);
 VSIP_IMPL_OP2SUP(op::Div, float*,           float*,          float*);
Index: src/vsip/impl/extdata.hpp
===================================================================
--- src/vsip/impl/extdata.hpp	(revision 145195)
+++ src/vsip/impl/extdata.hpp	(working copy)
@@ -424,9 +424,10 @@
   static int    cost         (Block const& block, LP const&)
     { return is_direct_ok<LP>(block) ? 0 : 2; }
   static size_t mem_required (Block const& block, LP const&)
-    { return sizeof(typename Block::value_type) * block.size(); }
-  static size_t xfer_required(Block const&, LP const&)
-    { return !CT_Xfer_not_req; }
+    { return is_direct_ok<LP>(block) ? 0 :
+	sizeof(typename Block::value_type) * block.size(); }
+  static size_t xfer_required(Block const& block, LP const&)
+    { return is_direct_ok<LP>(block) ? false : !CT_Xfer_not_req; }
 
   // Constructor and destructor.
 public:
@@ -878,6 +879,25 @@
 
 
 
+/// Return whether a transfer is required to access a block with
+/// a given layout.
+
+template <typename LP,
+	  typename Block>
+bool
+xfer_required(
+  Block const& block,
+  LP    const& layout = LP())
+{
+  typedef typename Choose_access<Block, LP>::type
+		access_type;
+
+  return data_access::Low_level_data_access<access_type, Block, LP>
+    ::xfer_required(block, layout);
+}
+
+
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/impl/par-support.hpp
===================================================================
--- src/vsip/impl/par-support.hpp	(revision 145195)
+++ src/vsip/impl/par-support.hpp	(working copy)
@@ -506,7 +506,7 @@
   index_type     l_idx)
 {
   return view.block().map().impl_global_from_local_index(dim,
-						    view.block().subblock(),
+						    view.block().map().subblock(),
 						    l_idx);
 }
 
Index: src/vsip/impl/block-traits.hpp
===================================================================
--- src/vsip/impl/block-traits.hpp	(revision 145195)
+++ src/vsip/impl/block-traits.hpp	(working copy)
@@ -247,39 +247,42 @@
 
 
 
-/// Check if lhs map is same as rhs block's map.
-
-/// Two blocks are the same if they distribute a view into subblocks
-/// containing the same elements.
-
-template <typename MapT,
-	  typename BlockT>
-struct Is_par_same_map
-{
-  static bool value(MapT const& map, BlockT const& block)
-    { return map_equal(map, block.map()); }
-};
-
-
-
-template <typename Map1,
-	  typename Map2>
+template <dimension_type Dim,
+	  typename       Map1,
+	  typename       Map2>
 struct Map_equal
 {
   static bool value(Map1 const&, Map2 const&)
     { return false; }
 };
 
-template <typename Map1,
-	  typename Map2>
+template <dimension_type Dim,
+	  typename       Map1,
+	  typename       Map2>
 inline bool
 map_equal(Map1 const& map1, Map2 const& map2)
 {
-  return Map_equal<Map1, Map2>::value(map1, map2);
+  return Map_equal<Dim, Map1, Map2>::value(map1, map2);
 }
 
 
 
+/// Check if lhs map is same as rhs block's map.
+
+/// Two blocks are the same if they distribute a view into subblocks
+/// containing the same elements.
+
+template <dimension_type Dim,
+	  typename       MapT,
+	  typename       BlockT>
+struct Is_par_same_map
+{
+  static bool value(MapT const& map, BlockT const& block)
+    { return map_equal<Dim>(map, block.map()); }
+};
+
+
+
 template <typename BlockT>
 struct Is_par_reorg_ok
 {
Index: src/vsip/impl/vmmul.hpp
===================================================================
--- src/vsip/impl/vmmul.hpp	(revision 145195)
+++ src/vsip/impl/vmmul.hpp	(working copy)
@@ -219,11 +219,12 @@
 //  - vector and matrix mapped to single, single processor
 //
 
-template <typename       MapT,
+template <dimension_type MapDim,
+	  typename       MapT,
 	  dimension_type VecDim,
 	  typename       Block0,
 	  typename       Block1>
-struct Is_par_same_map<MapT,
+struct Is_par_same_map<MapDim, MapT,
                        Vmmul_expr_block<VecDim, Block0, Block1> const>
 {
   typedef Vmmul_expr_block<VecDim, Block0, Block1> const block_type;
@@ -236,17 +237,17 @@
 
     return 
       // Case 1: vector is global
-      (Is_par_same_map<Global_map<1>, Block0>::value(
+      (Is_par_same_map<1, Global_map<1>, Block0>::value(
 			Global_map<1>(), block.get_vblk()) &&
        map.num_subblocks(1-VecDim) == 1 &&
-       Is_par_same_map<MapT, Block1>::value(map, block.get_mblk())) ||
+       Is_par_same_map<MapDim, MapT, Block1>::value(map, block.get_mblk())) ||
 
       // Case 2:
       (map.num_subblocks(VecDim) == 1 &&
-       Is_par_same_map<typename Map_project_1<VecDim, MapT>::type, Block0>
+       Is_par_same_map<1, typename Map_project_1<VecDim, MapT>::type, Block0>
 	    ::value(Map_project_1<VecDim, MapT>::project(map, 0),
 		    block.get_vblk()) &&
-       Is_par_same_map<MapT, Block1>::value(map, block.get_mblk()));
+       Is_par_same_map<MapDim, MapT, Block1>::value(map, block.get_mblk()));
   }
 };
 
Index: src/vsip/impl/simd/eval-generic.hpp
===================================================================
--- src/vsip/impl/simd/eval-generic.hpp	(revision 145195)
+++ src/vsip/impl/simd/eval-generic.hpp	(working copy)
@@ -134,7 +134,7 @@
          const Binary_expr_block<1, op::Mult,
                                  Scalar_block<1, T>, T,
                                  VBlock, std::complex<T> >,
-         Intel_ipp_tag>
+         Simd_tag>
 {
   typedef Binary_expr_block<1, op::Mult,
 			    Scalar_block<1, T>, T,
@@ -185,7 +185,7 @@
          const Binary_expr_block<1, op::Mult,
                                  VBlock, std::complex<T>,
                                  Scalar_block<1, T>, T>,
-         Intel_ipp_tag>
+         Simd_tag>
 {
   typedef Binary_expr_block<1, op::Mult,
 			    VBlock, std::complex<T>,
Index: src/vsip/impl/dispatch-assign.hpp
===================================================================
--- src/vsip/impl/dispatch-assign.hpp	(revision 145195)
+++ src/vsip/impl/dispatch-assign.hpp	(working copy)
@@ -37,11 +37,11 @@
 
 struct Tag_illegal_mix_of_local_and_global_in_assign;
 
-struct Tag_serial_assign;
-struct Tag_serial_expr;
-struct Tag_par_assign;
-struct Tag_par_expr_noreorg;
-struct Tag_par_expr;
+struct Tag_serial_assign {};
+struct Tag_serial_expr {};
+struct Tag_par_assign {};
+struct Tag_par_expr_noreorg {};
+struct Tag_par_expr {};
 
 
 
@@ -236,7 +236,7 @@
     dst_type dst(blk1);
     src_type src(const_cast<Block2&>(blk2));
 
-    if (Is_par_same_map<map1_type, Block2>::value(blk1.map(), blk2))
+    if (Is_par_same_map<Dim, map1_type, Block2>::value(blk1.map(), blk2))
     {
       par_expr_simple(dst, src);
     }
@@ -271,12 +271,18 @@
 
   static void exec(Block1& blk1, Block2 const& blk2)
   {
-    if (Is_par_same_map<map1_type, Block2>::value(blk1.map(), blk2))
+    if (Is_par_same_map<Dim, map1_type, Block2>::value(blk1.map(), blk2))
     {
       // Maps are same, no communication required.
-      dst_type dst(blk1);
-      src_type src(const_cast<Block2&>(blk2));
-      par_expr_simple(dst, src);
+      typedef typename Distributed_local_block<Block1>::type block1_t;
+      typedef typename Distributed_local_block<Block2>::type block2_t;
+      typedef typename View_block_storage<block1_t>::type::equiv_type stor1_t;
+      typedef typename View_block_storage<block2_t>::type::equiv_type stor2_t;
+
+      stor1_t l_blk1 = get_local_block(blk1);
+      stor2_t l_blk2 = get_local_block(blk2);
+
+      Dispatch_assign<Dim, block1_t, block2_t>::exec(l_blk1, l_blk2);
     }
     else
     {
@@ -306,12 +312,18 @@
 
   static void exec(Block1& blk1, Block2 const& blk2)
   {
-    if (Is_par_same_map<map1_type, Block2>::value(blk1.map(), blk2))
+    if (Is_par_same_map<Dim, map1_type, Block2>::value(blk1.map(), blk2))
     {
       // Maps are same, no communication required.
-      dst_type dst(blk1);
-      src_type src(const_cast<Block2&>(blk2));
-      par_expr_simple(dst, src);
+      typedef typename Distributed_local_block<Block1>::type block1_t;
+      typedef typename Distributed_local_block<Block2>::type block2_t;
+      typedef typename View_block_storage<block1_t>::type::equiv_type stor1_t;
+      typedef typename View_block_storage<block2_t>::type::equiv_type stor2_t;
+
+      stor1_t l_blk1 = get_local_block(blk1);
+      stor2_t l_blk2 = get_local_block(blk2);
+
+      Dispatch_assign<Dim, block1_t, block2_t>::exec(l_blk1, l_blk2);
     }
     else
     {
Index: src/vsip/impl/expr_binary_block.hpp
===================================================================
--- src/vsip/impl/expr_binary_block.hpp	(revision 145195)
+++ src/vsip/impl/expr_binary_block.hpp	(working copy)
@@ -268,14 +268,15 @@
 
 
 
-template <typename MapT,
+template <dimension_type                      MapDim,
+	  typename                            MapT,
 	  dimension_type                      Dim,
 	  template <typename, typename> class Operator,
 	  typename                            LBlock,
 	  typename                            LType,
 	  typename                            RBlock,
 	  typename                            RType>
-struct Is_par_same_map<MapT,
+struct Is_par_same_map<MapDim, MapT,
 		       const Binary_expr_block<Dim, Operator,
 					       LBlock, LType,
 					       RBlock, RType> >
@@ -286,8 +287,8 @@
 
   static bool value(MapT const& map, block_type& block)
   {
-    return Is_par_same_map<MapT, LBlock>::value(map, block.left()) &&
-           Is_par_same_map<MapT, RBlock>::value(map, block.right());
+    return Is_par_same_map<MapDim, MapT, LBlock>::value(map, block.left()) &&
+           Is_par_same_map<MapDim, MapT, RBlock>::value(map, block.right());
   }
 };
 
Index: src/vsip/impl/par-expr.hpp
===================================================================
--- src/vsip/impl/par-expr.hpp	(revision 145195)
+++ src/vsip/impl/par-expr.hpp	(working copy)
@@ -485,7 +485,6 @@
   View2<T2, Block2> src)
 {
   VSIP_IMPL_STATIC_ASSERT((View1<T1, Block1>::dim == View2<T2, Block2>::dim));
-  typedef typename Block1::map_type         map_t;
 
   typedef typename Distributed_local_block<Block1>::type dst_lblock_type;
   typedef typename Distributed_local_block<Block2>::type src_lblock_type;
@@ -495,19 +494,10 @@
   // assert(Is_par_same_map<map_t, Block2>::value(dst.block().map(),
   //                                              src.block()));
 
-  Block1&      block = dst.block();
-  // unused! // map_t const& map   = dst.block().map();
+  View1<T1, dst_lblock_type> dst_lview = get_local_view(dst);
+  View2<T2, src_lblock_type> src_lview = get_local_view(src);
 
-  // Iterator through subblocks, performing assignment.  Not necessary
-  // iterate through patches since blocks have the same distribution.
-
-  if (block.map().subblock() != no_subblock)
-  {
-    View1<T1, dst_lblock_type> dst_lview = get_local_view(dst);
-    View2<T2, src_lblock_type> src_lview = get_local_view(src);
-
-    dst_lview = src_lview;
-  }
+  dst_lview = src_lview;
 }
 
 
Index: src/vsip/impl/subblock.hpp
===================================================================
--- src/vsip/impl/subblock.hpp	(revision 145195)
+++ src/vsip/impl/subblock.hpp	(working copy)
@@ -1045,7 +1045,7 @@
 
   const_data_type impl_data() const VSIP_NOTHROW
   {
-    return storage_type::offset(blk_->impl_data()
+    return storage_type::offset(blk_->impl_data(),
 				+ index1_*blk_->impl_stride(Block::dim, D1)
 				+ index2_*blk_->impl_stride(Block::dim, D2));
   }
Index: src/vsip/impl/fast-transpose.hpp
===================================================================
--- src/vsip/impl/fast-transpose.hpp	(revision 145195)
+++ src/vsip/impl/fast-transpose.hpp	(working copy)
@@ -126,10 +126,10 @@
     stride_type const dst_col_stride,
     stride_type const src_row_stride)
   {
-    __v4sf row0 = _mm_loadu_ps(src + 0*src_row_stride + 0);
-    __v4sf row1 = _mm_loadu_ps(src + 1*src_row_stride + 0);
-    __v4sf row2 = _mm_loadu_ps(src + 2*src_row_stride + 0);
-    __v4sf row3 = _mm_loadu_ps(src + 3*src_row_stride + 0);
+    __m128 row0 = _mm_loadu_ps(src + 0*src_row_stride + 0);
+    __m128 row1 = _mm_loadu_ps(src + 1*src_row_stride + 0);
+    __m128 row2 = _mm_loadu_ps(src + 2*src_row_stride + 0);
+    __m128 row3 = _mm_loadu_ps(src + 3*src_row_stride + 0);
     _MM_TRANSPOSE4_PS(row0, row1, row2, row3);
     _mm_storeu_ps(dst + 0 + 0*dst_col_stride, row0);
     _mm_storeu_ps(dst + 0 + 1*dst_col_stride, row1);
@@ -151,10 +151,10 @@
     stride_type const dst_col_stride,
     stride_type const src_row_stride)
   {
-    __v4sf row0 = _mm_load_ps(src + 0*src_row_stride + 0);
-    __v4sf row1 = _mm_load_ps(src + 1*src_row_stride + 0);
-    __v4sf row2 = _mm_load_ps(src + 2*src_row_stride + 0);
-    __v4sf row3 = _mm_load_ps(src + 3*src_row_stride + 0);
+    __m128 row0 = _mm_load_ps(src + 0*src_row_stride + 0);
+    __m128 row1 = _mm_load_ps(src + 1*src_row_stride + 0);
+    __m128 row2 = _mm_load_ps(src + 2*src_row_stride + 0);
+    __m128 row3 = _mm_load_ps(src + 3*src_row_stride + 0);
     _MM_TRANSPOSE4_PS(row0, row1, row2, row3);
     _mm_store_ps(dst + 0 + 0*dst_col_stride, row0);
     _mm_store_ps(dst + 0 + 1*dst_col_stride, row1);
@@ -176,13 +176,13 @@
     stride_type const     dst_col_stride,
     stride_type const     src_row_stride)
   {
-    __v4sf row0 = _mm_loadu_ps(
+    __m128 row0 = _mm_loadu_ps(
 		reinterpret_cast<float const*>(src + 0*src_row_stride + 0));
-    __v4sf row1 = _mm_loadu_ps(
+    __m128 row1 = _mm_loadu_ps(
 		reinterpret_cast<float const*>(src + 1*src_row_stride + 0));
 
-    __v4sf col0 = __builtin_ia32_shufps(row0, row1, 0x44); // 10 00 01 00
-    __v4sf col1 = __builtin_ia32_shufps(row0, row1, 0xEE); // 11 10 11 10
+    __m128 col0 = _mm_shuffle_ps(row0, row1, 0x44); // 10 00 01 00
+    __m128 col1 = _mm_shuffle_ps(row0, row1, 0xEE); // 11 10 11 10
 
     _mm_storeu_ps(reinterpret_cast<float*>(dst + 0 + 0*dst_col_stride), col0);
     _mm_storeu_ps(reinterpret_cast<float*>(dst + 0 + 1*dst_col_stride), col1);
@@ -202,13 +202,13 @@
     stride_type const     dst_col_stride,
     stride_type const     src_row_stride)
   {
-    __v4sf row0 = _mm_load_ps(
+    __m128 row0 = _mm_load_ps(
 		reinterpret_cast<float const*>(src + 0*src_row_stride + 0));
-    __v4sf row1 = _mm_load_ps(
+    __m128 row1 = _mm_load_ps(
 		reinterpret_cast<float const*>(src + 1*src_row_stride + 0));
 
-    __v4sf col0 = __builtin_ia32_shufps(row0, row1, 0x44); // 10 00 01 00
-    __v4sf col1 = __builtin_ia32_shufps(row0, row1, 0xEE); // 11 10 11 10
+    __m128 col0 = _mm_shuffle_ps(row0, row1, 0x44); // 10 00 01 00
+    __m128 col1 = _mm_shuffle_ps(row0, row1, 0xEE); // 11 10 11 10
 
     _mm_store_ps(reinterpret_cast<float*>(dst + 0 + 0*dst_col_stride), col0);
     _mm_store_ps(reinterpret_cast<float*>(dst + 0 + 1*dst_col_stride), col1);
Index: src/vsip/impl/replicated_map.hpp
===================================================================
--- src/vsip/impl/replicated_map.hpp	(revision 145195)
+++ src/vsip/impl/replicated_map.hpp	(working copy)
@@ -121,8 +121,8 @@
 
   // Extensions.
 public:
-  impl::Communicator impl_comm() const { return impl::default_communicator(); }
-  impl_pvec_type     impl_pvec() const
+  impl::Communicator& impl_comm() const { return impl::default_communicator();}
+  impl_pvec_type      impl_pvec() const
     { return this->pset_->impl_vector(); }
 
   length_type        impl_working_size() const
@@ -184,7 +184,7 @@
 { static bool const value = true; };
 
 template <dimension_type Dim>
-struct Map_equal<Replicated_map<Dim>, Replicated_map<Dim> >
+struct Map_equal<Dim, Replicated_map<Dim>, Replicated_map<Dim> >
 {
   static bool value(Replicated_map<Dim> const& a,
 		    Replicated_map<Dim> const& b)
Index: src/vsip/impl/expr_scalar_block.hpp
===================================================================
--- src/vsip/impl/expr_scalar_block.hpp	(revision 145195)
+++ src/vsip/impl/expr_scalar_block.hpp	(working copy)
@@ -231,10 +231,11 @@
 
 
 
-template <typename       MapT,
+template <dimension_type MapDim,
+	  typename       MapT,
 	  dimension_type D,
 	  typename       Scalar>
-struct Is_par_same_map<MapT,
+struct Is_par_same_map<MapDim, MapT,
 		       Scalar_block<D, Scalar> >
 {
   typedef Scalar_block<D, Scalar> block_type;
Index: src/vsip/impl/par-foreach.hpp
===================================================================
--- src/vsip/impl/par-foreach.hpp	(revision 145195)
+++ src/vsip/impl/par-foreach.hpp	(working copy)
@@ -396,7 +396,7 @@
         "foreach_vector requires the dimension being processed to be undistributed"));
     }
 
-    if (Is_par_same_map<map_t, typename InView::block_type>
+    if (Is_par_same_map<2, map_t, typename InView::block_type>
 	::value(map, in.block()))
     {
       typename InView::local_type  l_in  = get_local_view(in);
@@ -469,7 +469,7 @@
         "foreach_vector requires the dimension being processed to be undistributed"));
     }
 
-    if (Is_par_same_map<map_t, typename InView::block_type>
+    if (Is_par_same_map<3, map_t, typename InView::block_type>
 	::value(map, in.block()))
     {
       typename InView::local_type  l_in  = get_local_view(in);
Index: src/vsip/impl/local_map.hpp
===================================================================
--- src/vsip/impl/local_map.hpp	(revision 145195)
+++ src/vsip/impl/local_map.hpp	(working copy)
@@ -92,10 +92,15 @@
     const VSIP_NOTHROW
     { assert(0); }
 
+  index_type impl_global_from_local_index(dimension_type /*d*/, index_type sb,
+				     index_type idx)
+    const VSIP_NOTHROW
+  { assert(sb == 0); return idx; }
+
   // Extensions.
 public:
-  impl::Communicator impl_comm() const { return impl::default_communicator(); }
-  pvec_type          impl_pvec() const
+  impl::Communicator& impl_comm() const { return impl::default_communicator();}
+  pvec_type           impl_pvec() const
     { return impl::default_communicator().pvec(); }
 
   length_type        impl_working_size() const
@@ -118,8 +123,8 @@
 
 
 
-template < >
-struct Map_equal<Local_map,Local_map>
+template <dimension_type Dim>
+struct Map_equal<Dim, Local_map, Local_map>
 {
   static bool value(Local_map const&, Local_map const&)
     { return true; }
Index: src/vsip/impl/expr_ternary_block.hpp
===================================================================
--- src/vsip/impl/expr_ternary_block.hpp	(revision 145195)
+++ src/vsip/impl/expr_ternary_block.hpp	(working copy)
@@ -300,13 +300,14 @@
 
 
 
-template <typename                  MapT,
+template <dimension_type MapDim,
+	  typename MapT,
 	  dimension_type D,
 	  template <typename, typename, typename> class Functor,
 	  typename Block1, typename Type1,
 	  typename Block2, typename Type2,
 	  typename Block3, typename Type3>
-struct Is_par_same_map<MapT,
+struct Is_par_same_map<MapDim, MapT,
 		       Ternary_expr_block<D, Functor,
 					      Block1, Type1,
 					      Block2, Type2,
@@ -320,9 +321,9 @@
 
   static bool value(MapT const& map, block_type& block)
   {
-    return Is_par_same_map<MapT, Block1>::value(map, block.first()) &&
-           Is_par_same_map<MapT, Block2>::value(map, block.second()) &&
-           Is_par_same_map<MapT, Block3>::value(map, block.third());
+    return Is_par_same_map<MapDim, MapT, Block1>::value(map, block.first()) &&
+           Is_par_same_map<MapDim, MapT, Block2>::value(map, block.second()) &&
+           Is_par_same_map<MapDim, MapT, Block3>::value(map, block.third());
   }
 };
 
Index: src/vsip/impl/global_map.hpp
===================================================================
--- src/vsip/impl/global_map.hpp	(revision 145195)
+++ src/vsip/impl/global_map.hpp	(working copy)
@@ -105,8 +105,8 @@
 
   // Extensions.
 public:
-  impl::Communicator impl_comm() const { return impl::default_communicator(); }
-  pvec_type          impl_pvec() const
+  impl::Communicator& impl_comm() const { return impl::default_communicator();}
+  pvec_type           impl_pvec() const
     { return impl::default_communicator().pvec(); }
 
   length_type        impl_working_size() const
@@ -154,7 +154,7 @@
 
 
 template <dimension_type Dim>
-struct Map_equal<Global_map<Dim>, Global_map<Dim> >
+struct Map_equal<Dim, Global_map<Dim>, Global_map<Dim> >
 {
   static bool value(Global_map<Dim> const&,
 		    Global_map<Dim> const&)
Index: src/vsip/impl/par-services.hpp
===================================================================
--- src/vsip/impl/par-services.hpp	(revision 145195)
+++ src/vsip/impl/par-services.hpp	(working copy)
@@ -38,7 +38,7 @@
 
 // Return the default communicator.
 
-inline Communicator
+inline Communicator&
 default_communicator()
 {
   return Par_service::default_communicator();
Index: src/vsip/impl/expr_unary_block.hpp
===================================================================
--- src/vsip/impl/expr_unary_block.hpp	(revision 145195)
+++ src/vsip/impl/expr_unary_block.hpp	(working copy)
@@ -224,12 +224,13 @@
 
 
 
-template <typename                  MapT,
+template <dimension_type            MapDim,
+	  typename                  MapT,
 	  dimension_type            Dim,
 	  template <typename> class Op,
 	  typename                  Block,
 	  typename                  Type>
-struct Is_par_same_map<MapT,
+struct Is_par_same_map<MapDim, MapT,
 		       const Unary_expr_block<Dim, Op,
 					      Block, Type> >
 {
@@ -238,7 +239,7 @@
 
   static bool value(MapT const& map, block_type& block)
   {
-    return Is_par_same_map<MapT, Block>::value(map, block.op());
+    return Is_par_same_map<MapDim, MapT, Block>::value(map, block.op());
   }
 };
 
Index: src/vsip/impl/ipp.cpp
===================================================================
--- src/vsip/impl/ipp.cpp	(revision 145195)
+++ src/vsip/impl/ipp.cpp	(working copy)
@@ -36,11 +36,14 @@
   length_type len)							\
 {									\
   VSIP_IMPL_COVER_FCN("IPP_V", IPPFCN)					\
-  IppStatus status = IPPFCN(						\
-    reinterpret_cast<IPPT const*>(A),					\
-    reinterpret_cast<IPPT*>(Z),						\
-    static_cast<int>(len));						\
-  assert(status == ippStsNoErr);					\
+  if (len > 0)								\
+  {									\
+    IppStatus status = IPPFCN(						\
+      reinterpret_cast<IPPT const*>(A),					\
+      reinterpret_cast<IPPT*>(Z),					\
+      static_cast<int>(len));						\
+    assert(status == ippStsNoErr);					\
+  }									\
 }
 
 #define VSIP_IMPL_IPP_VV(FCN, T, IPPFCN, IPPT)				\
@@ -51,12 +54,15 @@
   T*       Z,								\
   length_type len)							\
 {									\
-  IppStatus status = IPPFCN(						\
-    reinterpret_cast<IPPT const*>(A),					\
-    reinterpret_cast<IPPT const*>(B),					\
-    reinterpret_cast<IPPT*>(Z),						\
-    static_cast<int>(len));						\
-  assert(status == ippStsNoErr);					\
+  if (len > 0)								\
+  {									\
+    IppStatus status = IPPFCN(						\
+      reinterpret_cast<IPPT const*>(A),					\
+      reinterpret_cast<IPPT const*>(B),					\
+      reinterpret_cast<IPPT*>(Z),					\
+      static_cast<int>(len));						\
+    assert(status == ippStsNoErr);					\
+  }									\
 }
 
 #define VSIP_IMPL_IPP_VV_R(FCN, T, IPPFCN, IPPT)			\
@@ -67,12 +73,15 @@
   T*       Z,								\
   length_type len)							\
 {									\
-  IppStatus status = IPPFCN(						\
-    reinterpret_cast<IPPT const*>(B),					\
-    reinterpret_cast<IPPT const*>(A),					\
-    reinterpret_cast<IPPT*>(Z),						\
-    static_cast<int>(len));						\
-  assert(status == ippStsNoErr);					\
+  if (len > 0)								\
+  {									\
+    IppStatus status = IPPFCN(						\
+      reinterpret_cast<IPPT const*>(B),					\
+      reinterpret_cast<IPPT const*>(A),					\
+      reinterpret_cast<IPPT*>(Z),					\
+      static_cast<int>(len));						\
+    assert(status == ippStsNoErr);					\
+  }									\
 }
 
 // Abs
@@ -141,8 +150,11 @@
 
 void svadd(float A, float const* B, float* Z, length_type len)
 {
-  IppStatus status = ippsAddC_32f(B, A, Z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
+  if (len > 0)
+  {
+    IppStatus status = ippsAddC_32f(B, A, Z, static_cast<int>(len));
+    assert(status == ippStsNoErr);
+  }
 }
 
 void svadd(double A, double const* B, double* Z, length_type len)
Index: src/vsip/impl/par-chain-assign.hpp
===================================================================
--- src/vsip/impl/par-chain-assign.hpp	(revision 145195)
+++ src/vsip/impl/par-chain-assign.hpp	(working copy)
@@ -269,6 +269,7 @@
       src_      (src.block()),
       dst_am_   (dst_.block().map()),
       src_am_   (src_.block().map()),
+      comm_     (dst_am_.impl_comm()),
       send_list (),
       recv_list (),
       copy_list (),
@@ -321,18 +322,18 @@
 
   void wait_send_list();
 
-  void cleanup();	// Cleanup send_list buffers.
+  void cleanup() {}	// Cleanup send_list buffers.
 
 
   // Invoke the parallel assignment
 public:
   void operator()()
   {
-    exec_send_list();
-    exec_copy_list();
-    exec_recv_list();
+    if (send_list.size() > 0) exec_send_list();
+    if (copy_list.size() > 0) exec_copy_list();
+    if (recv_list.size() > 0) exec_recv_list();
 
-    wait_send_list();
+    if (req_list.size() > 0)  wait_send_list();
 
     cleanup();
   }
@@ -345,6 +346,7 @@
 
   dst_appmap_t const& dst_am_;
   src_appmap_t const& src_am_;
+  impl::Communicator& comm_;
 
   std::vector<Msg_record>    send_list;
   std::vector<Msg_record>    recv_list;
@@ -692,7 +694,6 @@
 Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::exec_send_list()
 {
   impl::profile::Scope_event ev("Chained_parallel_assign-exec_send_list");
-  impl::Communicator comm = dst_am_.impl_comm();
 
 #if VSIP_IMPL_PCA_VERBOSE >= 1
   processor_type rank = local_processor();
@@ -700,37 +701,24 @@
 	    << "exec_send_list(size: " << send_list.size()
 	    << ") -------------------------------------\n";
 #endif
+  typedef typename std::vector<Msg_record>::iterator sl_iterator;
 
-  length_type dsize = dst_am_.impl_working_size();
-
-  // Iterate over all processors
-  for (index_type pi=0; pi<dsize; ++pi)
   {
-    // TODO: Rotate
-    processor_type proc = dst_am_.impl_proc_from_rank(pi);
-
-    impl::Chain_builder builder;
-
-    typedef typename std::vector<Msg_record>::iterator sl_iterator;
-    for (sl_iterator sl_cur = send_list.begin();
-	 sl_cur != send_list.end();
-	 ++sl_cur)
+    sl_iterator sl_cur = send_list.begin();
+    sl_iterator sl_end = send_list.end();
+    for (; sl_cur != sl_end; ++sl_cur)
     {
-      if (proc == (*sl_cur).proc_)
-      {
-	src_ext_type* ext = src_ext_[(*sl_cur).subblock_];
-	ext->begin();
-	builder.stitch(ext->data(), (*sl_cur).chain_);
-	ext->end();
-      }
-    }
+      impl::Chain_builder builder;
+      processor_type proc = (*sl_cur).proc_;
 
-    if (!builder.is_empty())
-    {
+      src_ext_type* ext = src_ext_[(*sl_cur).subblock_];
+      ext->begin();
+      builder.stitch(ext->data(), (*sl_cur).chain_);
+      ext->end();
+      
       chain_type chain = builder.get_chain();
-
       request_type   req;
-      comm.send(proc, chain, req);
+      comm_.send(proc, chain, req);
       impl::free_chain(chain);
       req_list.push_back(req);
     }
@@ -750,7 +738,6 @@
 Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::exec_recv_list()
 {
   impl::profile::Scope_event ev("Chained_parallel_assign-exec_recv_list");
-  impl::Communicator comm = src_am_.impl_comm();
 
 #if VSIP_IMPL_PCA_VERBOSE >= 1
   processor_type rank = local_processor();
@@ -759,39 +746,23 @@
 	    << ") -------------------------------------\n";
 #endif
 
-  length_type ssize = src_am_.impl_working_size();
-
-  // Iterate over all sending processors
-  for (index_type pi=0; pi<ssize; ++pi)
+  typedef typename std::vector<Msg_record>::iterator rl_iterator;
+  rl_iterator rl_cur = recv_list.begin();
+  rl_iterator rl_end = recv_list.end();
+    
+  for (; rl_cur != rl_end; ++rl_cur)
   {
-    // processor_type proc = (src_am_.impl_proc_from_rank(pi) + rank) % size;
-    processor_type proc = src_am_.impl_proc_from_rank(pi);
-
     impl::Chain_builder builder;
+    processor_type proc = (*rl_cur).proc_;
 
-    msg_count++;
-    
-    typedef typename std::vector<Msg_record>::iterator rl_iterator;
-    
-    for (rl_iterator rl_cur = recv_list.begin();
-	 rl_cur != recv_list.end();
-	 ++rl_cur)
-    {
-      if ((*rl_cur).proc_ == proc)
-      {
-	dst_ext_type* ext = dst_ext_[(*rl_cur).subblock_];
-	ext->begin();
-	builder.stitch(ext->data(), (*rl_cur).chain_);
-	ext->end();
-      }
-    }
+    dst_ext_type* ext = dst_ext_[(*rl_cur).subblock_];
+    ext->begin();
+    builder.stitch(ext->data(), (*rl_cur).chain_);
+    ext->end();
 
-    if (!builder.is_empty())
-    {
-      chain_type chain = builder.get_chain();
-      comm.recv(proc, chain);
-      impl::free_chain(chain);
-    }
+    chain_type chain = builder.get_chain();
+    comm_.recv(proc, chain);
+    impl::free_chain(chain);
   }
 }
 
@@ -808,7 +779,6 @@
 Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::exec_copy_list()
 {
   impl::profile::Scope_event ev("Chained_parallel_assign-exec_copy_list");
-  impl::Communicator comm = dst_am_.impl_comm();
 
 #if VSIP_IMPL_PCA_VERBOSE >= 1
   processor_type rank = local_processor();
@@ -817,15 +787,16 @@
 	    << ") -------------------------------------\n";
 #endif
 
+  src_lview_type src_lview = get_local_view(src_);
+  dst_lview_type dst_lview = get_local_view(dst_);
+
   typedef typename std::vector<Copy_record>::iterator cl_iterator;
   for (cl_iterator cl_cur = copy_list.begin();
        cl_cur != copy_list.end();
        ++cl_cur)
   {
     view_assert_local(src_, (*cl_cur).src_sb_);
-    src_lview_type src_lview = get_local_view(src_);
     view_assert_local(dst_, (*cl_cur).dst_sb_);
-    dst_lview_type dst_lview = get_local_view(dst_);
 
     dst_lview((*cl_cur).dst_dom_) = src_lview((*cl_cur).src_dom_);
 #if VSIP_IMPL_PCA_VERBOSE >= 2
@@ -849,32 +820,17 @@
 void
 Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::wait_send_list()
 {
-  impl::Communicator comm = dst_am_.impl_comm();
-
   typename std::vector<request_type>::iterator
 		cur = req_list.begin(),
 		end = req_list.end();
   for(; cur != end; ++cur)
   {
-    comm.wait(*cur);
+    comm_.wait(*cur);
   }
   req_list.clear();
 }
 
 
-  // Cleanup send_list buffers.
-
-template <dimension_type Dim,
-	  typename       T1,
-	  typename       T2,
-	  typename       Block1,
-	  typename       Block2>
-void
-Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::cleanup()
-{
-}
-
-
 } // namespace vsip::impl
 
 } // namespace vsip
Index: src/vsip/impl/par-services-mpi.hpp
===================================================================
--- src/vsip/impl/par-services-mpi.hpp	(revision 145195)
+++ src/vsip/impl/par-services-mpi.hpp	(working copy)
@@ -357,7 +357,7 @@
       delete[] buf_;
     }
 
-  static communicator_type default_communicator()
+  static communicator_type& default_communicator()
     {
       return default_communicator_;
     }
Index: src/vsip/map.hpp
===================================================================
--- src/vsip/map.hpp	(revision 145195)
+++ src/vsip/map.hpp	(working copy)
@@ -19,6 +19,7 @@
 
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
+#include <vsip/impl/refcount.hpp>
 #include <vsip/impl/value-iterator.hpp>
 #include <vsip/impl/par-services.hpp>
 #include <vsip/map_fwd.hpp>
@@ -83,23 +84,103 @@
 
 
 // Forward declaration.
-template <typename Dim0,
-	  typename Dim1,
-	  typename Dim2>
+template <typename Dist0,
+	  typename Dist1,
+	  typename Dist2>
 bool
-operator==(Map<Dim0, Dim1, Dim2> const& map1,
-	   Map<Dim0, Dim1, Dim2> const& map2) VSIP_NOTHROW;
+operator==(Map<Dist0, Dist1, Dist2> const& map1,
+	   Map<Dist0, Dist1, Dist2> const& map2) VSIP_NOTHROW;
 
 // Forward declaration.
-template <typename Dim0,
-	  typename Dim1,
-	  typename Dim2>
+template <dimension_type Dim,
+	  typename       Dist0,
+	  typename       Dist1,
+	  typename       Dist2>
 bool
-map_equiv(Map<Dim0, Dim1, Dim2> const& map1,
-	  Map<Dim0, Dim1, Dim2> const& map2) VSIP_NOTHROW;
+map_equiv(Map<Dist0, Dist1, Dist2> const& map1,
+	  Map<Dist0, Dist1, Dist2> const& map2) VSIP_NOTHROW;
 
 
 
+template <typename Dist0,
+	  typename Dist1,
+	  typename Dist2>
+struct Map_data
+  : public impl::Ref_count<Map_data<Dist0, Dist1, Dist2> >,
+    impl::Non_copyable
+{
+  typedef std::vector<processor_type> impl_pvec_type;
+
+  // Constructors.
+public:
+  Map_data(
+    Dist0 const&            dist0,
+    Dist1 const&            dist1,
+    Dist2 const&            dist2)
+  VSIP_NOTHROW
+  : dist0_ (dist0),
+    dist1_ (dist1),
+    dist2_ (dist2),
+    comm_  (impl::default_communicator()),
+    pvec_  (comm_.pvec()),
+    num_subblocks_(dist0.num_subblocks() *
+		   dist1.num_subblocks() *
+		   dist2.num_subblocks()),
+    num_procs_ (pvec_.size())
+  {
+    subblocks_[0] = dist0_.num_subblocks();
+    subblocks_[1] = dist1_.num_subblocks();
+    subblocks_[2] = dist2_.num_subblocks();
+
+    // It is necessary that the number of subblocks be less than the
+    // number of processors.
+    assert(num_subblocks_ <= num_procs_);
+  }
+
+  template <typename BlockT>
+  Map_data(
+    const_Vector<processor_type, BlockT> pvec,
+    Dist0 const&                         dist0,
+    Dist1 const&                         dist1,
+    Dist2 const&                         dist2)
+  VSIP_NOTHROW
+  : dist0_ (dist0),
+    dist1_ (dist1),
+    dist2_ (dist2),
+    comm_  (impl::default_communicator()),
+    pvec_  (),
+    num_subblocks_(dist0.num_subblocks() *
+		   dist1.num_subblocks() *
+		   dist2.num_subblocks()),
+    num_procs_ (pvec.size())
+  {
+    for (index_type i=0; i<pvec.size(); ++i)
+      pvec_.push_back(pvec.get(i));
+
+    subblocks_[0] = dist0_.num_subblocks();
+    subblocks_[1] = dist1_.num_subblocks();
+    subblocks_[2] = dist2_.num_subblocks();
+  }
+
+  // Member data.
+public:
+  Dist0               dist0_;
+  Dist1               dist1_;
+  Dist2               dist2_;
+
+  impl::Communicator& comm_;
+  impl_pvec_type      pvec_;		  // Grid function.
+
+  length_type	      num_subblocks_;	  // Total number of subblocks.
+  length_type	      num_procs_;	  // Total number of processors.
+
+  index_type	      subblocks_[VSIP_MAX_DIMENSION];
+					  // Number of subblocks in each
+					  // dimension.
+};
+
+
+
 // Map class.
 
 template <typename Dist0,
@@ -111,7 +192,8 @@
 public:
   typedef impl::Value_iterator<processor_type, unsigned> processor_iterator;
 
-  typedef std::vector<processor_type> impl_pvec_type;
+  typedef typename Map_data<Dist0, Dist1, Dist2>::impl_pvec_type
+    impl_pvec_type;
   static bool const impl_local_only  = false;
   static bool const impl_global_only = true;
 
@@ -141,9 +223,12 @@
   length_type       num_subblocks    (dimension_type d) const VSIP_NOTHROW;
   length_type       cyclic_contiguity(dimension_type d) const VSIP_NOTHROW;
 
-  length_type num_subblocks()  const VSIP_NOTHROW { return num_subblocks_; }
-  length_type num_processors() const VSIP_NOTHROW { return num_procs_; }
+  length_type num_subblocks()  const VSIP_NOTHROW
+  { return data_->num_subblocks_; }
 
+  length_type num_processors() const VSIP_NOTHROW
+  { return data_->num_procs_; }
+
   index_type subblock(processor_type pr) const VSIP_NOTHROW;
   index_type subblock() const VSIP_NOTHROW;
 
@@ -174,12 +259,12 @@
   Domain<Dim> applied_domain () const VSIP_NOTHROW;
 
   // Implementation functions.
-  impl_pvec_type     impl_pvec() const { return pvec_; }
-  impl::Communicator impl_comm() const { return comm_; }
-  bool               impl_is_applied() const { return dim_ != 0; }
+  impl_pvec_type      impl_pvec() const { return data_->pvec_; }
+  impl::Communicator& impl_comm() const { return data_->comm_; }
+  bool                impl_is_applied() const { return dim_ != 0; }
 
-  length_type        impl_working_size() const
-    { return std::min(this->num_subblocks(), this->pvec_.size()); }
+  length_type         impl_working_size() const
+    { return std::min(this->num_subblocks(), this->data_->pvec_.size()); }
 
 
   // Implementation functions.
@@ -226,31 +311,32 @@
   typedef Dist2 impl_dim2_type;
 
   friend bool operator==<>(Map const&, Map const&) VSIP_NOTHROW;
-  friend bool map_equiv<>(Map const&, Map const&) VSIP_NOTHROW;
+  friend bool map_equiv<1>(Map const&, Map const&) VSIP_NOTHROW;
+  friend bool map_equiv<2>(Map const&, Map const&) VSIP_NOTHROW;
+  friend bool map_equiv<3>(Map const&, Map const&) VSIP_NOTHROW;
+  friend struct impl::Map_equal<1, Map, Map>;
+  friend struct impl::Map_equal<2, Map, Map>;
+  friend struct impl::Map_equal<3, Map, Map>;
 
 public:
   index_type     impl_rank_from_proc(processor_type pr) const;
   processor_type impl_proc_from_rank(index_type idx) const
-    { return pvec_[idx]; }
+    { return data_->pvec_[idx]; }
 
   // Members.
 private:
-  Dist0              dist0_;
-  Dist1              dist1_;
-  Dist2              dist2_;
+  impl::Ref_counted_ptr<Map_data<Dist0, Dist1, Dist2> > data_;
 
-  impl::Communicator comm_;
-  impl_pvec_type     pvec_;		  // Grid function.
-
-  length_type	     num_subblocks_;	  // Total number of subblocks.
-  length_type	     num_procs_;	  // Total number of processors.
-
   Domain<3>	     dom_;		  // Applied domain.
   dimension_type     dim_;		  // Dimension of applied domain.
 
-  index_type	     subblocks_[VSIP_MAX_DIMENSION];
-					  // Number of subblocks in each
-					  // dimension.
+  // Base map that this map was created from (or this map if created
+  // from scratch).  This is used to optimize a common case of
+  // comparing two maps for equivalence when they are created from the
+  // same source map.  Since non-applied properties of maps cannot be
+  // modified after creation, if two maps have the same base_map_
+  // pointer, they are equivalanet.
+  // Map* const         base_map_;
 };
 
 
@@ -268,23 +354,12 @@
   Dist1 const&            dist1,
   Dist2 const&            dist2)
 VSIP_NOTHROW
-: dist0_ (dist0),
-  dist1_ (dist1),
-  dist2_ (dist2),
-  comm_  (impl::default_communicator()),
-  pvec_  (comm_.pvec()),
-  num_subblocks_(dist0.num_subblocks() *
-		 dist1.num_subblocks() *
-		 dist2.num_subblocks()),
-  num_procs_ (pvec_.size()),
+: data_      (new Map_data<Dist0, Dist1, Dist2>(dist0, dist1, dist2)),
   dim_       (0)
 {
-  for (dimension_type d=0; d<VSIP_MAX_DIMENSION; ++d)
-    subblocks_[d] = num_subblocks(d);
-
   // It is necessary that the number of subblocks be less than the
   // number of processors.
-  assert(num_subblocks_ <= num_procs_);
+  assert(data_->num_subblocks_ <= data_->num_procs_);
 }
 
 
@@ -300,26 +375,12 @@
   Dist1 const&                         dist1,
   Dist2 const&                         dist2)
 VSIP_NOTHROW
-: dist0_ (dist0),
-  dist1_ (dist1),
-  dist2_ (dist2),
-  comm_  (impl::default_communicator()),
-  pvec_  (),
-  num_subblocks_(dist0.num_subblocks() *
-		 dist1.num_subblocks() *
-		 dist2.num_subblocks()),
-  num_procs_ (pvec.size()),
-  dim_       (0)
+: data_     (new Map_data<Dist0, Dist1, Dist2>(pvec, dist0, dist1, dist2)),
+  dim_      (0)
 {
-  for (index_type i=0; i<pvec.size(); ++i)
-    pvec_.push_back(pvec.get(i));
-
-  for (dimension_type d=0; d<VSIP_MAX_DIMENSION; ++d)
-    subblocks_[d] = num_subblocks(d);
-
   // It is necessary that the number of subblocks be less than the
   // number of processors.
-  assert(num_subblocks_ <= num_procs_);
+  assert(data_->num_subblocks_ <= data_->num_procs_);
 }
 
 
@@ -329,20 +390,10 @@
 	  typename       Dist2>
 inline
 Map<Dist0, Dist1, Dist2>::Map(Map const& rhs) VSIP_NOTHROW
-: dist0_ (rhs.dist0_),
-  dist1_ (rhs.dist1_),
-  dist2_ (rhs.dist2_),
-  comm_  (rhs.comm_),
-  pvec_  (rhs.pvec_),
-  num_subblocks_(dist0_.num_subblocks() *
-		 dist1_.num_subblocks() *
-		 dist2_.num_subblocks()),
-  num_procs_ (pvec_.size()),
-  dom_   (rhs.dom_),
-  dim_   (0)
+: data_      (rhs.data_),
+  dom_       (rhs.dom_),
+  dim_       (0)
 {
-  for (dimension_type d=0; d<VSIP_MAX_DIMENSION; ++d)
-    subblocks_[d] = num_subblocks(d);
 }
 
 
@@ -353,20 +404,11 @@
 inline Map<Dist0, Dist1, Dist2>&
 Map<Dist0, Dist1, Dist2>::operator=(Map const& rhs) VSIP_NOTHROW
 {
-  dist0_ = rhs.dist0_;
-  dist1_ = rhs.dist1_;
-  dist2_ = rhs.dist2_;
-  comm_  = rhs.comm_;
-  pvec_  = rhs.pvec_;
-  num_subblocks_ = rhs.num_subblocks_;
+  data_ = rhs.data_;
 
-  num_procs_ = pvec_.size();
-  dom_       = rhs.dom_;
-  dim_       = 0;
+  dom_  = rhs.dom_;
+  dim_  = 0;
 
-  for (dimension_type d=0; d<VSIP_MAX_DIMENSION; ++d)
-    subblocks_[d] = num_subblocks(d);
-
   return *this;
 }
 
@@ -405,9 +447,9 @@
   switch (d)
   {
   default: assert(false);
-  case 0: return dist0_.distribution();
-  case 1: return dist1_.distribution();
-  case 2: return dist2_.distribution();
+  case 0: return data_->dist0_.distribution();
+  case 1: return data_->dist1_.distribution();
+  case 2: return data_->dist2_.distribution();
   }
 }
 
@@ -425,9 +467,9 @@
   switch (d)
   {
   default: assert(false);
-  case 0: return dist0_.num_subblocks();
-  case 1: return dist1_.num_subblocks();
-  case 2: return dist2_.num_subblocks();
+  case 0: return data_->dist0_.num_subblocks();
+  case 1: return data_->dist1_.num_subblocks();
+  case 2: return data_->dist2_.num_subblocks();
   }
 }
 
@@ -445,9 +487,9 @@
   switch (d)
   {
   default: assert(false);
-  case 0: return dist0_.cyclic_contiguity();
-  case 1: return dist1_.cyclic_contiguity();
-  case 2: return dist2_.cyclic_contiguity();
+  case 0: return data_->dist0_.cyclic_contiguity();
+  case 1: return data_->dist1_.cyclic_contiguity();
+  case 2: return data_->dist2_.cyclic_contiguity();
   }
 }
 
@@ -470,9 +512,9 @@
   switch (d)
   {
   default: assert(false);
-  case 0: return dist0_.impl_subblock_patches(dom_[0], sb);
-  case 1: return dist1_.impl_subblock_patches(dom_[1], sb);
-  case 2: return dist2_.impl_subblock_patches(dom_[2], sb);
+  case 0: return data_->dist0_.impl_subblock_patches(dom_[0], sb);
+  case 1: return data_->dist1_.impl_subblock_patches(dom_[1], sb);
+  case 2: return data_->dist2_.impl_subblock_patches(dom_[2], sb);
   }
 }
 
@@ -495,9 +537,9 @@
   switch (d)
   {
   default: assert(false);
-  case 0: return dist0_.impl_subblock_size(dom_[0], sb);
-  case 1: return dist1_.impl_subblock_size(dom_[1], sb);
-  case 2: return dist2_.impl_subblock_size(dom_[2], sb);
+  case 0: return data_->dist0_.impl_subblock_size(dom_[0], sb);
+  case 1: return data_->dist1_.impl_subblock_size(dom_[1], sb);
+  case 2: return data_->dist2_.impl_subblock_size(dom_[2], sb);
   }
 }
 
@@ -521,9 +563,9 @@
   switch (d)
   {
   default: assert(false);
-  case 0: return dist0_.impl_patch_global_dom(dom_[0], sb, p);
-  case 1: return dist1_.impl_patch_global_dom(dom_[1], sb, p);
-  case 2: return dist2_.impl_patch_global_dom(dom_[2], sb, p);
+  case 0: return data_->dist0_.impl_patch_global_dom(dom_[0], sb, p);
+  case 1: return data_->dist1_.impl_patch_global_dom(dom_[1], sb, p);
+  case 2: return data_->dist2_.impl_patch_global_dom(dom_[2], sb, p);
   }
 }
 
@@ -547,9 +589,9 @@
   switch (d)
   {
   default: assert(false);
-  case 0: return dist0_.impl_patch_local_dom(dom_[0], sb, p);
-  case 1: return dist1_.impl_patch_local_dom(dom_[1], sb, p);
-  case 2: return dist2_.impl_patch_local_dom(dom_[2], sb, p);
+  case 0: return data_->dist0_.impl_patch_local_dom(dom_[0], sb, p);
+  case 1: return data_->dist1_.impl_patch_local_dom(dom_[1], sb, p);
+  case 2: return data_->dist2_.impl_patch_local_dom(dom_[2], sb, p);
   }
 }
 
@@ -573,9 +615,9 @@
   switch (d)
   {
   default: assert(false);
-  case 0: return dist0_.impl_subblock_from_index(dom_[0], idx);
-  case 1: return dist1_.impl_subblock_from_index(dom_[1], idx);
-  case 2: return dist2_.impl_subblock_from_index(dom_[2], idx);
+  case 0: return data_->dist0_.impl_subblock_from_index(dom_[0], idx);
+  case 1: return data_->dist1_.impl_subblock_from_index(dom_[1], idx);
+  case 2: return data_->dist2_.impl_subblock_from_index(dom_[2], idx);
   }
 }
 
@@ -599,9 +641,9 @@
   switch (d)
   {
   default: assert(false);
-  case 0: return dist0_.impl_patch_from_index(dom_[0], idx);
-  case 1: return dist1_.impl_patch_from_index(dom_[1], idx);
-  case 2: return dist2_.impl_patch_from_index(dom_[2], idx);
+  case 0: return data_->dist0_.impl_patch_from_index(dom_[0], idx);
+  case 1: return data_->dist1_.impl_patch_from_index(dom_[1], idx);
+  case 2: return data_->dist2_.impl_patch_from_index(dom_[2], idx);
   }
 }
 
@@ -623,9 +665,9 @@
   switch (d)
   {
   default: assert(false);
-  case 0: return dist0_.impl_local_from_global_index(dom_[0], idx);
-  case 1: return dist1_.impl_local_from_global_index(dom_[1], idx);
-  case 2: return dist2_.impl_local_from_global_index(dom_[2], idx);
+  case 0: return data_->dist0_.impl_local_from_global_index(dom_[0], idx);
+  case 1: return data_->dist1_.impl_local_from_global_index(dom_[1], idx);
+  case 2: return data_->dist2_.impl_local_from_global_index(dom_[2], idx);
   }
 }
 
@@ -650,13 +692,13 @@
   {
     assert(idx[d] < dom_[d].size());
     if (d != 0)
-      sb *= subblocks_[d];
+      sb *= data_->subblocks_[d];
     sb += impl_dim_subblock_from_index(d, idx[d]);
   }
 
-  assert(sb < num_subblocks_);
+  assert(sb < data_->num_subblocks_);
   index_type dim_sb[VSIP_MAX_DIMENSION];
-  impl::split_tuple(sb, dim_, subblocks_, dim_sb);
+  impl::split_tuple(sb, dim_, data_->subblocks_, dim_sb);
   for (dimension_type d=0; d<Dim; ++d)
   {
     assert(dim_sb[d] == impl_dim_subblock_from_index(d, idx[d]));
@@ -685,7 +727,7 @@
   assert(dim_ != 0 && dim_ == Dim);
 
   index_type sb = this->impl_subblock_from_global_index(idx);
-  impl::split_tuple(sb, dim_, subblocks_, dim_sb);
+  impl::split_tuple(sb, dim_, data_->subblocks_, dim_sb);
 
   for (dimension_type d=0; d<Dim; ++d)
   {
@@ -725,14 +767,14 @@
   assert(dim_ != 0 && d < dim_);
 
   index_type dim_sb[VSIP_MAX_DIMENSION];
-  impl::split_tuple(sb, dim_, subblocks_, dim_sb);
+  impl::split_tuple(sb, dim_, data_->subblocks_, dim_sb);
 
   switch (d)
   {
   default: assert(false);
-  case 0: return dist0_.impl_global_from_local_index(dom_[0], dim_sb[0], idx);
-  case 1: return dist1_.impl_global_from_local_index(dom_[1], dim_sb[1], idx);
-  case 2: return dist2_.impl_global_from_local_index(dom_[2], dim_sb[2], idx);
+  case 0: return data_->dist0_.impl_global_from_local_index(dom_[0], dim_sb[0], idx);
+  case 1: return data_->dist1_.impl_global_from_local_index(dom_[1], dim_sb[1], idx);
+  case 2: return data_->dist2_.impl_global_from_local_index(dom_[2], dim_sb[2], idx);
   }
 }
 
@@ -749,13 +791,13 @@
   )
   const VSIP_NOTHROW
 {
-  assert(sb < num_subblocks_);
+  assert(sb < data_->num_subblocks_);
   assert(dim_ == Dim);
 
   Domain<1>  l_dom[VSIP_MAX_DIMENSION];
 
   index_type dim_sb[VSIP_MAX_DIMENSION];
-  impl::split_tuple(sb, Dim, subblocks_, dim_sb);
+  impl::split_tuple(sb, Dim, data_->subblocks_, dim_sb);
 
   for (dimension_type d=0; d<Dim; ++d)
   {
@@ -798,8 +840,8 @@
 Map<Dist0, Dist1, Dist2>::impl_rank_from_proc(processor_type pr)
   const
 {
-  for (index_type i=0; i<pvec_.size(); ++i)
-    if (pvec_[i] == pr)
+  for (index_type i=0; i<data_->pvec_.size(); ++i)
+    if (data_->pvec_[i] == pr)
       return i;
 
   return no_processor;
@@ -824,7 +866,7 @@
 {
   index_type pi = impl_rank_from_proc(pr);
 
-  if (pi != no_processor && pi < num_subblocks_)
+  if (pi != no_processor && pi < data_->num_subblocks_)
     return pi;
   else
     return no_subblock;
@@ -848,7 +890,7 @@
   processor_type pr = local_processor();
   index_type     pi = impl_rank_from_proc(pr);
 
-  if (pi != no_processor && pi < num_subblocks_)
+  if (pi != no_processor && pi < data_->num_subblocks_)
     return pi;
   else
     return no_subblock;
@@ -876,9 +918,9 @@
 Map<Dist0, Dist1, Dist2>::processor_begin(index_type sb)
   const VSIP_NOTHROW
 {
-  assert(sb < num_subblocks_);
+  assert(sb < data_->num_subblocks_);
 
-  return processor_iterator(pvec_[sb % num_procs_], 1);
+  return processor_iterator(data_->pvec_[sb % data_->num_procs_], 1);
 }
 
 
@@ -903,9 +945,9 @@
 Map<Dist0, Dist1, Dist2>::processor_end(index_type sb)
   const VSIP_NOTHROW
 {
-  assert(sb < num_subblocks_);
+  assert(sb < data_->num_subblocks_);
 
-  return processor_iterator(pvec_[sb % num_procs_]+1, 1);
+  return processor_iterator(data_->pvec_[sb % data_->num_procs_]+1, 1);
 }
 
 
@@ -923,10 +965,10 @@
 Map<Dist0, Dist1, Dist2>::processor_set()
   const
 {
-  Vector<processor_type> pset(this->num_procs_);
+  Vector<processor_type> pset(this->data_->num_procs_);
 
-  for (index_type i=0; i<this->num_procs_; ++i)
-    pset.put(i, this->pvec_[i]);
+  for (index_type i=0; i<this->data_->num_procs_; ++i)
+    pset.put(i, this->data_->pvec_[i]);
 
   return pset;
 }
@@ -946,7 +988,7 @@
 Map<Dist0, Dist1, Dist2>::impl_num_patches(index_type sb)
   const VSIP_NOTHROW
 {
-  assert(sb < num_subblocks_ || sb == no_subblock);
+  assert(sb < data_->num_subblocks_ || sb == no_subblock);
   assert(dim_ != 0);
 
   if (sb == no_subblock)
@@ -955,7 +997,7 @@
   {
     index_type dim_sb[VSIP_MAX_DIMENSION];
 
-    impl::split_tuple(sb, dim_, subblocks_, dim_sb);
+    impl::split_tuple(sb, dim_, data_->subblocks_, dim_sb);
 
     length_type patches = 1;
     for (dimension_type d=0; d<dim_; ++d)
@@ -981,7 +1023,7 @@
 Map<Dist0, Dist1, Dist2>::impl_subblock_domain(index_type sb)
   const VSIP_NOTHROW
 {
-  assert(sb < num_subblocks_ || sb == no_subblock);
+  assert(sb < data_->num_subblocks_ || sb == no_subblock);
   assert(dim_ == Dim);
 
   if (sb == no_subblock)
@@ -991,7 +1033,7 @@
     index_type dim_sb[VSIP_MAX_DIMENSION];
     Domain<1>  dom[VSIP_MAX_DIMENSION];
 
-    impl::split_tuple(sb, dim_, subblocks_, dim_sb);
+    impl::split_tuple(sb, dim_, data_->subblocks_, dim_sb);
 
     for (dimension_type d=0; d<dim_; ++d)
       dom[d] = Domain<1>(impl_subblock_size(d, dim_sb[d]));
@@ -1033,11 +1075,11 @@
     return impl::construct_domain<Dim>(dom);
   }
 
-  assert(sb < num_subblocks_);
+  assert(sb < data_->num_subblocks_);
   assert(p  < this->impl_num_patches(sb));
   assert(dim_ == Dim);
 
-  impl::split_tuple(sb, Dim, subblocks_, dim_sb);
+  impl::split_tuple(sb, Dim, data_->subblocks_, dim_sb);
 
   for (dimension_type d=0; d<Dim; ++d)
     p_size[d] = impl_subblock_patches(d, dim_sb[d]);
@@ -1084,12 +1126,12 @@
     return impl::construct_domain<Dim>(dom);
   }
 
-  assert(sb < num_subblocks_);
+  assert(sb < data_->num_subblocks_);
   assert(p  < this->impl_num_patches(sb));
   assert(dim_ == Dim);
 
 
-  impl::split_tuple(sb, Dim, subblocks_, dim_sb);
+  impl::split_tuple(sb, Dim, data_->subblocks_, dim_sb);
 
   for (dimension_type d=0; d<Dim; ++d)
     p_size[d] = impl_subblock_patches(d, dim_sb[d]);
@@ -1144,14 +1186,14 @@
       return false;
   }
 
-  if (map1.comm_ != map2.comm_)
+  if (map1.data_->comm_ != map2.data_->comm_)
     return false;
 
-  if (map1.pvec_.size() != map2.pvec_.size())
+  if (map1.data_->pvec_.size() != map2.data_->pvec_.size())
     return false;
 
-  for (index_type i=0; i<map1.pvec_.size(); ++i)
-    if (map1.pvec_[i] != map2.pvec_[i])
+  for (index_type i=0; i<map1.data_->pvec_.size(); ++i)
+    if (map1.data_->pvec_[i] != map2.data_->pvec_[i])
       return false;
 
   return true;
@@ -1159,32 +1201,57 @@
 
 
 
-template <typename Dim0,
-	  typename Dim1,
-	  typename Dim2>
+template <dimension_type Dim,
+	  typename       Dist0,
+	  typename       Dist1,
+	  typename       Dist2>
 bool
-map_equiv(Map<Dim0, Dim1, Dim2> const& map1,
-	  Map<Dim0, Dim1, Dim2> const& map2) VSIP_NOTHROW
+map_equiv(Map<Dist0, Dist1, Dist2> const& map1,
+	  Map<Dist0, Dist1, Dist2> const& map2) VSIP_NOTHROW
 {
-  for (dimension_type d=0; d<VSIP_MAX_DIMENSION; ++d)
-  {
-    if (map1.distribution(d)      != map2.distribution(d) ||
-	map1.num_subblocks(d)     != map2.num_subblocks(d) ||
-	map1.cyclic_contiguity(d) != map2.cyclic_contiguity(d))
-      return false;
-  }
+  if (Dim == 1 &&
+         (map1.data_->dist0_.num_subblocks()     !=
+          map2.data_->dist0_.num_subblocks()
+       || map1.data_->dist0_.cyclic_contiguity() !=
+          map2.data_->dist0_.cyclic_contiguity()))
+    return false;
+  else if (Dim == 2 &&
+         (map1.data_->dist0_.num_subblocks()     !=
+          map2.data_->dist0_.num_subblocks()
+       || map1.data_->dist0_.cyclic_contiguity() !=
+          map2.data_->dist0_.cyclic_contiguity()
+       || map1.data_->dist1_.num_subblocks()     !=
+          map2.data_->dist1_.num_subblocks()
+       || map1.data_->dist1_.cyclic_contiguity() !=
+          map2.data_->dist1_.cyclic_contiguity()))
+    return false;
+  else if (Dim == 3 &&
+      (   map1.data_->dist0_.num_subblocks()     !=
+          map2.data_->dist0_.num_subblocks()
+       || map1.data_->dist0_.cyclic_contiguity() !=
+          map2.data_->dist0_.cyclic_contiguity()
+       || map1.data_->dist1_.num_subblocks()     !=
+          map2.data_->dist1_.num_subblocks()
+       || map1.data_->dist1_.cyclic_contiguity() !=
+          map2.data_->dist1_.cyclic_contiguity()
+       || map1.data_->dist2_.num_subblocks()     !=
+          map2.data_->dist2_.num_subblocks()
+       || map1.data_->dist2_.cyclic_contiguity() !=
+          map2.data_->dist2_.cyclic_contiguity()))
+    return false;
 
-  // implied by loop
+
+  // implied by checks on distX_.num_subblocks()
   assert(map1.num_subblocks() == map1.num_subblocks());
 
-  if (map1.comm_ != map2.comm_)
+  if (map1.data_->comm_ != map2.data_->comm_)
     return false;
 
-  assert(map1.pvec_.size() >= map1.num_subblocks());
-  assert(map2.pvec_.size() >= map2.num_subblocks());
+  assert(map1.data_->pvec_.size() >= map1.num_subblocks());
+  assert(map2.data_->pvec_.size() >= map2.num_subblocks());
 
   for (index_type i=0; i<map1.num_subblocks(); ++i)
-    if (map1.pvec_[i] != map2.pvec_[i])
+    if (map1.data_->pvec_[i] != map2.data_->pvec_[i])
       return false;
 
   return true;
@@ -1218,14 +1285,16 @@
 
 
 
-template <typename Dim0,
-	  typename Dim1,
-	  typename Dim2>
-struct Map_equal<Map<Dim0, Dim1, Dim2>, Map<Dim0, Dim1, Dim2> >
+template <dimension_type Dim,
+	  typename       Dist0,
+	  typename       Dist1,
+	  typename       Dist2>
+struct Map_equal<Dim, Map<Dist0, Dist1, Dist2>, Map<Dist0, Dist1, Dist2> >
 {
-  static bool value(Map<Dim0, Dim1, Dim2> const& map1,
-		    Map<Dim0, Dim1, Dim2> const& map2)
-    { return map_equiv(map1, map2); }
+  static bool value(Map<Dist0, Dist1, Dist2> const& map1,
+		    Map<Dist0, Dist1, Dist2> const& map2)
+  { return (map1.data_.get() == map2.data_.get()) ||
+           map_equiv<Dim>(map1, map2); }
 };
 
 
Index: tests/extdata-runtime.cpp
===================================================================
--- tests/extdata-runtime.cpp	(revision 145195)
+++ tests/extdata-runtime.cpp	(working copy)
@@ -146,7 +146,16 @@
     
     test_assert((ct_cost == impl::Ext_data_cost<BlockT, LP>::value));
     test_assert(rt_cost == ext.cost());
+    test_assert(rt_cost == impl::cost<LP>(view.block()));
 
+    // Check that rt_cost == 0 implies mem_required == 0
+    test_assert((rt_cost == 0 && impl::mem_required<LP>(view.block()) == 0) ||
+		(rt_cost != 0 && impl::mem_required<LP>(view.block()) > 0));
+
+    // Check that rt_cost == 0 implies xfer_required == false
+    test_assert((rt_cost == 0 && !impl::xfer_required<LP>(view.block())) ||
+		(rt_cost != 0 &&  impl::xfer_required<LP>(view.block())) );
+
     test_assert(ext.size(0) == view.size(0));
 
     T* ptr              = ext.data();
@@ -279,6 +288,14 @@
     test_assert((ct_cost == impl::Ext_data_cost<BlockT, LP>::value));
     test_assert(rt_cost == ext.cost());
 
+    // Check that rt_cost == 0 implies mem_required == 0
+    test_assert((rt_cost == 0 && impl::mem_required<LP>(view.block()) == 0) ||
+		(rt_cost != 0 && impl::mem_required<LP>(view.block()) > 0));
+
+    // Check that rt_cost == 0 implies xfer_required == false
+    test_assert((rt_cost == 0 && !impl::xfer_required<LP>(view.block())) ||
+		(rt_cost != 0 &&  impl::xfer_required<LP>(view.block())) );
+
     test_assert(ext.size(0) == view.size(0));
     test_assert(ext.size(1) == view.size(1));
 
@@ -441,6 +458,14 @@
     test_assert((ct_cost == impl::Ext_data_cost<BlockT, LP>::value));
     test_assert(rt_cost == ext.cost());
 
+    // Check that rt_cost == 0 implies mem_required == 0
+    test_assert((rt_cost == 0 && impl::mem_required<LP>(view.block()) == 0) ||
+		(rt_cost != 0 && impl::mem_required<LP>(view.block()) > 0));
+
+    // Check that rt_cost == 0 implies xfer_required == false
+    test_assert((rt_cost == 0 && !impl::xfer_required<LP>(view.block())) ||
+		(rt_cost != 0 &&  impl::xfer_required<LP>(view.block())) );
+
     test_assert(ext.size(0) == view.size(0));
     test_assert(ext.size(1) == view.size(1));
     test_assert(ext.size(2) == view.size(2));
Index: benchmarks/copy.cpp
===================================================================
--- benchmarks/copy.cpp	(revision 145195)
+++ benchmarks/copy.cpp	(working copy)
@@ -19,6 +19,7 @@
 #include <vsip/impl/setup-assign.hpp>
 #include <vsip/impl/par-chain-assign.hpp>
 #include <vsip/map.hpp>
+#include <vsip/parallel.hpp>
 #include <vsip/impl/profile.hpp>
 
 #include <vsip_csl/test.hpp>
@@ -31,14 +32,31 @@
 
 
 /***********************************************************************
+  Declarations
+***********************************************************************/
+
+struct Impl_assign;
+struct Impl_sa;
+struct Impl_cpa;
+
+template <typename T,
+	  typename SrcMapT,
+	  typename DstMapT,
+	  typename ImplTag>
+struct t_vcopy;
+
+
+
+/***********************************************************************
   Vector copy - normal assignment
 ***********************************************************************/
 
 template <typename T,
-	  typename MapT>
-struct t_vcopy
+	  typename SrcMapT,
+	  typename DstMapT>
+struct t_vcopy<T, SrcMapT, DstMapT, Impl_assign>
 {
-  char* what() { return "t_vcopy"; }
+  char* what() { return "t_vcopy<..., Impl_assign>"; }
   int ops_per_point(length_type)  { return 1; }
   int riob_per_point(length_type) { return 1*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
@@ -46,11 +64,16 @@
 
   void operator()(length_type size, length_type loop, float& time)
   {
-    typedef Dense<1, T, row1_type, MapT> block_t;
-    Vector<T, block_t>   A(size, T(), map_);
-    Vector<T, block_t>   Z(size,      map_);
+    typedef Dense<1, T, row1_type, SrcMapT> src_block_t;
+    typedef Dense<1, T, row1_type, DstMapT> dst_block_t;
+    Vector<T, src_block_t>   A(size, T(), src_map_);
+    Vector<T, dst_block_t>   Z(size,      dst_map_);
 
-    get_local_view(A).put(0, T(3));
+    for (index_type i=0; i<A.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(A, 0, i);
+      A.local().put(i, T(g_i));
+    }
     
     vsip::impl::profile::Timer t1;
     
@@ -58,53 +81,40 @@
     for (index_type l=0; l<loop; ++l)
       Z = A;
     t1.stop();
-    
-    if (!equal(get_local_view(Z).get(0), T(3)))
+
+    for (index_type i=0; i<Z.local().size(); ++i)
     {
-      std::cout << "t_vcopy: ERROR" << std::endl;
-      abort();
+      index_type g_i = global_from_local_index(Z, 0, i);
+      test_assert(equal(Z.local().get(i), T(g_i)));
     }
     
     time = t1.delta();
   }
 
-  t_vcopy(MapT map) : map_(map) {}
+  t_vcopy(SrcMapT src_map, DstMapT dst_map)
+    : src_map_(src_map), dst_map_(dst_map)
+  {}
 
   // Member data.
-  MapT	map_;
+  SrcMapT	src_map_;
+  DstMapT	dst_map_;
 };
 
 
 
-template <typename T>
-struct t_vcopy_local : t_vcopy<T, Local_map>
-{
-  typedef t_vcopy<T, Local_map> base_type;
-  t_vcopy_local()
-    : base_type(Local_map()) 
-  {}
-};
 
-template <typename T>
-struct t_vcopy_root : t_vcopy<T, Map<> >
-{
-  typedef t_vcopy<T, Map<> > base_type;
-  t_vcopy_root()
-    : base_type(Map<>()) 
-  {}
-};
 
 
-
 /***********************************************************************
   Vector copy - Chained_parallel_assign
 ***********************************************************************/
 
 template <typename T,
-	  typename MapT>
-struct t_vcopy_cpa
+	  typename SrcMapT,
+	  typename DstMapT>
+struct t_vcopy<T, SrcMapT, DstMapT, Impl_cpa>
 {
-  char* what() { return "t_vcopy_cpa"; }
+  char* what() { return "t_vcopy<..., Impl_cpa>"; }
   int ops_per_point(length_type)  { return 1; }
   int riob_per_point(length_type) { return 1*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
@@ -113,62 +123,58 @@
   void operator()(length_type size, length_type loop, float& time)
   {
     dimension_type const dim = 1;
-    typedef Dense<dim, T, row1_type, MapT> block_t;
-    Vector<T, block_t>   A(size, T(), map_);
-    Vector<T, block_t>   Z(size,      map_);
+    typedef Dense<1, T, row1_type, SrcMapT> src_block_t;
+    typedef Dense<1, T, row1_type, DstMapT> dst_block_t;
+    Vector<T, src_block_t>   A(size, T(), src_map_);
+    Vector<T, dst_block_t>   Z(size,      dst_map_);
 
-    get_local_view(A).put(0, T(3));
+    for (index_type i=0; i<A.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(A, 0, i);
+      A.local().put(i, T(g_i));
+    }
     
     vsip::impl::profile::Timer t1;
 
-    Setup_assign expr(Z, A);
-    
+    vsip::impl::Chained_parallel_assign<dim, T, T, dst_block_t, src_block_t>
+      cpa(Z, A);
     t1.start();
     for (index_type l=0; l<loop; ++l)
     {
-      vsip::impl::Chained_parallel_assign<dim, T, T, block_t, block_t>
-	cpa(Z, A);
       cpa();
     }
     t1.stop();
     
-    if (!equal(get_local_view(Z).get(0), T(3)))
+    for (index_type i=0; i<Z.local().size(); ++i)
     {
-      std::cout << "t_vcopy_cpa: ERROR" << std::endl;
-      abort();
+      index_type g_i = global_from_local_index(Z, 0, i);
+      test_assert(equal(Z.local().get(i), T(g_i)));
     }
     
     time = t1.delta();
   }
 
-  t_vcopy_cpa(MapT map) : map_(map) {}
+  t_vcopy(SrcMapT src_map, DstMapT dst_map)
+    : src_map_(src_map), dst_map_(dst_map)
+  {}
 
   // Member data.
-  MapT	map_;
+  SrcMapT	src_map_;
+  DstMapT	dst_map_;
 };
 
 
 
-template <typename T>
-struct t_vcopy_cpa_root : t_vcopy_cpa<T, Map<> >
-{
-  typedef t_vcopy_cpa<T, Map<> > base_type;
-  t_vcopy_cpa_root()
-    : base_type(Map<>()) 
-  {}
-};
-
-
-
 /***********************************************************************
   Vector copy - early-binding (setup_assign)
 ***********************************************************************/
 
 template <typename T,
-	  typename MapT>
-struct t_vcopy_sa
+	  typename SrcMapT,
+	  typename DstMapT>
+struct t_vcopy<T, SrcMapT, DstMapT, Impl_sa>
 {
-  char* what() { return "t_vcopy_sa"; }
+  char* what() { return "t_vcopy<..., Impl_sa>"; }
   int ops_per_point(length_type)  { return 1; }
   int riob_per_point(length_type) { return 1*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
@@ -176,11 +182,16 @@
 
   void operator()(length_type size, length_type loop, float& time)
   {
-    typedef Dense<1, T, row1_type, MapT> block_t;
-    Vector<T, block_t>   A(size, T(), map_);
-    Vector<T, block_t>   Z(size,      map_);
+    typedef Dense<1, T, row1_type, SrcMapT> src_block_t;
+    typedef Dense<1, T, row1_type, DstMapT> dst_block_t;
+    Vector<T, src_block_t>   A(size, T(), src_map_);
+    Vector<T, dst_block_t>   Z(size,      dst_map_);
 
-    get_local_view(A).put(0, T(3));
+    for (index_type i=0; i<A.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(A, 0, i);
+      A.local().put(i, T(g_i));
+    }
     
     vsip::impl::profile::Timer t1;
 
@@ -191,34 +202,91 @@
       expr();
     t1.stop();
     
-    if (!equal(get_local_view(Z).get(0), T(3)))
+    for (index_type i=0; i<Z.local().size(); ++i)
     {
-      std::cout << "t_vcopy_sa: ERROR" << std::endl;
-      abort();
+      index_type g_i = global_from_local_index(Z, 0, i);
+      test_assert(equal(Z.local().get(i), T(g_i)));
     }
     
     time = t1.delta();
   }
 
-  t_vcopy_sa(MapT map) : map_(map) {}
+  t_vcopy(SrcMapT src_map, DstMapT dst_map)
+    : src_map_(src_map), dst_map_(dst_map) {}
 
   // Member data.
-  MapT	map_;
+  SrcMapT	src_map_;
+  DstMapT	dst_map_;
 };
 
 
 
-template <typename T>
-struct t_vcopy_sa_root : t_vcopy_sa<T, Map<> >
+/***********************************************************************
+  Local/Distributed wrappers
+***********************************************************************/
+
+template <typename T,
+	  typename ImplTag>
+struct t_vcopy_local : t_vcopy<T, Local_map, Local_map, ImplTag>
 {
-  typedef t_vcopy_sa<T, Map<> > base_type;
-  t_vcopy_sa_root()
-    : base_type(Map<>()) 
+  typedef t_vcopy<T, Local_map, Local_map, ImplTag> base_type;
+  t_vcopy_local()
+    : base_type(Local_map(), Local_map()) 
   {}
 };
 
+template <typename T,
+	  typename ImplTag>
+struct t_vcopy_root : t_vcopy<T, Map<>, Map<>, ImplTag>
+{
+  typedef t_vcopy<T, Map<>, Map<>, ImplTag> base_type;
+  t_vcopy_root()
+    : base_type(Map<>(), Map<>()) 
+  {}
+};
 
+inline Map<>
+create_map(char type)
+{
+  length_type np = num_processors();
+  switch(type)
+  {
+  case 'a':
+    // 'a' - all processors
+    return Map<>(num_processors());
+  case '1':
+    // '1' - first processor
+    return Map<>(1);
+  case '2':
+  {
+    // '2' - last processor
+    Vector<processor_type> pset(1); pset.put(0, np-1);
+    return Map<>(pset, 1);
+  }
+  case 'b':
+  {
+    // 'b' - non-root processors
+    Vector<processor_type> pset(np-1);
+    for (index_type i=0; i<np; ++i)
+      pset.put(i, i+1);
+    return Map<>(pset, np-1);
+  }
+  }
+      
+}
 
+template <typename T,
+	  typename ImplTag>
+struct t_vcopy_redist : t_vcopy<T, Map<>, Map<>, ImplTag>
+{
+  typedef t_vcopy<T, Map<>, Map<>, ImplTag> base_type;
+  t_vcopy_redist(char src_dist, char dst_dist)
+    : base_type(create_map(src_dist), create_map(dst_dist))
+  {}
+};
+
+
+
 void
 defaults(Loop1P&)
 {
@@ -231,10 +299,58 @@
 {
   switch (what)
   {
-  case  1: loop(t_vcopy_local<float>()); break;
-  case  2: loop(t_vcopy_root<float>()); break;
-  case  3: loop(t_vcopy_sa_root<float>()); break;
-  case  4: loop(t_vcopy_cpa_root<float>()); break;
+  case  1: loop(t_vcopy_local<float, Impl_assign>()); break;
+  case  2: loop(t_vcopy_root<float, Impl_assign>()); break;
+  case  3: loop(t_vcopy_root<float, Impl_sa>()); break;
+  case  4: loop(t_vcopy_root<float, Impl_cpa>()); break;
+
+  case 10: loop(t_vcopy_redist<float, Impl_assign>('1', '1')); break;
+  case 11: loop(t_vcopy_redist<float, Impl_assign>('1', 'a'));  break;
+  case 12: loop(t_vcopy_redist<float, Impl_assign>('a', '1')); break;
+  case 13: loop(t_vcopy_redist<float, Impl_assign>('a', 'a'));  break;
+  case 14: loop(t_vcopy_redist<float, Impl_assign>('1', '2')); break;
+  case 15: loop(t_vcopy_redist<float, Impl_assign>('1', 'b')); break;
+
+  case 20: loop(t_vcopy_redist<float, Impl_sa>('1', '1')); break;
+  case 21: loop(t_vcopy_redist<float, Impl_sa>('1', 'a')); break;
+  case 22: loop(t_vcopy_redist<float, Impl_sa>('a', '1')); break;
+  case 23: loop(t_vcopy_redist<float, Impl_sa>('a', 'a')); break;
+  case 24: loop(t_vcopy_redist<float, Impl_sa>('1', '2')); break;
+  case 25: loop(t_vcopy_redist<float, Impl_sa>('1', 'b')); break;
+
+  case 30: loop(t_vcopy_redist<float, Impl_cpa>('1', '1')); break;
+  case 31: loop(t_vcopy_redist<float, Impl_cpa>('1', 'a')); break;
+  case 32: loop(t_vcopy_redist<float, Impl_cpa>('a', '1')); break;
+  case 33: loop(t_vcopy_redist<float, Impl_cpa>('a', 'a')); break;
+  case 34: loop(t_vcopy_redist<float, Impl_cpa>('1', '2')); break;
+  case 35: loop(t_vcopy_redist<float, Impl_cpa>('1', 'b')); break;
+
+  case 0:
+    std::cout
+      << "copy -- vector copy\n"
+      << " Using assignment (A = B):\n"
+      << "  -10 -- float root copy      (root -> root)\n"
+      << "  -11 -- float scatter        (root -> all)\n"
+      << "  -12 -- float gather         (all  -> root)\n"
+      << "  -13 -- float dist copy      (all  -> all)\n"
+      << "  -14 -- float point-to-point (p0   -> p1)\n"
+      << "  -15 -- float scatter2       (root -> all non-root)\n"
+      << " Using Setup_assign:\n"
+      << "  -20 -- float root copy      (root -> root)\n"
+      << "  -21 -- float scatter        (root -> all)\n"
+      << "  -22 -- float gather         (all  -> root)\n"
+      << "  -23 -- float dist copy      (all  -> all)\n"
+      << "  -24 -- float point-to-point (p0   -> p1)\n"
+      << "  -25 -- float scatter2       (root -> all non-root)\n"
+      << " Using low-level Par_assign directly:\n"
+      << "  -30 -- float root copy      (root -> root)\n"
+      << "  -31 -- float scatter        (root -> all)\n"
+      << "  -32 -- float gather         (all  -> root)\n"
+      << "  -33 -- float dist copy      (all  -> all)\n"
+      << "  -34 -- float point-to-point (p0   -> p1)\n"
+      << "  -35 -- float scatter2       (root -> all non-root)\n"
+      ;
+
   default:
     return 0;
   }
Index: benchmarks/vmul.cpp
===================================================================
--- benchmarks/vmul.cpp	(revision 145195)
+++ benchmarks/vmul.cpp	(working copy)
@@ -17,16 +17,126 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
+#include <vsip/impl/setup-assign.hpp>
 #include "benchmarks.hpp"
 
 using namespace vsip;
 
 
+template <vsip::dimension_type Dim,
+	  typename             MapT>
+struct Create_map {};
+
+template <vsip::dimension_type Dim>
+struct Create_map<Dim, vsip::Local_map>
+{
+  typedef vsip::Local_map type;
+  static type exec() { return type(); }
+};
+
+template <vsip::dimension_type Dim>
+struct Create_map<Dim, vsip::Global_map<Dim> >
+{
+  typedef vsip::Global_map<Dim> type;
+  static type exec() { return type(); }
+};
+
+template <typename Dist0, typename Dist1, typename Dist2>
+struct Create_map<1, vsip::Map<Dist0, Dist1, Dist2> >
+{
+  typedef vsip::Map<Dist0, Dist1, Dist2> type;
+  static type exec() { return type(vsip::num_processors()); }
+};
+
+template <vsip::dimension_type Dim,
+	  typename             MapT>
+MapT
+create_map()
+{
+  return Create_map<Dim, MapT>::exec();
+}
+
+
+// Sync Policy: use barrier.
+
+struct Barrier
+{
+  Barrier() : comm_(DEFAULT_COMMUNICATOR()) {}
+
+  void sync() { BARRIER(comm_); }
+
+  COMMUNICATOR_TYPE comm_;
+};
+
+
+
+// Sync Policy: no barrier.
+
+struct No_barrier
+{
+  No_barrier() {}
+
+  void sync() {}
+};
+
+
+
+
+
 /***********************************************************************
   Definitions - vector element-wise multiply
 ***********************************************************************/
 
+// Elementwise vector-multiply, non-distributed (explicit Local_map)
+// This is equivalent to t_vmul1<T, Local_map>.
+
 template <typename T>
+struct t_vmul1_nonglobal
+{
+  char* what() { return "t_vmul1_nonglobal"; }
+  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef Dense<1, T, row1_type, Local_map> block_type;
+
+    Vector<T, block_type> A(size, T());
+    Vector<T, block_type> B(size, T());
+    Vector<T, block_type> C(size);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    A.put(0, T(3));
+    B.put(0, T(4));
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      C = A * B;
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+// Element-wise vector-multiply.  Supports distributed views, using
+// implicit data-parallelism.
+
+template <typename T,
+	  typename MapT = Local_map,
+	  typename SP   = No_barrier>
 struct t_vmul1
 {
   char* what() { return "t_vmul1"; }
@@ -38,10 +148,14 @@
   void operator()(length_type size, length_type loop, float& time)
     VSIP_IMPL_NOINLINE
   {
-    Vector<T>   A(size, T());
-    Vector<T>   B(size, T());
-    Vector<T>   C(size);
+    typedef Dense<1, T, row1_type, MapT> block_type;
 
+    MapT map = create_map<1, MapT>();
+
+    Vector<T, block_type> A(size, T(), map);
+    Vector<T, block_type> B(size, T(), map);
+    Vector<T, block_type> C(size,      map);
+
     Rand<T> gen(0, 0);
     A = gen.randu(size);
     B = gen.randu(size);
@@ -50,18 +164,67 @@
     B.put(0, T(4));
 
     vsip::impl::profile::Timer t1;
+    SP sp;
     
     t1.start();
+    sp.sync();
     for (index_type l=0; l<loop; ++l)
       C = A * B;
+    sp.sync();
     t1.stop();
     
-    if (!equal(C.get(0), T(12)))
-    {
-      std::cout << "t_vmul1: ERROR" << std::endl;
-      abort();
-    }
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
 
+
+
+
+// Element-wise vector-multiply.  Supports distributed views, using
+// in-loop local views.
+
+template <typename T,
+	  typename MapT = Local_map,
+	  typename SP   = No_barrier>
+struct t_vmul1_local
+{
+  char* what() { return "t_vmul1"; }
+  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef Dense<1, T, row1_type, MapT> block_type;
+
+    MapT map = create_map<1, MapT>();
+
+    Vector<T, block_type> A(size, T(), map);
+    Vector<T, block_type> B(size, T(), map);
+    Vector<T, block_type> C(size,      map);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    A.put(0, T(3));
+    B.put(0, T(4));
+
+    vsip::impl::profile::Timer t1;
+    SP sp;
+    
+    t1.start();
+    sp.sync();
+    for (index_type l=0; l<loop; ++l)
+      C.local() = A.local() * B.local();
+    sp.sync();
+    t1.stop();
+    
     for (index_type i=0; i<size; ++i)
       test_assert(equal(C.get(i), A.get(i) * B.get(i)));
     
@@ -71,6 +234,113 @@
 
 
 
+// Element-wise vector-multiply.  Supports distributed views, using
+// early local views.
+
+template <typename T,
+	  typename MapT = Local_map,
+	  typename SP   = No_barrier>
+struct t_vmul1_early_local
+{
+  char* what() { return "t_vmul1_early_local"; }
+  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef Dense<1, T, row1_type, MapT> block_type;
+
+    MapT map = create_map<1, MapT>();
+
+    Vector<T, block_type> A(size, T(), map);
+    Vector<T, block_type> B(size, T(), map);
+    Vector<T, block_type> C(size,      map);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    A.put(0, T(3));
+    B.put(0, T(4));
+
+    vsip::impl::profile::Timer t1;
+    SP sp;
+    
+    t1.start();
+    typename Vector<T, block_type>::local_type A_local = A.local();
+    typename Vector<T, block_type>::local_type B_local = B.local();
+    typename Vector<T, block_type>::local_type C_local = C.local();
+    sp.sync();
+    for (index_type l=0; l<loop; ++l)
+      C_local = A_local * B_local;
+    sp.sync();
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+// Element-wise vector-multiply.  Supports distributed views, using
+// Setup_assign.
+
+template <typename T,
+	  typename MapT = Local_map,
+	  typename SP   = No_barrier>
+struct t_vmul1_sa
+{
+  char* what() { return "t_vmul1_sa"; }
+  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef Dense<1, T, row1_type, MapT> block_type;
+
+    MapT map = create_map<1, MapT>();
+
+    Vector<T, block_type> A(size, T(), map);
+    Vector<T, block_type> B(size, T(), map);
+    Vector<T, block_type> C(size,      map);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    A.put(0, T(3));
+    B.put(0, T(4));
+
+
+    vsip::impl::profile::Timer t1;
+    SP sp;
+    
+    t1.start();
+    Setup_assign expr(C, A*B);
+    sp.sync();
+    for (index_type l=0; l<loop; ++l)
+      expr();
+    sp.sync();
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
 template <typename T>
 struct t_vmul_ip1
 {
@@ -139,12 +409,6 @@
       C(dom) = A(dom) * B(dom);
     t1.stop();
     
-    if (!equal(C.get(0), T(12)))
-    {
-      std::cout << "t_vmul_dom1: ERROR" << std::endl;
-      abort();
-    }
-
     for (index_type i=0; i<size; ++i)
       test_assert(equal(C.get(i), A.get(i) * B.get(i)));
     
@@ -329,44 +593,78 @@
 {
   switch (what)
   {
-  case  1: loop(t_vmul1<float>()); break;
-  case  2: loop(t_vmul1<complex<float> >()); break;
+  case   1: loop(t_vmul1<float>()); break;
+  case   2: loop(t_vmul1<complex<float> >()); break;
 #ifdef VSIP_IMPL_SOURCERY_VPP
-  case  3: loop(t_vmul2<complex<float>, impl::Cmplx_inter_fmt>()); break;
-  case  4: loop(t_vmul2<complex<float>, impl::Cmplx_split_fmt>()); break;
+  case   3: loop(t_vmul2<complex<float>, impl::Cmplx_inter_fmt>()); break;
+  case   4: loop(t_vmul2<complex<float>, impl::Cmplx_split_fmt>()); break;
 #endif
-  case  5: loop(t_rcvmul1<float>()); break;
+  case   5: loop(t_rcvmul1<float>()); break;
 
-  case 11: loop(t_svmul1<float,          float>()); break;
-  case 12: loop(t_svmul1<float,          complex<float> >()); break;
-  case 13: loop(t_svmul1<complex<float>, complex<float> >()); break;
+  case  11: loop(t_svmul1<float,          float>()); break;
+  case  12: loop(t_svmul1<float,          complex<float> >()); break;
+  case  13: loop(t_svmul1<complex<float>, complex<float> >()); break;
 
-  case 14: loop(t_svmul2<float>()); break;
-  case 15: loop(t_svmul2<complex<float> >()); break;
+  case  14: loop(t_svmul2<float>()); break;
+  case  15: loop(t_svmul2<complex<float> >()); break;
 
-  case 21: loop(t_vmul_dom1<float>()); break;
-  case 22: loop(t_vmul_dom1<complex<float> >()); break;
+  case  21: loop(t_vmul_dom1<float>()); break;
+  case  22: loop(t_vmul_dom1<complex<float> >()); break;
 
-  case 31: loop(t_vmul_ip1<float>()); break;
-  case 32: loop(t_vmul_ip1<complex<float> >()); break;
+  case  31: loop(t_vmul_ip1<float>()); break;
+  case  32: loop(t_vmul_ip1<complex<float> >()); break;
 
+  case  91: loop(t_vmul1_nonglobal<        float  >()); break;
+  case  92: loop(t_vmul1_nonglobal<complex<float> >()); break;
+
+  case 101: loop(t_vmul1<        float , Map<> >()); break;
+  case 102: loop(t_vmul1<complex<float>, Map<> >()); break;
+
+  case 111: loop(t_vmul1<        float , Map<>, Barrier>()); break;
+  case 112: loop(t_vmul1<complex<float>, Map<>, Barrier>()); break;
+
+  case 121: loop(t_vmul1_local<        float  >()); break;
+  case 122: loop(t_vmul1_local<complex<float> >()); break;
+
+  case 131: loop(t_vmul1_early_local<        float  >()); break;
+  case 132: loop(t_vmul1_early_local<complex<float> >()); break;
+
+  case 141: loop(t_vmul1_sa<        float  >()); break;
+  case 142: loop(t_vmul1_sa<complex<float> >()); break;
+
   case 0:
     std::cout
       << "vmul -- vector multiplication\n"
-      << "  -1  --         float  vector *         float  vector\n"
-      << "  -2  -- complex<float> vector * complex<float> vector\n"
-      << "  -3  -- complex<float> vector * complex<float> vector (split)\n"
-      << "  -4  -- complex<float> vector * complex<float> vector (inter)\n"
-      << "  -5  --         float  vector * complex<float> vector\n"
-      << " -11  --         float  scalar *         float  vector\n"
-      << " -12  --         float  scalar * complex<float> vector\n"
-      << " -13  -- complex<float> scalar * complex<float> vector\n"
-      << " -14  -- t_svmul2\n"
-      << " -15  -- t_svmul2\n"
-      << " -21  -- t_vmul_dom1\n"
-      << " -22  -- t_vmul_dom1\n"
-      << " -31  -- t_vmul_ip1\n"
-      << " -32  -- t_vmul_ip1\n"
+      << "   -1 -- Vector<        float > * Vector<        float >\n"
+      << "   -2 -- Vector<complex<float>> * Vector<complex<float>>\n"
+      << "   -1 --         float  vector *         float  vector\n"
+      << "   -2 -- complex<float> vector * complex<float> vector\n"
+      << "   -3 -- complex<float> vector * complex<float> vector (split)\n"
+      << "   -4 -- complex<float> vector * complex<float> vector (inter)\n"
+      << "   -5 --         float  vector * complex<float> vector\n"
+      << "  -11 --         float  scalar *         float  vector\n"
+      << "  -12 --         float  scalar * complex<float> vector\n"
+      << "  -13 -- complex<float> scalar * complex<float> vector\n"
+      << "  -14 -- t_svmul2\n"
+      << "  -15 -- t_svmul2\n"
+      << "  -21 -- t_vmul_dom1\n"
+      << "  -22 -- t_vmul_dom1\n"
+      << "  -31 -- t_vmul_ip1\n"
+      << "  -32 -- t_vmul_ip1\n"
+
+      << "  -91 -- Vector<        float > * Vector<        float > NONGLOBAL\n"
+      << "  -92 -- Vector<complex<float>> * Vector<complex<float>> NONGLOBAL\n"
+
+      << " -101 -- Vector<        float > * Vector<        float > PAR\n"
+      << " -102 -- Vector<complex<float>> * Vector<complex<float>> PAR\n"
+      << " -111 -- Vector<        float > * Vector<        float > PAR sync\n"
+      << " -112 -- Vector<complex<float>> * Vector<complex<float>> PAR sync\n"
+      << " -121 -- Vector<        float > * Vector<        float > PAR local\n"
+      << " -122 -- Vector<complex<float>> * Vector<complex<float>> PAR local\n"
+      << " -131 -- Vector<        float > * Vector<        float > PAR early local\n"
+      << " -132 -- Vector<complex<float>> * Vector<complex<float>> PAR early local\n"
+      << " -141 -- Vector<        float > * Vector<        float > PAR setup assign\n"
+      << " -142 -- Vector<complex<float>> * Vector<complex<float>> PAR setup assign\n"
       ;
 
   default:
Index: benchmarks/vmul_sal.cpp
===================================================================
--- benchmarks/vmul_sal.cpp	(revision 145195)
+++ benchmarks/vmul_sal.cpp	(working copy)
@@ -447,9 +447,9 @@
     
     t1.start();
     for (size_t l=0; l<loop; ++l)
-      zvzsmlx((COMPLEX_SPLIT*)&pA, 2,
+      zvzsmlx((COMPLEX_SPLIT*)&pA, 1,
 	      (COMPLEX_SPLIT*)&pB,
-	      (COMPLEX_SPLIT*)&pC, 2,
+	      (COMPLEX_SPLIT*)&pC, 1,
 	      size, 0 );
     t1.stop();
     }
