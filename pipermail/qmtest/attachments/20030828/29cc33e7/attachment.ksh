Index: setup.py
===================================================================
RCS file: /home/qm/Repository/qm/setup.py,v
retrieving revision 1.2
diff -u -r1.2 setup.py
--- setup.py	27 Aug 2003 20:59:19 -0000	1.2
+++ setup.py	28 Aug 2003 04:23:05 -0000
@@ -28,8 +28,14 @@
 def prefix(list, pref): return map(lambda x, p=pref: p + x, list)
 
 def find_file(paths, predicate):
-    """This function returns the found file (with path) or None if it
-    wasn't found"""
+    """Return a file satisfying 'predicate' from 'paths'.
+
+    'paths' -- A sequence of glob patterns.
+
+    'predicate' -- A callable taking a single string as an argument.
+
+    returns -- The name of the first file matching one of the 'paths'
+    and 'predicate'."""
     for path in paths:
         matches = filter(predicate, glob.glob(path))
         if matches:
@@ -37,13 +43,29 @@
     return None
 
 class qm_build_doc(build.build):
-    """This class compiles the QMTest's documentation."""
+    """Defines the specific procedure to build QMTest's documentation.
+
+    As this command is only ever used on 'posix' platforms, no efford
+    has been made to make this code portable to other platforms such
+    as 'nt'."""
 
     def call_jade(self, jade, args, dcl, type, src, builddir):
-        """The call_jade command compiles the output file from the
-        input files, using 'type' as the type attribute."""
+        """Runs 'jade' in a subprocess to process a docbook file.
+
+        'jade' -- The jade executable with its full path.
+
+        'args' -- A sequence of arguments to be passed.
+
+        'dcl' -- An sgml declaration file for xml.
+
+        'type' -- The output type to be generated.
+
+        'src' -- The xml (master) source file to be processed.
+
+        'builddir' -- The directory from which to call jade."""
         cwd = os.getcwd()
-        # just to be sure this is still valid after chdir()
+        # Use an absolute path so that calls to chdir do not invalidate
+        # the name.
         src = os.path.abspath(src)
         builddir = os.path.join(self.build_temp, builddir)
         self.mkpath(builddir)
@@ -76,6 +98,10 @@
         os.chdir(cwd)
 
     def run(self):
+        """Run this command, i.e. do the actual document generation.
+
+        As this command requires 'jade', it will do nothing if
+        that couldn't be found in the default path."""
 
         source_files = ['qm/test/doc/manual.xml',
                         'qm/test/doc/introduction.xml',
@@ -103,7 +129,7 @@
             return
 
         #
-        # build html output
+        # Build html output.
         #
         self.announce("building html manual")
         target = os.path.join(self.build_lib, 'qm/test/doc/html')
@@ -121,7 +147,7 @@
                 copy_tree(src, dst, 1, 1, 0, 1, self.verbose, self.dry_run)
 
         #
-        # build tex output
+        # Build tex output.
         #
         self.announce("building tex manual")
         target = os.path.join(self.build_lib, 'qm/test/doc/print/manual.tex')
@@ -144,7 +170,7 @@
                           1, 1, 1, None, self.verbose, self.dry_run)
 
         #
-        # build pdf output
+        # Build pdf output.
         #
         self.announce("building pdf manual")
         target = os.path.join(self.build_lib, 'qm/test/doc/print/manual.pdf')
@@ -164,23 +190,28 @@
                 copy_file(src, target,
                           1, 1, 1, None, self.verbose, self.dry_run)
 
+        #
+        # Build reference manual via 'happydoc'.
+        #
         happydoc = find_executable('happydoc')
         if (happydoc):
             self.announce("building reference manual")
             spawn(['happydoc', 'qm'])
 
 class qm_build(build.build):
-    """The qm_build class extends the build subcommands by 'qm_build_doc'."""
+    """Extends 'build' by adding support for building documentation."""
 
     sub_commands = build.build.sub_commands[:] + [('build_doc', None)]
 
 class qm_install_data(install_data.install_data):
-    """This class overrides the system install_data command. In addition
-    to the original processing, a 'config' module is created that
-    contains the data only available at installation time, such as
-    installation paths."""
+    """Extends 'install_data' by generating a config module.
+
+    This module contains data only available at installation time,
+    such as installation paths for data files."""
 
     def run(self):
+        """Run this command."""
+        
         id = self.distribution.get_command_obj('install_data')
         il = self.distribution.get_command_obj('install_lib')
         install_data.install_data.run(self)
