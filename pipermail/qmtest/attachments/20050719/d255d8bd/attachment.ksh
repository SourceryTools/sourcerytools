2005-07-19  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/file_database.py: Fix typo in documentation.

Index: qm/test/file_database.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/file_database.py,v
retrieving revision 1.23
diff -c -5 -p -r1.23 file_database.py
*** qm/test/file_database.py	23 Jun 2005 14:07:31 -0000	1.23
--- qm/test/file_database.py	19 Jul 2005 17:11:12 -0000
*************** class FileDatabase(Database):
*** 419,429 ****
          return os.path.join(*self.GetLabelComponents(label))
  
  
  
  class ExtensionDatabase(FileDatabase):
!     """An 'ExtensionFileDatabase' is a 'FileDatabase' where each kind of
      entity (test, suite, resource) has a particular extension.  For
      example, if tests have the extension '.qmt', then all files ending
      with '.qmt' are considered tests.  If an extension for a particular
      kind of entity is not specified or is the empty string, then all files
      will be considered to be that kind of entity.
--- 419,429 ----
          return os.path.join(*self.GetLabelComponents(label))
  
  
  
  class ExtensionDatabase(FileDatabase):
!     """An 'ExtensionDatabase' is a 'FileDatabase' where each kind of
      entity (test, suite, resource) has a particular extension.  For
      example, if tests have the extension '.qmt', then all files ending
      with '.qmt' are considered tests.  If an extension for a particular
      kind of entity is not specified or is the empty string, then all files
      will be considered to be that kind of entity.
