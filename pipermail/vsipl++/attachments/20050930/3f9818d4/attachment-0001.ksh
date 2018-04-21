Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.284
diff -c -p -r1.284 ChangeLog
*** ChangeLog	30 Sep 2005 21:43:07 -0000	1.284
--- ChangeLog	30 Sep 2005 21:58:42 -0000
***************
*** 1,5 ****
--- 1,16 ----
  2005-09-30  Jules Bergmann  <jules@codesourcery.com>
  
+ 	Work arounds for ICC 9.0 compilation errors.
+ 	* src/vsip/selgen.hpp: Determine clip and invclip return type
+ 	  through helper classes.
+ 	* src/vsip/impl/fns_elementwise.hpp: Use single function and
+ 	  operator^().  Have functor distinguish bxor and lxor cases.
+ 	* src/vsip/impl/fns_userelt.hpp: For function object overloads of
+ 	  unary, binary, and ternary functions, determine return values
+ 	  through helper classes.
+ 
+ 2005-09-30  Jules Bergmann  <jules@codesourcery.com>
+ 
  	Implement LU linear system solver.
  	* src/vsip/impl/solver-lu.hpp: New file, LU solver.
  	* src/vsip/solvers.hpp: Include solver-lu.
Index: src/vsip/selgen.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/selgen.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 selgen.hpp
*** src/vsip/selgen.hpp	27 Sep 2005 22:44:40 -0000	1.2
--- src/vsip/selgen.hpp	30 Sep 2005 21:58:43 -0000
*************** struct clip_wrapper
*** 198,213 ****
      result_type upper_clip_value;
    };
  };
    
  }
  
  template <typename Tout, typename Tin0, typename Tin1,
  	  template <typename, typename> class const_View,
  	  typename Block>
! const_View<Tout,
!   impl::Unary_expr_block<const_View<Tin0, Block>::dim,
! 			 impl::clip_wrapper<Tout, Tin1>::template clip_functor,
! 			 Block, Tin0> const>
  clip(const_View<Tin0, Block> v, Tin1 lower_threshold, Tin1 upper_threshold,
       Tout lower_clip_value, Tout upper_clip_value)
  {
--- 198,236 ----
      result_type upper_clip_value;
    };
  };
+ 
+ template <typename Tout, typename Tin0, typename Tin1, 
+ 	  template <typename, typename> class const_View,
+ 	  typename Block>
+ struct Clip_return_type
+ {
+   typedef
+     const_View<Tout,
+     impl::Unary_expr_block<const_View<Tin0, Block>::dim,
+ 			 impl::clip_wrapper<Tout, Tin1>::template clip_functor,
+ 			 Block, Tin0> const>
+     type;
+ };
+ 
+ template <typename Tout, typename Tin0, typename Tin1, 
+ 	  template <typename, typename> class const_View,
+ 	  typename Block>
+ struct Invclip_return_type
+ {
+   typedef
+     const_View<Tout,
+        impl::Unary_expr_block<const_View<Tin0, Block>::dim,
+           impl::clip_wrapper<Tout, Tin1>::template invclip_functor,
+ 	  Block, Tin0> const>
+     type;
+ };
    
  }
  
  template <typename Tout, typename Tin0, typename Tin1,
  	  template <typename, typename> class const_View,
  	  typename Block>
