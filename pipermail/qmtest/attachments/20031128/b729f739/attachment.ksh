Index: qm/test/file_database.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/file_database.py,v
retrieving revision 1.19
diff -u -r1.19 file_database.py
--- qm/test/file_database.py	23 Jun 2003 06:46:47 -0000	1.19
+++ qm/test/file_database.py	28 Nov 2003 20:23:07 -0000
@@ -463,7 +463,7 @@
         if self._AreLabelsPaths():
             return label
 
-        path = os.path.join(self.GetLabelComponents(label))
+        return os.path.join(*self.GetLabelComponents(label))
 
 
 
