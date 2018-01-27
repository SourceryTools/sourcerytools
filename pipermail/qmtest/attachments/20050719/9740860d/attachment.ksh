2005-07-19  Mark Mitchell  <mark@codesourcery.com>

	* qmdist/command/build_doc.py (find_file): Remove.
	(build_doc.user_options): New variable.
	(build_doc.xml_dcl_paths): Likewise.
	(build_doc.dtd_dirs): Likewise.
	(build_doc.stylesheet_dirs): Likewise.
	(build_doc.initialize_options): New function.
	(build_doc.finalize_options): Likewise.
	(build_doc.call_jade): Remove dcl parameter.  Use Jade options
	provided by the user.
	(build_doc.run): Honor user direction regarding what
	documentation to build.
	(build_doc.find_file): New function.

Index: qmdist/command/build_doc.py
===================================================================
RCS file: /home/qm/Repository/qm/qmdist/command/build_doc.py,v
retrieving revision 1.6
diff -c -5 -p -r1.6 build_doc.py
*** qmdist/command/build_doc.py	28 Oct 2004 22:34:02 -0000	1.6
--- qmdist/command/build_doc.py	19 Jul 2005 22:08:02 -0000
*************** import os
*** 22,65 ****
  import os.path
  from   os.path import join, normpath
  import string
  import glob
  
- def find_file(paths, predicate):
-     """Return a file satisfying 'predicate' from 'paths'.
- 
-     'paths' -- A sequence of glob patterns.
- 
-     'predicate' -- A callable taking a single string as an argument.
- 
-     returns -- The name of the first file matching one of the 'paths'
-     and 'predicate'."""
-     for path in paths:
-         matches = filter(predicate, glob.glob(path))
-         if matches:
-             return matches[0]
-     return None
- 
- 
  class build_doc(build.build):
      """Defines the specific procedure to build QMTest's documentation.
  
      As this command is only ever used on 'posix' platforms, no effort
      has been made to make this code portable to other platforms such
      as 'nt'."""
  
      description = "build documentation"
  
!     def call_jade(self, jade, args, dcl, type, src, builddir):
          """Runs 'jade' in a subprocess to process a docbook file.
  
          'jade' -- The jade executable with its full path.
  
          'args' -- A sequence of arguments to be passed.
  
-         'dcl' -- An sgml declaration file for xml.
- 
          'type' -- The output type to be generated.
  
          'src' -- The xml (master) source file to be processed.
  
          'builddir' -- The directory from which to call jade."""
--- 22,145 ----
  import os.path
  from   os.path import join, normpath
  import string
  import glob
  
  class build_doc(build.build):
      """Defines the specific procedure to build QMTest's documentation.
  
      As this command is only ever used on 'posix' platforms, no effort
      has been made to make this code portable to other platforms such
      as 'nt'."""
  
      description = "build documentation"
  
