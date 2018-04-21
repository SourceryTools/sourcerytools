? scripts/fix-exec.sh
? scripts/run-par.sh
Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.445
diff -u -r1.445 ChangeLog
--- ChangeLog	28 Apr 2006 23:25:43 -0000	1.445
+++ ChangeLog	29 Apr 2006 03:25:51 -0000
@@ -1,5 +1,16 @@
 2006-04-28  Jules Bergmann  <jules@codesourcery.com>
 
+	* configure.ac: Add support for Intel MPI.
+	* lib/GNUmakefile.inc.in: Use placeholder entry after wildcard
+	  variable to avoid passing an empty list to /bin/sh 'for'.
+	  Solaris /bin/sh doesn't like them.
+	* scripts/config: Don't build long-double FFTW on SPARC.
+	* scripts/fix-pkg-config-prefix.sh: Use test "=" for portability.
+	* scripts/release.sh: Fix /bin/sh portability issues for Solaris.
+	* src/vsip/map.hpp (impl_num_patches): Handle sb == no_subblock.
+
+2006-04-28  Jules Bergmann  <jules@codesourcery.com>
+
 	* configure.ac: Make sure src/vsip/impl subdirectories exist.
 	  Necessary to build synopsis documentation.
 	* doc/quickstart/quickstart.xml: Fix ending tag typo.
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.95
diff -u -r1.95 configure.ac
--- configure.ac	28 Apr 2006 23:25:43 -0000	1.95
+++ configure.ac	29 Apr 2006 03:25:51 -0000
@@ -865,6 +865,16 @@
       PAR_SERVICE=mpipro
     fi
 
+    # Intel MPI also defines MPICH_NAME.  Require user to specify
+    # --enable-mpi=intelmpi.
+    if test "$enable_mpi" = "intelmpi"; then
+      if test $PAR_SERVICE != "mpich"; then
+        AC_MSG_ERROR([Intel MPI enabled (--enable-mpi=intelmpi), but not found])
+      else
+        PAR_SERVICE=intelmpi
+      fi
+    fi
+
     case $PAR_SERVICE in
       unknown)
         AC_MSG_ERROR([unrecognized MPI implementation])
@@ -873,6 +883,21 @@
       mpich)
 	check_mpicxx="yes"
         if test -n "$with_mpi_prefix"; then
+          MPICXX="$with_mpi_prefix/bin/mpicxx -show"
+        elif test -n "$with_mpi_prefix64"; then
+          MPICXX="$with_mpi_prefix64/bin64/mpicxx -show"
+        else
+          MPICXX="mpicxx -show"
+        fi
+      ;;
+
+      # Intel MPI looks like MPICH, except that 'mpicxx -show' emits an
+      # extra command to check that the compiler is setup properly, which
+      # confuses our option extraction below.  We use '-nocompchk' to
+      # disable this command.
+      intelmpi)
+	check_mpicxx="yes"
+        if test -n "$with_mpi_prefix"; then
           MPICXX="$with_mpi_prefix/bin/mpicxx -nocompchk -show"
         elif test -n "$with_mpi_prefix64"; then
           MPICXX="$with_mpi_prefix64/bin64/mpicxx -nocompchk -show"
Index: lib/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/lib/GNUmakefile.inc.in,v
retrieving revision 1.2
diff -u -r1.2 GNUmakefile.inc.in
--- lib/GNUmakefile.inc.in	19 Jan 2006 04:08:26 -0000	1.2
+++ lib/GNUmakefile.inc.in	29 Apr 2006 03:25:51 -0000
@@ -16,8 +16,15 @@
 
 clean::
 
+# Install libraries in lib directory.  However, lib may be empty and not
+# every /bin/sh can deal with 'for file in ; do ...', in particular
+# Solaris 8.  We use justincase as a bogus entry just in case 'lib/*.a'
+# comes up empty.
+
 install::
 	$(INSTALL) -d $(DESTDIR)$(libdir)