! typename impl::Clip_return_type<Tout, Tin0, Tin1, const_View, Block>::type
  clip(const_View<Tin0, Block> v, Tin1 lower_threshold, Tin1 upper_threshold,
       Tout lower_clip_value, Tout upper_clip_value)
  {
*************** clip(const_View<Tin0, Block> v, Tin1 low
*** 227,236 ****
  template <typename Tout, typename Tin0, typename Tin1,
  	  template <typename, typename> class const_View,
  	  typename Block>
! const_View<Tout,
!   impl::Unary_expr_block<const_View<Tin0, Block>::dim,
! 			 impl::clip_wrapper<Tout, Tin1>::template invclip_functor,
! 			 Block, Tin0> const>
  invclip(const_View<Tin0, Block> v,
  	Tin1 lower_threshold, Tin1 middle_threshold, Tin1 upper_threshold,
  	Tout lower_clip_value, Tout upper_clip_value)
--- 250,256 ----
  template <typename Tout, typename Tin0, typename Tin1,
  	  template <typename, typename> class const_View,
  	  typename Block>
! typename impl::Invclip_return_type<Tout, Tin0, Tin1, const_View, Block>::type
  invclip(const_View<Tin0, Block> v,
  	Tin1 lower_threshold, Tin1 middle_threshold, Tin1 upper_threshold,
  	Tout lower_clip_value, Tout upper_clip_value)
Index: src/vsip/impl/fns_elementwise.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fns_elementwise.hpp,v
retrieving revision 1.13
diff -c -p -r1.13 fns_elementwise.hpp
*** src/vsip/impl/fns_elementwise.hpp	30 Sep 2005 15:19:16 -0000	1.13
--- src/vsip/impl/fns_elementwise.hpp	30 Sep 2005 21:58:43 -0000
*************** VSIP_IMPL_BINARY_OP(&&, land)
*** 392,424 ****
  VSIP_IMPL_BINARY_OP(&, band)
  VSIP_IMPL_BINARY_OP(||, lor)
  VSIP_IMPL_BINARY_OP(|, bor)
- VSIP_IMPL_BINARY_OP(^, bxor)
  
! template <template <typename, typename> class V1,
! 	  typename B1,
! 	  template <typename, typename> class V2,
! 	  typename B2,
!           bool P = Is_view_type<V1<bool, B1> >::value || 
!                    Is_view_type<V2<bool, B2> >::value>
! struct Dispatch_op_lxor
!   : As_type<Binary_func_view<lxor_functor,
! 			     V1<bool, B1>,
! 			     V2<bool, B2> > >::type {};
! template <template <typename, typename> class V1,
! 	  typename B1,
! 	  template <typename, typename> class V2,
! 	  typename B2>
! struct Dispatch_op_lxor<V1, B1, V2, B2, false> {};
! 
! template <template <typename, typename> class V1,
! 	  typename B1,
! 	  template <typename, typename> class V2,
! 	  typename B2>
! typename Dispatch_op_lxor<V1, B1, V2, B2>::result_type
! operator ^(V1<bool, B1> v, V2<bool, B2> w) 
  {
!   return Dispatch_op_lxor<V1, B1, V2, B2>::apply(v, w);
! }
  
  } // namespace vsip::impl
  
--- 392,415 ----
  VSIP_IMPL_BINARY_OP(&, band)
  VSIP_IMPL_BINARY_OP(||, lor)
  VSIP_IMPL_BINARY_OP(|, bor)
  
! template <typename T1, typename T2>
! struct bxor_or_lxor_functor
  {
!   typedef typename Promotion<T1, T2>::type result_type;
!   static result_type apply(T1 t1, T2 t2) { return fn::bxor(t1, t2);}
!   result_type operator()(T1 t1, T2 t2) const { return apply(t1, t2);}
! };
! 
! template <>
! struct bxor_or_lxor_functor<bool, bool>
! {
!   typedef bool result_type;
!   static result_type apply(bool t1, bool t2) { return fn::lxor(t1, t2);}
!   result_type operator()(bool t1, bool t2) const { return apply(t1, t2);}
! };
! 
! VSIP_IMPL_BINARY_OP(^, bxor_or_lxor)
  
  } // namespace vsip::impl
  
Index: src/vsip/impl/fns_userelt.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fns_userelt.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 fns_userelt.hpp
*** src/vsip/impl/fns_userelt.hpp	2 Aug 2005 09:53:32 -0000	1.1
--- src/vsip/impl/fns_userelt.hpp	30 Sep 2005 21:58:43 -0000
*************** struct Ternary_function<R, R (*)(A1, A2,
*** 167,179 ****
    };
  };
  
  } // namespace vsip::impl
  
  template <typename R, typename F,
  	  template <typename, typename> class View,
  	  typename T, typename Block>