!     user_options = [
!         ("html", None, "generate HTML documentation"),
!         ("no-html", None, "do not generate HTML documentation"),
!         ("pdf", None, "generate PDF documentation"),
!         ("no-pdf", None, "do not generate PDF documentation"),
!         ("internal", None, "generate internal documentation"),
!         ("no-internal", None, "do not generate internal documentation"),
!         
!         ("jadeopts=", None, "options to pass to Jade"),
!         ("xmldcl=", None, "path to xml.dcl"),
!         ("dtddir=", None, "path to DocBook DTD directory"),
!         ("stydir=", None, "path to DSSSL stylesheet directory"),
!         ]
! 
!     boolean_options = [ "html", "pdf", "internal" ]
!     negative_opt = { "no-html" : "html",
!                      "no-pdf" : "pdf",
!                      "no-internal" : "internal" }
!     
!     xml_dcl_paths = (
!         # Debian Sarge
!         '/usr/share/xml/declaration/xml.dcl',
!         # Debian Sarge
!         '/usr/share/sgml/declaration/xml.dcl',
!         # Red Hat 8.0, RHEL 3
!         '/usr/share/sgml/xml.dcl',
!         # Cygwin
!         '/usr/share/OpenSP/xml.dcl',
!     )
!     """Paths to search for the SGML declaration of XML.
! 
!     The paths used to locate the SGML declaration of XML.  These paths
!     are searched in the order listed."""
!     
!     dtd_dirs = (
!         '/usr/lib/sgml',
!         # Debian Sarge
!         # Red Hat 8.0, RHEL 3
!         '/usr/share/sgml/docbook',
!         # Cygwin
!         '/usr/share/xml/docbook'
!         )
!     """Directories to search for the DocBook DTD.
! 
!     A list of directories searched for the DocBook DTD.  The
!     directories are searched in the order listed."""
!     
!     stylesheet_dirs = (
!         '/usr/lib/sgml/stylesheets/docbook',
!         '/usr/lib/sgml/stylesheets/dsssl/docbook',
!         # Red Hat 8.0, RHEL 3
!         '/usr/share/sgml/docbook/dsssl-stylesheets',
!         # Debian Sarge
!         '/usr/share/sgml/docbook/stylesheet/dsssl/modular'
!         )
!     """Directories to search for the DSSSL stylesheets.
! 
!     A list of directories searched for the DSSSL stylesheets.  The
!     directories are searched in the order listed."""
! 
!     def initialize_options(self):
! 
!         self.html = True
!         self.pdf = True
!         self.internal = True
!         
!         self.jadeopts = None
!         self.xmldcl = None
!         self.dtddir = None
!         self.stydir = None
!         
!         build.build.initialize_options(self)
!         
! 
!     def finalize_options(self):
! 
!         # Look for programs and supporting libraries required to build
!         # DocBook documentation.  Unfortunately, different
!         # distributions use different paths for the various key
!         # components.  We allow the user to tell us where to look on
!         # the command line.  If they do not provide a hint, then we
!         # look in locations known to be in use on various systems.
!         if not self.xmldcl:
!             self.xmldcl = self.find_file(map(normpath, self.xml_dcl_paths),
!                                          os.path.isfile,
!                                          "xml.dcl")
!         if not self.dtddir:
!             self.dtddir = self.find_file(map(normpath, self.dtd_dirs),
!                                          os.path.isdir,
!                                          "DocBook DTD")
!         if not self.stydir:
!             self.stydir = self.find_file(map(normpath, self.stylesheet_dirs),
!                                          os.path.isdir,
!                                          "DSSSL stylesheets")
!             
!         build.build.finalize_options(self)
!         
!         
!     def call_jade(self, jade, args, type, src, builddir):
          """Runs 'jade' in a subprocess to process a docbook file.
  
          'jade' -- The jade executable with its full path.
  
          'args' -- A sequence of arguments to be passed.
  
          'type' -- The output type to be generated.
  
          'src' -- The xml (master) source file to be processed.
  
          'builddir' -- The directory from which to call jade."""
*************** class build_doc(build.build):
*** 76,88 ****
          else:
              self.mkpath(builddir)
  
          cwd = os.getcwd()
          os.chdir(builddir)            
!         cmd = [jade] + args + ['-t', type]
          cmd += ['-d', os.path.join(cwd, 'doc', 'qm-%s.dsl'%type)]
!         cmd += [dcl]
          cmd += [src]
          self.announce(string.join(cmd, ' '))
          spawn(cmd)
          os.chdir(cwd)
  
--- 156,173 ----
          else:
              self.mkpath(builddir)
  
          cwd = os.getcwd()
          os.chdir(builddir)            
!         cmd = [jade]
!         cmd += ['-D' + self.dtddir, '-D' + self.stydir]
!         cmd += args
!         cmd += ['-t', type]
!         if self.jadeopts:
!             cmd += self.jadeopts.split()
          cmd += ['-d', os.path.join(cwd, 'doc', 'qm-%s.dsl'%type)]
!         cmd += [self.xmldcl]
          cmd += [src]
          self.announce(string.join(cmd, ' '))
          spawn(cmd)
          os.chdir(cwd)
  
*************** class build_doc(build.build):
*** 91,129 ****
          """Run this command, i.e. do the actual document generation.
  
          As this command requires 'jade', it will do nothing if
          that couldn't be found in the default path."""
  
          source_files = map(normpath,
                             ['qm/test/doc/manual.xml',
                              'qm/test/doc/introduction.xml',
                              'qm/test/doc/tour.xml',
                              'qm/test/doc/reference.xml'])
  
!         # Some versions of Jade are called "jade"; others are called
!         # "openjade".  We look for both forms.
          jade = find_executable('jade') or find_executable('openjade')
  
