Index: src/vsip/impl/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft.hpp,v
retrieving revision 1.4
diff -u -r1.4 fft.hpp
--- src/vsip/impl/fft.hpp	10 May 2006 14:08:53 -0000	1.4
+++ src/vsip/impl/fft.hpp	11 May 2006 02:14:21 -0000
@@ -181,11 +181,13 @@
   {}
 
   template <typename Block0, typename Block1,
- 	    template <typename, typename> class View>
-  View<O,Block1>
-  operator()(View<I,Block0> in, View<O,Block1> out)
+ 	    template <typename, typename> class View0,
+ 	    template <typename, typename> class View1>
+  View1<O,Block1>
+  operator()(View0<I,Block0> in, View1<O,Block1> out)
     VSIP_NOTHROW
   {
+    VSIP_IMPL_STATIC_ASSERT((View0<I,Block0>::dim == View1<O,Block1>::dim));
     workspace_.by_reference(this->backend_.get(), in, out);
     return out;
   }
