Index: src/vsip/impl/fns_elementwise.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fns_elementwise.hpp,v
retrieving revision 1.14
diff -u -r1.14 fns_elementwise.hpp
--- src/vsip/impl/fns_elementwise.hpp	3 Oct 2005 12:49:42 -0000	1.14
+++ src/vsip/impl/fns_elementwise.hpp	11 Nov 2005 17:14:05 -0000
@@ -74,7 +74,8 @@
 #define VSIP_IMPL_UNARY_OP(op, name)           			          \
 template <typename T>	 				                  \
 typename Dispatch_##name<T>::result_type			          \
-operator op(T t) { return Dispatch_##name<T>::apply(t);}
+operator op(typename Is_view_type<T>::type t)                             \
+{ return Dispatch_##name<T>::apply(t);}
 
 /// Macro to define a binary function on views in terms of
 /// its homologe on scalars.
