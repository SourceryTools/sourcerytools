Index: qm/test/base.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/base.py,v
retrieving revision 1.77
diff -u -r1.77 base.py
--- qm/test/base.py	17 Oct 2002 20:38:15 -0000	1.77
+++ qm/test/base.py	21 Oct 2002 13:15:12 -0000
@@ -33,6 +33,7 @@
 import sys
 import tempfile
 import types
+import exceptions
 
 ########################################################################
 # constants
@@ -327,6 +328,13 @@
     try:
         klass = qm.common.load_class(class_name, [directory],
                                      path + sys.path)
+    except exceptions.SyntaxError, e:
+        raise PythonException, \
+              (qm.error("syntax error in extension module",
+                        module=e.filename, line=e.lineno, offset=e.offset),
+               sys.exc_info()[0],
+               sys.exc_info()[1]), \
+               sys.exc_info()[2]                              
     except:
         raise PythonException, \
               (qm.error("extension class not found",
Index: qm/test/share/messages/diagnostics.txt
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/share/messages/diagnostics.txt,v
retrieving revision 1.9
diff -u -r1.9 diagnostics.txt
--- qm/test/share/messages/diagnostics.txt	11 Oct 2002 20:23:26 -0000	1.9
+++ qm/test/share/messages/diagnostics.txt	21 Oct 2002 13:15:12 -0000
@@ -194,6 +194,9 @@
 @ suite already exists
 There is already a test suite with ID "%(suite_id)s".
 
+@ syntax error in extension module 
+Syntax error in extension module %(module)s, at line %(line)d, column %(offset)d.
+
 @ test already exists
 There is already a test with ID "%(test_id)s".
 
