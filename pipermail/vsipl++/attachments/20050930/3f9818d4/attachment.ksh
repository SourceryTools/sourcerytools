1. In view_operators.cpp, ICC finds the overloads for operator^() 
   ambiguous.

../../../CVS-HEAD/tests/view_operators.cpp(250): error: more than one operator "^" matches these operands:
            function template "vsip::impl::operator^(T1, T2)"
            function template "vsip::impl::operator^(V1<bool, B1>, V2<bool, B2>)"
            operand types are: vsip::Vector<bool, vsip::Dense<1U, bool, vsip::impl::Row_major<1U>::type, vsip::Local_map>> ^ vsip::Vector<bool, vsip::Dense<1U, bool, vsip::impl::Row_major<1U>::type, vsip::Local_map>>
      Vector<bool, Dense<1, bool> > result = v1 ^ v2;

   From the arguments given (two 'Vector<bool, Dense<1, bool> >'s),
   the second operator^ seems more specialized.

   As a work around, (in fns_elementwise.hpp) I replaced the separate
   operator^ functions for bxor and lxor with a single function that
   uses a its functor to dispatch between the logical and bitwise (the
   primary case (general T1 and T2) goes to bxor, while the
   specialzation for bool goes to lxor).



2. In fns_userelt.cpp, ICC was having trouble finding a 'unary' function
   for the std::ptr_fun and function object cases:

../../../CVS-HEAD/tests/fns_userelt.cpp(68): error: no instance of overloaded function "unary" matches the argument list
            argument types are: (std::pointer_to_unary_function<float, int>, DVector)
    DVector result = unary<int>(std::ptr_fun(my_unary), input);
                     ^

../../../CVS-HEAD/tests/fns_userelt.cpp(77): error: no instance of overloaded function "unary" matches the argument list
            argument types are: (my_func_obj, DVector)
    DVector result = unary<int>(my_func_obj(), input);
                     ^
   (similar errors for binary and ternary).

   The following overload should match (in fns_userelt.hpp):

	template <typename R, typename F,
		  template <typename, typename> class View,
		  typename T, typename Block>
	typename impl::Unary_operator_return_type<
	  View, T, Block, impl::Unary_function<R, F>::template Type>::view_type
	unary(F f, View<T, Block> v)
	{ ... }

   After some trial and error, I found that the return type was
   preventing the function from matching.  Changing the function name
   to be unique and changing the return type to void made the error go
   away.  Likewise, changing the return type to return a particular
   unary function, such as 'vsip::impl::op::Plus', instead of the
   correct one 'Unary_function<R, F>::template Type' made the error go
   away.

   Apparently ICC was getting hung up by the use of a member class
   template in the function return type.  By determining the return
   type in a helper class, the error goes away.

	template <typename R, typename F,
		  template <typename, typename> class View,
		  typename T, typename Block>
	struct Unary_userelt_return_type
	{
	  typedef
	    typename impl::Unary_operator_return_type<
	      View, T, Block, impl::Unary_function<R, F>::template Type>::view_type
	    type;
	};

	template <typename R, typename F,
		  template <typename, typename> class View,
		  typename T, typename Block>
	typename impl::Unary_userelt_return_type<R, F, View, T, Block>::type
	unary(F f, View<T, Block> v)
	{ ... }
   
   The errors for binary and ternary could be worked around in the same
   way.



3. In selgen.cpp, ICC was complaining that a template instantiation
   resulted in an unexpected function type ...

../../../CVS-HEAD/tests/selgen.cpp(101): error: template instantiation resulted in unexpected function type of "vsip::Vector<float, const vsip::impl::Unary_expr_block<1U, vsip::impl::clip_wrapper<float, float>::invclip_functor, vsip::Dense<1U, float, vsip::impl::Row_major<1U>::type, vsip::Local_map>, float>> (vsip::Vector<float, vsip::Dense<1U, float, vsip::impl::Row_major<1U>::type, vsip::Local_map>>, float, float, float, float, float)" (the meaning of a name may have changed since the
          template declaration -- the type of the template is "const_View<Tout, const vsip::impl::Unary_expr_block<const_View<Tin0, Block>::dim, vsip::impl::clip_wrapper<Tout, Tin1>::clip_functor, Block, Tin0>> (const_View<Tin0, Block>, Tin1, Tin1, Tin1, Tout, Tout)")
    Vector<float> result = invclip(v, 1.1f, 2.1f, 3.1f, 1.1f, 3.1f);
                                                                   ^
          detected during instantiation of "vsip::invclip" based on template arguments <float, float, float, vsip::Vector, vsip::Dense<1U, float, vsip::impl::Row_major<1U>::type, vsip::Local_map>> at line 101


   This is curious since the clip function is nearly identical to
   invclip, but ICC was only complaining about invclip.

	template <typename Tout, typename Tin0, typename Tin1,
		  template <typename, typename> class const_View,
		  typename Block>
	const_View<Tout,
	  impl::Unary_expr_block<const_View<Tin0, Block>::dim,
			 impl::clip_wrapper<Tout, Tin1>::template clip_functor,
			 Block, Tin0> const>
	clip(const_View<Tin0, Block> v,
	     Tin1 lower_threshold, Tin1 upper_threshold,
	     Tout lower_clip_value, Tout upper_clip_value)
        { ... }


	template <typename Tout, typename Tin0, typename Tin1,
		  template <typename, typename> class const_View,
		  typename Block>
	const_View<Tout,
	  impl::Unary_expr_block<const_View<Tin0, Block>::dim,
		     impl::clip_wrapper<Tout, Tin1>::template invclip_functor,
		     Block, Tin0> const>
	invclip(const_View<Tin0, Block> v,
	     Tin1 lower_threshold, Tin1 middle_threshold, Tin1 upper_threshold,
	     Tout lower_clip_value, Tout upper_clip_value)
	{ .. }

   clip and invclip share a struct called clip_wrapper to define their
   functor classes:

	struct clip_wrapper
	{
	  struct clip_functor { ... };
	  struct invclip_functor { ... };
	};


   By separating clip_function and invclip_functor into separate
   wrapper classes, the error went away:

	struct clip_wrapper
	{
	  struct clip_functor { ... };
	};
	
	struct invclip_wrapper
	{
	  struct clip_functor { ... };
	};

   But only if the functors had the same name.  Changing the name of
   invclip_wrapper::clip_functor to anything else (such as
   invclip_wrapper::invclip_functor,
   invclip_wrapper::XinvclipX_functor, invclip_wrapper::functor)
   brought the error back.

   However, the return type of invclip involves a member template class:

	'impl::clip_wrapper<Tout, Tin1>::template invclip_functor'

   Similar to problem number #2, moving the return type into a
   separate helper class makes the compilation error go away
   (Actually, moving the type into a helper class in the same
   namespace makes the error go away.  Moving the into a helper class
   in the impl:: namespace made the error go away for invclip, but
   caused clip to break!  Fortunately, putting helper classes for both
   clip and invclip in the impl namespace works).