-	for file in $(wildcard lib/*.a); do		\
-	  $(INSTALL_DATA) $$file $(DESTDIR)$(libdir);	\
+	for file in "$(wildcard lib/*.a) justincase"; do	\
+	  if test $$file != "justincase"; then			\
+	    $(INSTALL_DATA) $$file $(DESTDIR)$(libdir);		\
+	  fi 							\
 	done
Index: scripts/config
===================================================================
RCS file: /home/cvs/Repository/vpp/scripts/config,v
retrieving revision 1.12
diff -u -r1.12 config
--- scripts/config	28 Apr 2006 23:25:43 -0000	1.12
+++ scripts/config	29 Apr 2006 03:25:51 -0000
@@ -346,7 +346,7 @@
 
 common_sparc = ['--enable-profile-timer=posix']
 
-builtin_fft_sparc    = ['--with-fft=builtin']
+builtin_fft_sparc    = ['--with-fft=builtin', '--disable-fft-long-double']
 
 builtin_lapack_sparc = ['--with-lapack=builtin',
 		        '--with-atlas-cfg-opts="--with-mach=SunUS2 --with-int-type=int --with-string-convention=sun"']
Index: scripts/fix-pkg-config-prefix.sh
===================================================================
RCS file: /home/cvs/Repository/vpp/scripts/fix-pkg-config-prefix.sh,v
retrieving revision 1.1
diff -u -r1.1 fix-pkg-config-prefix.sh
--- scripts/fix-pkg-config-prefix.sh	28 Apr 2006 21:25:27 -0000	1.1
+++ scripts/fix-pkg-config-prefix.sh	29 Apr 2006 03:25:51 -0000
@@ -45,7 +45,7 @@
   error "error: fix-intel-pkg-config-prefix.sh -p PCFILE option required"
 fi
 
-if test "$drop_arch" == "yes"; then
+if test "$drop_arch" = "yes"; then
   prefix=`dirname $prefix`
 fi
 
Index: scripts/release.sh
===================================================================
RCS file: /home/cvs/Repository/vpp/scripts/release.sh,v
retrieving revision 1.8
diff -u -r1.8 release.sh
--- scripts/release.sh	28 Apr 2006 21:25:27 -0000	1.8
+++ scripts/release.sh	29 Apr 2006 03:25:51 -0000
@@ -47,6 +47,7 @@
 cvs_tag="HEAD"
 pkg_opts=""
 version="1.0"
+host=`hostname`
 
 while getopts "w:d:c:p:C:t:D:T:s" arg; do
     case $arg in
@@ -76,7 +77,7 @@
 	    ;;
 	s)
 	    pkg_opts="$pkg_opts --snapshot"
-            version=$(date +%Y%m%d)
+            version=`date +%Y%m%d`
 	    ;;
 	\?)
             error "usage: release.sh [-v VERSION]"
@@ -88,11 +89,11 @@
 srcpkg="$srcdir.tar.bz2"
 
 package=$dir/scripts/package
-if test "$cfgfile" == "default"; then
+if test "$cfgfile" = "default"; then
   cfgfile=$dir/scripts/config
 fi
 
-if test "$test_srcdir" == "default"; then
+if test "$test_srcdir" = "default"; then
   test_srcdir=$srcdir
 fi
 
@@ -113,30 +114,38 @@
 ipp_dir=/opt/intel/ipp
 mkl_dir=/opt/intel/mkl
 
-export PATH=$TOOL_DIR/sourceryg++/bin
-export PATH=$PATH:$TOOL_DIR/bin
-export PATH=$PATH:$GCCTOOL_DIR/bin
-export PATH=$PATH:/usr/bin
-export PATH=$PATH:/bin
-export PATH=$PATH:/usr/local/bin
-export PATH=$PATH:$DOT_DIR/bin
-export PATH=$PATH:/opt/renderx/xep
-
-export LD_LIBRARY_PATH=$TOOL_DIR/sourceryg++/lib
-export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TOOL_DIR/sourceryg++/lib64
-export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TOOL_DIR/lib
-export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TOOL_DIR/lib64
-export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GC_DIR
-# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DOT_DIR/lib
-# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DOT_DIR/lib/graphviz
-export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/em64t/sharedlib
-export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/em64t/sharedlib/linuxem64t
-export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/ia32_itanium/sharedlib
-export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/ia32_itanium/sharedlib/linux32
-export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$mkl_dir/lib/em64t
-export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$mkl_dir/lib/32
+PATH=$TOOL_DIR/sourceryg++/bin
+PATH=$PATH:$TOOL_DIR/bin
+PATH=$PATH:$GCCTOOL_DIR/bin
+PATH=$PATH:/usr/bin
+PATH=$PATH:/bin
+PATH=$PATH:/usr/local/bin
+PATH=$PATH:$DOT_DIR/bin
+PATH=$PATH:/opt/renderx/xep
+
+LD_LIBRARY_PATH=$TOOL_DIR/sourceryg++/lib
+LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TOOL_DIR/sourceryg++/lib64
+LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TOOL_DIR/lib
+LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TOOL_DIR/lib64
+LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GC_DIR
+# LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DOT_DIR/lib
+# LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DOT_DIR/lib/graphviz
+LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/em64t/sharedlib
+LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/em64t/sharedlib/linuxem64t
+LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/ia32_itanium/sharedlib
+LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/ia32_itanium/sharedlib/linux32
+LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$mkl_dir/lib/em64t
+LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$mkl_dir/lib/32
+if test `hostname` = "gannon.codesourcery.com"; then
+  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GCCTOOL_DIR/lib
+  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GCCTOOL_DIR/lib/sparcv9
+fi
+
+export PATH
+export LD_LIBRARY_PATH
 
-if test "$debug" == "yes"; then
+if test "$debug" = "yes"; then
+  echo "host          : $host"
   echo "which g++     : " `which g++`
   echo "which dot     : " `which dot`
   echo "configure file: $cfgfile"
@@ -151,7 +160,7 @@
 fi
 
 # 1. Build/unpack source package.
-if test "$what" == "src" -o "$what" == "all"; then
+if test "$what" = "src" -o "$what" = "all"; then
   echo "#####################################################################"
   echo "# build source package                                              #"
   echo "#####################################################################"
@@ -187,7 +196,7 @@
 
 
 # 2. Build binary packages.
-if test "$what" == "bin" -o "$what" == "all"; then
+if test "$what" = "bin" -o "$what" = "all"; then
   echo "#####################################################################"
   echo "# build binary packages                                             #"
   echo "#####################################################################"
@@ -211,7 +220,7 @@
 fi
 
 # 3. Test binary packages.
-if test "$what" == "test" -o "$what" == "all"; then
+if test "$what" = "test" -o "$what" = "all"; then
   echo "#####################################################################"
   echo "# test binary packages                                              #"
   echo "#####################################################################"
Index: src/vsip/map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/map.hpp,v
retrieving revision 1.24
diff -u -r1.24 map.hpp
--- src/vsip/map.hpp	28 Apr 2006 21:25:27 -0000	1.24
+++ src/vsip/map.hpp	29 Apr 2006 03:25:51 -0000
@@ -936,7 +936,7 @@
 /// Get the number of patches in a subblock.
 
 /// Requires:
-///   SB is a valid subblock of THIS.
+///   SB is a valid subblock of THIS, or NO_SUBBLOCK.
 
 template <typename       Dist0,
 	  typename       Dist1,
@@ -946,18 +946,23 @@
 Map<Dist0, Dist1, Dist2>::impl_num_patches(index_type sb)
   const VSIP_NOTHROW
 {
-  assert(sb < num_subblocks_);
+  assert(sb < num_subblocks_ || sb == no_subblock);
   assert(dim_ != 0);
 
-  index_type dim_sb[VSIP_MAX_DIMENSION];
+  if (sb == no_subblock)
+    return 0;
+  else
+  {
+    index_type dim_sb[VSIP_MAX_DIMENSION];
 
-  impl::split_tuple(sb, dim_, subblocks_, dim_sb);
+    impl::split_tuple(sb, dim_, subblocks_, dim_sb);
 
-  length_type patches = 1;
-  for (dimension_type d=0; d<dim_; ++d)
-    patches *= impl_subblock_patches(d, dim_sb[d]);
+    length_type patches = 1;
+    for (dimension_type d=0; d<dim_; ++d)
+      patches *= impl_subblock_patches(d, dim_sb[d]);
 
-  return patches;
+    return patches;
+  }
 }
 
 
@@ -965,7 +970,7 @@
 /// Get the size of a subblock (represented by a domain).
 
 /// Requires:
-///   SB is a valid subblock of THIS.
+///   SB is a valid subblock of THIS, or NO_SUBBLOCK.
 
 template <typename       Dist0,
 	  typename       Dist1,
