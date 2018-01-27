Index: ChangeLog
===================================================================
--- ChangeLog	(revision 211164)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2008-06-09  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/diag/eval.hpp (See_summary): Qualify specialization
+	  for Cml_tag if CML is configured.
+
 2008-06-05  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/subblock.hpp: Support distributed Transposed_blocks
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 211164)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -265,6 +265,7 @@
 
 // Specialization for Cml_tag
 
+#ifdef VSIP_IMPL_CBE_SDK
 template <typename       DstBlockT,
           typename       SrcBlockT>
 struct See_summary<2, Cml_tag, DstBlockT, SrcBlockT>
@@ -306,6 +307,7 @@
     cout << endl;
   }
 };
+#endif
 
 
 
