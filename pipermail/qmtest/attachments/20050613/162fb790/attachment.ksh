Index: qm/host.py
===================================================================
RCS file: qm/host.py
diff -N qm/host.py
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- qm/host.py	13 Jun 2005 21:53:48 -0000
***************
*** 0 ****
--- 1,159 ----
+ ########################################################################
+ #
+ # File:   host.py
+ # Author: Mark Mitchell
+ # Date:   2005-06-03
+ #
+ # Contents:
+ #   Host
+ #
+ # Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. 
+ #
+ ########################################################################
+ 
+ ########################################################################
+ # Imports
+ #######################################################################
+ 
+ from   qm.executable import RedirectedExecutable
+ from   qm.extension import Extension
+ import os.path
+ 
+ ########################################################################
+ # Classes
+ #######################################################################
+ 
+ class Host(Extension):
+     """A 'Host' is a logical machine.
+ 
+     Each logical machine has a default directory.  When a file is
+     uploaded to or downloaded from the machine, and a relative patch
+     is specified, the patch is relative to the default directory.
+     Similarly, when a program is run on the remote machine, its
+     initial working directory is the default directory.
+ 
+     The interface presented by 'Host' is a lowest common
+     denominator.  The objective is not to expose all the functionality
+     of any host; rather it is to provide an interface that can be used
+     on many hosts."""
+ 
+     kind = "host"
+     
+     class Executable(RedirectedExecutable):
+         """An 'Executable' is a simple redirected executable.
+ 
+         The standard error and standard output streams are combined
+         into a single stream.
+ 
+         The standard input is not closed before
+         invoking the program because SSH hangs if its standard input
+         is closed before it is invoked.  For example, running:
+ 
+            ssh machine echo hi <&-
+ 
+         will hang with some versions of SSH."""     
+ 
+         def _StderrPipe(self):
+ 
+             return None
+ 
+ 
+ 
+     def Run(self, arguments, environment = None, timeout = -1):
+         """Run a program on the remote host.
+ 
+         'path' -- The name of the program to run, on the remote host.
+         If 'path' is an absolute path or contains no directory
+         separators it is used unmodified; otherwise (i.e., if it is a
+         relative path containing at least one separator) it is
+         interpreted relative to the default directory.
+         
+         'arguments' -- The sequence of arguments that should be passed
+         to the program.
+ 
+         'environment' -- If not 'None', a dictionary of pairs of
+         strings to add to the environment of the running program.
+         
+         'timeout' -- The number of seconds the program is permitted
+         to execute.  After the 'timeout' expires, the program will be
+         terminated.  However, in some cases (such as when using 'rsh')
+         it will be the local side of the connection that is closed.
+         The remote side of the connection may or may not continue to
+         operate, depending on the vagaries of the remote operating
+         system.
+         
+         returns -- A pair '(status, output)'.  The 'status' is the
+         exit status returned by the program, or 'None' if the exit
+         status is not available.  The 'output' is a string giving the
+         combined standard output and standard error output from the
+         program.""" 
+ 
+         raise NotImplementedError
+ 
+ 
+     def UploadFile(self, local_file, remote_file = None):
+         """Copy 'local_file' to 'remote_file'.
+ 
+         'local_file' -- The name of the file on the local machine.
+ 
+         'remote_file' -- The name of the file on the remote machine.
+         The 'remote_file' must be a relative path.  It is interpreted
+         relative to the default directory.  If 'None', the
+         'remote_file' is placed in the default directory using the
+         basename of the 'local_file'.
+ 
+         If the 'local_file' and 'remote_file' are the same, then this
+         function succeeds, but takes no action."""
+ 
+         raise NotImplementedError
+ 
+ 
+     def DownloadFile(self, remote_file, local_file):
+         """Copy 'remote_file' to 'local_file'.
+ 
+         'remote_file' -- The name of the file on the remote machine.
+         The 'remote_file' must be a relative path.  It is interpreted
+         relative to the default directory.
+ 
+         'local_file' -- The name of the file on the local machine.  If
+         'None', the 'local_file' is placed in the current directory
+         using the basename of the 'remote_file'.
+ 
+         If the 'local_file' and 'remote_file' are the same, then this
+         function succeeds, but takes no action."""
+ 
+         raise NotImplementedError
+ 
+ 
+     def UploadAndRun(self, path, arguments, environment = None,
+                      timeout = -1):
+         """Run a program on the remote host.
+ 
+         'path' -- The name of the program to run, as a path on the
+         local machine.
+ 
+         'arguments' -- As for 'Run'.
+ 
+         'environment' -- As for 'Run'.
+         
+         'timeout' -- As for 'Run'.
+ 
+         returns -- As for 'Run'.
+ 
+         The program is uploaded to the default directory on the remote
+         host.""" 
+         
+         self.UploadFile(path)
+         return self.Run(os.path.join(os.path.curdir,
+                                      os.path.basename(path)),
+                         arguments,
+                         environment,
+                         timeout)
+         
+         
+     def DeleteFile(self, remote_file):
+         """Delete the 'remote_file'.
+ 
+         'remote_file' -- A relative path to the file to be deleted."""
+ 
+         raise NotImplementedError
Index: qm/remote_host.py
===================================================================
RCS file: qm/remote_host.py
diff -N qm/remote_host.py
*** qm/remote_host.py	10 Jun 2005 21:23:20 -0000	1.1
--- /dev/null	1 Jan 1970 00:00:00 -0000
***************
*** 1,159 ****
- ########################################################################
- #
- # File:   remote_host.py
- # Author: Mark Mitchell
- # Date:   2005-06-03
- #
- # Contents:
- #   RemoteHost
- #
- # Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. 
- #
- ########################################################################
- 
- ########################################################################
- # Imports
- #######################################################################
- 
- from   qm.executable import RedirectedExecutable
- from   qm.extension import Extension
- import os.path
- 
- ########################################################################
- # Classes
- #######################################################################
- 
- class RemoteHost(Extension):
-     """A 'RemoteHost' is a logical machine.
- 
-     Each logical machine has a default directory.  When a file is
-     uploaded to or downloaded from the machine, and a relative patch
-     is specified, the patch is relative to the default directory.
-     Similarly, when a program is run on the remote machine, its
-     initial working directory is the default directory.
- 
-     The interface presented by 'RemoteHost' is a lowest common
-     denominator.  The objective is not to expose all the functionality
-     of any host; rather it is to provide an interface that can be used
-     on many hosts."""
- 
-     kind = "remote_host"
-     
-     class Executable(RedirectedExecutable):
-         """An 'Executable' is a simple redirected executable.
- 
-         The standard error and standard output streams are combined
-         into a single stream.
- 
-         The standard input is not closed before
-         invoking the program because SSH hangs if its standard input
-         is closed before it is invoked.  For example, running:
- 
-            ssh machine echo hi <&-
- 
-         will hang with some versions of SSH."""     
- 
-         def _StderrPipe(self):
- 
-             return None
- 
- 
- 
-     def Run(self, arguments, environment = None, timeout = -1):
-         """Run a program on the remote host.
- 
-         'path' -- The name of the program to run, on the remote host.
-         If 'path' is an absolute path or contains no directory
-         separators it is used unmodified; otherwise (i.e., if it is a
-         relative path containing at least one separator) it is
-         interpreted relative to the default directory.
-         
-         'arguments' -- The sequence of arguments that should be passed
-         to the program.
- 
-         'environment' -- If not 'None', a dictionary of pairs of
-         strings to add to the environment of the running program.
-         
-         'timeout' -- The number of seconds the program is permitted
-         to execute.  After the 'timeout' expires, the program will be
-         terminated.  However, in some cases (such as when using 'rsh')
-         it will be the local side of the connection that is closed.
-         The remote side of the connection may or may not continue to
-         operate, depending on the vagaries of the remote operating
-         system.
-         
-         returns -- A pair '(status, output)'.  The 'status' is the
-         exit status returned by the program, or 'None' if the exit
-         status is not available.  The 'output' is a string giving the
-         combined standard output and standard error output from the
-         program.""" 
- 
-         raise NotImplementedError
- 
- 
-     def UploadFile(self, local_file, remote_file = None):
-         """Copy 'local_file' to 'remote_file'.
- 
-         'local_file' -- The name of the file on the local machine.
- 
-         'remote_file' -- The name of the file on the remote machine.
-         The 'remote_file' must be a relative path.  It is interpreted
-         relative to the default directory.  If 'None', the
-         'remote_file' is placed in the default directory using the
-         basename of the 'local_file'.
- 
-         If the 'local_file' and 'remote_file' are the same, then this
-         function succeeds, but takes no action."""
- 
-         raise NotImplementedError
- 
- 
-     def DownloadFile(self, remote_file, local_file):
-         """Copy 'remote_file' to 'local_file'.
- 
-         'remote_file' -- The name of the file on the remote machine.
-         The 'remote_file' must be a relative path.  It is interpreted
-         relative to the default directory.
- 
-         'local_file' -- The name of the file on the local machine.  If
-         'None', the 'local_file' is placed in the current directory
-         using the basename of the 'remote_file'.
- 
-         If the 'local_file' and 'remote_file' are the same, then this
-         function succeeds, but takes no action."""
- 
-         raise NotImplementedError
- 
- 
-     def UploadAndRun(self, path, arguments, environment = None,
-                      timeout = -1):
-         """Run a program on the remote host.
- 
-         'path' -- The name of the program to run, as a path on the
-         local machine.
- 
-         'arguments' -- As for 'Run'.
- 
-         'environment' -- As for 'Run'.
-         
-         'timeout' -- As for 'Run'.
- 
-         returns -- As for 'Run'.
- 
-         The program is uploaded to the default directory on the remote
-         host.""" 
-         
-         self.UploadFile(path)
-         return self.Run(os.path.join(os.path.curdir,
-                                      os.path.basename(path)),
-                         arguments,
-                         environment,
-                         timeout)
-         
-         
-     def DeleteFile(self, remote_file):
-         """Delete the 'remote_file'.
- 
-         'remote_file' -- A relative path to the file to be deleted."""
- 
-         raise NotImplementedError
--- 0 ----
Index: qm/test/base.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/base.py,v
retrieving revision 1.99
diff -c -5 -p -r1.99 base.py
*** qm/test/base.py	10 Jun 2005 21:23:20 -0000	1.99
--- qm/test/base.py	13 Jun 2005 21:53:48 -0000
*************** def _result_from_dom(node):
*** 386,407 ****
  # variables
  ########################################################################
  
  import qm.test.database
  import qm.label