! typename impl::Unary_operator_return_type<
!   View, T, Block, impl::Unary_function<R, F>::template Type>::view_type
  unary(F f, View<T, Block> v)
  {
    typedef typename impl::Unary_function<R, F>::template Type<T> Function;
--- 167,228 ----
    };
  };
  
+ /// These classes ({Unary,Binary,Ternary}_userelt_return_type)
+ /// determine the return types for the unary, binary, and ternary
+ /// functions, respectively.
+ ///
+ /// They are necessary for Intel C++ (9.0), which has difficulty with the
+ ///   'impl::Unary_function<R, F>::template Type'
+ /// member class template when used directly in the return types for
+ /// those functions.
+ 
+ template <typename R, typename F,
+ 	  template <typename, typename> class View,
+ 	  typename T, typename Block>
+ struct Unary_userelt_return_type
+ {
+   typedef
+     typename impl::Unary_operator_return_type<
+       View, T, Block, impl::Unary_function<R, F>::template Type>::view_type
+     type;
+ };
+ 
+ template <typename R, typename F,
+ 	  template <typename, typename> class View,
+ 	  typename LType, typename LBlock,
+ 	  typename RType, typename RBlock>
+ struct Binary_userelt_return_type
+ {
+   typedef
+   typename impl::Binary_operator_return_type<
+     View, LType, LBlock,
+     View, RType, RBlock,
+     impl::Binary_function<R, F> ::template Type>::view_type
+   type;
+ };
+ 
+ template <typename R, typename F,
+ 	  template <typename, typename> class View,
+ 	  typename Type1, typename Block1,
+ 	  typename Type2, typename Block2,
+ 	  typename Type3, typename Block3>
+ struct Ternary_userelt_return_type
+ {
+   typedef
+     typename impl::Ternary_func_return_type<
+       View, Type1, Block1,
+       View, Type2, Block2,
+       View, Type3, Block3,
+       impl::Ternary_function<R, F>::template Type>::view_type
+     type;
+ };
+ 
  } // namespace vsip::impl
  
  template <typename R, typename F,
  	  template <typename, typename> class View,
  	  typename T, typename Block>
! typename impl::Unary_userelt_return_type<R, F, View, T, Block>::type
  unary(F f, View<T, Block> v)
  {
    typedef typename impl::Unary_function<R, F>::template Type<T> Function;
*************** template <typename R, typename F,
*** 223,234 ****
  	  template <typename, typename> class View,
  	  typename LType, typename LBlock,
  	  typename RType, typename RBlock>
! typename impl::Binary_operator_return_type<View, 
! 					   LType, LBlock,
! 					   View,
! 					   RType, RBlock,
! 					   impl::Binary_function<R, F>
!   ::template Type>::view_type
  binary(F f, View<LType, LBlock> v1, View<RType, RBlock> v2)
  {
    typedef typename impl::Binary_function<R, F>
--- 272,279 ----
  	  template <typename, typename> class View,
  	  typename LType, typename LBlock,
  	  typename RType, typename RBlock>
! typename impl::Binary_userelt_return_type<R, F, View, LType, LBlock,
! 					  RType, RBlock>::type
  binary(F f, View<LType, LBlock> v1, View<RType, RBlock> v2)
  {
    typedef typename impl::Binary_function<R, F>
*************** template <typename R, typename F,
*** 299,309 ****
  	  typename Type1, typename Block1,
  	  typename Type2, typename Block2,
  	  typename Type3, typename Block3>
! typename impl::Ternary_func_return_type<
!   View, Type1, Block1,
!   View, Type2, Block2,
!   View, Type3, Block3,
!   impl::Ternary_function<R, F>::template Type>::view_type
  ternary(F f,
  	View<Type1, Block1> v1,
  	View<Type2, Block2> v2,
--- 344,351 ----
  	  typename Type1, typename Block1,
  	  typename Type2, typename Block2,
  	  typename Type3, typename Block3>
! typename impl::Ternary_userelt_return_type<
!   R, F, View, Type1, Block1, Type2, Block2, Type3, Block3>::type
  ternary(F f,
  	View<Type1, Block1> v1,
  	View<Type2, Block2> v2,
