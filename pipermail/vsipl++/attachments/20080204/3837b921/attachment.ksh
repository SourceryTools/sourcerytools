Index: ChangeLog
===================================================================
--- ChangeLog	(revision 192395)
+++ ChangeLog	(working copy)
@@ -1,5 +1,11 @@
-2008-01-31  Jules Bergmann  <jules@codesourcery.com>
+2008-02-04  Jules Bergmann  <jules@codesourcery.com>
 
+	* configure.ac (EMBED_SPU): Include -m32/-m64 option.
+	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Use -m32/-m64 from
+	  EMBED_SPU.
+
+2008-02-01  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/simd/simd.hpp (SSE2 double): Fix bug in mag mask width.
 	  Add extract function.
 
Index: configure.ac
===================================================================
--- configure.ac	(revision 192274)
+++ configure.ac	(working copy)
@@ -422,6 +422,14 @@
   AC_CHECK_PROGS(CC_SPU, [spu-gcc])
   AC_CHECK_PROGS(CXX_SPU, [spu-g++])
   AC_CHECK_PROGS(EMBED_SPU, [ppu-embedspu embedspu])
+
+  if test -n "`echo $CFLAGS | sed -n '/-m32/p'`" -o \
+          -n "`echo $CFLAGS | sed -n '/-q32/p'`"; then
+    EMBED_SPU="$EMBED_SPU -m32"
+  elif test -n "`echo $CFLAGS | sed -n '/-m64/p'`" -o \
+            -n "`echo $CFLAGS | sed -n '/-q64/p'`"; then
+    EMBED_SPU="$EMBED_SPU -m64"
+  fi
 else
   # Use autoconf default lists
   cxx_compiler_list="g++ c++ gpp aCC CC cxx cc++ cl.exe FCC KCC RCC xlC_r xlC"
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 191870)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -46,7 +46,7 @@
 
 CC_SPU := @CC_SPU@
 CXX_SPU := @CXX_SPU@
-EMBED_SPU := @EMBED_SPU@ -m32
+EMBED_SPU := @EMBED_SPU@
 CPP_SPU_FLAGS := @CPP_SPU_FLAGS@
 
 alf_prefix := $(srcdir)/src/vsip/opt/cbe/alf