!         dcl = find_file(map(normpath,
!                             ['/usr/share/doc/jade*/pubtext/xml.dcl',
!                              '/usr/share/doc/openjade*/pubtext/xml.dcl',
!                              '/usr/doc/jade*/pubtext/xml.dcl',
!                              '/usr/share/sgml/declaration/xml.dcl']),
!                         os.path.isfile)
! 
!         stylesheets = find_file(map(normpath,
!                                     ['/usr/lib/sgml/stylesheets/docbook',
!                                      '/usr/lib/sgml/stylesheets/dsssl/docbook',
!                                      '/usr/share/sgml/docbook/dsssl-stylesheets']),
!                                 os.path.isdir)
! 
!         dtd = find_file(map(normpath,
!                             ['/usr/lib/sgml',
!                              '/usr/share/sgml/docbook']),
!                         os.path.isdir)
! 
!         if not jade or not dcl or not stylesheets or not dtd:
              self.warn("cannot build documentation")
              return
  
          # All files that are generated below are generated in the
          # source tree.  That is the only way that Distutils will
--- 176,207 ----
          """Run this command, i.e. do the actual document generation.
  
          As this command requires 'jade', it will do nothing if
          that couldn't be found in the default path."""
  
+         # If the user has not requested that we build any
+         # documentation, just skip it.
+         if not self.html and not self.pdf:
+             return
+         
          source_files = map(normpath,
                             ['qm/test/doc/manual.xml',
                              'qm/test/doc/introduction.xml',
                              'qm/test/doc/tour.xml',
                              'qm/test/doc/reference.xml'])
  
!         # Look for programs and supporting libraries required to build
!         # DocBook documentation.  Unfortunately, different
!         # distributions use different paths for the various key
!         # components.  We allow the user to tell us where to look on
!         # the command line.  If they do not provide a hint, then we
!         # look in locations known to be in use on various systems.
          jade = find_executable('jade') or find_executable('openjade')
+         if not jade:
+             self.warn("could not find jade or openjade in PATH")
  
!         if not jade or not self.xmldcl or not self.stydir or not self.dtddir:
              self.warn("cannot build documentation")
              return
  
          # All files that are generated below are generated in the
          # source tree.  That is the only way that Distutils will
*************** class build_doc(build.build):
*** 141,213 ****
          f.close()
  
          #
          # Build html output.
          #
!         html_dir = os.path.join("qm", "test", "doc", "html")
!         if newer_group(source_files, html_dir):
!             self.announce("building html manual")
!             # Remove the html_dir first such that its new mtime reflects
!             # this build.
!             if os.path.isdir(html_dir): remove_tree(html_dir)
!             self.call_jade(jade, ['-D%s'%dtd, '-D%s'%stylesheets],
!                            dcl, 'sgml',
!                            normpath('qm/test/doc/manual.xml'),
!                            normpath('qm/test/doc'))
!             tidy = find_executable('tidy')
!             if tidy:
!                 for f in glob.glob(normpath('/qm/test/doc/html/*.html')):
!                     spawn([tidy,
!                            '-wrap', '72', '-i',
!                            '--indent-spaces', '1',
!                            '-f', '/dev/null',
!                            '-asxml', '-modify', f])
!             # Copy the appropriate stylseheet into the HTML directory.
!             copy_file(join("doc", "qm.css"), join(html_dir, "qm.css"))
! 
!         target = normpath("qm/test/doc/print/manual.tex")
!         if newer_group(source_files, target):
!             self.announce("building tex manual")
!             # Remove the target first such that its new mtime reflects
!             # this build.
!             if os.path.isfile(target): os.remove(target)
!             self.call_jade(jade,
!                            ['-D%s'%dtd, '-D%s'%stylesheets, '-o',
!                             'manual.tex'],
!                            dcl, 'tex',
!                            normpath('qm/test/doc/manual.xml'),
!                            normpath('qm/test/doc'))
! 
!             # Jade places the output TeX source file in the current
!             # directory, so move it where we want it afterwards.  We have
!             # to change -- into -{-} so that TeX does not generate long
!             # dashes.  This is a bug in Jade.
!             orig_tex_manual = normpath("qm/test/doc/manual.tex")
!             self.mkpath(normpath("qm/test/doc/print"))
!             self.spawn(['sh', '-c',
!                         ('sed -e "s|--|-{-}|g" < %s > %s'
!                          % (orig_tex_manual,
!                             normpath("qm/test/doc/print/manual.tex")))])
!             os.remove(orig_tex_manual)
  
          #
          # Build pdf output.
          #
