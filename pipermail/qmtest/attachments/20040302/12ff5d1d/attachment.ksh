2004-03-02  Mark Mitchell  <mark@codesourcery.com>

	* qmdist/command/install_scripts.py (install_scripts.run): Handle
	pathnames that contain backslashes correctly.

Index: qmdist/command/install_scripts.py
===================================================================
RCS file: /home/qm/Repository/qm/qmdist/command/install_scripts.py,v
retrieving revision 1.3
diff -c -5 -p -r1.3 install_scripts.py
*** qmdist/command/install_scripts.py	24 Nov 2003 06:35:01 -0000	1.3
--- qmdist/command/install_scripts.py	3 Mar 2004 07:07:26 -0000
*************** class install_scripts(base.install_scrip
*** 47,64 ****
              # Encode the relative path from that script to the top of the
              # installation directory.
              i = self.distribution.get_command_obj('install')
              prefix = i.root or i.prefix
              rel_prefix = get_relative_path(self.install_dir, prefix)
!             assignment = 'rel_prefix = "%s"' % rel_prefix
              qmtest_script = re.sub("rel_prefix = .*", assignment,
                                     qmtest_script)
              # Encode the relative path from the prefix to the library
              # directory.
              il = self.distribution.get_command_obj('install_lib')
              rel_libdir = get_relative_path(prefix, il.install_dir)
!             assignment = 'rel_libdir = "%s"' % rel_libdir
              qmtest_script = re.sub("rel_libdir = .*", assignment,
                                     qmtest_script)
  
              # Write the script back out.
              open(qmtest_file, "w").write(qmtest_script)
--- 47,70 ----
              # Encode the relative path from that script to the top of the
              # installation directory.
              i = self.distribution.get_command_obj('install')
              prefix = i.root or i.prefix
              rel_prefix = get_relative_path(self.install_dir, prefix)
!             assignment = 'rel_prefix = ' + repr(rel_prefix)
! 	    # Because re.sub processes backslash escapes in the
! 	    # replacement string, we must double up any backslashes.
! 	    assignment = assignment.replace("\\", "\\\\")
              qmtest_script = re.sub("rel_prefix = .*", assignment,
                                     qmtest_script)
              # Encode the relative path from the prefix to the library
              # directory.
              il = self.distribution.get_command_obj('install_lib')
              rel_libdir = get_relative_path(prefix, il.install_dir)
!             assignment = 'rel_libdir = ' + repr(rel_libdir)
! 	    # Because re.sub processes backslash escapes in the
! 	    # replacement string, we must double up any backslashes.
! 	    assignment = assignment.replace("\\", "\\\\")
              qmtest_script = re.sub("rel_libdir = .*", assignment,
                                     qmtest_script)
  
              # Write the script back out.
              open(qmtest_file, "w").write(qmtest_script)
