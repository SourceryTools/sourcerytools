Index: scripts/package.py
===================================================================
--- scripts/package.py	(revision 169305)
+++ scripts/package.py	(working copy)
@@ -31,20 +31,39 @@
     suffix=''
     host=''
 
-def read_config_file(filename):
+class Source:
+    svpp_rev = 'HEAD'
+    fftw_rev = 'HEAD'
+    patches  = []
 
-    env = {'Configuration':Configuration, 'Package':Package}
+    
+
+def read_config_file(filename, parameters):
+    configdir = parameters['configdir']
+
+    env = {'Configuration':Configuration, 'Package':Package, 'Source':Source}
+
+    def my_include(filename):
+        exec open("%s/%s"%(configdir, filename), 'r').read() in env
+
+    env['include'] = my_include
+
     exec open(filename, 'r').read() in env
     del env['Configuration']
     del env['Package']
+    del env['Source']
     packages = {}
+    sources = {}
     for n, o in env.iteritems():
         if type(o) is ClassType and issubclass(o, Package):
             packages[n] = o
+        if type(o) is ClassType and issubclass(o, Source):
+            sources[n] = o
 
-    return packages
+    return packages, sources
 
 
+
 def extract_package_info(package):
 
     configs = {}
@@ -69,7 +88,6 @@
 parameters['configfile'] = ''
 parameters['suffix'] = ''
 parameters['maintainer_mode'] = True
-parameters['svntag'] = 'HEAD'
 # Configurations are stored as key / value pairs.
 # The key is the suffix to use (may be ''), and the
 # value is a string to be concatenated to the configure
@@ -93,16 +111,25 @@
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
@@ -118,14 +145,13 @@
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
@@ -149,7 +175,7 @@
         os.chdir(cwd)
     
 
-def build_bdist(**args):
+def build_bdist(cfg, **args):
 
     announce('building binary package...')
     srcdir = parameters['srcdir']
@@ -161,7 +187,7 @@
     pkgconfig_dir = '%s/%s/lib/pkgconfig/'%(abs_distdir,prefix)
     if not os.path.exists(srcdir):
         os.makedirs(srcdir)
-        checkout()
+        checkout(cfg)
     if not os.path.exists(builddir):
         os.makedirs(builddir)
     # create a lib/pkgconfig director for .pc links.
@@ -215,7 +241,7 @@
         os.chdir(cwd)
     
 
-def test_bdist(**args):
+def test_bdist(cfg, **args):
 
     packagefile = parameters.get('packagefile')
     if not packagefile:
@@ -231,7 +257,7 @@
     if not os.path.exists(srcdir):
         print 'srcdir does not exist: %s'%srcdir
         os.makedirs(srcdir)
-        checkout()
+        checkout(cfg)
     if not os.path.exists(abs_builddir):
         os.makedirs(abs_builddir)
     cwd = os.getcwd()
@@ -320,6 +346,7 @@
                                 'prefix=',
                                 'config=',
                                 'configfile=',
+                                'configdir=',
                                 'package=',
                                 'packagefile=',
                                 'no-maintainer-mode',
@@ -346,6 +373,8 @@
             parameters['version'] = a
         elif o == '--configfile':
             parameters['configfile'] = os.path.expanduser(a)
+        elif o == '--configdir':
+            parameters['configdir'] = a
         elif o == '--config':
             if '=' in a:
                 suffix, options = a.split('=', 1)
@@ -354,8 +383,6 @@
             parameters['config'][suffix] = options
         elif o == '--no-maintainer-mode':
             parameters['maintainer_mode'] = False
-        elif o == '--svn-tag':
-            parameters['svntag'] = a
     # There are no non-positional arguments
     if args:
         error('Error: Did not expect non-positional arguments.')
@@ -364,12 +391,24 @@
     parameters['abs_builddir'] = os.path.abspath(parameters['builddir'])
     parameters['abs_distdir'] = os.path.abspath(parameters['distdir'])
 
+    configfile = parameters['configfile']
+    if not configfile:
+        error('Error: No configfile option given.')
+    if not os.path.isfile(configfile):
+        error('Error: configfile "%s" not found.'%configfile)
+
+    packages, sources = read_config_file(configfile, parameters)
+
+    if (len(sources) == 0):
+        error('Error: configfile "%s" contains no Source definitions.'%configfile)
+    if (len(sources) > 1):
+        error('Error: configfile "%s" contains multiple Source definitions.'%configfile)
+
+    cfg = sources.values()[0]
+    
+
     if parameters.get('package'):
-        configfile = parameters['configfile']
         # If there is a package option, there also should be a configfile option.