! import qm.remote_host
  import qm.test.resource
  import qm.test.result_reader
  import qm.test.result_stream
  import qm.test.suite
  import qm.test.target
  import qm.test.test
  
  __extension_bases = {
      'database' : qm.test.database.Database,
      'label' : qm.label.Label,
-     'remote_host' : qm.remote_host.RemoteHost,
      'resource' : qm.test.resource.Resource,
      'result_reader' : qm.test.result_reader.ResultReader,
      'result_stream' : qm.test.result_stream.ResultStream,
      'suite' : qm.test.suite.Suite,
      'target' : qm.test.target.Target,
--- 386,407 ----
  # variables
  ########################################################################
  
  import qm.test.database
  import qm.label
! import qm.host
  import qm.test.resource
  import qm.test.result_reader
  import qm.test.result_stream
  import qm.test.suite
  import qm.test.target
  import qm.test.test
  
  __extension_bases = {
      'database' : qm.test.database.Database,
+     'host' : qm.host.Host,
      'label' : qm.label.Label,
      'resource' : qm.test.resource.Resource,
      'result_reader' : qm.test.result_reader.ResultReader,
      'result_stream' : qm.test.result_stream.ResultStream,
      'suite' : qm.test.suite.Suite,
      'target' : qm.test.target.Target,
Index: qm/test/classes/classes.qmc
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/classes.qmc,v
retrieving revision 1.18
diff -c -5 -p -r1.18 classes.qmc
*** qm/test/classes/classes.qmc	10 Jun 2005 21:23:21 -0000	1.18
--- qm/test/classes/classes.qmc	13 Jun 2005 21:53:48 -0000
***************
*** 25,34 ****
   <class kind="test" name="python.ExecTest"/>
   <class kind="test" name="python.StringExceptionTest"/>
   <class kind="label" name="file_label.FileLabel"/>
   <class kind="label" name="python_label.PythonLabel"/>
   <class kind="suite" name="explicit_suite.ExplicitSuite"/>
!  <class kind="remote_host" name="local_host.LocalHost"/>
!  <class kind="remote_host" name="ssh_host.SSHHost"/>
!  <class kind="remote_host" name="ssh_host.RSHHost"/>
!  <class kind="remote_host" name="simulator.Simulator"/>
  </class-directory>
--- 25,34 ----
   <class kind="test" name="python.ExecTest"/>
   <class kind="test" name="python.StringExceptionTest"/>
   <class kind="label" name="file_label.FileLabel"/>
   <class kind="label" name="python_label.PythonLabel"/>
   <class kind="suite" name="explicit_suite.ExplicitSuite"/>
!  <class kind="host" name="local_host.LocalHost"/>
!  <class kind="host" name="ssh_host.SSHHost"/>
!  <class kind="host" name="ssh_host.RSHHost"/>
!  <class kind="host" name="simulator.Simulator"/>
  </class-directory>
Index: qm/test/classes/compiler_table.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/compiler_table.py,v
retrieving revision 1.3
diff -c -5 -p -r1.3 compiler_table.py
*** qm/test/classes/compiler_table.py	10 Jun 2005 21:23:21 -0000	1.3
--- qm/test/classes/compiler_table.py	13 Jun 2005 21:53:48 -0000
*************** class CompilerTable(Resource):
*** 76,86 ****
         'Compiler' to use when compiling source files by using this
         map.
  
      - 'CompilerTable.target'
  
!        An instance of 'RemoteHost' that can be used to run compiler
         programs."""
  
      def SetUp(self, context, result):
  
          # There are no compilers yet.
--- 76,86 ----
         'Compiler' to use when compiling source files by using this
         map.
  
      - 'CompilerTable.target'
  
!        An instance of 'Host' that can be used to run compiler
         programs."""
  
      def SetUp(self, context, result):
  
          # There are no compilers yet.
*************** class CompilerTable(Resource):
*** 121,132 ****
          else:
              target_desc = context.get("CompilerTable.target")
              if target_desc is None:
                  target = LocalHost({})
              else:
!                 f = lambda n: qm.test.base.get_extension_class(n,
!                                                                "remote_host",
                                                                 None)
                  host_class, arguments \
                      = qm.extension.parse_descriptor(target_desc, f)
                  target = host_class(arguments)
          context["CompilerTable.target"] = target
--- 121,131 ----
          else:
              target_desc = context.get("CompilerTable.target")
              if target_desc is None:
                  target = LocalHost({})
              else:
!                 f = lambda n: qm.test.base.get_extension_class(n, "host",
                                                                 None)
                  host_class, arguments \
                      = qm.extension.parse_descriptor(target_desc, f)
                  target = host_class(arguments)
          context["CompilerTable.target"] = target
Index: qm/test/classes/local_host.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/local_host.py,v
retrieving revision 1.1
diff -c -5 -p -r1.1 local_host.py
*** qm/test/classes/local_host.py	10 Jun 2005 21:23:21 -0000	1.1
--- qm/test/classes/local_host.py	13 Jun 2005 21:53:48 -0000
***************
*** 15,32 ****
  # Imports
  #######################################################################
  
  import os
  import os.path
! from   qm.remote_host import RemoteHost
  import shutil
  
  ########################################################################
  # Classes
  #######################################################################
  
! class LocalHost(RemoteHost):
      """A 'LocalHost' is the machine on which Python is running.
  
      The default directory for a 'LocalHost' is the current working
      directory for this Python process."""
  
--- 15,32 ----
  # Imports
  #######################################################################
  
  import os
  import os.path
! from   qm.host import Host
  import shutil
  
  ########################################################################
  # Classes
  #######################################################################
  
! class LocalHost(Host):
      """A 'LocalHost' is the machine on which Python is running.
  
      The default directory for a 'LocalHost' is the current working
      directory for this Python process."""
  
