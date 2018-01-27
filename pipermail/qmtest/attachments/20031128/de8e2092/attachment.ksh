2003-11-28  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/file_database.py: Remove misleading comments about
	methods that cannot be overridden.

Index: qm/test/file_database.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/file_database.py,v
retrieving revision 1.19
diff -c -5 -p -r1.19 file_database.py
*** qm/test/file_database.py	23 Jun 2003 06:46:47 -0000	1.19
--- qm/test/file_database.py	28 Nov 2003 20:32:08 -0000
*************** class FileDatabase(Database):
*** 47,59 ****
          'test_id' -- A label naming the test.
  
          returns -- A 'TestDescriptor' corresponding to 'test_id'.
          
          raises -- 'NoSuchTestError' if there is no test in the database
!         named 'test_id'.
! 
!         Derived classes must not override this method."""
  
          path = self.GetTestPath(test_id)
          if not self._IsTestFile(path):
              raise NoSuchTestError, test_id
  
--- 47,57 ----
          'test_id' -- A label naming the test.
  
          returns -- A 'TestDescriptor' corresponding to 'test_id'.
          
          raises -- 'NoSuchTestError' if there is no test in the database
!         named 'test_id'."""
  
          path = self.GetTestPath(test_id)
          if not self._IsTestFile(path):
              raise NoSuchTestError, test_id
  
*************** class FileDatabase(Database):
*** 110,122 ****
  
          returns -- An instance of 'Suite' (or a derived class of
          'Suite') corresponding to 'suite_id'.
          
          raises -- 'NoSuchSuiteError' if there is no test in the database
!         named 'test_id'.
! 
!         Derived classes must not override this method."""
  
          path = self.GetSuitePath(suite_id)
          if not self._IsSuiteFile(path):
              raise NoSuchSuiteError, suite_id
  
--- 108,118 ----
  
          returns -- An instance of 'Suite' (or a derived class of
          'Suite') corresponding to 'suite_id'.
          
          raises -- 'NoSuchSuiteError' if there is no test in the database
!         named 'test_id'."""
  
          path = self.GetSuitePath(suite_id)
          if not self._IsSuiteFile(path):
              raise NoSuchSuiteError, suite_id
  
*************** class FileDatabase(Database):
*** 184,196 ****
          'resource_id' -- A label naming the resource.
  
          returns -- A 'ResourceDescriptor' corresponding to 'resource_id'.
          
          raises -- 'NoSuchResourceError' if there is no resource in the
!         database named 'resource_id'.
! 
!         Derived classes must not override this method."""
  
          path = self.GetResourcePath(resource_id)
          if not self._IsResourceFile(path):
              raise NoSuchResourceError, resource_id
  
--- 180,190 ----
          'resource_id' -- A label naming the resource.
  
          returns -- A 'ResourceDescriptor' corresponding to 'resource_id'.
          
          raises -- 'NoSuchResourceError' if there is no resource in the
!         database named 'resource_id'."""
  
          path = self.GetResourcePath(resource_id)
          if not self._IsResourceFile(path):
              raise NoSuchResourceError, resource_id
  
*************** class FileDatabase(Database):
*** 354,366 ****
          """Returns the file system path corresponding to 'label'.
  
          'label' -- The id for a test, test suite, or similar entity.
  
          returns -- The absolute path for the corresponding entry in
!         the file system, but without any required extension.
! 
!         Derived classes must not override this method."""
  
          return os.path.join(self.GetRoot(),
                              self._GetRelativeLabelPath(label))
  
  
--- 348,358 ----
          """Returns the file system path corresponding to 'label'.
  
          'label' -- The id for a test, test suite, or similar entity.
  
          returns -- The absolute path for the corresponding entry in
!         the file system, but without any required extension."""
  
          return os.path.join(self.GetRoot(),
                              self._GetRelativeLabelPath(label))
  
  
*************** class FileDatabase(Database):
*** 374,385 ****
          Derived classes may override this method."""
   
          return basename
  
  
-     # Derived classes must not override any methods below this point.
- 
      def _GetLabels(self, directory, scan_subdirs, label, predicate):
          """Returns the labels of entities in 'directory'.
  
          'directory' -- The absolute path name of the directory in
          which to begin the search.
--- 366,375 ----
*************** class FileDatabase(Database):
*** 392,404 ****
          'predicate' -- A function that takes a file name and returns
          a boolean.
  
          returns -- Labels for all file names in 'directory'. that
          satisfy 'predicate'  If 'scan_subdirs' is true, subdirectories
!         are scanned as well.
! 
!         Derived classes must not override this method."""
  
          labels = []
  
          # Go through all of the files (and subdirectories) in that
          # directory.
--- 382,392 ----
          'predicate' -- A function that takes a file name and returns
          a boolean.
  
          returns -- Labels for all file names in 'directory'. that
          satisfy 'predicate'  If 'scan_subdirs' is true, subdirectories
!         are scanned as well."""
  
          labels = []
  
          # Go through all of the files (and subdirectories) in that
          # directory.
*************** class FileDatabase(Database):
*** 430,442 ****
          """Remove an entity.
  
          'path' -- The name of the file containing the entity.
  
          'exception' -- The type of exception to raise if the file
!         is not present.
! 
!         Derived classes must not override this method."""
  
          if not os.path.isfile(path):
              raise exception, entity_id
  
          os.remove(path)
--- 418,428 ----
          """Remove an entity.
  
          'path' -- The name of the file containing the entity.
  
          'exception' -- The type of exception to raise if the file
!         is not present."""
  
          if not os.path.isfile(path):
              raise exception, entity_id
  
          os.remove(path)
