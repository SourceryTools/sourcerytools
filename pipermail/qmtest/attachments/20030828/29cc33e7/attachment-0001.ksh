--- setup.py	2003-08-28 00:35:02.000000000 -0400
+++ setup.py,new	2003-08-28 00:24:31.000000000 -0400
@@ -49,6 +49,8 @@
     has been made to make this code portable to other platforms such
     as 'nt'."""
 
+    description = "build documentation"
+
     def call_jade(self, jade, args, dcl, type, src, builddir):
         """Runs 'jade' in a subprocess to process a docbook file.
 
@@ -67,34 +69,22 @@
         # Use an absolute path so that calls to chdir do not invalidate
         # the name.
         src = os.path.abspath(src)
-        builddir = os.path.join(self.build_temp, builddir)
-        self.mkpath(builddir)
-        # the stylesheet defines the output dir, which is identical
-        # to the last component in 'builddir'. So we move one level
-        # up
-        os.chdir(os.path.dirname(builddir))
+        builddir = self.build_temp + '/' + builddir
+        if (type == 'sgml'):
+            # The stylesheet used for html output sets
+            # 'html' to be the output directory. Jade
+            # expects that to exist.
+            self.mkpath(builddir + '/html')
+        else:
+            self.mkpath(builddir)
+            
+        os.chdir(builddir)            
         cmd = [jade] + args + ['-t', type]
-        cmd += ['-d', os.path.join(cwd, 'doc', 'qm-%s.dsl'%type)]
-        if type == 'tex':
-            out = os.path.splitext(os.path.basename(src))[0] + '.tex'
-            cmd += ['-o', out]
+        cmd += ['-d', cwd + '/doc/qm-%s.dsl'%type]
         cmd += [dcl]
         cmd += [src]
+        self.announce(string.join(cmd, ' '))
         spawn(cmd)
-
-        if (type == 'sgml'):
-            tidy = find_executable('tidy')
-            if tidy:
-                for f in glob.glob('html/*.html'):
-                    spawn([tidy, '-wrap', '72', '-i', '--indent-spaces', '1',
-                           '-f', '/dev/null', '-asxml', '-modify', f])
-        elif (type == 'tex'):
-            # We have to change -- into -{-} so that TeX does not generate long 
-            # dashes.  This is a bug in Jade.
-            self.spawn(['sh', '-c',
-                        'sed -e "s|--|-{-}|g" < manual.tex > print/manual.tex'])
-            os.remove('manual.tex')
-
         os.chdir(cwd)
 
     def run(self):
@@ -125,45 +115,65 @@
                         os.path.isdir)
 
         if not jade or not dcl or not stylesheets or not dtd:
-            self.announce("can't build documentation")
+            self.warn("can't build documentation")
             return
 
         #
         # Build html output.
         #
-        self.announce("building html manual")
-        target = os.path.join(self.build_lib, 'qm/test/doc/html')
+        target = self.build_lib + '/qm/test/doc/html'
         if newer_group(source_files, target):
-            # remove first such that its mtime reflects this build
+            self.announce("building html manual")
+            # Remove the target first such that its new mtime reflects
+            # this build.
             if os.path.isdir(target): remove_tree(target)
             self.call_jade(jade, ['-D%s'%dtd, '-D%s'%stylesheets],
                            dcl, 'sgml',
                            'qm/test/doc/manual.xml',
-                           'qm/test/doc/html')
+                           'qm/test/doc')
+            tidy = find_executable('tidy')
+            if tidy:
+                for f in glob.glob(self.build_temp + '/qm/test/doc/html/*.html'):
+                    spawn([tidy,
+                           '-wrap', '72', '-i',
+                           '--indent-spaces', '1',
+                           '-f', '/dev/null',
+                           '-asxml', '-modify', f])
             if self.build_temp != self.build_lib:
