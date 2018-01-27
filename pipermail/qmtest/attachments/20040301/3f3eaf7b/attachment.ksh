2004-03-01  Mark Mitchell  <mark@codesourcery.com>

	* qm/executable.py (Executable.Spawn): Under Windows, convert all
	environment variables to Unicode if any of them are Unicode.
	* NEWS: Mention this improvement.

Index: qm/executable.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/executable.py,v
retrieving revision 1.23
diff -c -5 -p -r1.23 executable.py
*** qm/executable.py	18 Feb 2004 11:01:57 -0000	1.23
--- qm/executable.py	2 Mar 2004 03:23:13 -0000
*************** class Executable(object):
*** 130,139 ****
--- 130,163 ----
          if sys.platform == "win32":
              # Compute the command line.  The Windows API uses a single
              # string as the command line, rather than an array of
              # arguments.
              command_line = self.__CreateCommandLine(arguments)
+ 
+             # Windows supports wide-characters in the environment, but
+             # the Win32 extensions to Python require that all of the
+             # entries in the environment be of the same type,
+             # i.e,. that either all of them be of type StringType or
+             # of type UnicodeType.  Therefore, if we find any elements
+             # that are Unicode strings, convert all of them to Unicode
+             # strings.
+             if environment is not None:
+                 # See if there any Unicode strings in the environment.
+                 uses_unicode = 0
+                 for (k, v) in environment.iteritems():
+                     if (isinstance(k, unicode)
+                         or isinstance(v, unicode)):
+                         uses_unicode = 1
+                         break
+                 # If there are Unicode strings in the environment,
+                 # convert all of the key-value pairs to Unicode.
+                 if uses_unicode:
+                     new_environment = {}
+                     for (k, v) in environment.iteritems():
+                         new_environment[unicode(k)] = unicode(v)
+                     environment = new_environment
+                         
              # Create the child process.
              self.__child \
                  = win32process.CreateProcess(path,
                                               command_line,
                                               None,
