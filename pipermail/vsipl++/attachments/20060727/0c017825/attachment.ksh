Index: ChangeLog
===================================================================
--- ChangeLog	(revision 145823)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2006-07-27  Jules Bergmann  <jules@codesourcery.com>
+
+	* GNUmakefile.in (subdirs): Move benchmarks and benchmarks/hpec_kernel
+	  subdirectories to end of list.  This way the see $(libs) after
+	  it has been set by src/vsip and src/vsip_csl.
+
 2006-07-26  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip/impl/simd/simd.hpp: Make load() argument const, add div().
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 145823)
+++ GNUmakefile.in	(working copy)
@@ -152,13 +152,12 @@
 html_manuals :=
 
 # The subdirectories in which we can find sub-Makefiles.  The "tests"
-# and "examples" directories must be last because some of their
-# targets depend on $(libs), and $(libs) will not be full initialized
-# until all other subdirectories have been processed.
+# "examples", "benchmarks", and "benchmarks/hpec_kernel" directories
+# must be last because some of their targets depend on $(libs), and
+# $(libs) will not be full initialized until all other subdirectories
+# have been processed.
 subdirs := \
 	apps \
-	benchmarks \
-	benchmarks/hpec_kernel \
 	doc \
 	src \
 	src/vsip \
@@ -166,6 +165,8 @@
 	lib \
 	tools \
 	vendor \
+	benchmarks \
+	benchmarks/hpec_kernel \
 	tests \
 	examples
 