-                src = os.path.join(self.build_temp, 'qm/test/doc/html')
+                src = self.build_temp + '/qm/test/doc/html'
                 dst = target
                 self.mkpath(dst)
-                copy_tree(src, dst, 1, 1, 0, 1, self.verbose, self.dry_run)
+                copy_tree(src, dst, 1, 1, 0, 1,
+                          self.verbose, self.dry_run)
 
         #
         # Build tex output.
         #
-        self.announce("building tex manual")
-        target = os.path.join(self.build_lib, 'qm/test/doc/print/manual.tex')
+        target = self.build_lib + '/qm/test/doc/print/manual.tex'
         if newer_group(source_files, target):
-            # remove first such that its mtime reflects this build
+            self.announce("building tex manual")
+            # Remove the target first such that its new mtime reflects
+            # this build.
             if os.path.isfile(target): os.remove(target)
-            # build tex output
-            # Jade places the output TeX source file in the current directory,
-            # so move it where we want it afterwards.
-            self.call_jade(jade, ['-D%s'%dtd, '-D%s'%stylesheets],
+            self.call_jade(jade,
+                           ['-D%s'%dtd, '-D%s'%stylesheets, '-o', 'manual.tex'],
                            dcl, 'tex',
                            'qm/test/doc/manual.xml',
-                           'qm/test/doc/print')
+                           'qm/test/doc')
 
+            # Jade places the output TeX source file in the current directory,
+            # so move it where we want it afterwards.
+            # We have to change -- into -{-} so that TeX does not generate long 
+            # dashes.  This is a bug in Jade.
+            cwd = os.getcwd()
+            self.mkpath(self.build_temp + '/qm/test/doc/print')
+            os.chdir(self.build_temp + '/qm/test/doc')
+            self.spawn(['sh', '-c',
+                        'sed -e "s|--|-{-}|g" < manual.tex > print/manual.tex'])
+            os.remove('manual.tex')
+            os.chdir(cwd)
             if self.build_temp != self.build_lib:
-                src = os.path.join(self.build_temp, 'qm/test/doc/print/manual.tex')
+                src = self.build_temp + '/qm/test/doc/print/manual.tex'
                 dst = target
                 self.mkpath(os.path.dirname(dst))
                 copy_file(src, target,
@@ -172,19 +182,20 @@
         #
         # Build pdf output.
         #
-        self.announce("building pdf manual")
-        target = os.path.join(self.build_lib, 'qm/test/doc/print/manual.pdf')
+        target = self.build_lib + '/qm/test/doc/print/manual.pdf'
         if newer_group(source_files, target):
-            # remove first such that its mtime reflects this build
+            self.announce("building pdf manual")
+            # Remove the target first such that its new mtime reflects
+            # this build.
             if os.path.isfile(target): os.remove(target)
             cwd = os.getcwd()
-            os.chdir(os.path.join(self.build_temp, 'qm/test/doc/print/'))
+            os.chdir(self.build_temp + '/qm/test/doc/print/')
             self.spawn(['pdfjadetex', 'manual.tex'])
             self.spawn(['pdfjadetex', 'manual.tex'])
             self.spawn(['pdfjadetex', 'manual.tex'])
             os.chdir(cwd)
             if self.build_temp != self.build_lib:
-                src = os.path.join(self.build_temp, 'qm/test/doc/print/manual.pdf')
+                src = self.build_temp + '/qm/test/doc/print/manual.pdf'
                 dst = target
                 self.mkpath(os.path.dirname(dst))
                 copy_file(src, target,
@@ -237,7 +248,8 @@
           'qm/test',
           'qm/test/web']
 
-classes= filter(lambda f: f[-3:] == '.py', os.listdir('qm/test/classes/'))
+classes= filter(lambda f: f[-3:] == '.py',
+                os.listdir(os.path.join('qm','test','classes')))
 classes.append('classes.qmc')
 
 diagnostics=['common.txt','common-help.txt']
