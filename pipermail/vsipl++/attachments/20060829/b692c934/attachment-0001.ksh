Index: src/vsip/impl/par-foreach.hpp
===================================================================
--- src/vsip/impl/par-foreach.hpp	(revision 147946)
+++ src/vsip/impl/par-foreach.hpp	(working copy)
@@ -18,6 +18,7 @@
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
+#include <vsip/tensor.hpp>
 #include <vsip/impl/distributed-block.hpp>
 #include <vsip/impl/par-util.hpp>
 
Index: src/vsip/impl/expr_serial_dispatch.hpp
===================================================================
--- src/vsip/impl/expr_serial_dispatch.hpp	(revision 147946)
+++ src/vsip/impl/expr_serial_dispatch.hpp	(working copy)
@@ -70,13 +70,25 @@
   template <typename DstBlock,
 	    typename SrcBlock>
   Eval_profile_policy(DstBlock const&, SrcBlock const& src)
-    : event_( Expr_op_name<EvalExpr, SrcBlock>::tag(src), 
-              Expr_ops_per_point<SrcBlock>::value * 
-                Expr_ops_per_point<SrcBlock>::size(src) )
-  {}
+  {
+    if ( profile::Profile::mode() != profile::pm_none )
+    {
+      event_ = new event_type( Expr_op_name<EvalExpr, SrcBlock>::tag(src), 
+        Expr_ops_per_point<SrcBlock>::value * 
+          Expr_ops_per_point<SrcBlock>::size(src) );
+    }
+    else
+      event_ = NULL;
+  }
 
+  ~Eval_profile_policy()
+  {
+    if (event_)
+      delete event_;
+  }
+
 private:
-  event_type event_;
+  event_type *event_;
 };
 
 
Index: src/vsip/impl/profile.hpp
===================================================================
--- src/vsip/impl/profile.hpp	(revision 147946)
+++ src/vsip/impl/profile.hpp	(working copy)
@@ -363,6 +363,7 @@
     stamp_type stamp = stamp_type());
   void dump(char* filename, char mode='w');
   void set_mode(profiler_mode mode) { mode_ = mode; }
+  profiler_mode get_mode() const { return mode_; }
 
 private:
   typedef std::map<std::string, Accum_entry> accum_type;
@@ -391,6 +392,8 @@
     VSIP_IMPL_PROFILE( prof->dump(this->filename_) );
   }
 
+  static profiler_mode mode() { return prof->get_mode(); }
+
 private:
   char* const filename_;
   profiler_mode mode_;
