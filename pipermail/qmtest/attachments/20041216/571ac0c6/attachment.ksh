Index: qm/test/web/web.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/web/web.py,v
retrieving revision 1.82
retrieving revision 1.83
diff -u -r1.82 -r1.83
--- qm/test/web/web.py	8 Feb 2004 20:54:41 -0000	1.82
+++ qm/test/web/web.py	16 Dec 2004 21:57:32 -0000	1.83
@@ -2006,12 +2006,12 @@
                 field_errors["_id"] = qm.error("invalid id", id=item_id)
             else:
                 # Check that the ID doesn't already exist.
-                if type is "resource":
+                if type == "resource":
                     if database.HasResource(item_id):
                         field_errors["_id"] \
                            = qm.error("resource already exists",
                                       resource_id=item_id)
-                elif type is "test":
+                elif type == "test":
                     if database.HasTest(item_id):
                         field_errors["_id"] = qm.error("test already exists",
                                                        test_id=item_id)
@@ -2040,21 +2040,21 @@
 
             # Construct a test with default argument values, as the
             # starting point for editing.
-            if type is "resource":
+            if type == "resource":
                 item = self.MakeNewResource(class_name, item_id)
-            elif type is "test":
+            elif type == "test":
                 item = self.MakeNewTest(class_name, item_id)
         else:
             # We're showing or editing an existing item.
             # Look it up in the database.
-            if type is "resource":
+            if type == "resource":
                 try:
                     item = database.GetResource(item_id)
                 except qm.test.database.NoSuchTestError, e:
                     # An test with the specified test ID was not fount.
                     # Show a page indicating the error.
                     return qm.web.generate_error_page(request, str(e))
-            elif type is "test":
+            elif type == "test":
                 try:
                     item = database.GetTest(item_id)
                 except qm.test.database.NoSuchResourceError, e:
@@ -2291,7 +2291,7 @@
                 field_errors[field_name] = message
                 redisplay = 1
 
-        if type is "test":
+        if type == "test":
             # Create a new test.
             item = TestDescriptor(
                     database,
@@ -2299,7 +2299,7 @@
                     test_class_name=item_class_name,
                     arguments=arguments)
 
-        elif type is "resource":
+        elif type == "resource":
             # Create a new resource.
             item = ResourceDescriptor(database, item_id,
                                       item_class_name, arguments)
