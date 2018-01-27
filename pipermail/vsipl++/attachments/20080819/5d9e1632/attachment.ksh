Index: ChangeLog
===================================================================
--- ChangeLog	(revision 217955)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2008-08-19  Jules Bergmann  <jules@codesourcery.com>
 
+	* tests/correlation.cpp: Adjust threshold on Cell.
+
+2008-08-19  Jules Bergmann  <jules@codesourcery.com>
+
 	Ported from branches/afrl-ncet:
 	* src/vsip/opt/cbe/pwarp_params.h (VSIP_IMPL_CBE_PWARP_BUFFER_SIZE): 
 	  Move SPU kernel input image buffer size here.
@@ -4817,9 +4821,7 @@
 	  passed to the Profile_options constructor.  Added new function 
 	  member for that purpose.
 	* src/vsip/impl/profile.hpp: Added definitions for the different 
-	  values for VSIP_IMPL_PROFILER.  Revised comments.
-	* configure.ac: Removed configuration options related to profiling.
-	* examples/fft.cpp: Added command-line arguments to library
+	  values for VSIP_IMPLles/fft.cpp: Added command-line arguments to library
 	  initialization call.  Changed profiler output filename.
 	* examples/png.cpp: Added command-line arguments.
 	* examples/example1.cpp: Added command-line arguments.
Index: tests/correlation.cpp
===================================================================
--- tests/correlation.cpp	(revision 217743)
+++ tests/correlation.cpp	(working copy)
@@ -35,8 +35,14 @@
 using namespace vsip;
 using namespace vsip_csl;
 
+#ifdef VSIP_IMPL_CBE_SDK
+float threshold = -80;
+#else
+float threshold = -100;
+#endif
 
 
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -96,7 +102,7 @@
     double error = error_db(out, chk);
 
 #if VERBOSE
-    if (error > -100)
+    if (error > threshold)
     {
       for (index_type i=0; i<P; ++i)
       {
@@ -104,11 +110,20 @@
 	     << "  chk = " << chk(i)
 	     << endl;
       }
-      cout << "error = " << error << endl;
+      std::cout << "corr<"
+	// << vsip::impl::diag_detail::Class_name<T>::name()
+		<< ">("
+		<< (bias == biased ? "biased" : "unbiased") << " "
+		<< (support == support_min  ? "support_min"  :
+		    support == support_same ? "support_same" :
+		    support == support_full ? "support_full" : "other")
+		<< " M: " << M
+		<< " N: " << N << ") = "
+		<< error << "\n";
     }
 #endif
 
-    test_assert(error < -100);
+    test_assert(error < threshold);
   }
 }
 
@@ -175,7 +190,7 @@
     double error = error_db(out, chk);
 
 #if VERBOSE
-    if (error > -120)
+    if (error > threshold)
     {
       for (index_type i=0; i<P; ++i)
       {
@@ -183,11 +198,21 @@
 	     << "  chk = " << chk(i)
 	     << endl;
       }
-      cout << "error = " << error << endl;
     }
+    std::cout << "impl_core<"
+	// << vsip::impl::diag_detail::Class_name<Tag>::name() << ", "
+	// << vsip::impl::diag_detail::Class_name<T>::name()
+		<< ">("
+		<< (bias == biased ? "biased" : "unbiased") << " "
+		<< (support == support_min ? "support_min" :
+		    support == support_same ? "support_same" :
+		    support == support_full ? "support_full" : "other")
+		<< " M: " << M
+		<< " N: " << N << ") = "
+		<< error << "\n";
 #endif
 
-    test_assert(error < -100);
+    test_assert(error < threshold);
   }
 }
 
