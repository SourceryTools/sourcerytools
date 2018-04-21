Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.470
diff -u -r1.470 ChangeLog
--- ChangeLog	11 May 2006 13:06:52 -0000	1.470
+++ ChangeLog	11 May 2006 14:41:09 -0000
@@ -1,4 +1,8 @@
 2006-05-11  Jules Bergmann  <jules@codesourcery.com>
+	
+	* scripts/release.sh: Update paths for solaris snapshot.
+	
+2006-05-11  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/impl/solver_common.hpp: Remove duplicate defns.
 	* src/vsip/impl/fft.hpp (Fft::operator()): Use separate template
Index: scripts/release.sh
===================================================================
RCS file: /home/cvs/Repository/vpp/scripts/release.sh,v
retrieving revision 1.10
diff -u -r1.10 release.sh
--- scripts/release.sh	29 Apr 2006 14:30:58 -0000	1.10
+++ scripts/release.sh	11 May 2006 14:41:09 -0000
@@ -91,7 +91,7 @@
 srcdir="sourceryvsipl++-$version"
 srcpkg="$srcdir.tar.bz2"
 
-package=$dir/scripts/package
+package=$dir/scripts/package.py
 if test "$cfgfile" = "default"; then
   cfgfile=$dir/scripts/config
 fi
@@ -112,7 +112,7 @@
 # GC_DIR=/opt/gc6.6/lib
 # DOT_DIR=/usr/local/graphviz-2.6
 GC_DIR=$HOME/build-cugel/gc6.6/lib
-DOT_DIR=$HOME/local/x86_64/
+DOT_DIR=$HOME/local/`arch`
 
 ipp_dir=/opt/intel/ipp
 mkl_dir=/opt/intel/mkl
@@ -125,6 +125,9 @@
 PATH=$PATH:/usr/local/bin
 PATH=$PATH:$DOT_DIR/bin
 PATH=$PATH:/opt/renderx/xep
+if test `hostname` = "gannon.codesourcery.com"; then
+  PATH=$PATH:/home/jules/local/sun4/bin
+fi
 
 LD_LIBRARY_PATH=$TOOL_DIR/sourceryg++/lib
 LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TOOL_DIR/sourceryg++/lib64
@@ -148,11 +151,12 @@
 export LD_LIBRARY_PATH
 
 if test "$debug" = "yes"; then
-  echo "host          : $host"
-  echo "which g++     : " `which g++`
-  echo "which dot     : " `which dot`
-  echo "configure file: $cfgfile"
-  echo "cvs_srcdir    : $cvs_srcdir"
+  echo "host            : $host"
+  echo "which g++       : " `which g++`
+  echo "which dot       : " `which dot`
+  echo "which pkg-config: " `which pkg-config`
+  echo "configure file  : $cfgfile"
+  echo "cvs_srcdir      : $cvs_srcdir"
 
   save_IFS=$IFS; IFS=":"
   for dir in $LD_LIBRARY_PATH
