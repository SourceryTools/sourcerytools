? .solver-lu.cpp.swp
? Makefile.in
Index: reductions-idx.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/reductions-idx.cpp,v
retrieving revision 1.2
diff -u -r1.2 reductions-idx.cpp
--- reductions-idx.cpp	20 Dec 2005 12:48:41 -0000	1.2
+++ reductions-idx.cpp	4 Apr 2006 16:37:57 -0000
@@ -47,7 +47,7 @@
     
     val = maxval(vec, idx);
     test_assert(equal(val, nval));
-    test_assert(idx == i);
+    test_assert(idx == Index<1>(i));
   }
 }
 
@@ -304,11 +304,11 @@
 
    val = maxmgval(vec, idx);
    test_assert(equal(val, T(10)));
-   test_assert(idx == 1);
+   test_assert(idx == Index<1>(1));
 
    val = minmgval(vec, idx);
    test_assert(equal(val, T(0.5)));
-   test_assert(idx == 2);
+   test_assert(idx == Index<1>(2));
 }
 
 
