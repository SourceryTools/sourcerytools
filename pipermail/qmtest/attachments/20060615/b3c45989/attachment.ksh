Index: ChangeLog
===================================================================
RCS file: /home/qm/Repository/qm/ChangeLog,v
retrieving revision 1.705
diff -u -r1.705 ChangeLog
--- ChangeLog	2 Jun 2006 22:28:33 -0000	1.705
+++ ChangeLog	10 Jun 2006 02:20:12 -0000
@@ -1,3 +1,10 @@
+2006-06-09  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* qm/host.py: Fix signature of Host.Run(), and implement it
+	(using local_host.LocalHost.Run() code).
+	* qm/test/classes/local_host.py: Remove now obsolete Run() method.
+	* qm/test/classes/ssh_host.py: Derive from Host, not LocalHost.
+
 2006-06-02  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* qm/extension.py: Raise AttributeError instead of AssertionError when
Index: qm/host.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/host.py,v
retrieving revision 1.2
diff -u -r1.2 host.py
--- qm/host.py	1 Dec 2005 06:46:43 -0000	1.2
+++ qm/host.py	10 Jun 2006 02:20:12 -0000
@@ -59,7 +59,7 @@
 
 
 
-    def Run(self, arguments, environment = None, timeout = -1):
+    def Run(self, path, arguments, environment = None, timeout = -1):
         """Run a program on the remote host.
 
         'path' -- The name of the program to run, on the remote host.
@@ -88,7 +88,14 @@
         combined standard output and standard error output from the
         program.""" 
 
-        raise NotImplementedError
+        # Compute the full environment for the child.
+        if environment is not None:
+            new_environment = os.environ.copy()
+            new_environment.update(environment)
+            environment = new_environment
+        executable = self.Executable(timeout)
+        status = executable.Run([path] + arguments, environment)
+        return (status, executable.stdout)
 
 
     def UploadFile(self, local_file, remote_file = None):
Index: qm/test/classes/local_host.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/local_host.py,v
retrieving revision 1.3
diff -u -r1.3 local_host.py
--- qm/test/classes/local_host.py	1 Dec 2005 06:46:43 -0000	1.3
+++ qm/test/classes/local_host.py	10 Jun 2006 02:20:12 -0000
@@ -30,18 +30,6 @@
     The default directory for a 'LocalHost' is the current working
     directory for this Python process."""
 
-    def Run(self, path, arguments, environment = None, timeout = -1):
-
-        # Compute the full environment for the child.
-        if environment is not None:
-            new_environment = os.environ.copy()
-            new_environment.update(environment)
-            environment = new_environment
-        executable = self.Executable(timeout)
-        status = executable.Run([path] + arguments, environment)
-        return (status, executable.stdout)
-
-
     def UploadFile(self, local_file, remote_file = None):
 
         if remote_file is None:
Index: qm/test/classes/ssh_host.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/ssh_host.py,v
retrieving revision 1.1
diff -u -r1.1 ssh_host.py
--- qm/test/classes/ssh_host.py	10 Jun 2005 21:23:21 -0000	1.1
+++ qm/test/classes/ssh_host.py	10 Jun 2006 02:20:12 -0000
@@ -15,7 +15,7 @@
 # Imports
 #######################################################################
 
-from   local_host import LocalHost
+from   qm.host import Host
 import os
 import os.path
 from   qm.fields import TextField, SetField
@@ -26,7 +26,7 @@
 # Classes
 #######################################################################
 
-class SSHHost(LocalHost):
+class SSHHost(Host):
     """An 'SSHHost' is accessible via 'ssh' or a similar program."""
 
     # If not empty, the name of the remote host. 
