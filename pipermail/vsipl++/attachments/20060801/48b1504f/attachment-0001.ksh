Index: vendor/atlas/configure.ac
===================================================================
--- vendor/atlas/configure.ac	(revision 146102)
+++ vendor/atlas/configure.ac	(working copy)
@@ -256,7 +256,7 @@
 mach_is_alpha=""	# true if Alpha architecture
 
 case $mach in
-  PII | PIII | PPRO | P5MMX | P4 | P4E )
+  PII | PIII | PPRO | P5MMX | P4 | P4E | ATHLON | HAMMER32 )
     mach_is_x86_32="true" ;;
   P4E64 | HAMMER64 )
     mach_is_x86_64="true" ;;
@@ -1395,19 +1395,19 @@
 
 if test $mach = "HP9735"; then
   if test $os_name = "HPUX"; then
-    if test $F77 = "f77"; then
+    if test "$F77" = "f77"; then
       FLINKFLAGS="-Aa"
     fi
-    if test $CC != "gcc"; then
+    if test "$CC" != "gcc"; then
       CLINKFLAGS="-Aa"
     fi
   fi
 fi
 
-if test $F77 = "xlf"; then
+if test "$F77" = "xlf"; then
   FLINKFLAGS="FLINKFLAGS -bmaxdata:0x70000000"
 fi
-if test $CC = "xlc"; then
+if test "$CC" = "xlc"; then
   CLINKFLAGS="FLINKFLAGS -bmaxdata:0x70000000"
 fi
 
