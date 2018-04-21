2005-07-20  Mark Mitchell  <mark@codesourcery.com>

	* qm/executable.py (Executable.Spawn): Initialize self.__child.
	(Executable._GetChildPID): Adjust documentation to reflect that
	this function may return None.
	(TimeoutExecutable.Run): If the child is None, do not try to kill
	it.

Index: qm/executable.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/executable.py,v
retrieving revision 1.25
diff -c -5 -p -r1.25 executable.py
*** qm/executable.py	6 May 2004 00:35:35 -0000	1.25
--- qm/executable.py	21 Jul 2005 04:52:48 -0000
*************** class Executable(object):
*** 126,135 ****
--- 126,140 ----
              pass
  
          # Initialize the parent.
          startupinfo = self._InitializeParent()
  
+         # Initialize self.__child so that if "fork" or "CreateProcess"
+         # throws an exception our caller can tell that there is no
+         # child process to kill.
+         self.__child = None
+         
          if sys.platform == "win32":
              # Compute the command line.  The Windows API uses a single
              # string as the command line, rather than an array of
              # arguments.
              command_line = self.__CreateCommandLine(arguments)
*************** class Executable(object):
*** 352,362 ****
  
      def _GetChildPID(self):
          """Return the process ID for the child process.
  
          returns -- The process ID for the child process.  (On Windows,
!         the value returned is the process handle.)"""
  
          return self.__child
      
          
      def __CreateCommandLine(self, arguments):
--- 357,370 ----
  
      def _GetChildPID(self):
          """Return the process ID for the child process.
  
          returns -- The process ID for the child process.  (On Windows,
!         the value returned is the process handle.)  Returns 'None' if
!         the child has not yet been created, or if something went awry
!         when creating it.  For example, if 'os.fork' throws an
!         exception, this value will return 'None'."""
  
          return self.__child
      
          
      def __CreateCommandLine(self, arguments):
*************** class TimeoutExecutable(Executable):
*** 547,557 ****
                                                          dir,
                                                          path)
          finally:
              if self.__UseSeparateProcessGroupForChild():
                  # Clean up the monitoring program; it is no longer needed.
!                 os.kill(-self._GetChildPID(), signal.SIGKILL)
                  if self.__monitor_pid is not None:
                      os.waitpid(self.__monitor_pid, 0)
              elif self.__timeout >= 0 and sys.platform == "win32":
                  # Join the monitoring thread.
                  if self.__monitor_thread is not None:
--- 555,567 ----
                                                          dir,
                                                          path)
          finally:
              if self.__UseSeparateProcessGroupForChild():
                  # Clean up the monitoring program; it is no longer needed.
!                 child_pid = self._GetChildPID()
!                 if child_pid is not None:
!                     os.kill(-child_pid, signal.SIGKILL)
                  if self.__monitor_pid is not None:
                      os.waitpid(self.__monitor_pid, 0)
              elif self.__timeout >= 0 and sys.platform == "win32":
                  # Join the monitoring thread.
                  if self.__monitor_thread is not None:
