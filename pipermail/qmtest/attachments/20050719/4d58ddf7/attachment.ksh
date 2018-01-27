2005-07-19  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/classes/command.py (ShellScriptTest._GetShell): New
	function.
	(ShellScriptTest.Run): Use it.

Index: qm/test/classes/command.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/command.py,v
retrieving revision 1.47
diff -c -5 -p -r1.47 command.py
*** qm/test/classes/command.py	31 May 2005 15:48:37 -0000	1.47
--- qm/test/classes/command.py	19 Jul 2005 17:17:59 -0000
*************** class ShellScriptTest(ExecTestBase):
*** 474,491 ****
              = qm.open_temporary_file("w+", suffix) 
          try:
              # Write the script to the temporary file.
              script_file.write(self.script)
              script_file.close()
!             # If the context specifies a shell, use it.
!             if context.has_key("ShellScriptTest.script_shell"):
!                 # Split the context value to build the argument list.
!                 shell = qm.common.split_argument_list(
!                     context["ShellScriptTest.script_shell"])
!             else:
!                 # Otherwise, use a platform-specific default.
!                 shell = qm.platform.get_shell_for_script()
              # Construct the argument list.  The argument list for the
              # interpreter is followed by the name of the script
              # temporary file, and then the arguments to the script.
              arguments = shell \
                          + [ self.__script_file_name ] \
--- 474,484 ----
              = qm.open_temporary_file("w+", suffix) 
          try:
              # Write the script to the temporary file.
              script_file.write(self.script)
              script_file.close()
!             shell = self._GetShell(context)
              # Construct the argument list.  The argument list for the
              # interpreter is followed by the name of the script
              # temporary file, and then the arguments to the script.
              arguments = shell \
                          + [ self.__script_file_name ] \
*************** class ShellScriptTest(ExecTestBase):
*** 494,503 ****
--- 487,517 ----
          finally:
              # Clean up the script file.
              os.remove(self.__script_file_name)
  
  
+     def _GetShell(self, context):
+         """Return the shell to use to run this test.
+ 
+         'context' -- As for 'Test.Run'.
+         
+         returns -- A sequence of strings giving the path and arguments
+         to be supplied to the shell.  The default implementation uses
+         the value of the context property
+         'ShellScriptTest.script_shell', or, if that is not defined, a
+         platform-specific default."""
+         
+         # If the context specifies a shell, use it.
+         if context.has_key("ShellScriptTest.script_shell"):
+             # Split the context value to build the argument list.
+             return qm.common.split_argument_list(
+                 context["ShellScriptTest.script_shell"])
+ 
+         # Otherwise, use a platform-specific default.
+         return qm.platform.get_shell_for_script()
+         
+ 
  
  ########################################################################
  # Local Variables:
  # mode: python
  # indent-tabs-mode: nil
