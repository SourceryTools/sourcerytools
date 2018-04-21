Index: qm/test/cmdline.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/cmdline.py,v
retrieving revision 1.73
diff -u -r1.73 cmdline.py
--- qm/test/cmdline.py	11 Oct 2002 20:23:25 -0000	1.73
+++ qm/test/cmdline.py	22 Oct 2002 09:49:00 -0000
@@ -1186,7 +1186,12 @@
         except ValueError, exception:
             raise qm.cmdline.CommandError, \
                   qm.error("no such ID", id=str(exception))
-
+        except PythonException, pe:
+            self._stderr.write(qm.common.format_exception
+                               ((pe.exc_type, pe.exc_value,
+                                 sys.exc_info()[2])))
+            raise
+            
         # Filter the set of tests to be run, eliminating any that should
         # be skipped.
         test_ids = self.__FilterTestsToRun(test_ids, expectations)
