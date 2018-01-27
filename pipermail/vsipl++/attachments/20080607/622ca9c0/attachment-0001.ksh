Index: src/vsip/core/cvsip/fir.hpp
===================================================================
--- src/vsip/core/cvsip/fir.hpp	(revision 210702)
+++ src/vsip/core/cvsip/fir.hpp	(working copy)
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
--- src/vsip/opt/ipp/fir.hpp	(revision 210702)
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
Index: src/vsip/opt/signal/fir_opt.hpp
===================================================================
--- src/vsip/opt/signal/fir_opt.hpp	(revision 210702)
+++ src/vsip/opt/signal/fir_opt.hpp	(working copy)
@@ -165,7 +165,7 @@
   static return_type exec(aligned_array<T> k, length_type ks,
                           length_type is, length_type d,
                           unsigned, alg_hint_type)
-  { return return_type(new Fir_impl<T, S, C>(k, ks, is, d));}
+  { return return_type(new Fir_impl<T, S, C>(k, ks, is, d), noincrement);}
 };
 
 }
