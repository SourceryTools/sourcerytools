Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.498
diff -u -r1.498 ChangeLog
--- ChangeLog	8 Jun 2006 18:50:49 -0000	1.498
+++ ChangeLog	8 Jun 2006 18:53:49 -0000
@@ -1,5 +1,11 @@
 2006-06-08  Jules Bergmann  <jules@codesourcery.com>
 
+	* benchmarks/vmul.cpp: Add documentation for benchmark cases.
+	* src/vsip/impl/subblock.hpp: Fix bug in how dimension-order for
+	  a Sliced_block is determined.
+	
+2006-06-08  Jules Bergmann  <jules@codesourcery.com>
+
 	* configure.ac (--disable-eval-dense-expr): New option to disable
 	  evaluation of dense matrix and tensor expressions as vector
 	  expressions.
Index: benchmarks/vmul.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/vmul.cpp,v
retrieving revision 1.8
diff -u -r1.8 vmul.cpp
--- benchmarks/vmul.cpp	21 Mar 2006 15:53:09 -0000	1.8
+++ benchmarks/vmul.cpp	8 Jun 2006 18:53:49 -0000
@@ -350,6 +350,25 @@
   case 31: loop(t_vmul_ip1<float>()); break;
   case 32: loop(t_vmul_ip1<complex<float> >()); break;
 
+  case 0:
+    std::cout
+      << "vmul -- vector multiplication\n"
+      << "  -1  --         float  vector *         float  vector\n"
+      << "  -2  -- complex<float> vector * complex<float> vector\n"
+      << "  -3  -- complex<float> vector * complex<float> vector (split)\n"
+      << "  -4  -- complex<float> vector * complex<float> vector (inter)\n"
+      << "  -5  --         float  vector * complex<float> vector\n"
+      << " -11  --         float  scalar *         float  vector\n"
+      << " -12  --         float  scalar * complex<float> vector\n"
+      << " -13  -- complex<float> scalar * complex<float> vector\n"
+      << " -14  -- t_svmul2\n"
+      << " -15  -- t_svmul2\n"
+      << " -21  -- t_vmul_dom1\n"
+      << " -22  -- t_vmul_dom1\n"
+      << " -31  -- t_vmul_ip1\n"
+      << " -32  -- t_vmul_ip1\n"
+      ;
+
   default:
     return 0;
   }
Index: src/vsip/impl/subblock.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/subblock.hpp,v
retrieving revision 1.39
diff -u -r1.39 subblock.hpp
--- src/vsip/impl/subblock.hpp	27 Mar 2006 23:19:34 -0000	1.39
+++ src/vsip/impl/subblock.hpp	8 Jun 2006 18:53:49 -0000
@@ -1163,11 +1163,11 @@
 struct Sliced_block_order<tuple<Dim0, Dim1, Dim2>, 3, FixedDim>
 {
   typedef typename
-  ITE_Type<FixedDim == 0,
+  ITE_Type<FixedDim == Dim0,
 	   ITE_Type<(Dim2 > Dim1), As_type<row2_type>, As_type<col2_type> >,
-  ITE_Type<FixedDim == 1,
+  ITE_Type<FixedDim == Dim1,
 	   ITE_Type<(Dim2 > Dim0), As_type<row2_type>, As_type<col2_type> >,
-    ITE_Type<(Dim1 > Dim0), As_type<row2_type>, As_type<col2_type> >
+           ITE_Type<(Dim1 > Dim0), As_type<row2_type>, As_type<col2_type> >
           > >::type
 		type;
   static bool const unit_stride_preserved = (FixedDim != Dim2);
