2004-10-28  Matthias Klose <doko@cs.tu-berlin.de>

	* qmdist/command/build_doc.py (build_doc.run): Use "openjade" if
	"jade" is not available.

Index: qmdist/command/build_doc.py
===================================================================
RCS file: /home/qm/Repository/qm/qmdist/command/build_doc.py,v
retrieving revision 1.5
diff -c -5 -p -r1.5 build_doc.py
*** qmdist/command/build_doc.py	24 May 2004 20:37:41 -0000	1.5
--- qmdist/command/build_doc.py	28 Oct 2004 22:33:23 -0000
*************** class build_doc(build.build):
*** 96,107 ****
          source_files = map(normpath,
                             ['qm/test/doc/manual.xml',
                              'qm/test/doc/introduction.xml',
                              'qm/test/doc/tour.xml',
                              'qm/test/doc/reference.xml'])
!         
!         jade = find_executable('jade')
          dcl = find_file(map(normpath,
                              ['/usr/share/doc/jade*/pubtext/xml.dcl',
                               '/usr/share/doc/openjade*/pubtext/xml.dcl',
                               '/usr/doc/jade*/pubtext/xml.dcl',
                               '/usr/share/sgml/declaration/xml.dcl']),
--- 96,110 ----
          source_files = map(normpath,
                             ['qm/test/doc/manual.xml',
                              'qm/test/doc/introduction.xml',
                              'qm/test/doc/tour.xml',
                              'qm/test/doc/reference.xml'])
! 
!         # Some versions of Jade are called "jade"; others are called
!         # "openjade".  We look for both forms.
!         jade = find_executable('jade') or find_executable('openjade')
! 
          dcl = find_file(map(normpath,
                              ['/usr/share/doc/jade*/pubtext/xml.dcl',
                               '/usr/share/doc/openjade*/pubtext/xml.dcl',
                               '/usr/doc/jade*/pubtext/xml.dcl',
                               '/usr/share/sgml/declaration/xml.dcl']),
