Index: tests/load_view.hpp
===================================================================
RCS file: tests/load_view.hpp
diff -N tests/load_view.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/load_view.hpp	30 Sep 2005 21:41:46 -0000
***************
*** 0 ****
--- 1,113 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/load_view.hpp
+     @author  Jules Bergmann
+     @date    2005-09-30
+     @brief   VSIPL++ Library: Utility to load a view from disk.
+ */
+ 
+ #ifndef VSIP_TEST_LOAD_VIEW_HPP
+ #define VSIP_TEST_LOAD_VIEW_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/vector.hpp>
+ #include <vsip/matrix.hpp>
+ #include <vsip/tensor.hpp>
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ // This is nearly same as sarsim LoadView, but doesn't include byte
+ // ordering.  Move this into common location.
+ 
+ template <typename T>
+ struct Load_view_traits
+ {
+   typedef T base_t;
+   static unsigned const factor = 1;
+ };
+ 
+ template <typename T>
+ struct Load_view_traits<vsip::complex<T> >
+ {
+   typedef T base_t;
+   static unsigned const factor = 2;
+ };
+ 
+ 
+ template <vsip::dimension_type Dim,
+ 	  typename             T>
+ class Load_view
+ {
+ public:
+   typedef typename Load_view_traits<T>::base_t base_t;
+   static unsigned const factor = Load_view_traits<T>::factor;
+ 
+   typedef vsip::Dense<Dim, T> block_t;
+   typedef typename vsip::impl::View_of_dim<Dim, T, block_t>::type view_t;
+ 
+ public:
+   Load_view(char*                    filename,
+ 	    vsip::Domain<Dim> const& dom)
+     : data_  (new base_t[factor*dom.size()]),
+       block_ (dom, data_),
+       view_  (block_)
+   {
+     FILE*  fd;
+     size_t size = dom.size();
+     
+     if (!(fd = fopen(filename,"r")))
+     {
+       fprintf(stderr,"Load_view: error opening '%s'.\n", filename);
+       exit(1);
+     }
+ 
+     if (size != fread(data_, sizeof(T), size, fd))
+     {
+       fprintf(stderr, "Load_view: error reading file %s.\n", filename);
+       exit(1);
+     }
+   
+     fclose(fd);
+     
+     block_.admit(true);
+   }
+ 
+ 
+ 
+   Load_view(FILE*              fd,
+ 	    vsip::Domain<Dim> const& dom)
+     : data_  (new base_t[factor*dom.size()]),
+       block_ (dom, data_),
+       view_  (block_)
+   {
+     size_t size = dom.size();
+ 
+     if (size != fread(data_, sizeof(T), size, fd))
+     {
+       fprintf(stderr, "Load_view: error reading file.\n");
+       exit(1);
+     }
+     
+     block_.admit(true);
+   }
+ 
+   ~Load_view()
+   { delete[] data_; }
+ 
+   view_t view() { return view_; }
+ 
+ private:
+   base_t*       data_;
+ 
+   block_t       block_;
+   view_t        view_;
+ };
+ 
+ #endif // VSIP_TEST_LOAD_VIEW_HPP
Index: tests/save_view.hpp
===================================================================
RCS file: tests/save_view.hpp
diff -N tests/save_view.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/save_view.hpp	30 Sep 2005 21:41:46 -0000
***************
*** 0 ****
--- 1,136 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/save_view.cpp
+     @author  Jules Bergmann
+     @date    2005-09-30
+     @brief   VSIPL++ Library: Utility to save a view to disk.
+ */
+ 
+ #ifndef VSIP_TEST_SAVE_VIEW_HPP
+ #define VSIP_TEST_SAVE_VIEW_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/vector.hpp>
+ #include <vsip/matrix.hpp>
+ #include <vsip/tensor.hpp>
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ template <typename T>
+ struct Save_view_traits
+ {
+    typedef T base_t;
+    static unsigned const factor = 1;
+ };
+ 
+ template <typename T>
+ struct Save_view_traits<vsip::complex<T> >
+ {
+    typedef T base_t;
+    static unsigned const factor = 2;
+ };
+ 
+ 
+ 
+ template <vsip::dimension_type Dim,
+ 	  typename             T>
+ class Save_view
+ {
+ public:
+   typedef typename Save_view_traits<T>::base_t base_t;
+   static unsigned const factor = Save_view_traits<T>::factor;
+ 
+   typedef vsip::Dense<Dim, T> block_t;
+   typedef typename vsip::impl::View_of_dim<Dim, T, block_t>::type view_t;
+ 
+ public:
+   static void save(char*  filename,
+ 		   view_t view)
+   {
+     vsip::Domain<Dim> dom(get_domain(view));
+     base_t*           data(new base_t[factor*dom.size()]);
+ 
+     block_t           block(dom, data);
+     view_t            store(block);
+ 
+     FILE*  fd;
+     size_t size = dom.size();
+ 
+     if (!(fd = fopen(filename,"w")))
+     {
+       fprintf(stderr,"Save_view: error opening '%s'.\n", filename);
+       exit(1);
+     }
+ 
+     block.admit(false);
+     store = view;
+     block.release(true);
+     
+     if (size != fwrite(data, sizeof(T), size, fd))
+     {
+       fprintf(stderr, "Save_view: Error writing.\n");
+       exit(1);
+     }
+ 
+     fclose(fd);
+   }
+ 
+ private:
+   template <typename T1,
+ 	    typename Block1>
+   static vsip::Domain<1> get_domain(vsip::const_Vector<T1, Block1> view)
+   { return vsip::Domain<1>(view.size()); }
+ 
+   template <typename T1,
+ 	    typename Block1>
+   static vsip::Domain<2> get_domain(vsip::const_Matrix<T1, Block1> view)
+   { return vsip::Domain<2>(view.size(0), view.size(1)); }
+ 
+   template <typename T1,
+ 	    typename Block1>
+   static vsip::Domain<3> get_domain(vsip::const_Tensor<T1, Block1> view)
+   { return vsip::Domain<3>(view.size(0), view.size(1), view.size(2)); }
+ };
+ 
+ 
+ template <typename T,
+ 	  typename Block>
+ void
+ save_view(
+    char*                        filename,
+    vsip::const_Vector<T, Block> view)
+ {
+    Save_view<1, T>::save(filename, view);
+ }
+ 
+ 
+ 
+ template <typename T,
+ 	  typename Block>
+ void
+ save_view(
+    char*                        filename,
+    vsip::const_Matrix<T, Block> view)
+ {
+    Save_view<2, T>::save(filename, view);
+ }
+ 
+ 
+ 
+ template <typename T,
+ 	  typename Block>
+ void
+ save_view(
+    char*                        filename,
+    vsip::const_Tensor<T, Block> view)
+ {
+    Save_view<3, T>::save(filename, view);
+ }
+ #endif // VSIP_TEST_SAVE_VIEW_HPP
