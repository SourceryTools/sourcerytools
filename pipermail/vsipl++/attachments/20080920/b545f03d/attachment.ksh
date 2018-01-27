Index: tests/ukernel/interp.cpp
===================================================================
--- tests/ukernel/interp.cpp	(revision 222174)
+++ tests/ukernel/interp.cpp	(working copy)
@@ -155,9 +155,12 @@
 {
   vsipl init(argc, argv);
 
+// This kernel is presently only implemented for interleaved complex
+#if !VSIP_IMPL_PREFER_SPLIT_COMPLEX
   test_ukernel<float>(8, 4, 5);
   test_ukernel<float>(512, 256, 9);
   test_ukernel<float>(1144, 1072, 5);
+#endif
 
   return 0;
 }
Index: tests/ukernel/madd.cpp
===================================================================
--- tests/ukernel/madd.cpp	(revision 222174)
+++ tests/ukernel/madd.cpp	(working copy)
@@ -79,7 +79,6 @@
 }
 
 
-
 /***********************************************************************
   Main
 ***********************************************************************/
@@ -91,8 +90,12 @@
 
   // Parameters are rows then cols
   test_ukernel<float, float>(64, 1024);
+
+// This kernel is presently only implemented for interleaved complex
+#if !VSIP_IMPL_PREFER_SPLIT_COMPLEX
   test_ukernel<float, complex<float> >(64, 1024);
   test_ukernel<complex<float>, complex<float> >(64, 1024);
+#endif
 
   return 0;
 }
