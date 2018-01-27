? tests/Makefile.in
Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.325
diff -c -p -r1.325 ChangeLog
*** ChangeLog	6 Dec 2005 00:58:40 -0000	1.325
--- ChangeLog	6 Dec 2005 02:14:11 -0000
***************
*** 1,3 ****
--- 1,9 ----
+ 2005-12-05 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* doc/quickstart/quickstart.xml: Document configure options.
+ 	* src/vsip/parallel.hpp: Put processor_set decl in vsip namespace.
+ 	* tests/ref-impl/selgen.cpp: Use clip/invclip API in current spec.
+ 
  2005-12-05  Don McCoy  <don@codesourcery.com>
  
  	* src/vsip/signal.hpp: new header for histograms.
Index: src/vsip/parallel.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/parallel.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 parallel.hpp
*** src/vsip/parallel.hpp	5 Dec 2005 20:25:05 -0000	1.2
--- src/vsip/parallel.hpp	6 Dec 2005 02:14:11 -0000
***************
*** 24,29 ****
--- 24,34 ----
    Declarations
  ***********************************************************************/
  
+ namespace vsip
+ {
+ 
  Vector<processor_type> processor_set();
  
+ } // namespace vsip
+ 
  #endif // VSIP_PARALLEL_HPP
Index: tests/ref-impl/selgen.cpp
===================================================================
RCS file: /home/cvs/Repository/vsipl++/implementation/tests/selgen.cpp,v
retrieving revision 1.8
diff -c -p -r1.8 selgen.cpp
*** tests/ref-impl/selgen.cpp	18 Mar 2005 03:05:14 -0000	1.8
--- tests/ref-impl/selgen.cpp	6 Dec 2005 02:14:11 -0000
*************** main ()
*** 258,285 ****
  		vector_clip_i (vsip::ramp (static_cast<vsip::scalar_i>(0),
  					   static_cast<vsip::scalar_i>(1),
  					   input_length));
-   vsip::Clip<vsip::scalar_i, vsip::scalar_i>
- 		clip_i (3, 15, -73, 73);
- 
-   /* Briefly test copying and assignment.  */
- 
-   vsip::Clip<vsip::scalar_i, vsip::scalar_i>
-     clip_i_two (clip_i);
-   clip_i_two = clip_i;
- 
-   /* Test clipping of individual elements.  */
- 
-   insist (clip_i (0) == -73);
-   insist (clip_i (3) == -73);
-   insist (clip_i (4) == 4);
-   insist (clip_i (14) == 14);
-   insist (clip_i (15) == 73);
-   insist (clip_i (1500) == 73);
  
    /* Test clipping of a vector.  */
  
!   vsip::Vector<vsip::scalar_i>
! 		vector_clip_answer_i (clip_i (vector_clip_i));
    insist (vector_clip_answer_i.size () == input_length);
    insist (vector_clip_answer_i.get (0) == -73);
    insist (vector_clip_answer_i.get (3) == -73);
--- 258,270 ----
  		vector_clip_i (vsip::ramp (static_cast<vsip::scalar_i>(0),
  					   static_cast<vsip::scalar_i>(1),
  					   input_length));
  
    /* Test clipping of a vector.  */
  
!   vsip::Vector<vsip::scalar_i> vector_clip_answer_i(input_length);
!   
!   vector_clip_answer_i = clip(vector_clip_i, 3, 15, -73, 73);
! 
    insist (vector_clip_answer_i.size () == input_length);
    insist (vector_clip_answer_i.get (0) == -73);
    insist (vector_clip_answer_i.get (3) == -73);
*************** main ()
*** 294,324 ****
  		vector_invclip_f (vsip::ramp (static_cast<vsip::scalar_f>(0.0),
  					      static_cast<vsip::scalar_f>(1.0),
  					      input_length));
-   vsip::InverseClip<vsip::scalar_f, vsip::scalar_f>
-     invclip_f (3.0, 9.0, 15.0, -73.0, 73.0);
  
!   /* Briefly test copying and assignment.  */
  
!   vsip::InverseClip<vsip::scalar_f, vsip::scalar_f>
!     invclip_f_two (invclip_f);
!   invclip_f_two = invclip_f;
! 
!   /* Test inverse clipping of individual elements.  */
! 
!   insist (invclip_f (0.0) == 0.0);
!   insist (invclip_f (3.0) == -73.0);
!   insist (invclip_f (4.0) == -73.0);
!   insist (invclip_f (8.99) == -73.0);
!   insist (invclip_f (9.0) == 73.0);
!   insist (invclip_f (14.99) == 73.0);
!   insist (invclip_f (15.0) == 73.0);
!   insist (invclip_f (16.0) == 16.0);
!   insist (invclip_f (1500.0) == 1500.0);
  
!   /* Test inverse clipping of a vector.  */
  
-   vsip::Vector<vsip::scalar_f>
- 		vector_invclip_answer_f (invclip_f (vector_invclip_f));
    insist (vector_invclip_answer_f.size () == input_length);
    insist (vector_invclip_answer_f.get (0) == 0.0);
    insist (vector_invclip_answer_f.get (2) == 2.0);
--- 279,291 ----
  		vector_invclip_f (vsip::ramp (static_cast<vsip::scalar_f>(0.0),
  					      static_cast<vsip::scalar_f>(1.0),
  					      input_length));
  
!   /* Test inverse clipping of a vector.  */
  
!   vsip::Vector<vsip::scalar_f> vector_invclip_answer_f (input_length);
  
!   vector_invclip_answer_f  = invclip(vector_invclip_f, 3., 9., 15., -73., 73.);
  
    insist (vector_invclip_answer_f.size () == input_length);
    insist (vector_invclip_answer_f.get (0) == 0.0);
    insist (vector_invclip_answer_f.get (2) == 2.0);
