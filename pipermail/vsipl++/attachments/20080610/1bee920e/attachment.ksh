Index: ChangeLog
===================================================================
--- ChangeLog	(revision 211165)
+++ ChangeLog	(working copy)
@@ -1,3 +1,14 @@
+2008-06-10  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/signal/window.cpp: Use out-of-place freqswap to
+	  reduce number of copies.
+	* src/vsip/core/signal/freqswap.hpp: Store referee block type using
+	  View_block_storage.  Fix handling of in-place for odd-size vectors
+	  and matrices.
+	* tests/window.cpp: Remove unnecessary header.
+	* tests/freqswap.cpp: Extend coverage to in-place and nested
+	  expressions.
+
 2008-06-09  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/diag/eval.hpp (See_summary): Qualify specialization
@@ -31,7 +42,7 @@
 	
 2008-06-05  Stefan Seefeld  <stefan@codesourcery.com>
 
-	* src/vsip/signal/freqswap.hpp: Reimplement, using return-block
+	* src/vsip/core/signal/freqswap.hpp: Reimplement, using return-block
 	  optimization.
 
 2008-06-05  Jules Bergmann  <jules@codesourcery.com>
Index: src/vsip/core/signal/window.cpp
===================================================================
--- src/vsip/core/signal/window.cpp	(revision 211164)
+++ src/vsip/core/signal/window.cpp	(working copy)
@@ -137,8 +137,8 @@
     wf = scale * wf;
   }
   
-  Vector<scalar_f> ret(wfR);
-  ret = freqswap(ret);
+  Vector<scalar_f> ret(len);
+  ret = freqswap(wfR);
 
   return ret;
 }
Index: src/vsip/core/signal/freqswap.hpp
===================================================================
--- src/vsip/core/signal/freqswap.hpp	(revision 211164)
+++ src/vsip/core/signal/freqswap.hpp	(working copy)
@@ -38,13 +38,14 @@
 class Freqswap_functor<B, 1>
 {
 public:
+  typedef typename B::map_type   map_type;
+  typedef typename B::value_type value_type;
+  typedef typename View_block_storage<B>::plain_type block_ref_type;
 
-  typedef typename B::map_type map_type;
-
   typedef Freqswap_functor<typename Distributed_local_block<B>::type, 1>
 		local_type;
 
-  Freqswap_functor(B const &in) : in_(in) {}
+  Freqswap_functor(block_ref_type in) : in_(in) {}
 
   length_type size(dimension_type block_dim, dimension_type d) const
   {
@@ -61,40 +62,40 @@
     length_type const M = in_.size();
 
     index_type const ia = M % 2;  // adjustment to get source index
+
+    value_type mid = in_.get(M / 2);
+
     for (index_type i = 0, ii = M / 2; i < M / 2; ++i, ++ii)
     {
       // Be careful to allow 'out' to alias 'in'
-      typename B::value_type tmp = in_.get(ii + ia);
+      value_type tmp = in_.get(ii + ia);
       out.put(ii, in_.get(i));
       out.put(i, tmp);
     }
 
     // if odd, fill in the last row/column(s)
     if (ia)
-    {
-      index_type i = M / 2;
-      index_type ii = M - 1;
-      out.put(ii, in_.get(i));
-    }
+      out.put(M-1, mid);
   }
 
   map_type const& map() const { return in_.map();}
 
 private:
-  B const &in_;
+  block_ref_type in_;
 };
 
 template <typename B>
 class Freqswap_functor<B, 2>
 {
 public:
+  typedef typename B::map_type   map_type;
+  typedef typename B::value_type value_type;
+  typedef typename View_block_storage<B>::plain_type block_ref_type;
 
-  typedef typename B::map_type map_type;
-
   typedef Freqswap_functor<typename Distributed_local_block<B>::type, 2>
 		local_type;
 
-  Freqswap_functor(B const & in) : in_(in) {}
+  Freqswap_functor(block_ref_type in) : in_(in) {}
 
   length_type size(dimension_type block_dim, dimension_type d) const
   {
@@ -106,57 +107,97 @@
   template <typename B1>
   void apply(B1 & out) const
   {
-    // equiv. to out[i,j] = in[(M/2 + i) mod M,(N/2 + i) mod N], 
-    //   where i = 0 --> M - 1 and j = 0 --> N - 1
-
     length_type const M = in_.size(2, 0);
     length_type const N = in_.size(2, 1);
 
     index_type const ia = M % 2;  // adjustment to get source index
-    for (index_type i = 0, ii = M / 2; i < M / 2; ++i, ++ii)
+    index_type const ja = N % 2;
+
+    if (&in_ == &out)
     {
-      index_type const ja = N % 2;
-      for (index_type j = 0, jj = N / 2; j < N / 2; ++j, ++jj)
+      // If in-place, use algorithm that trades O(1) temporary storage
+      // for extra copies.
+
+      // First swap rows.
+      for (index_type i=0; i < M; ++i)
       {
-        typename B::value_type tmp = in_.get(ii + ia, jj + ja);
-        out.put(ii, jj, in_.get(i, j));
-        out.put(i, j, tmp);
-        tmp = in_.get(ii + ia, j);
-        out.put(ii, j, in_.get(i, jj + ja));
-        out.put(i, jj, tmp);
+	value_type mid = in_.get(i, N / 2);
+
+	for (index_type j = 0, jj = N / 2; j < N / 2; ++j, ++jj)
+	{
+	  // Be careful to allow 'out' to alias 'in'
+	  value_type tmp = in_.get(i, jj + ja);
+	  out.put(i, jj, in_.get(i, j));
+	  out.put(i, j, tmp);
+	}
+
+	// if odd, fill in the last row/column(s)
+	if (ja) out.put(i, N-1, mid);
       }
-    }
 
-    // if odd, fill in the last row/column(s)
-    if (ia)
-    {
-      index_type i = M / 2;
-      index_type ii = M - 1;
-      index_type ja = N % 2;
-      for (index_type j = 0, jj = N / 2; j < N / 2; ++j, ++jj)
+      // Second, swap columns.
+      for (index_type j=0; j < N; ++j)
       {
-        out.put(ii, jj, in_.get(i, j));
-        out.put(ii,  j, in_.get(i,jj + ja));
+	value_type mid = in_.get(M / 2, j);
+
+	for (index_type i = 0, ii = M / 2; i < M / 2; ++i, ++ii)
+	{
+	  // Be careful to allow 'out' to alias 'in'
+	  value_type tmp = in_.get(ii + ia, j);
+	  out.put(ii, j, in_.get(i, j));
+	  out.put(i,  j, tmp);
+	}
+
+	// if odd, fill in the last row/column(s)
+	if (ia) out.put(M-1, j, mid);
       }
     }
-    if (N % 2)
+    else
     {
-      index_type j = N / 2;
-      index_type jj = N - 1;
-      index_type ia = M % 2;
+      // equiv. to out[i,j] = in[(M/2 + i) mod M,(N/2 + i) mod N], 
+      //   where i = 0 --> M - 1 and j = 0 --> N - 1
       for (index_type i = 0, ii = M / 2; i < M / 2; ++i, ++ii)
       {
-        out.put(ii, jj, in_.get(i      , j));
-        out.put( i, jj, in_.get(ii + ia, j));
+	for (index_type j = 0, jj = N / 2; j < N / 2; ++j, ++jj)
+	{
+	  value_type tmp = in_.get(ii + ia, jj + ja);
+	  out.put(ii, jj, in_.get(i, j));
+	  out.put(i, j, tmp);
+	  tmp = in_.get(ii + ia, j);
+	  out.put(ii, j, in_.get(i, jj + ja));
+	  out.put(i, jj, tmp);
+	}
       }
+
+      // if odd, fill in the last row/column(s)
+      if (ia)
+      {
+	index_type i = M / 2;
+	index_type ii = M - 1;
+	for (index_type j = 0, jj = N / 2; j < N / 2; ++j, ++jj)
+	{
+	  out.put(ii, jj, in_.get(i, j));
+	  out.put(ii,  j, in_.get(i,jj + ja));
+	}
+      }
+      if (ja)
+      {
+	index_type j = N / 2;
+	index_type jj = N - 1;
+	for (index_type i = 0, ii = M / 2; i < M / 2; ++i, ++ii)
+	{
+	  out.put(ii, jj, in_.get(i      , j));
+	  out.put( i, jj, in_.get(ii + ia, j));
+	}
+      }
+      if (ia && ja) out.put(M - 1, N - 1, in_.get(M / 2, N / 2));
     }
-    if (M % 2 && N % 2) out.put(M - 1, N - 1, in_.get(M / 2, N / 2));
   }
 
   map_type const& map() const { return in_.map();}
 
 private:
-  B const &in_;
+  block_ref_type in_;
 };
 
 template <typename B>
Index: tests/window.cpp
===================================================================
--- tests/window.cpp	(revision 211164)
+++ tests/window.cpp	(working copy)
@@ -14,7 +14,6 @@
   Included Files
 ***********************************************************************/
 
-#include <iomanip>
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/signal.hpp>
Index: tests/freqswap.cpp
===================================================================
--- tests/freqswap.cpp	(revision 211164)
+++ tests/freqswap.cpp	(working copy)
@@ -38,15 +38,43 @@
   a = rgen.randu(m);
 
   Vector<T> b(m);
+  Vector<T> c(m);
   b = vsip::freqswap(a);
+  c = a; c = vsip::freqswap(c);
 
   for ( index_type i = 0; i < m; i++ )
+  {
     test_assert(equal( b.get(i), a.get(((m+1)/2 + i) % m ) ));
+    test_assert(equal( c.get(i), a.get(((m+1)/2 + i) % m ) ));
+  }
 }
 
 
