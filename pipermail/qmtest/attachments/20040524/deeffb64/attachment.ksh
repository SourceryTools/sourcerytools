2004-05-24  Mark Mitchell  <mark@codesourcery.com>

	* GNUmakefile.in (distclean): Remove MANIFEST.
	* setup.py: Install documentation stylesheet.
	* doc/qm-sgml.dsl: Use documentation stylesheet.
	* doc/qm.css: Incorporate bits of CodeSourcery web site
	look-and-feel.
	* qmdist/command/build_doc.py (build_doc.run): Copy documentation
	stylesheet to HTML directory.

Index: GNUmakefile.in
===================================================================
RCS file: /home/qm/Repository/qm/GNUmakefile.in,v
retrieving revision 1.36
diff -c -5 -p -r1.36 GNUmakefile.in
*** GNUmakefile.in	6 May 2004 06:47:11 -0000	1.36
--- GNUmakefile.in	24 May 2004 20:26:46 -0000
*************** clean::
*** 85,94 ****
--- 85,95 ----
  	rm -rf qm/test/doc/print
  	rm -rf qm/test/doc/html
  
  distclean: clean
  	rm -f GNUmakefile config.cache config.status config.log
+ 	rm -f MANIFEST
  
  ########################################################################
  # Installation Rules
  ########################################################################
  
Index: MANIFEST.in
===================================================================
RCS file: /home/qm/Repository/qm/MANIFEST.in,v
retrieving revision 1.3
diff -c -5 -p -r1.3 MANIFEST.in
*** MANIFEST.in	24 Nov 2003 21:09:48 -0000	1.3
--- MANIFEST.in	24 May 2004 20:26:46 -0000
*************** recursive-include   qm *.py
*** 22,31 ****
--- 22,32 ----
  # This is the main executable.
  include             qm/test/qmtest
  # These are all docs, in (docbook) xml, html, tex, and pdf format.
  include             qm/test/doc/*.xml
  include             qm/test/doc/html/*.html
+ include		    qm/test/doc/html/*.css
  include             qm/test/doc/print/manual.pdf
  recursive-include   doc *
  # These are data files used by various parts of QMTest.
  include             qm/test/classes/classes.qmc
  recursive-include   qm/test/share *
Index: setup.py
===================================================================
RCS file: /home/qm/Repository/qm/setup.py,v
retrieving revision 1.11
diff -c -5 -p -r1.11 setup.py
*** setup.py	6 May 2004 00:35:35 -0000	1.11
--- setup.py	24 May 2004 20:26:46 -0000
*************** setup(name="qm", 
*** 129,139 ****
                     prefix(messages, 'qm/test/share/messages')),
                    # DTML files for the GUI.
                    ("qm/dtml/test", test_dtml_files),
                    # The documentation.
                    ('qm/doc', ('README', 'COPYING')),
!                   ('qm/doc/test/html', ['qm/test/doc/html/*.html']),
                    ('qm/doc/test/print', ["qm/test/doc/print/*.pdf"]),
                    # The tutorial.
                    ("qm/tutorial/test/tdb", tutorial_files),
                    ("qm/tutorial/test/tdb/QMTest",
                     ("qm/test/share/tutorial/tdb/QMTest/configuration",))]
--- 129,140 ----
                     prefix(messages, 'qm/test/share/messages')),
                    # DTML files for the GUI.
                    ("qm/dtml/test", test_dtml_files),
                    # The documentation.
                    ('qm/doc', ('README', 'COPYING')),
!                   ('qm/doc/test/html', ['qm/test/doc/html/*.html',
!                                         'qm/test/doc/html/qm.css']),
                    ('qm/doc/test/print', ["qm/test/doc/print/*.pdf"]),
                    # The tutorial.
                    ("qm/tutorial/test/tdb", tutorial_files),
                    ("qm/tutorial/test/tdb/QMTest",
                     ("qm/test/share/tutorial/tdb/QMTest/configuration",))]
Index: doc/qm-sgml.dsl
===================================================================
RCS file: /home/qm/Repository/qm/doc/qm-sgml.dsl,v
retrieving revision 1.3
diff -c -5 -p -r1.3 qm-sgml.dsl
*** doc/qm-sgml.dsl	4 Dec 2003 02:38:09 -0000	1.3
--- doc/qm-sgml.dsl	24 May 2004 20:26:46 -0000
***************
*** 37,46 ****
--- 37,50 ----
  (define %root-filename% "index")
  
  ;; Turn on Cascading Style Sheets markup in the resulting HTML.
  (define %css-decoration% #t)
  
+ ;; Use our stylesheet.
+ (define %stylesheet-type% "text/css")
+ (define %stylesheet% "qm.css")
+ 
  ;; Assign numbers to sections and subsections.
  (define %section-autolabel% #t)
  
  ;; Don't place the first section of each chapter in the same chunk as
  ;; the chapter head.
Index: doc/qm.css
===================================================================
RCS file: /home/qm/Repository/qm/doc/qm.css,v
retrieving revision 1.7
diff -c -5 -p -r1.7 qm.css
*** doc/qm.css	28 May 2002 01:37:53 -0000	1.7
--- doc/qm.css	24 May 2004 20:26:46 -0000
***************
*** 11,73 ****
  
    For license terms see the file COPYING.
  
  ***********************************************************************/
  
