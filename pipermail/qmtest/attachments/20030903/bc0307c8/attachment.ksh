Index: setup.py
===================================================================
RCS file: /home/qm/Repository/qm/setup.py,v
retrieving revision 1.3
diff -u -r1.3 setup.py
--- setup.py	28 Aug 2003 20:28:30 -0000	1.3
+++ setup.py	3 Sep 2003 03:49:35 -0000
@@ -14,238 +14,16 @@
 ########################################################################
 
 from distutils.core import setup
-from distutils.command import build
-from distutils.command import install_data
-from distutils.spawn import spawn, find_executable
-from distutils.dep_util import newer, newer_group
-from distutils.dir_util import copy_tree, remove_tree
-from distutils.file_util import copy_file
+import sys
 import os
 import os.path
 import string
 import glob
 
-def prefix(list, pref): return map(lambda x, p=pref: p + x, list)
-
-def find_file(paths, predicate):
-    """Return a file satisfying 'predicate' from 'paths'.
-
-    'paths' -- A sequence of glob patterns.
-
-    'predicate' -- A callable taking a single string as an argument.
-
-    returns -- The name of the first file matching one of the 'paths'
-    and 'predicate'."""
-    for path in paths:
-        matches = filter(predicate, glob.glob(path))
-        if matches:
-            return matches[0]
-    return None
-
-class qm_build_doc(build.build):
-    """Defines the specific procedure to build QMTest's documentation.
-
-    As this command is only ever used on 'posix' platforms, no effort
-    has been made to make this code portable to other platforms such
-    as 'nt'."""
-
-    description = "build documentation"
-
-    def call_jade(self, jade, args, dcl, type, src, builddir):
-        """Runs 'jade' in a subprocess to process a docbook file.
-
-        'jade' -- The jade executable with its full path.
-
-        'args' -- A sequence of arguments to be passed.
-
-        'dcl' -- An sgml declaration file for xml.
-
-        'type' -- The output type to be generated.
-
-        'src' -- The xml (master) source file to be processed.
-
-        'builddir' -- The directory from which to call jade."""
-        cwd = os.getcwd()
-        # Use an absolute path so that calls to chdir do not invalidate
-        # the name.
-        src = os.path.abspath(src)
-        builddir = os.path.join(self.build_temp, builddir)
-        if (type == 'sgml'):
-            # The stylesheet used for html output sets
-            # 'html' to be the output directory. Jade
-            # expects that to exist.
-            self.mkpath(builddir + '/html')
-        else:
-            self.mkpath(builddir)
-            
-        os.chdir(builddir)            
-        cmd = [jade] + args + ['-t', type]
-        cmd += ['-d', os.path.join(cwd, 'doc', 'qm-%s.dsl'%type)]
-        cmd += [dcl]
-        cmd += [src]
-        self.announce(string.join(cmd, ' '))
-        spawn(cmd)
-        os.chdir(cwd)
-
-    def run(self):
-        """Run this command, i.e. do the actual document generation.
-
-        As this command requires 'jade', it will do nothing if
-        that couldn't be found in the default path."""
+from qmdist.command.build_doc import build_doc
+from qmdist.command.install_data import install_data
 
