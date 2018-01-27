Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.443
diff -u -r1.443 ChangeLog
--- ChangeLog	27 Apr 2006 01:23:21 -0000	1.443
+++ ChangeLog	28 Apr 2006 20:52:55 -0000
@@ -1,3 +1,26 @@
+2006-04-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* GNUmakefile.in (hdr): Include headers from fft, lapack, sal,
+	  ipp, fftw3 subdirectories of src/vsip/impl.
+	* configure.ac: Add tidying up MPI installation prefix in .pc file
+	  using fix-pkg-config-prefix.sh script.  Use script for IPP and MKL
+	  tidy up instead of fix-intel-pkg-config.sh.
+	* doc/quickstart/quickstart.xml: Document new set-prefix.sh usage,
+	  cover setting prefix for MPI too.
+	* scripts/set-prefix.sh: Generalize to handle other prefixes besides
+	  IPP and MKL, in particular MPI.
+	* src/vsip/GNUmakefile.inc.in: Install headers from fft, lapack, sal,
+	  ipp, fftw3 subdirectories of src/vsip/impl.
+	* src/vsip/map.hpp (impl_subblock_domain): Handle sb == no_subblock.
+	* src/vsip/impl/aligned_allocator.hpp: Avoid calling alloc_align
+	  when size == 0, return NULL pointer instead.
+	* tests/make.standalone: Add -I. to CXXFLAGS to handle tests in
+	  subdirectories.
+	* tests/output.hpp (operator<<): New overload for vsip::impl::Length.
+	* tests/parallel/expr.cpp (test_distributed_expr): Use correct map
+	  to check if local processor has a subblock.
+	* vendor/GNUmakefile.inc.in: Install libF77.
+
 2006-04-26  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac (--with-lapack): Support both CLAPACK and Fortran