-        if not configfile:
-            error('Error: No configfile option given.')
-        packages = read_config_file(configfile)
         package = packages.get(parameters['package'])
         if not package:
             error('Error: Unknown package "%s".'%parameters['package'], False)
@@ -379,7 +418,7 @@
         parameters['config'] = config
 
     # Call the command
-    commands[command]()
+    commands[command](cfg)
         
 if __name__ == '__main__':
 
Index: scripts/release.sh
===================================================================
--- scripts/release.sh	(revision 169305)
+++ scripts/release.sh	(working copy)
@@ -37,6 +37,7 @@
 
 what="all"
 dir=$HOME/csl/src/vpp/SVN-HEAD
+cfgdir=default
 cfgfile=default
 pkgs="SerialBuiltin32 SerialBuiltin64 ParallelBuiltin32 ParallelBuiltin64 SerialIntel32 SerialIntel64 ParallelIntel32 ParallelIntel64"
 svn_srcdir="svn_srcdir"
@@ -44,44 +45,40 @@
 test_srcdir="default"
 distdir="vpp-dist"
 debug="yes"
-svn_tag="HEAD"
 pkg_opts=""
 version="1.3"
 host=`hostname`
 
-while getopts "w:d:c:p:P:C:t:D:T:s" arg; do
+while getopts "w:c:d:p:C:t:D:T:sS:v:" arg; do
     case $arg in
 	w)
 	    what=$OPTARG
 	    ;;
-	d)
-	    dir=$OPTARG
-	    ;;
 	c)
 	    cfgfile=$OPTARG
 	    ;;
 	C)
 	    svn_srcdir=$OPTARG
 	    ;;
+	d)
+	    dir=$OPTARG
+	    ;;
+	D)
+	    distdir=$OPTARG
+	    ;;
 	p)
 	    pkgs=$OPTARG
 	    ;;
-	P)
-	    patches=$OPTARG
-	    ;;
 	t)
 	    test_srcdir=$OPTARG
 	    ;;
-	D)
-	    distdir=$OPTARG
-	    ;;
-	T)
-	    svn_tag=$OPTARG
-	    ;;
 	s)
 	    pkg_opts="$pkg_opts --snapshot"
             version=`date +%Y%m%d`
 	    ;;
+	v)
+	    version=$OPTARG
+	    ;;
 	\?)
             error "usage: release.sh [-v VERSION]"
 	    ;;
@@ -92,10 +89,15 @@
 srcpkg="$srcdir.tar.bz2"
 
 package=$dir/scripts/package.py
-if test "$cfgfile" = "default"; then
-  cfgfile=$dir/scripts/config
+if test "$cfgdir" = "default"; then
+  cfgdir=$dir/scripts
 fi
 
+if test "x$cfgfile" = "x"; then
+  echo "ERROR: Must specify a config file -c <file>"
+  exit -1
+fi
+
 if test "$test_srcdir" = "default"; then
   test_srcdir=$srcdir
 fi
@@ -162,9 +164,9 @@
   echo "svn_srcdir      : $svn_srcdir"
 
   save_IFS=$IFS; IFS=":"
-  for dir in $LD_LIBRARY_PATH
+  for d in $LD_LIBRARY_PATH
   do
-    echo "LD_LIBRARY_PATH: $dir"
+    echo "LD_LIBRARY_PATH: $d"
   done
   IFS=$save_IFS
 fi
@@ -179,38 +181,22 @@
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
-	--builddir=$src_builddir			\
+    $package build_sdist --verbose			\
+	--srcdir=$svn_srcdir				\
 	--configfile=$cfgfile				\
+	--builddir=$src_builddir			\
+	--configdir="$dir/scripts"			\
 	$pkg_opts					\
 	2>&1 > log-src-build
 
-    # 1d. Untar source package.  Use this to build binary packages.
+    # 1b. Untar source package.  Use this to build binary packages.
     mv $src_builddir/$srcpkg .
   fi
 fi
@@ -234,6 +220,7 @@
     $package build_bdist --verbose --srcdir=$srcdir		\
         --no-maintainer-mode					\
 	--configfile=$cfgfile					\
+	--configdir="$dir/scripts"				\
 	--builddir=$builddir					\
 	$pkg_opts						\
 	--package=$pkg 2>&1 > log-build-$pkg
@@ -258,6 +245,7 @@
 	--distdir=$distdir					\
 	--srcdir=$test_srcdir					\
 	--configfile=$cfgfile					\
+	--configdir="$dir/scripts"				\
 	--builddir=$builddir					\
 	--package=$pkg 2>&1 > log-test-$pkg
   done