!         pdf_file = os.path.join("qm", "test", "doc", "print", "manual.pdf")
!         if newer_group(source_files, pdf_file):
!             self.announce("building pdf manual")
!             # Remove the pdf_file first such that its new mtime reflects
!             # this build.
!             if os.path.isfile(pdf_file): os.remove(pdf_file)
!             cwd = os.getcwd()
!             os.chdir("qm/test/doc/print")
!             for i in xrange(3):
!                 self.spawn(['pdfjadetex', "manual.tex"])
!             os.chdir(cwd)
  
          #
          # Build reference manual via 'happydoc'.
          #
!         happydoc = find_executable('happydoc')
!         if (happydoc):
!             self.announce("building reference manual")
!             spawn(['happydoc', 'qm'])
--- 219,314 ----
          f.close()
  
          #
          # Build html output.
          #
!         if self.html:
!             html_dir = os.path.join("qm", "test", "doc", "html")
!             if newer_group(source_files, html_dir):
!                 self.announce("building html manual")
!                 # Remove the html_dir first such that its new mtime reflects
!                 # this build.
!                 if os.path.isdir(html_dir): remove_tree(html_dir)
!                 self.call_jade(jade, [], 'sgml',
!                                normpath('qm/test/doc/manual.xml'),
!                                normpath('qm/test/doc'))
!                 tidy = find_executable('tidy')
!                 if tidy:
!                     for f in glob.glob(normpath('/qm/test/doc/html/*.html')):
!                         spawn([tidy,
!                                '-wrap', '72', '-i',
!                                '--indent-spaces', '1',
!                                '-f', '/dev/null',
!                                '-asxml', '-modify', f])
!                 # Copy the appropriate stylseheet into the HTML directory.
!                 copy_file(join("doc", "qm.css"), join(html_dir, "qm.css"))
  
          #
          # Build pdf output.
          #
!         if self.pdf:
!             target = normpath("qm/test/doc/print/manual.tex")
!             if newer_group(source_files, target):
!                 self.announce("building tex manual")
!                 # Remove the target first such that its new mtime reflects
!                 # this build.
!                 if os.path.isfile(target): os.remove(target)
!                 self.call_jade(jade, ['-o','manual.tex'], 'tex',
!                                normpath('qm/test/doc/manual.xml'),
!                                normpath('qm/test/doc'))
! 
!                 # Jade places the output TeX source file in the current
!                 # directory, so move it where we want it afterwards.  We have
!                 # to change -- into -{-} so that TeX does not generate long
!                 # dashes.  This is a bug in Jade.
!                 orig_tex_manual = normpath("qm/test/doc/manual.tex")
!                 self.mkpath(normpath("qm/test/doc/print"))
!                 self.spawn(['sh', '-c',
!                             ('sed -e "s|--|-{-}|g" < %s > %s'
!                              % (orig_tex_manual,
!                                 normpath("qm/test/doc/print/manual.tex")))])
!                 os.remove(orig_tex_manual)
! 
!             pdf_file = os.path.join("qm", "test", "doc", "print", "manual.pdf")
!             if newer_group(source_files, pdf_file):
!                 self.announce("building pdf manual")
!                 # Remove the pdf_file first such that its new mtime reflects
!                 # this build.
!                 if os.path.isfile(pdf_file): os.remove(pdf_file)
!                 cwd = os.getcwd()
!                 os.chdir("qm/test/doc/print")
!                 for i in xrange(3):
!                     self.spawn(['pdfjadetex', "manual.tex"])
!                 os.chdir(cwd)
  
          #
          # Build reference manual via 'happydoc'.
          #
!         if self.internal:
!             happydoc = find_executable('happydoc')
!             if (happydoc):
!                 self.announce("building reference manual")
!                 spawn(['happydoc', 'qm'])
! 
! 
!     def find_file(self, paths, predicate, description):
!         """Return a file satisfying 'predicate' from 'paths'.
! 
!         'paths' -- A sequence of glob patterns.
!         
!         'predicate' -- A callable taking a single string as an argument.
!         
!         returns -- The name of the first file matching one of the 'paths'
!         and 'predicate'."""
! 
!         for path in paths:
!             matches = filter(predicate, glob.glob(path))
!             if matches:
!                 return matches[0]
! 
!         self.warn("could not find %s in:" % description)
!         for p in paths:
!             self.warn("  " + p)
!             
!         return None
! 
! 