-        source_files = map(os.path.normpath,
-                           ['qm/test/doc/manual.xml',
-                            'qm/test/doc/introduction.xml',
-                            'qm/test/doc/tour.xml',
-                            'qm/test/doc/reference.xml'])
-
-        jade = find_executable('jade')
-        dcl = find_file(map(os.path.normpath,
-                            ['/usr/share/doc/jade*/pubtext/xml.dcl',
-                             '/usr/share/doc/openjade*/pubtext/xml.dcl',
-                             '/usr/doc/jade*/pubtext/xml.dcl',
-                             '/usr/share/sgml/declaration/xml.dcl']),
-                        os.path.isfile)
-
-        stylesheets = find_file(map(os.path.normpath,
-                                    ['/usr/lib/sgml/stylesheets/docbook',
-                                     '/usr/lib/sgml/stylesheets/dsssl/docbook',
-                                     '/usr/share/sgml/docbook/dsssl-stylesheets']),
-                                os.path.isdir)
-
-        dtd = find_file(map(os.path.normpath,
-                            ['/usr/lib/sgml',
-                             '/usr/share/sgml/docbook']),
-                        os.path.isdir)
-
-        if not jade or not dcl or not stylesheets or not dtd:
-            self.warn("can't build documentation")
-            return
-
-        #
-        # Build html output.
-        #
-        target = os.path.normpath(self.build_lib + '/qm/test/doc/html')
-        if newer_group(source_files, target):
-            self.announce("building html manual")
-            # Remove the target first such that its new mtime reflects
-            # this build.
-            if os.path.isdir(target): remove_tree(target)
-            self.call_jade(jade, ['-D%s'%dtd, '-D%s'%stylesheets],
-                           dcl, 'sgml',
-                           os.path.normpath('qm/test/doc/manual.xml'),
-                           os.path.normpath('qm/test/doc'))
-            tidy = find_executable('tidy')
-            if tidy:
-                for f in glob.glob(map(os.path.normpath,
-                                       self.build_temp + '/qm/test/doc/html/*.html')):
-                    spawn([tidy,
-                           '-wrap', '72', '-i',
-                           '--indent-spaces', '1',
-                           '-f', '/dev/null',
-                           '-asxml', '-modify', f])
-            if self.build_temp != self.build_lib:
-                src = os.path.normpath(self.build_temp + '/qm/test/doc/html')
-                dst = target
-                self.mkpath(dst)
-                copy_tree(src, dst, 1, 1, 0, 1,
-                          self.verbose, self.dry_run)
-
-        #
-        # Build tex output.
-        #
-        target = os.path.normpath(self.build_lib + '/qm/test/doc/print/manual.tex')
-        if newer_group(source_files, target):
-            self.announce("building tex manual")
-            # Remove the target first such that its new mtime reflects
-            # this build.
-            if os.path.isfile(target): os.remove(target)
-            self.call_jade(jade,
-                           ['-D%s'%dtd, '-D%s'%stylesheets, '-o', 'manual.tex'],
-                           dcl, 'tex',
-                           os.path.normpath('qm/test/doc/manual.xml'),
-                           os.path.normpath('qm/test/doc'))
-
-            # Jade places the output TeX source file in the current directory,
-            # so move it where we want it afterwards.
-            # We have to change -- into -{-} so that TeX does not generate long 
-            # dashes.  This is a bug in Jade.
-            cwd = os.getcwd()
-            self.mkpath(self.build_temp + '/qm/test/doc/print')
-            os.chdir(os.path.normpath(self.build_temp + '/qm/test/doc'))
-            self.spawn(['sh', '-c',
-                        'sed -e "s|--|-{-}|g" < manual.tex > print/manual.tex'])
-            os.remove('manual.tex')
-            os.chdir(cwd)
-            if self.build_temp != self.build_lib:
-                src = os.path.normpath(self.build_temp + '/qm/test/doc/print/manual.tex')
-                dst = target
-                self.mkpath(os.path.dirname(dst))
-                copy_file(src, target,
-                          1, 1, 1, None, self.verbose, self.dry_run)
-
-        #
-        # Build pdf output.
-        #
-        target = os.path.normpath(self.build_lib + '/qm/test/doc/print/manual.pdf')
-        if newer_group(source_files, target):
-            self.announce("building pdf manual")
-            # Remove the target first such that its new mtime reflects
-            # this build.
-            if os.path.isfile(target): os.remove(target)
-            cwd = os.getcwd()
-            os.chdir(os.path.normpath(self.build_temp + '/qm/test/doc/print/'))
-            self.spawn(['pdfjadetex', 'manual.tex'])
-            self.spawn(['pdfjadetex', 'manual.tex'])
-            self.spawn(['pdfjadetex', 'manual.tex'])
-            os.chdir(cwd)
-            if self.build_temp != self.build_lib:
-                src = os.path.normpath(self.build_temp + '/qm/test/doc/print/manual.pdf')
-                dst = target
-                self.mkpath(os.path.dirname(dst))
-                copy_file(src, target,
-                          1, 1, 1, None, self.verbose, self.dry_run)
-
-        #
-        # Build reference manual via 'happydoc'.
-        #
-        happydoc = find_executable('happydoc')
-        if (happydoc):
-            self.announce("building reference manual")
-            spawn(['happydoc', 'qm'])
-
-class qm_build(build.build):
-    """Extends 'build' by adding support for building documentation."""
-
-    sub_commands = build.build.sub_commands[:] + [('build_doc', None)]
-
-class qm_install_data(install_data.install_data):
-    """Extends 'install_data' by generating a config module.
-
-    This module contains data only available at installation time,
-    such as installation paths for data files."""
-
-    def run(self):
-        """Run this command."""
-        
-        id = self.distribution.get_command_obj('install_data')
-        il = self.distribution.get_command_obj('install_lib')
-        install_data.install_data.run(self)
-        config = os.path.join(il.install_dir, 'qm/config.py')
-        self.announce("generating %s" %(config))
-        outf = open(config, "w")
-        outf.write("#the old way...\n")
-        outf.write("import os\n")
-        outf.write("os.environ['QM_HOME']='%s'\n"%(id.install_dir))
-        outf.write("os.environ['QM_BUILD']='0'\n")
-        outf.write("#the new way...\n")
-        outf.write("version='%s'\n"%(self.distribution.get_version()))
-        
-        outf.write("class config:\n")
-        outf.write("  data_dir='%s'\n"%(os.path.join(id.install_dir,
-                                                     'share',
-                                                     'qm')))
-        outf.write("\n")
+def prefix(list, pref): return map(lambda x, p=pref: p + x, list)
 
 packages=['qm',
           'qm/external',
@@ -261,9 +39,21 @@
 
 messages=['help.txt', 'diagnostics.txt']
 
-setup(cmdclass={'build_doc': qm_build_doc,
-                'build': qm_build,
-                'install_data': qm_install_data},
+html_docs = []
+print_docs = []
+
+if not os.path.isdir(os.path.normpath('qm/test/doc/html')):
+    print """Warning: to include documentation into the package please run
+         the \'build_doc\' command first."""
+
+else:
+    html_docs = filter(lambda f: f[-5:] == '.html',
+                       os.listdir(os.path.normpath('qm/test/doc/html')))
+    print_docs = ['manual.tex', 'manual.pdf']
+
+setup(cmdclass={'build_doc': build_doc,
+                #'build': qm_build,
+                'install_data': install_data},
       name="qm", 
       version="2.1",
       packages=packages,
@@ -273,7 +63,11 @@
                   ('share/qm/diagnostics',
                    prefix(diagnostics,'share/diagnostics/')),
                   ('share/qm/messages/test',
-                   prefix(messages,'qm/test/share/messages/'))])
+                   prefix(messages,'qm/test/share/messages/')),
+                  ('share/qm/doc/html',
+                   prefix(html_docs, 'qm/test/doc/html/')),
+                  ('share/qm/doc/print',
+                   prefix(print_docs, 'qm/test/doc/print/'))])
 
 ########################################################################
 # Local Variables:
