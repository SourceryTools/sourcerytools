Index: qm/test/cmdline.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/cmdline.py,v
retrieving revision 1.79
diff -u -r1.79 cmdline.py
--- qm/test/cmdline.py	3 Jan 2003 04:18:21 -0000	1.79
+++ qm/test/cmdline.py	4 Jan 2003 06:42:26 -0000
@@ -888,7 +888,8 @@
 
         # Figure out what kinds of extensions we're going to list.
         kind = self.GetCommandOption("kind")
-        kinds = ['test', 'resource', 'database', 'target']
+        global extension_kinds
+        kinds = extension_kinds
         if kind:
             if kind not in kinds:
                 raise qm.cmdline.CommandError, \
