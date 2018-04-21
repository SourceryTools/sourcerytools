2006-09-05  Mark Mitchell  <mark@codesourcery.com>

	* qm/executable.py (Executable.Spawn): Search PATH on Windows if
	appropriate.

Index: executable.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/executable.py,v
retrieving revision 1.26
diff -c -5 -p -r1.26 executable.py
*** executable.py	21 Jul 2005 04:56:16 -0000	1.26
--- executable.py	5 Sep 2006 21:41:20 -0000
*************** class Executable(object):
*** 105,115 ****
          # The path to the executable is the first argument, if not
          # explicitly specified.
          if not path:
              path = arguments[0]
  
!         # Normalize the path name.
          if os.path.isabs(path):
              # An absolute path.
              pass
          elif (os.sep in path or (os.altsep and os.altsep in path)):
              # A relative path name, like "./program".
--- 105,117 ----
          # The path to the executable is the first argument, if not
          # explicitly specified.
          if not path:
              path = arguments[0]
  
!         # Normalize the path name.  At the conclusion of this
!         # processing, the path is either an absolute path, or contains
!         # no directory seperators.
          if os.path.isabs(path):
              # An absolute path.
              pass
          elif (os.sep in path or (os.altsep and os.altsep in path)):
              # A relative path name, like "./program".
*************** class Executable(object):
*** 137,146 ****
--- 139,154 ----
              # Compute the command line.  The Windows API uses a single
              # string as the command line, rather than an array of
              # arguments.
              command_line = self.__CreateCommandLine(arguments)
  
+             # If the path is not absolute, then we need to search the
+             # PATH.  Since CreateProcess only searches the PATH if its
+             # first argument is None, we clear path here.
+             if not os.path.isabs(path):
+                 path = None
+             
              # Windows supports wide-characters in the environment, but
              # the Win32 extensions to Python require that all of the
              # entries in the environment be of the same type,
              # i.e,. that either all of them be of type StringType or
              # of type UnicodeType.  Therefore, if we find any elements
