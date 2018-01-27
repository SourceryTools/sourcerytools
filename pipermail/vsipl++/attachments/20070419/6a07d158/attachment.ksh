Index: ChangeLog
===================================================================
--- ChangeLog	(revision 169277)
+++ ChangeLog	(working copy)
@@ -1,5 +1,12 @@
 2007-04-19  Jules Bergmann  <jules@codesourcery.com>
 
+	* scripts/package.py (--src_cfg): New option to accept
+	  source configuration file, which describes SVN directories
+	  to checkout and patches to apply.
+	* scripts/release.sh: Use new option.
+
+2007-04-19  Jules Bergmann  <jules@codesourcery.com>
+
 	* svn:externals: Remove vendor/fftw entry.
 
 2007-04-18  Jules Bergmann  <jules@codesourcery.com>
Index: scripts/package.py
===================================================================
--- scripts/package.py	(revision 169277)
+++ scripts/package.py	(working copy)
@@ -45,6 +45,16 @@
     return packages
 
 
+def read_src_cfg(filename):
+    class Cfg:
+        patches  = []
+        svpp_rev = 'HEAD'
+        fftw_rev = 'HEAD'
+    env = {'cfg':Cfg}
+    exec open(filename, 'r').read() in env
+    return env['cfg']
+
+
 def extract_package_info(package):
 
     configs = {}
@@ -69,7 +79,6 @@
 parameters['configfile'] = ''
 parameters['suffix'] = ''
 parameters['maintainer_mode'] = True
-parameters['svntag'] = 'HEAD'
 # Configurations are stored as key / value pairs.
 # The key is the suffix to use (may be ''), and the
 # value is a string to be concatenated to the configure
@@ -93,16 +102,25 @@
         print 'options :', c['options']
 
 
-def checkout(**args):
+def checkout(cfg, **args):
+    svnroot = args.get('svnroot', 'svn+ssh://gateway/home/svk/Repository')
 
-    svnroot = args.get('svnroot', 'svn+ssh://cugel/net/merlin/home-s/svk/Repository/csl/vpp/trunk')
-    svntag = args.get('svntag', parameters['svntag'])
     srcdir = parameters['srcdir']
 
-    announce('checking out...')
-    cmd = ['svn', 'export', '-r', svntag, svnroot, srcdir]
+    announce('checking out SVPP (%s)...'%cfg.svpp_dir)
+    spawn(['svn', 'export', '-r', cfg.svpp_rev, svnroot + "/" + cfg.svpp_dir,
+                                  srcdir])
 
-    spawn(cmd)
+    announce('checking out FFTW (%s)...'%cfg.fftw_dir)
+    spawn(['svn', 'export', '-r', cfg.fftw_rev, svnroot + "/" + cfg.fftw_dir,
+                                  srcdir + "/vendor/fftw"])
+
+    for patch in cfg.patches:
+        abs_patch = os.path.abspath(patch)
+        announce('applying patch %s - %s'%(patch,abs_patch))
+        # patch looks for the '-i' file relative to the '-d' directory.
+        spawn(['patch', '-d', srcdir, '-p0', '-i', abs_patch])
+
     cwd = os.getcwd()
     os.chdir(srcdir)
     spawn(['./autogen.sh'])
@@ -118,14 +136,13 @@
     spawn(['sh', '-c', cmd])
 
 
-def build_sdist(**args):
+def build_sdist(cfg, **args):
 
     announce('building source package...')
     srcdir = parameters['srcdir']
     builddir = parameters['builddir']
     if not os.path.exists(srcdir):
-        os.makedirs(srcdir)
-        checkout()
+        checkout(cfg)
     if not os.path.exists(builddir):
         os.makedirs(builddir)
     cwd = os.getcwd()
@@ -149,7 +166,7 @@
         os.chdir(cwd)
     
 
-def build_bdist(**args):
+def build_bdist(cfg, **args):
 
     announce('building binary package...')
     srcdir = parameters['srcdir']
@@ -161,7 +178,7 @@
     pkgconfig_dir = '%s/%s/lib/pkgconfig/'%(abs_distdir,prefix)
     if not os.path.exists(srcdir):
         os.makedirs(srcdir)
-        checkout()
+        checkout(cfg)
     if not os.path.exists(builddir):
         os.makedirs(builddir)
     # create a lib/pkgconfig director for .pc links.
@@ -215,7 +232,7 @@
         os.chdir(cwd)
     
 
-def test_bdist(**args):
+def test_bdist(cfg, **args):
 
     packagefile = parameters.get('packagefile')
     if not packagefile:
@@ -231,7 +248,7 @@
     if not os.path.exists(srcdir):
         print 'srcdir does not exist: %s'%srcdir
         os.makedirs(srcdir)
-        checkout()
+        checkout(cfg)
     if not os.path.exists(abs_builddir):
         os.makedirs(abs_builddir)
     cwd = os.getcwd()
@@ -318,6 +335,7 @@
                                 'builddir=',
                                 'distdir=',
                                 'prefix=',
+                                'src_cfg=',
                                 'config=',
                                 'configfile=',
                                 'package=',
@@ -354,8 +372,8 @@
             parameters['config'][suffix] = options
         elif o == '--no-maintainer-mode':
             parameters['maintainer_mode'] = False