Index: GNUmakefile.in
===================================================================
RCS file: /home/cvs/Repository/vpp/GNUmakefile.in,v
retrieving revision 1.48
diff -u -r1.48 GNUmakefile.in
--- GNUmakefile.in	13 Apr 2006 18:36:21 -0000	1.48
+++ GNUmakefile.in	28 Apr 2006 20:52:55 -0000
@@ -185,6 +185,16 @@
              $(wildcard $(srcdir)/src/vsip/impl/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/impl/simd/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/impl/fft/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/impl/lapack/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/impl/sal/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/impl/ipp/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/impl/fftw3/*.hpp))
 
 ########################################################################
 # Included Files
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.93
diff -u -r1.93 configure.ac
--- configure.ac	27 Apr 2006 01:21:21 -0000	1.93
+++ configure.ac	28 Apr 2006 20:52:55 -0000
@@ -1738,22 +1738,30 @@
 AC_OUTPUT
 
 #
-# Tidy up IPP and MKL prefixes (if any) in .pc file
+# Tidy up library prefixes in .pc file
 #
-fix_pc_opt=""
+
+# if $srcdir is relative, correct by chdir into scripts/*.
+fix_pc="`(cd $srcdir/scripts; echo \"$PWD\")`"/fix-pkg-config-prefix.sh
+
+# Tidy up IPP
 if test "$enable_ipp" == "yes" -a "$with_ipp_prefix" != ""; then
-  fix_pc_opt="$fix_pc_opt -i $with_ipp_prefix"
+  $fix_pc -p vsipl++.pc -d -k ipp_prefix -v $with_ipp_prefix
 fi
+
+# Tidy up MKL
 if expr "$lapack_found" : "mkl" > /dev/null; then
   if test "$with_mkl_prefix" != ""; then
-    fix_pc_opt="$fix_pc_opt -m $with_mkl_prefix"
+    $fix_pc -p vsipl++.pc -k mkl_prefix -v $with_mkl_prefix
   fi
 fi
 
-if test "x$fix_pc_opt" != "x"; then
-  # if $srcdir is relative, correct by chdir into scripts/*.
-  fix_pc="`(cd $srcdir/scripts; echo \"$PWD\")`"/fix-intel-pkg-config.sh
-
-  $fix_pc -d -p vsipl++.pc $fix_pc_opt
+# Tidy up MPI
+if test "$enable_mpi" = "yes"; then
+  if test "x$with_mpi_prefix" != x; then
+    $fix_pc -p vsipl++.pc -k mpi_prefix -v $with_mpi_prefix
+  elif test "x$with_mpi_prefix64" != x; then
+    $fix_pc -p vsipl++.pc -k mpi_prefix -v $with_mpi_prefix64
+  fi
 fi
-
+  
Index: doc/quickstart/quickstart.xml
===================================================================
RCS file: /home/cvs/Repository/vpp/doc/quickstart/quickstart.xml,v
retrieving revision 1.27
diff -u -r1.27 quickstart.xml
--- doc/quickstart/quickstart.xml	22 Mar 2006 20:48:57 -0000	1.27
+++ doc/quickstart/quickstart.xml	28 Apr 2006 20:52:55 -0000
@@ -292,6 +292,7 @@
      <itemizedlist>
       <listitem> <para>GCC 3.4 (IA32 GNU/Linux)</para> </listitem>
       <listitem> <para>GCC 3.4 (AMD64 GNU/Linux)</para> </listitem>
+      <listitem> <para>GCC 3.4 (SPARC Solaris 8)</para> </listitem>
       <listitem> <para>GCC 4.0 (IA32 GNU/Linux)</para> </listitem>
       <listitem> <para>GCC 4.0 (AMD64 GNU/Linux)</para> </listitem>
       <listitem> <para>GCC 4.1 (IA32 GNU/Linux)</para> </listitem>
@@ -1337,18 +1338,28 @@
 
    </section>
    <section>
-    <title>Intel IPP and MKL Libraries</title>
+    <title>Paths for External Libraries</title>
     <para>
-     Sourcery VSIPL++ binary packages that use the Intel IPP and
-     MKL libraries have the paths to those libraries hard-coded
-     into their pkg-config files.  For IPP, the default path is
-     <filename>/opt/intel/ipp</filename>.  For MKL, the default
-     path is <filename>/opt/intel/mkl</filename>.
+     Sourcery VSIPL++ binary packages that use the following
+     external libraries have the library installation paths
+     hard-coded in their pkg-config files (install path in
+     parenthesis):
+     <itemizedlist>
+      <listitem><para>
+       Intel IPP (<filename>/opt/intel/ipp<filename>).
+      </para> </listitem>
+      <listitem><para>
+       Intel MKL (<filename>/opt/intel/mkl<filename>).
+      </para> </listitem>
+      <listitem><para>
+       MPICH (Solaris only) (<filename>/opt/intel/mkl<filename>).
+      </para> </listitem>
+     </itemizedlist>
     </para>
 
     <para>
-     If IPP and/or MKL are not installed in these locations, it
-     is necessary to either:
+     If these libraries are not installed in these locations, it
+     is necessary to do one of the following:
      <itemizedlist>
       <listitem><para>
        Update the pkg-config file paths using <command>set-prefix.sh</command>.
@@ -1358,7 +1369,7 @@
        the actual install location.
       </para> </listitem>
       <listitem><para>
-       Manually specify the paths to IPP and MKL on each invocation
+       Manually specify the paths to the libraries on each invocation
        of pkg-config.
       </para> </listitem>
      </itemizedlist>
@@ -1366,13 +1377,14 @@
     </para>
 
     <para>
-     Using the <command>set-prefix.sh</command> script in the
-     <filename>usr/local/sbin</filename>, it is possible
-     to update the pkg-config files with the correct installation
-     prefixes for IPP and MKL.  <command>set-prefix.sh</command>
-     takes two options <option>-i IPP_PREFIX</option> and
-     <option>-m MKL_PREFIX</option> to specify prefixes for IPP
-     and MKL.
+     The <command>set-prefix.sh</command> script in the
+     <filename>usr/local/sbin</filename> can update
+     the pkg-config files with the correct installation
+     prefixes for external libraries.  <command>set-prefix.sh</command>
+     takes arguments of the form <option>ipp:/prefix/to/ipp</option>,
+     <option>mkl:/prefix/to/mkl</option>, and
+     <option>mpi:/prefix/to/mpi</option>, and to specify prefixes for IPP,
+     MKL, and MPICH respectively.
     </para>
 
     <para>
@@ -1382,17 +1394,30 @@
     </para>
 
     <example>
-     <title>Using <command>set-prefix.sh</command> to use IPP from different prefix</title>
+     <title>Using <command>set-prefix.sh</command> to use IPP from
+            different prefix</title>
      <screen>
-> /usr/local/sbin/set-prefix.sh -i /opt/intel/ipp41
+> /usr/local/sbin/set-prefix.sh ipp:/opt/intel/ipp41
      </screen>
     </example>
 
     <para>
-     Using symbolic links, it is possible to direct
-     <filename>/opt/intel/ipp</filename> and
-     <filename>/opt/intel/mkl</filename> to the actual installation
-     libraries.
+     If multiple prefixes need to be changed,
+     <command>set-prefix.sh</command> can either be called once with
+     multiple prefixes:
+     <screen>
+> /usr/local/sbin/set-prefix.sh ipp:/opt/intel/ipp41 mkl:/opt/intel/mkl821
+     </screen>
+     Or multiple times, once for each prefix:
+     <screen>
+> /usr/local/sbin/set-prefix.sh ipp:/opt/intel/ipp41
+> /usr/local/sbin/set-prefix.sh mkl:/opt/intel/mkl821
+     </screen>
+    </para>
+
+    <para>
+     Using symbolic links, it is possible to direct Sourcery VSIPL++'s
+     expected directory to the actual installation libraries.
     </para>
 	
     <para>
@@ -1409,7 +1434,7 @@
 
     <para>
      Finally, it is possible to manually pass the prefixes for
-     IPP and MKL to pkg-config program on each invocation.
+     external libraries to pkg-config program on each invocation.
     </para>
 
     <para>
@@ -1420,7 +1445,7 @@
     </para>
 
     <example>
-     <title>Overriding IPP and MKL prefixes from command line</title>
+     <title>Overriding library prefixes from the command line</title>
      <screen>
 LIBS = `pkg-config --define-variable=ipp_prefix=/usr/local/ipp41  \
                    --define-variable=mkl_prefix=/usr/local/mkl821 \
@@ -1428,6 +1453,7 @@
      </screen>
     </example>
    </section>
+
   </section>
  </chapter>
 
Index: scripts/fix-pkg-config-prefix.sh
===================================================================
RCS file: scripts/fix-pkg-config-prefix.sh
diff -N scripts/fix-pkg-config-prefix.sh
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ scripts/fix-pkg-config-prefix.sh	28 Apr 2006 20:52:55 -0000
@@ -0,0 +1,58 @@
+#! /bin/sh
+
+########################################################################
+#
+# File:   fix-pkg-config-prefix.sh
+# Author: Jules Bergmann
+# Date:   2006-04-28
+#
+# Contents:
+#   Edit pkg-config files to put install prefixes for libraries such
+#   as IPP, MKL, and MPI into pkg-config variables.
+#
+########################################################################
+
+# SYNOPSIS
+#   fix-pkg-config-prefix.sh -p PCFILE -k VAR -v VALUE [-d]
+#
+
+drop_arch="no"
+
+# .pc file
+pcfile=""
+
+while getopts "p:v:k:d" arg; do
+    case $arg in
+	p)
+	    pcfile=$OPTARG
+	    ;;
+	v)
+	    prefix=$OPTARG
+	    ;;
+	k)
+	    key=$OPTARG
+	    ;;
+	d)
+	    drop_arch="yes";
+	    ;;
+	\?)
+            error "usage: fix-pkg-config-prefix.sh -p PCFILE [-i IPPDIR] [-m MKLDIR]"
+	    ;;
+    esac
+done
+
+if test ! -f "$pcfile"; then
+  error "error: fix-intel-pkg-config-prefix.sh -p PCFILE option required"
+fi
+
+if test "$drop_arch" == "yes"; then
+  prefix=`dirname $prefix`
+fi
+
+echo "$key=$prefix" >  $pcfile.new
+
+cat $pcfile | sed -e "s|$prefix/|\${$key}/|g" >> $pcfile.new
+
+if test -f "$pcfile.new"; then
+  mv $pcfile.new $pcfile
+fi
Index: scripts/release.sh
===================================================================
RCS file: /home/cvs/Repository/vpp/scripts/release.sh,v
retrieving revision 1.7
diff -u -r1.7 release.sh
--- scripts/release.sh	28 Mar 2006 14:46:54 -0000	1.7
+++ scripts/release.sh	28 Apr 2006 20:52:55 -0000
@@ -105,8 +105,10 @@
 
 TOOL_DIR=/usr/local/tools/vpp-1.0
 GCCTOOL_DIR=/usr/local/tools/gcc-3.4.0
-GC_DIR=/opt/gc6.6/lib
-DOT_DIR=/usr/local/graphviz-2.6
+# GC_DIR=/opt/gc6.6/lib
+# DOT_DIR=/usr/local/graphviz-2.6
+GC_DIR=$HOME/build-cugel/gc6.6/lib
+DOT_DIR=$HOME/local/x86_64/
 
 ipp_dir=/opt/intel/ipp
 mkl_dir=/opt/intel/mkl
@@ -125,6 +127,8 @@
 export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TOOL_DIR/lib
 export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TOOL_DIR/lib64
 export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GC_DIR
+# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DOT_DIR/lib
+# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DOT_DIR/lib/graphviz
 export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/em64t/sharedlib
 export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/em64t/sharedlib/linuxem64t
 export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/ia32_itanium/sharedlib
@@ -134,6 +138,7 @@
 
 if test "$debug" == "yes"; then
   echo "which g++     : " `which g++`
+  echo "which dot     : " `which dot`
   echo "configure file: $cfgfile"
   echo "cvs_srcdir    : $cvs_srcdir"
 
Index: scripts/set-prefix.sh
===================================================================
RCS file: /home/cvs/Repository/vpp/scripts/set-prefix.sh,v
retrieving revision 1.2
diff -u -r1.2 set-prefix.sh
--- scripts/set-prefix.sh	20 Jan 2006 21:49:59 -0000	1.2
+++ scripts/set-prefix.sh	28 Apr 2006 20:52:55 -0000
@@ -21,6 +21,8 @@
 #                 [-i IPP_PREFIX]
 #                 [-m IPP_PREFIX]
 #                 -v
+#                 PRE1:PATH1 [PRE2:PATH2 ...]
+#                 
 #
 # DESCRIPTION
 #   Sets the prefix variables in the a Sourcery VSIPL++ binary package's
@@ -36,8 +38,14 @@
 #   if it is in the standard location ($prefix/lib/pkgconfig),
 #   derived from the library PREFIX.  
 #
-#   IPP_PREFIX and MKL_PREFIX are the IPP and MKL prefixes.  They
-#   are specified with the -i and -m options.
+#   Arguments of the form 'PRE:PATH' indicate the value of
+#   variable 'PRE_prefix' should be set to 'PATH'.
+#
+#   For backwards compatibility, the "-i" and "-m" options can
+#   be used to substitute IPP_PREFIX and MKL_PREFIX are the IPP and
+#   MKL prefixes.  The option '-i IPP_PREFIX' is equivalent to the
+#   argument 'ipp:IPP_PREFIX'.  The option '-m MKL_PREFIX' is equivalent
+#   to the argument 'mkl:MKL_PREFIX'.
 #
 #   It is always necessary to specify or guess the library prefix,
 #   since this determines the location of the pkg-config files.
@@ -63,6 +71,7 @@
 
 pcdir='*use-default*'
 verbose="no"
+pairs=''
 
 while getopts "xp:l:i:m:v" arg; do
     case $arg in
@@ -73,10 +82,12 @@
 	    pcdir=$OPTARG
 	    ;;
 	i)
-	    ipp_prefix=$OPTARG
+	    # ipp_prefix=$OPTARG
+	    pairs="ipp:$OPTARG $pairs"
 	    ;;
 	m)
-	    mkl_prefix=$OPTARG
+	    # mkl_prefix=$OPTARG
+	    pairs="mkl:$OPTARG $pairs"
 	    ;;
 	v)
 	    verbose="yes"
@@ -91,28 +102,48 @@
 if test "$verbose" == "yes"; then
   echo "VSIPL++ prefix  : " $prefix
   echo "  pkgconfig dir : " $pcdir
-  if test "x$ipp_prefix" != "x"; then
-    echo "IPP prefix      : " $ipp_prefix
-  fi
-  if test "x$mkl_prefix" != "x"; then
-    echo "MKL prefix      : " $mkl_prefix
-  fi
+
+  for pair in $pairs; do
+    old_IFS=$IFS
+    IFS=":"
+    i=0
+    for x in $arg; do
+      if test $i = 0; then
+        key=$x
+        i=1
+      else
+        value=$x
+      fi
+    done
+    IFS=$old_IFS
+    echo "$key prefix      : " $value
+  done
 fi
 
 for file in `ls $pcdir/*.pc`; do
-  cat $file | sed -e "s|^prefix=.*$|prefix=$prefix|" > $file.tmp
-
-  if test "x$ipp_prefix" != "x"; then
-    cat $file.tmp | sed -e "s|^ipp_prefix=.*$|ipp_prefix=$ipp_prefix|" \
-		> $file.tmp2
-    mv $file.tmp2 $file.tmp
+  if test "x$prefix" != "x"; then
+    cat $file | sed -e "s|^prefix=.*$|prefix=$prefix|" > $file.tmp
+  else
+    cp $file $file.tmp
   fi
 
-  if test "x$mkl_prefix" != "x"; then
-    cat $file.tmp | sed -e "s|^mkl_prefix=.*$|mkl_prefix=$mkl_prefix|" \
+  for pair in $pairs; do
+    old_IFS=$IFS
+    IFS=":"
+    i=0
+    for x in $arg; do
+      if test $i = 0; then
+        key=$x
+        i=1
+      else
+        value=$x
+      fi
+    done
+    IFS=$old_IFS
+    cat $file.tmp | sed -e "s|^${key}_prefix=.*$|${key}_prefix=$value|" \
 		> $file.tmp2
     mv $file.tmp2 $file.tmp
-  fi
+  done
 
   if test -f "$file.tmp"; then
     mv $file.tmp $file
Index: src/vsip/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/GNUmakefile.inc.in,v
retrieving revision 1.15
diff -u -r1.15 GNUmakefile.inc.in
--- src/vsip/GNUmakefile.inc.in	29 Mar 2006 13:10:55 -0000	1.15
+++ src/vsip/GNUmakefile.inc.in	28 Apr 2006 20:52:55 -0000
@@ -49,6 +49,11 @@
 	$(INSTALL_DATA) src/vsip/libvsip.a $(DESTDIR)$(libdir)/libvsip$(suffix).a
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/simd
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/fft
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/lapack
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/sal
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/ipp
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/fftw3
 	$(INSTALL_DATA) src/vsip/impl/acconfig.hpp $(DESTDIR)$(includedir)/vsip/impl
 	for header in $(hdr); do \
           $(INSTALL_DATA) $(srcdir)/src/$$header \
Index: src/vsip/map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/map.hpp,v
retrieving revision 1.23
diff -u -r1.23 map.hpp
--- src/vsip/map.hpp	27 Apr 2006 01:23:33 -0000	1.23
+++ src/vsip/map.hpp	28 Apr 2006 20:52:55 -0000
@@ -976,18 +976,23 @@
 Map<Dist0, Dist1, Dist2>::impl_subblock_domain(index_type sb)
   const VSIP_NOTHROW
 {
-  assert(sb < num_subblocks_);
+  assert(sb < num_subblocks_ || sb == no_subblock);
   assert(dim_ == Dim);
 
-  index_type dim_sb[VSIP_MAX_DIMENSION];
-  Domain<1>  dom[VSIP_MAX_DIMENSION];
+  if (sb == no_subblock)
+    return impl::empty_domain<Dim>();
+  else
+  {
+    index_type dim_sb[VSIP_MAX_DIMENSION];
+    Domain<1>  dom[VSIP_MAX_DIMENSION];
 
-  impl::split_tuple(sb, dim_, subblocks_, dim_sb);
+    impl::split_tuple(sb, dim_, subblocks_, dim_sb);
 
-  for (dimension_type d=0; d<dim_; ++d)
-    dom[d] = Domain<1>(impl_subblock_size(d, dim_sb[d]));
+    for (dimension_type d=0; d<dim_; ++d)
+      dom[d] = Domain<1>(impl_subblock_size(d, dim_sb[d]));
 
-  return impl::construct_domain<Dim>(dom);
+    return impl::construct_domain<Dim>(dom);
+  }
 }
 
 
Index: src/vsip/impl/aligned_allocator.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/aligned_allocator.hpp,v
retrieving revision 1.6
diff -u -r1.6 aligned_allocator.hpp
--- src/vsip/impl/aligned_allocator.hpp	7 Mar 2006 02:15:22 -0000	1.6
+++ src/vsip/impl/aligned_allocator.hpp	28 Apr 2006 20:52:55 -0000
@@ -86,6 +86,10 @@
   // allocate but don't initialize num elements of type T
   pointer allocate(size_type num, const void* = 0)
   {
+    // If num == 0, allocate 1 element.
+    if (num == 0)
+      num = 1;
+    
     // allocate aligned memory
     pointer p = alloc_align<value_type>(align, num);
     if (p == 0)
Index: tests/make.standalone
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/make.standalone,v
retrieving revision 1.2
diff -u -r1.2 make.standalone
--- tests/make.standalone	7 Mar 2006 12:18:49 -0000	1.2
+++ tests/make.standalone	28 Apr 2006 20:52:55 -0000
@@ -59,10 +59,12 @@
    PC    = pkg-config $(PKG)
 endif
 
+LOCAL_CXXFLAGS = -I.
 
 CXX      = $(shell $(PC) --variable=cxx )
 CXXFLAGS = $(shell $(PC) --cflags       ) \
-	   $(shell $(PC) --variable=cxxflags )
+	   $(shell $(PC) --variable=cxxflags ) \
+	   $(LOCAL_CXXFLAGS)
 LIBS     = $(shell $(PC) --libs         )
 
 REMOTE   =
Index: tests/output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/output.hpp,v
retrieving revision 1.3
diff -u -r1.3 output.hpp
--- tests/output.hpp	4 Apr 2006 02:21:13 -0000	1.3
+++ tests/output.hpp	28 Apr 2006 20:52:55 -0000
@@ -136,6 +136,28 @@
   return out;
 }
 
+
+
+/// Write an Length to a stream.
+
+template <vsip::dimension_type Dim>
+inline
+std::ostream&
+operator<<(
+  std::ostream&		         out,
+  vsip::impl::Length<Dim> const& idx)
+  VSIP_NOTHROW
+{
+  out << "(";
+  for (vsip::dimension_type d=0; d<Dim; ++d)
+  {
+    if (d > 0) out << ", ";
+    out << idx[d];
+  }
+  out << ")";
+  return out;
+}
+
 } // namespace vsip
 
 #endif // VSIP_OUTPUT_HPP
Index: tests/parallel/expr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/parallel/expr.cpp,v
retrieving revision 1.3
diff -u -r1.3 expr.cpp
--- tests/parallel/expr.cpp	4 Apr 2006 02:21:13 -0000	1.3
+++ tests/parallel/expr.cpp	28 Apr 2006 20:52:55 -0000
@@ -217,7 +217,7 @@
   foreach_point(Z7, checker5);
   test_assert(checker5.good());
 
-  if (map_res.subblock() != no_subblock)
+  if (map0.subblock() != no_subblock)
   {
     typename view0_t::local_type local_view = chk1.local();
 
Index: vendor/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/vendor/GNUmakefile.inc.in,v
retrieving revision 1.13
diff -u -r1.13 GNUmakefile.inc.in
--- vendor/GNUmakefile.inc.in	27 Apr 2006 01:23:33 -0000	1.13
+++ vendor/GNUmakefile.inc.in	28 Apr 2006 20:52:55 -0000
@@ -95,6 +95,9 @@
 	@echo "Building libF77 (see libF77.build.log)"
 	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 all > libF77.build.log 2>&1
 
+install:: $(vendor_LIBF77)
+	$(INSTALL_DATA) $(vendor_LIBF77) $(DESTDIR)$(libdir)
+
 clean::
 	@echo "Cleaning libF77 (see libF77.clean.log)"
 	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 clean > libF77.clean.log 2>&1