+
 template <typename T>
 void
+test_real_subview_vector_freqswap( length_type m )
+{
+  Vector<complex<T> > a(m);
+
+  a.real() = ramp<T>(0, 1, m);
+  a.imag() = T(0);
+
+  Vector<T> b(m);
+  Vector<complex<T> > c(m, T());
+  b = vsip::freqswap(a.real());
+  c.real() = a.real(); c.real() = vsip::freqswap(c.real());
+
+  for ( index_type i = 0; i < m; i++ )
+  {
+    test_assert(equal( b.get(i), a.real().get(((m+1)/2 + i) % m ) ));
+    test_assert(equal( c.real().get(i), a.real().get(((m+1)/2 + i) % m ) ));
+  }
+}
+
+
+template <typename T>
+void
 test_matrix_freqswap( length_type m, length_type n )
 {
   Matrix<T> a(m, n);
@@ -55,12 +83,18 @@
   a = rgen.randu(m, n);
 
   Matrix<T> b(m, n);
+  Matrix<T> c(m, n);
   b = vsip::freqswap(a);
+  c = a; c = vsip::freqswap(c);
 
   for ( index_type i = 0; i < m; i++ )
     for ( index_type j = 0; j < n; j++ )
+    {
       test_assert(equal( b.get(i, j),
                a.get(((m+1)/2 + i) % m, ((n+1)/2 + j) % n ) ));
+      test_assert(equal( c.get(i, j),
+               a.get(((m+1)/2 + i) % m, ((n+1)/2 + j) % n ) ));
+    }
 }
 
 
@@ -71,7 +105,12 @@
 {
   test_vector_freqswap<T>( 8 );
   test_vector_freqswap<T>( 9 );
+  test_vector_freqswap<T>( 33 );
 
+  test_real_subview_vector_freqswap<T>( 8 );
+  test_real_subview_vector_freqswap<T>( 9 );
+  test_real_subview_vector_freqswap<T>( 33 );
+
   test_matrix_freqswap<T>( 4, 4 );
   test_matrix_freqswap<T>( 4, 5 );
   test_matrix_freqswap<T>( 5, 4 );
