Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.418
diff -u -r1.418 ChangeLog
--- ChangeLog	22 Mar 2006 22:01:43 -0000	1.418
+++ ChangeLog	23 Mar 2006 15:05:18 -0000
@@ -1,3 +1,8 @@
+2006-03-23  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* tests/QMTest/vpp_database.py: Make 'parallel_service' a global
+	resource.
+
 2006-03-22  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* scripts/package: Rename variable to avoid naming collision.
Index: tests/QMTest/vpp_database.py
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/QMTest/vpp_database.py,v
retrieving revision 1.7
diff -u -r1.7 vpp_database.py
--- tests/QMTest/vpp_database.py	1 Mar 2006 16:36:48 -0000	1.7
+++ tests/QMTest/vpp_database.py	23 Mar 2006 15:05:18 -0000
@@ -197,12 +197,8 @@
             return None
 
         resources = ['compiler_table']
+        resources.append('parallel_service')
 
-        # Everything in the 'parallel' subdirectory requires
-        # some parallel service to be set up first:
-        if id_components[0] == 'parallel':
-            resources.append('parallel_service')
-            
         dirname = os.path.join(self.GetRoot(), *id_components[:-1])
         basename = id_components[-1]
 
