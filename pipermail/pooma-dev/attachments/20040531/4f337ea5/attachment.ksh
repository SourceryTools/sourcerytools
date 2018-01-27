===== src/Array/Array.h 1.12 vs edited =====
--- 1.12/r2/src/Array/Array.h	2004-05-31 15:47:13 +02:00
+++ edited/src/Array/Array.h	2004-05-31 16:16:31 +02:00
@@ -1288,12 +1288,6 @@
  * Changes to ComponentView should also be made to AltComponentView.
  */
 
-template<int Dim, class T, class EngineTag>
-struct ComponentView<int, Array<Dim, T, EngineTag> >
-{
-  typedef int Type_t;
-};
-
 template<class Components, int Dim, class T, class EngineTag>
 struct ComponentView<Components, Array<Dim, T, EngineTag> >
 {
@@ -1978,7 +1972,7 @@
   /// that returns a reference or proxy to the component.
   //@{
   inline typename AltComponentView<Loc<1>, This_t>::Type_t
-  comp(const int &i1) const
+  comp(int i1) const
     {
       return ComponentView<Loc<1>, This_t>::make(*this, Loc<1>(i1));
     }
===== src/Field/Field.h 1.19 vs edited =====
--- 1.19/r2/src/Field/Field.h	2004-05-31 15:47:13 +02:00
+++ edited/src/Field/Field.h	2004-05-31 16:14:56 +02:00
@@ -1414,7 +1414,7 @@
   //@{
 
   inline typename ComponentView<Loc<1>, This_t>::Type_t
-  comp(const int &i1) const
+  comp(int i1) const
   {
     return ComponentView<Loc<1>, This_t>::make(*this, Loc<1>(i1));
   }