- /* Document body.  */
- 
- body {
-     margin-left: 10%;
-     margin-right: 10%;
-     color: black;
-     background: white;
- }
- 
- 
- /* Links.  */
- 
- :link {
-     color: blue;
-     background-color: white;
- }
- 
- :visited {
-     color: blue;
-     background-color: white;
- }
- 
- :active {
-     color: blue;
-     background-color: white;
-     text-decoration: none;
- }
- 
- :hover {
-     color: blue;
-     background-color: #ffccff;
-     text-decoration: none;
- }
- 
- 
  /* Headings.  Use
       <h1>...</h1> for titles.
       <h2>...</h2> for subtitles.
       <h3>...</h3> for chapter headings.
       <h4>...</h4> for section headings.
       <h5>...</h5> for subsection headings.
       <h6>...</h6> for subsubsection headings.  */
  
! h1 {
!     text-align: center;
! }
! 
! h2 {
!     margin-left: -8%;
! }
  
! h3,h4,h5,h6 {
!     margin-left: -4%;
  }
  
  
  /* Table of contents.  Place table of contents inside
       <div class="Contents">...</div> .  */
--- 11,35 ----
  
    For license terms see the file COPYING.
  
  ***********************************************************************/
  
  /* Headings.  Use
       <h1>...</h1> for titles.
       <h2>...</h2> for subtitles.
       <h3>...</h3> for chapter headings.
       <h4>...</h4> for section headings.
       <h5>...</h5> for subsection headings.
       <h6>...</h6> for subsubsection headings.  */
  
! /* Document body.  */
  
! body {
!     margin-left: 10%;
!     margin-right: 10%;
!     color: black;
!     background: white;
  }
  
  
  /* Table of contents.  Place table of contents inside
       <div class="Contents">...</div> .  */
*************** tr.Heading {
*** 186,190 ****
--- 148,224 ----
  span.Fixme {
      background-color: white;
      color: red;
  }
  
+ /***********************************************************************
+  CodeSourcery Styles
+ ***********************************************************************/
+ 
+ /***
+ 
+   The styles below this point are taken from:
+ 	
+     http://www.codesourcery.com/codesourcerystyles.css
+ 
+ ***/
+ 
+ h1 {
+ 	font-family: Verdana, Arial, Helvetica, sans-serif;
+ 	font-size: 14px;
+ 	font-weight: bold;
+ 	color: #757c96;
+ }
+ 
+ 
+ h1  {
+ 	margin-top: 2px;
+ 	margin-bottom: 0px;
+ 	padding-top: 2px;
+ 	padding-bottom: 0px;
+ }
+ 
+ h2 {
+ 	font-family: Verdana, Arial, Helvetica, sans-serif;
+ 	font-size: 10px;
+ 	font-style: normal;
+ 	font-weight: bold;
+ 	font-variant: normal;
+ 	text-transform: capitalize;
+ 	color: #333333;
+ 	margin-top: 2px;
+ 	margin-bottom: 2px;
+ 	padding-top: 2px;
+ 	padding-bottom: 2px;
+ }
+ 
+ h3 {
+ 	font-family: Verdana, Arial, Helvetica, sans-serif;
+ 	font-size: 10px;
+ 	font-weight: normal;
+ 	color: #000000;
+ 	font-style: italic;
+ 	margin-top: 3px;
+ 	margin-bottom: 3px;
+ 	padding-top: 3px;
+ 	padding-bottom: 3px;
+ }
+ 
+ a:hover {
+ 	color: #bdaa7a;
+ }
+ 
+ a {
+ 	font-family: Verdana, Arial, Helvetica, sans-serif;
+ 	font-size: 11px;
+ 	line-height: 16px;
+ 	font-weight: normal;
+         color: #3050c0;
+ 	text-decoration: none;
+ }
+ 
+ .code,.filename,.command,.symbol,.literal,.userinput,.screen,.classname,.property {
+ 	font-family: "Courier New", Courier, mono;
+ 	font-size: small;
+ 	font-weight: normal;
+ 	text-transform: none;
+ }
Index: qmdist/command/build_doc.py
===================================================================
RCS file: /home/qm/Repository/qm/qmdist/command/build_doc.py,v
retrieving revision 1.4
diff -c -5 -p -r1.4 build_doc.py
*** qmdist/command/build_doc.py	24 May 2004 15:54:32 -0000	1.4
--- qmdist/command/build_doc.py	24 May 2004 20:26:49 -0000
*************** from distutils.spawn import spawn, find_
*** 18,28 ****
  from distutils.dep_util import newer, newer_group
  from distutils.dir_util import copy_tree, remove_tree
  from distutils.file_util import copy_file
  import os
  import os.path
! from   os.path import normpath
  import string
  import glob
  
  def find_file(paths, predicate):
      """Return a file satisfying 'predicate' from 'paths'.
--- 18,28 ----
  from distutils.dep_util import newer, newer_group
  from distutils.dir_util import copy_tree, remove_tree
  from distutils.file_util import copy_file
  import os
  import os.path
! from   os.path import join, normpath
  import string
  import glob
  
  def find_file(paths, predicate):
      """Return a file satisfying 'predicate' from 'paths'.
*************** class build_doc(build.build):
*** 156,165 ****
--- 156,167 ----
                      spawn([tidy,
                             '-wrap', '72', '-i',
                             '--indent-spaces', '1',
                             '-f', '/dev/null',
                             '-asxml', '-modify', f])
+             # Copy the appropriate stylseheet into the HTML directory.
+             copy_file(join("doc", "qm.css"), join(html_dir, "qm.css"))
  
          target = normpath("qm/test/doc/print/manual.tex")
          if newer_group(source_files, target):
              self.announce("building tex manual")
              # Remove the target first such that its new mtime reflects
