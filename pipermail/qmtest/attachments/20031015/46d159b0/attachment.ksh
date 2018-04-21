2003-10-15  Mark Mitchell  <mark@codesourcery.com>

	* qm/fields.py (SetField.ParseFormValue): Correct logic
	determining whether or not to redisplay the form.

Index: fields.py
===================================================================
RCS file: /home/sc/Repository/qm/qm/fields.py,v
retrieving revision 1.78
diff -c -5 -p -r1.78 fields.py
*** fields.py	8 Sep 2003 06:46:56 -0000	1.78
--- fields.py	15 Oct 2003 08:31:16 -0000
*************** class SetField(Field):
*** 1038,1055 ****
          
                         
      def ParseFormValue(self, request, name, attachment_store):
  
          values = []
! 
!         contained_field = self.GetContainedField()
! 
!         # See if the user wants to add or remove elements to the set.
          action = request[name]
- 
          # Loop over the entries for each of the elements, adding them to
          # the set.
          element = 0
  	for element in xrange(int(request[name + "_count"])):
              element_name = name + "_%d" % element
              if not (action == "remove"
                      and request.get(element_name + "_remove") == "on"):
--- 1038,1054 ----
          
                         
      def ParseFormValue(self, request, name, attachment_store):
  
          values = []
!         redisplay = 0
!         
!         # See if the user wants to add or remove elements from the set.
          action = request[name]
          # Loop over the entries for each of the elements, adding them to
          # the set.
+         contained_field = self.GetContainedField()
          element = 0
  	for element in xrange(int(request[name + "_count"])):
              element_name = name + "_%d" % element
              if not (action == "remove"
                      and request.get(element_name + "_remove") == "on"):
*************** class SetField(Field):
*** 1083,1094 ****
              # not actually select something, the problem will be
              # reported when the form is submitted.
              values.append(contained_field.GetDefaultValue())
          elif action == "remove":
              redisplay = 1
-         else:
-             redisplay = 0
  
          return (values, redisplay)
  
  
      def GetValueFromDomNode(self, node, attachment_store):
--- 1082,1091 ----