-        elif o == '--svn-tag':
-            parameters['svntag'] = a
+        elif o == '--src_cfg':
+            parameters['src_cfg_file'] = a
     # There are no non-positional arguments
     if args:
         error('Error: Did not expect non-positional arguments.')
@@ -364,6 +382,10 @@
     parameters['abs_builddir'] = os.path.abspath(parameters['builddir'])
     parameters['abs_distdir'] = os.path.abspath(parameters['distdir'])
 
+    if not parameters['src_cfg_file']:
+        error('Error: No src_cfg option given.')
+    cfg = read_src_cfg(parameters['src_cfg_file'])
+
     if parameters.get('package'):
         configfile = parameters['configfile']
         # If there is a package option, there also should be a configfile option.
@@ -379,7 +401,7 @@
         parameters['config'] = config
 
     # Call the command
-    commands[command]()
+    commands[command](cfg)
         
 if __name__ == '__main__':
 
Index: scripts/release.sh
===================================================================
--- scripts/release.sh	(revision 169277)
+++ scripts/release.sh	(working copy)
@@ -38,18 +38,18 @@
 what="all"
 dir=$HOME/csl/src/vpp/SVN-HEAD
 cfgfile=default
+src_cfg=
 pkgs="SerialBuiltin32 SerialBuiltin64 ParallelBuiltin32 ParallelBuiltin64 SerialIntel32 SerialIntel64 ParallelIntel32 ParallelIntel64"
 svn_srcdir="svn_srcdir"
 src_builddir="vpp-src-build"
 test_srcdir="default"
 distdir="vpp-dist"
 debug="yes"
-svn_tag="HEAD"
 pkg_opts=""
-version="1.3"
+version="0.0"
 host=`hostname`
 
-while getopts "w:d:c:p:P:C:t:D:T:s" arg; do
+while getopts "w:d:c:p:C:t:D:T:sS:v:" arg; do
     case $arg in
 	w)
 	    what=$OPTARG
@@ -66,22 +66,22 @@
 	p)
 	    pkgs=$OPTARG
 	    ;;
-	P)
-	    patches=$OPTARG
-	    ;;
 	t)
 	    test_srcdir=$OPTARG
 	    ;;
 	D)
 	    distdir=$OPTARG
 	    ;;
-	T)
-	    svn_tag=$OPTARG
-	    ;;
 	s)
 	    pkg_opts="$pkg_opts --snapshot"
             version=`date +%Y%m%d`
 	    ;;
+	S)
+	    src_cfg=$OPTARG
+	    ;;
+	v)
+	    version=$OPTARG
+	    ;;
 	\?)
             error "usage: release.sh [-v VERSION]"
 	    ;;
@@ -96,6 +96,11 @@
   cfgfile=$dir/scripts/config
 fi
 
+if test "x$src_cfg" = "x"; then
+  echo "ERROR: Must specify a source configuration file with -S option"
+  exit -1
+fi
+
 if test "$test_srcdir" = "default"; then
   test_srcdir=$srcdir
 fi
@@ -179,38 +184,22 @@
   else
     echo "Source package ($srcpkg) not found ... creating it"
 
-    # 1a. Checkout Sources
     if test -d "$svn_srcdir"; then
-      echo "No checkout ($svn_srcdir already exists)"
-    else
-      echo "Checkout ($svn_srcdir)"
-      $package checkout --verbose --srcdir=$svn_srcdir	\
-	--configfile=$cfgfile				\
-        --svn-tag=$svn_tag				\
-	2>&1 > log-checkout
+      echo "ERROR: ($svn_srcdir already exists)"
+      exit
     fi
 
-    # 1b. Apply patch
-    if test "x$patches" != "x"; then
-      echo "Applying patches: $patches"
-      old_IFS=$IFS
-      IFS=":"
-      for p in $patches; do
-        patch -d $svn_srcdir -p0 < $p
-      done
-      IFS=$old_IFS
-    fi
-
-
-    # 1c. Build source package
+    # 1a. Build source package (includes checkout and patch)
     echo "Build SDist (from $svn_srcdir)"
-    $package build_sdist --verbose --srcdir=$svn_srcdir	\
+    $package build_sdist --verbose			\
+	--srcdir=$svn_srcdir				\
+	--src_cfg=$src_cfg				\
 	--builddir=$src_builddir			\
 	--configfile=$cfgfile				\
 	$pkg_opts					\
 	2>&1 > log-src-build
 
-    # 1d. Untar source package.  Use this to build binary packages.
+    # 1b. Untar source package.  Use this to build binary packages.
     mv $src_builddir/$srcpkg .
   fi
 fi
@@ -232,6 +221,7 @@
     echo "Build: $pkg"
     builddir=vpp-build-$pkg
     $package build_bdist --verbose --srcdir=$srcdir		\
+	--src_cfg=$src_cfg					\
         --no-maintainer-mode					\
 	--configfile=$cfgfile					\
 	--builddir=$builddir					\
@@ -254,6 +244,7 @@
 
     rm -rf $distdir
     $package test_bdist --verbose				\
+	--src_cfg=$src_cfg					\
 	--packagefile=$pkgfile					\
 	--distdir=$distdir					\
 	--srcdir=$test_srcdir					\
