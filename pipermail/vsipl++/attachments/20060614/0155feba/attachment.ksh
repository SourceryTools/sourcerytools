Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.504
diff -u -r1.504 ChangeLog
--- ChangeLog	13 Jun 2006 19:11:53 -0000	1.504
+++ ChangeLog	14 Jun 2006 15:13:47 -0000
@@ -1,3 +1,8 @@
+2006-06-14  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Include <complex>, not <cmath>, in complex test.
+	* src/vsip/impl/setup-assign.hpp: Fix function return type.
+
 2006-06-13  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* vendor/GNUmakefile.inc.in: Tentatively remove symbolic link
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.109
diff -u -r1.109 configure.ac
--- configure.ac	8 Jun 2006 18:50:50 -0000	1.109
+++ configure.ac	14 Jun 2006 15:13:48 -0000
@@ -462,7 +462,7 @@
 
 AC_MSG_CHECKING([if complex<long double> supported.])
 AC_COMPILE_IFELSE([
-#include <cmath>
+#include <complex>
 
 int main(int, char **)
 {
Index: src/vsip/impl/setup-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/setup-assign.hpp,v
retrieving revision 1.3
diff -u -r1.3 setup-assign.hpp
--- src/vsip/impl/setup-assign.hpp	13 Dec 2005 20:35:54 -0000	1.3
+++ src/vsip/impl/setup-assign.hpp	14 Jun 2006 15:13:48 -0000
@@ -38,7 +38,7 @@
   public:
     virtual ~Holder_base() {}
     virtual void exec() = 0;
-    virtual char* type() = 0;
+    virtual char const * type() = 0;
   };
 
   class Null_holder : public Holder_base
@@ -47,7 +47,7 @@
     Null_holder() {}
     ~Null_holder() {}
     void exec() {}
-    char* type() { return "Null_holder"; }
+    char const * type() { return "Null_holder"; }
   };
 
   template <dimension_type Dim,
@@ -73,7 +73,7 @@
       par_expr_();
     }
 
-    char* type() { return "Par_expr_holder"; }
+    char const * type() { return "Par_expr_holder"; }
 
 
     // Member data
@@ -106,7 +106,7 @@
       par_assign_();
     }
 
-    char* type() { return "Par_assign_holder"; }
+    char const * type() { return "Par_assign_holder"; }
 
 
     // Member data
@@ -140,7 +140,7 @@
       par_expr_simple(dst_, src_);
     }
 
-    char* type() { return "Simple_par_expr_holder"; }
+    char const * type() { return "Simple_par_expr_holder"; }
 
     // Member data
   private:
@@ -173,7 +173,7 @@
       dst_ = src_;
     }
 
-    char* type() { return "Ser_expr_holder"; }
+    char const * type() { return "Ser_expr_holder"; }
 
 
     // Member data
@@ -242,7 +242,7 @@
     holder_->exec();
   }
 
-  char* impl_type()
+  char const * impl_type()
   {
     return holder_->type();
   }
