Index: ChangeLog
===================================================================
--- ChangeLog	(revision 236548)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2009-02-13  Jules Bergmann  <jules@codesourcery.com>
 
+	* doc/getting-started/getting-started.xml: Fix description for 
+	  building a program manually.
+
+2009-02-13  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/ukernel.hpp: Use ALF inout buffers for ukernels.
 	* src/vsip/opt/ukernel/cbe_accel/alf_base.hpp: Likewise.
 
Index: doc/getting-started/getting-started.xml
===================================================================
--- doc/getting-started/getting-started.xml	(revision 236492)
+++ doc/getting-started/getting-started.xml	(working copy)
@@ -2284,14 +2284,20 @@
     </para>  
 
    <para>
-     First, to compile the program, use the following command:
-     <screen>&gt; g++ -c `pkg-config --cflags vsipl++` \
+     First, determine what compiler is recommended:
+     <screen>&gt; CXX=`pkg-config vsipl++ --variable=cxx`</screen>
+   </para>
+
+   <para>
+     Second, to compile the program, use the following command:
+     <screen>&gt; $CXX -c `pkg-config vsipl++ --cflags` \
+                          `pkg-config vsipl++ --variable=cxxflags` \
       /opt/sourceryvsipl++-&version;/share/sourceryvsipl++/example1.cpp</screen>
     </para>  
 
     <para>
-     Next, to link the program, use the following command:
-     <screen>&gt; g++ -o example1 example1.o `pkg-config --libs vsipl++`</screen>
+     Finally, to link the program, use the following command:
+     <screen>&gt; $CXX -o example1 example1.o `pkg-config --libs vsipl++`</screen>
     </para>  
 
     <para>
