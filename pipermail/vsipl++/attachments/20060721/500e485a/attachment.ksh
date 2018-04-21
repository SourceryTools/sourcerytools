Index: scripts/package.py
===================================================================
--- scripts/package.py	(revision 145317)
+++ scripts/package.py	(working copy)
@@ -63,7 +63,7 @@
 parameters['configfile'] = ''
 parameters['suffix'] = ''
 parameters['maintainer_mode'] = True
-parameters['cvstag'] = 'HEAD'
+parameters['svntag'] = 'HEAD'
 # Configurations are stored as key / value pairs.
 # The key is the suffix to use (may be ''), and the
 # value is a string to be concatenated to the configure
@@ -89,14 +89,12 @@
 
 def checkout(**args):
 
-    cvsroot = args.get('cvsroot', 'cvs.codesourcery.com:/home/cvs/Repository')
-    cvstag = args.get('cvstag', parameters['cvstag'])
-    cvsmodule = args.get('cvsmodule', 'vpp')
+    svnroot = args.get('svnroot', 'svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/vpp/trunk')
+    svntag = args.get('svntag', parameters['svntag'])
     srcdir = parameters['srcdir']
 
     announce('checking out...')
-    cmd = ['cvs', '-Q', '-d', cvsroot, 'export',
-           '-r', cvstag, '-d', srcdir, cvsmodule]
+    cmd = ['svn', 'export', '-r', svntag, svnroot, srcdir]
 
     spawn(cmd)
     cwd = os.getcwd()
@@ -250,7 +248,7 @@
     --package=<package>            The package type to use (reference into the config file.
     --packagefile=<file>           The (binary) package file to test.
     --no-maintainer-mode           Do not build in maintainer-mode.
-    --cvs-tag=<tag>                Use <tag> during checkout.
+    --svn-tag=<tag>                Use <tag> during checkout.
     """%(sys.argv[0], commands.keys())
 
 def error(msg = None, print_usage = True):
@@ -281,7 +279,7 @@
                                 'package=',
                                 'packagefile=',
                                 'no-maintainer-mode',
-                                'cvs-tag='])
+                                'svn-tag='])
 
     for o, a in opts:
         if o == '--verbose':
@@ -312,8 +310,8 @@
             parameters['config'][suffix] = options
         elif o == '--no-maintainer-mode':
             parameters['maintainer_mode'] = False
-        elif o == '--cvs-tag':
-            parameters['cvstag'] = a
+        elif o == '--svn-tag':
+            parameters['svntag'] = a
     # There are no non-positional arguments
     if args:
         error('Error: Did not expect non-positional arguments.')
Index: scripts/release.sh
===================================================================
--- scripts/release.sh	(revision 145317)
+++ scripts/release.sh	(working copy)
@@ -30,21 +30,21 @@
 #   This script automates the building of source and binary packages
 #   for Sourcery VSIPL++.  It uses the 'package' script to perform
 #   the following steps:
-#     1. Check out sources from CVS,
+#     1. Check out sources from SVN,
 #     2. Build a source package,
 #     3. Build binary packages from source package,
 #     4. Test binary packages.
 
 what="all"
-dir=$HOME/csl/src/vpp/CVS-HEAD
+dir=$HOME/csl/src/vpp/SVN-HEAD
 cfgfile=default
 pkgs="SerialBuiltin32 SerialBuiltin64 ParallelBuiltin32 ParallelBuiltin64 SerialIntel32 SerialIntel64 ParallelIntel32 ParallelIntel64"
-cvs_srcdir="cvs_srcdir"
+svn_srcdir="svn_srcdir"
 src_builddir="vpp-src-build"
 test_srcdir="default"
 distdir="vpp-dist"
 debug="yes"
-cvs_tag="HEAD"
+svn_tag="HEAD"
 pkg_opts=""
 version="1.1"
 host=`hostname`
@@ -61,7 +61,7 @@
 	    cfgfile=$OPTARG
 	    ;;
 	C)
-	    cvs_srcdir=$OPTARG
+	    svn_srcdir=$OPTARG
 	    ;;
 	p)
 	    pkgs=$OPTARG
@@ -76,7 +76,7 @@
 	    distdir=$OPTARG
 	    ;;
 	T)
-	    cvs_tag=$OPTARG
+	    svn_tag=$OPTARG
 	    ;;
 	s)
 	    pkg_opts="$pkg_opts --snapshot"
@@ -156,7 +156,7 @@
   echo "which dot       : " `which dot`
   echo "which pkg-config: " `which pkg-config`
   echo "configure file  : $cfgfile"
-  echo "cvs_srcdir      : $cvs_srcdir"
+  echo "svn_srcdir      : $svn_srcdir"
 
   save_IFS=$IFS; IFS=":"
   for dir in $LD_LIBRARY_PATH
@@ -177,13 +177,13 @@
     echo "Source package ($srcpkg) not found ... creating it"
 
     # 1a. Checkout Sources
-    if test -d "$cvs_srcdir"; then
-      echo "No checkout ($cvs_srcdir already exists)"
+    if test -d "$svn_srcdir"; then
+      echo "No checkout ($svn_srcdir already exists)"
     else
-      echo "Checkout ($cvs_srcdir)"
-      $package checkout --verbose --srcdir=$cvs_srcdir	\
+      echo "Checkout ($svn_srcdir)"
+      $package checkout --verbose --srcdir=$svn_srcdir	\
 	--configfile=$cfgfile				\
-        --cvs-tag=$cvs_tag				\
+        --svn-tag=$svn_tag				\
 	2>&1 > log-checkout
     fi
 
@@ -193,15 +193,15 @@
       old_IFS=$IFS
       IFS=":"
       for p in $patches; do
-        patch -d $cvs_srcdir -p0 < $p
+        patch -d $svn_srcdir -p0 < $p
       done
       IFS=$old_IFS
     fi
 
 
     # 1c. Build source package
-    echo "Build SDist (from $cvs_srcdir)"
-    $package build_sdist --verbose --srcdir=$cvs_srcdir	\
+    echo "Build SDist (from $svn_srcdir)"
+    $package build_sdist --verbose --srcdir=$svn_srcdir	\
 	--builddir=$src_builddir			\
 	--configfile=$cfgfile				\
 	$pkg_opts					\
