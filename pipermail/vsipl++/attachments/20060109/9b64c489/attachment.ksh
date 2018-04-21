Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.360
diff -r1.360 ChangeLog
0a1,5
> 2006-01-09 Jules Bergmann  <jules@codesourcery.com>
> 
> 	* tests/GNUmakefile.inc.in (check): Fix dependency on libs.
> 	* vendor/GNUmakefile.inc.in (install): Add dependency to vendor_LIBS.
> 
Index: tests/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/GNUmakefile.inc.in,v
retrieving revision 1.8
diff -r1.8 GNUmakefile.inc.in
27c27
< check::	libs $(tests_qmtest_extensions)
---
> check::	$(libs) $(tests_qmtest_extensions)
Index: vendor/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/vendor/GNUmakefile.inc.in,v
retrieving revision 1.9
diff -r1.9 GNUmakefile.inc.in
66c66
< install::
---
> install:: $(vendor_LIBS)
