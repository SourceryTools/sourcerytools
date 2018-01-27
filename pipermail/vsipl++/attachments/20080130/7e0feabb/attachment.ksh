Index: ChangeLog
===================================================================
--- ChangeLog	(revision 192285)
+++ ChangeLog	(working copy)
@@ -1,5 +1,23 @@
 2008-01-30  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/initfin.cpp: Initialize default pool.
+	* src/vsip/dense.hpp: Use pools for allocation.
+	* src/vsip/core/pool.hpp: New file, pool virtual base class header.
+	* src/vsip/core/pool.cpp: New file, pool virtual base class impl.
+	* src/vsip/core/huge_page_pool.hpp: New file, pool implementation
+	  using huge page memory header.
+	* src/vsip/core/huge_page_pool.cpp:  New file, pool implementation
+	  using huge page memory impl.
+	* src/vsip/core/aligned_pool.hpp: New file, pool implementation 
+	  using alloc_align header.
+	* src/vsip/core/aligned_pool.cpp: New file, pool implementation 
+	  using alloc_align impl.
+	* src/vsip/core/parallel/local_map.hpp: Hold pool.
+	* benchmarks/loop.hpp: Allow alternate pool to be used.
+	* benchmarks/main.cpp: Likewise.
+
+2008-01-30  Jules Bergmann  <jules@codesourcery.com>
+
 	* m4/lapack.m4: Detect ATLAS with v3 lapack/blas, as found on
 	  Ubuntu 7.04.
 
Index: src/vsip/initfin.cpp
===================================================================
--- src/vsip/initfin.cpp	(revision 191870)
+++ src/vsip/initfin.cpp	(working copy)
@@ -13,6 +13,7 @@
 #include <vsip/initfin.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/core/parallel/services.hpp>
+#include <vsip/core/pool.hpp>
 #if defined(VSIP_IMPL_CBE_SDK) && !defined(VSIP_IMPL_REF_IMPL)
 # include <vsip/opt/cbe/ppu/task_manager.hpp>
 #endif
@@ -210,6 +211,8 @@
 
   par_service_ = new impl::Par_service(use_argc, use_argv);
 
+  impl::initialize_default_pool(use_argc, use_argv);
+
   // Copy argv back if necessary
   if (argv_is_tmp)
   {
Index: src/vsip/dense.hpp
===================================================================
--- src/vsip/dense.hpp	(revision 191870)
+++ src/vsip/dense.hpp	(working copy)
@@ -26,6 +26,7 @@
 #include <vsip/core/block_traits.hpp>
 #include <vsip/core/parallel/choose_dist_block.hpp>
 #include <vsip/domain.hpp>
+#include <vsip/core/pool.hpp>
 
 /// Complex storage format for dense blocks.
 #if VSIP_IMPL_PREFER_SPLIT_COMPLEX
@@ -295,8 +296,7 @@
 
 
 template <typename ComplexFmt,
-	  typename T,
-	  typename AllocT = vsip::impl::Aligned_allocator<T> >
+	  typename T>
 class Dense_storage
 {
   // Compile-time values and types.
@@ -306,23 +306,21 @@
 
   // Constructors and destructor.
 public:
-  Dense_storage(length_type   size,
-		type          buffer = NULL,
-		AllocT const& allocator = AllocT())
+  Dense_storage(Pool*         pool,
+		length_type   size,
+		type          buffer = NULL)
     VSIP_THROW((std::bad_alloc))
-    : allocator_ (allocator),
-      alloc_data_(buffer == NULL),
-      data_      (alloc_data_ ? allocator_.allocate(size) : (T*)buffer)
+    : alloc_data_(buffer == NULL),
+      data_      (alloc_data_ ? pool_alloc<T>(pool, size) : (T*)buffer)
   {}
 
-  Dense_storage(length_type   size,
+  Dense_storage(Pool*         pool,
+		length_type   size,
 		T             val,
-		type          buffer = NULL,
-		AllocT const& allocator = AllocT())
+		type          buffer = NULL)
   VSIP_THROW((std::bad_alloc))
-    : allocator_ (allocator),
-      alloc_data_(buffer == NULL),
-      data_      (alloc_data_ ? allocator_.allocate(size) : (T*)buffer)
+    : alloc_data_(buffer == NULL),
+      data_      (alloc_data_ ? pool_alloc<T>(pool, size) : (T*)buffer)
   {
     for (index_type i=0; i<size; ++i)
       data_[i] = val;
@@ -337,13 +335,13 @@
 
   // Accessors.
 protected:
-  void impl_rebind(length_type size, type buffer);
+  void impl_rebind(Pool* pool, length_type size, type buffer);
 
-  void deallocate(length_type size)
+  void deallocate(Pool* pool, length_type size)
   {
     if (alloc_data_)
     {
-      allocator_.deallocate(data_, size);
+      pool_dealloc(pool, data_, size);
       data_ = 0;
     }
   }
@@ -363,16 +361,14 @@
 
   // Member data.
 private:
-  AllocT allocator_;
   bool   alloc_data_;
   T*     data_;
 };
 
 
 
-template <typename T,
-	  typename AllocT>
-class Dense_storage<Cmplx_split_fmt, vsip::complex<T>, AllocT>
+template <typename T>
+class Dense_storage<Cmplx_split_fmt, vsip::complex<T> >
 {
   // Compile-time values and types.
 public:
@@ -381,23 +377,23 @@
 
   // Constructors and destructor.
 public:
-  Dense_storage(length_type   size,
-		type          buffer    = type(0, 0),
-		AllocT const& allocator = AllocT())
+  Dense_storage(Pool*         pool,
+		length_type   size,
+		type          buffer    = type(0, 0))
     VSIP_THROW((std::bad_alloc))
-    : allocator_ (allocator),
-      alloc_data_(buffer.first == NULL || buffer.second == NULL),
-      real_data_ (alloc_data_ ? allocator_.allocate(size) : buffer.first),
-      imag_data_ (alloc_data_ ? allocator_.allocate(size) : buffer.second)
+    : alloc_data_(buffer.first == NULL || buffer.second == NULL),
+      real_data_ (alloc_data_ ? pool_alloc<T>(pool, size) : buffer.first),
+      imag_data_ (alloc_data_ ? pool_alloc<T>(pool, size) : buffer.second)
   {}
 
-  Dense_storage(length_type      size,
+  Dense_storage(Pool*            pool,
+		length_type      size,
 		vsip::complex<T> val,
 		type buffer = type(0, 0))
     VSIP_THROW((std::bad_alloc))
     : alloc_data_(buffer.first == NULL || buffer.second == NULL),
-      real_data_ (alloc_data_ ? allocator_.allocate(size) : buffer.first),
-      imag_data_ (alloc_data_ ? allocator_.allocate(size) : buffer.second)
+      real_data_ (alloc_data_ ? pool_alloc<T>(pool, size) : buffer.first),
+      imag_data_ (alloc_data_ ? pool_alloc<T>(pool, size) : buffer.second)
   {
     for (index_type i=0; i<size; ++i)
       real_data_[i] = val.real();
@@ -414,14 +410,14 @@
 
   // Accessors.
 protected:
-  void impl_rebind(length_type size, type buffer);
+  void impl_rebind(Pool* pool, length_type size, type buffer);
 
-  void deallocate(length_type size)
+  void deallocate(Pool* pool, length_type size)
   {
     if (alloc_data_)
     {
-      allocator_.deallocate(real_data_, size);
-      allocator_.deallocate(imag_data_, size);
+      pool_dealloc(pool, real_data_, size);
+      pool_dealloc(pool, imag_data_, size);
       real_data_ = 0;
       imag_data_ = 0;
     }
@@ -452,7 +448,6 @@
 
   // Member data.
 private:
-  typename AllocT::template rebind<T>::other allocator_;
   bool   alloc_data_;
   T*     real_data_;
   T*     imag_data_;
@@ -525,7 +520,7 @@
     VSIP_THROW((std::bad_alloc));
 
   ~Dense_impl() VSIP_NOTHROW
-    { storage_type::deallocate(layout_.total_size()); }
+    { storage_type::deallocate(map_.impl_pool(), layout_.total_size()); }
 
 public:
   using storage_type::get;
@@ -1273,17 +1268,17 @@
 ///   SIZE to be size object was constructed with.
 
 template <typename ComplexFmt,
-	  typename T,
-	  typename AllocT>
+	  typename T>
 void
-Dense_storage<ComplexFmt, T, AllocT>::impl_rebind(
+Dense_storage<ComplexFmt, T>::impl_rebind(
+  Pool*       pool,
   length_type size,
   type        buffer)
 {
   if (buffer != NULL)
   {
     if (alloc_data_)
-      allocator_.deallocate(data_, size);
+      pool_dealloc<T>(pool, data_, size);
     
     alloc_data_ = false;
     data_       = buffer;
@@ -1293,7 +1288,7 @@
     if (!alloc_data_)
     {
       alloc_data_ = true;
-      data_ = allocator_.allocate(size);
+      data_ = pool_alloc<T>(pool, size);
     }
     /* else do nothing - we already own our data */
   }
@@ -1306,10 +1301,10 @@
 /// Requires:
 ///   SIZE to be size object was constructed with.
 
-template <typename T,
-	  typename AllocT>
+template <typename T>
 void
-Dense_storage<Cmplx_split_fmt, vsip::complex<T>, AllocT>::impl_rebind(
+Dense_storage<Cmplx_split_fmt, vsip::complex<T> >::impl_rebind(
+  Pool*       pool,
   length_type size,
   type        buffer)
 {
@@ -1317,8 +1312,8 @@
   {
     if (alloc_data_)
     {
-      allocator_.deallocate(real_data_, size);
-      allocator_.deallocate(imag_data_, size);
+      pool_dealloc(pool, real_data_, size);
+      pool_dealloc(pool, imag_data_, size);
     }
     
     alloc_data_ = false;
@@ -1330,8 +1325,8 @@
     if (!alloc_data_)
     {
       alloc_data_ = true;
-      real_data_ = allocator_.allocate(size);
-      imag_data_ = allocator_.allocate(size);
+      real_data_ = pool_alloc<T>(pool, size);
+      imag_data_ = pool_alloc<T>(pool, size);
     }
     /* else do nothing - we already own our data */
   }
@@ -1353,7 +1348,7 @@
   Domain<Dim> const& dom,
   MapT const&        map)
 VSIP_THROW((std::bad_alloc))
-  : storage_type(applied_layout_type(dom).total_size()),
+  : storage_type(map.impl_pool(), applied_layout_type(dom).total_size()),
     layout_     (dom),
     map_        (map),
     admitted_   (true)
@@ -1374,7 +1369,7 @@
   T                  val,
   MapT const&        map)
 VSIP_THROW((std::bad_alloc))
-  : storage_type(applied_layout_type(dom).total_size(), val),
+  : storage_type(map.impl_pool(), applied_layout_type(dom).total_size(), val),
     layout_     (dom),
     map_        (map),
     admitted_   (true)
@@ -1410,7 +1405,7 @@
   User_storage<T> const& user_data,
   MapT const&            map)
 VSIP_THROW((std::bad_alloc))
-  : storage_type(applied_layout_type(dom).total_size(),
+  : storage_type(map.impl_pool(), applied_layout_type(dom).total_size(),
 		 user_data.as_storage(complex_type())),
     layout_     (dom),
     user_data_  (user_data),
@@ -1747,8 +1742,9 @@
 {
   assert(!this->admitted() && this->user_storage() == array_format);
   this->user_data_.rebind(pointer);
-  this->impl_rebind(layout_.total_size(),
-	       this->user_data_.as_storage(complex_type()));
+  this->impl_rebind(
+		map_.impl_poo(), layout_.total_size(),
+		this->user_data_.as_storage(complex_type()));
 }
 
 
@@ -1776,8 +1772,8 @@
 	 (this->user_storage() == split_format ||
 	  this->user_storage() == interleaved_format));
   this->user_data_.rebind(pointer);
-  this->impl_rebind(layout_.total_size(),
-			this->user_data_.as_storage(complex_type()));
+  this->impl_rebind(map_.impl_pool(), layout_.total_size(),
+		    this->user_data_.as_storage(complex_type()));
 }
 
 
@@ -1807,8 +1803,9 @@
 	 (this->user_storage() == split_format ||
 	  this->user_storage() == interleaved_format));
   this->user_data_.rebind(real_pointer, imag_pointer);
-  this->impl_rebind(layout_.total_size(),
-			this->user_data_.as_storage(complex_type()));
+  this->impl_rebind(map_.impl_pool(),
+		    layout_.total_size(),
+		    this->user_data_.as_storage(complex_type()));
 }
 
 
Index: src/vsip/core/pool.hpp
===================================================================
--- src/vsip/core/pool.hpp	(revision 0)
+++ src/vsip/core/pool.hpp	(revision 0)
@@ -0,0 +1,81 @@
+/* Copyright (c) 2007 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/pool.hpp
+    @author  Jules Bergmann
+    @date    2007-04-11
+    @brief   VSIPL++ Library: Memory allocation pool
+*/
+
+#ifndef VSIP_CORE_POOL_HPP
+#define VSIP_CORE_POOL_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <limits>
+#include <cstdlib>
+#include <stdexcept>
+
+#include <vsip/support.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl 
+{
+
+/// Pool base class.
+
+class Pool
+{
+public:
+  Pool() {}
+  virtual ~Pool();
+
+  virtual void* allocate(size_t size) = 0;
+  virtual void  deallocate(void* ptr, size_t size) = 0;
+
+  virtual char const* name() = 0;
+};
+
+
+extern Pool* default_pool;
+
+void initialize_default_pool(int& argc, char**&argv);
+
+
+
+template <typename T>
+inline T*
+pool_alloc(
+  Pool*       pool,
+  length_type size)
+{
+  return (T*)(pool->allocate(size * sizeof(T)));
+}
+
+
+
+template <typename T>
+inline void
+pool_dealloc(
+  Pool*       pool,
+  T*          ptr,
+  length_type size)
+{
+  pool->deallocate(ptr, size * sizeof(T));
+}
+
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_CORE_POOL_HPP
Index: src/vsip/core/huge_page_pool.hpp
===================================================================
--- src/vsip/core/huge_page_pool.hpp	(revision 0)
+++ src/vsip/core/huge_page_pool.hpp	(revision 0)
@@ -0,0 +1,69 @@
+/* Copyright (c) 2007 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/huge_page_pool.hpp
+    @author  Jules Bergmann
+    @date    2007-04-11
+    @brief   VSIPL++ Library: Memory allocation pool
+*/
+
+#ifndef VSIP_CORE_HUGE_PAGE_POOL_HPP
+#define VSIP_CORE_HUGE_PAGE_POOL_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <limits>
+#include <cstdlib>
+
+#include <vsip/core/pool.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl 
+{
+
+class Huge_page_pool : public Pool
+{
+public:
+  static size_t const align = 128;
+
+  // Constructors and destructor.
+public:
+  Huge_page_pool(const char* file, int pages);
+  ~Huge_page_pool();
+
+  // Pool accessors.
+public:
+  void* allocate(size_t size);
+  void  deallocate(void* ptr, size_t size);
+
+  char const* name();
+
+  // Impl accessors.
+public:
+  size_t total_avail() { return total_avail_; }
+
+  // Member data.
+private:
+  char*  pool_;
+  size_t size_;
+  char*  free_;
+
+  size_t total_avail_;
+};
+
+
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_CORE_HUGE_PAGE_POOL_HPP
Index: src/vsip/core/aligned_pool.hpp
===================================================================
--- src/vsip/core/aligned_pool.hpp	(revision 0)
+++ src/vsip/core/aligned_pool.hpp	(revision 0)
@@ -0,0 +1,60 @@
+/* Copyright (c) 2007 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/aligned_pool.hpp
+    @author  Jules Bergmann
+    @date    2007-04-12
+    @brief   VSIPL++ Library: Memory allocation pool
+*/
+
+#ifndef VSIP_CORE_ALIGNED_POOL_HPP
+#define VSIP_CORE_ALIGNED_POOL_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/config.hpp>
+#include <vsip/core/pool.hpp>
+#include <vsip/core/allocation.hpp>
+#include <vsip/support.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl 
+{
+
+/// Aligned_pool implementation.
+
+class Aligned_pool
+  : public Pool
+{
+public:
+  static size_t const align = VSIP_IMPL_ALLOC_ALIGNMENT;
+
+  // Constructors and destructor.
+public:
+  Aligned_pool();
+  ~Aligned_pool();
+
+  // Accessors.
+public:
+  void* allocate(size_t size);
+  void  deallocate(void* ptr, size_t size);
+
+  char const* name();
+};
+  
+  
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_CORE_POOL_HPP
Index: src/vsip/core/pool.cpp
===================================================================
--- src/vsip/core/pool.cpp	(revision 0)
+++ src/vsip/core/pool.cpp	(revision 0)
@@ -0,0 +1,43 @@
+/* Copyright (c) 2007 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/pool.cpp
+    @author  Jules Bergmann
+    @date    2007-04-11
+    @brief   VSIPL++ Library: Memory allocation pool
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <limits>
+#include <cstdlib>
+
+#include <vsip/core/pool.hpp>
+#include <vsip/core/aligned_pool.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl 
+{
+
+Pool::~Pool()
+{}
+
+Pool* default_pool = 0;
+
+void initialize_default_pool(int& /*argc*/, char**& /*argv*/)
+{
+  default_pool = new Aligned_pool();
+}
+
+} // namespace vsip::impl
+
+} // namespace vsip
Index: src/vsip/core/huge_page_pool.cpp
===================================================================
--- src/vsip/core/huge_page_pool.cpp	(revision 0)
+++ src/vsip/core/huge_page_pool.cpp	(revision 0)
@@ -0,0 +1,236 @@
+/* Copyright (c) 2007 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/huge_page_pool.cpp
+    @author  Jules Bergmann
+    @date    2007-04-12
+    @brief   VSIPL++ Library: Memory allocation pool from huge pages
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <limits>
+#include <cstdlib>
+#include <iostream>
+#include <sys/types.h>
+#include <sys/stat.h>
+#include <sys/mman.h>
+#include <fcntl.h>
+#include <string.h>
+#include <errno.h>
+
+#include <vsip/core/config.hpp>
+#include <vsip/core/allocation.hpp>
+#include <vsip/core/huge_page_pool.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl 
+{
+
+// Allocate memory in huge page space (that are freed on program
+// termination)
+//
+// Requires
+//   MEM_FILE to be a filename in the /huge pages directory.
+//   PAGES to be the number of pages.
+//
+// Returns a pointer to the start of the memory if successful,
+//   NULL otherwise.
+
+char*
+open_huge_pages(char const* mem_file, int pages)
+{
+  int   fmem;
+  char* mem_addr;
+
+  if ((fmem = open(mem_file, O_CREAT | O_RDWR, 0755)) == -1)
+  {
+    std::cerr << "WARNING: unable to open file " << mem_file
+	      << " (errno=" << errno << " " << strerror(errno) << ")\n";
+    return 0;
+  }
+
+  // Delete file so that huge pages will get freed on program termination.
+  remove(mem_file);
+	
+  mem_addr = (char *)mmap(0, pages * 0x1000000,
+			   PROT_READ | PROT_WRITE, MAP_SHARED, fmem, 0);
+
+  if (mem_addr == MAP_FAILED)
+  {
+    std::cerr << "ERROR: unable to mmap file " << mem_file
+	      << " (errno=" << errno << " " << strerror(errno) << ")\n";
+    close(fmem);
+    return 0;
+  }
+
+    // Touch each of the large pages.
+    for (int i=0; i<pages; ++i)
+      mem_addr[i*0x1000000 + 0x0800000] = (char) 0;
+
+  return mem_addr;
+}
+
+
+
+/// Aligned_pool implementation.
+
+Huge_page_pool::Huge_page_pool(const char* file, int pages)
+  : pool_       (open_huge_pages(file, pages)),
+    size_       (pages * 0x1000000),
+    free_       (pool_),
+    total_avail_(size_)
+{
+  *(char**)free_ = 0; // next block
+  ((size_t*)free_)[1] = size_;
+}
+
+Huge_page_pool::~Huge_page_pool()
+{}
+
+void* 
+Huge_page_pool::allocate(size_t size)
+{
+  // std::cout << "allocate " << size << "\n";
+  // If size == 0, allocate 1 byte.
+  if (size < 2*sizeof(char*))
+    size = 2*sizeof(char*);
+
+  char*  prev  = 0;
+  char*  ptr   = free_;
+  size_t avail = ptr ? ((size_t*)ptr)[1] : 0;
+
+  while (ptr && avail < size)
+  {
+    // std::cout << " - skip " << avail << "\n";
+    prev  = ptr;
+    ptr   = *(char**)ptr;
+    avail = ptr ? ((size_t*)ptr)[1] : 0;
+  }
+
+  // std::cout << " = found " << avail << "\n";
+  if (ptr == 0)
+    VSIP_IMPL_THROW(std::bad_alloc());
+
+  total_avail_ -= size;
+
+  if (avail == size)
+  {
+    // std::cout << " - avail == size\n";
+    if (prev == 0)
+      free_ = *(char**)ptr;
+    else
+      *(char**)prev = *(char**)ptr;
+  }
+  else
+  {
+    if (prev == 0)
+    {
+      // std::cout << " - avail > size (moving free forward)\n";
+      free_ = ptr + size;
+    }
+    else
+    {
+      // std::cout << " - avail > size\n";
+      *(char**)prev = ptr + size;
+    }
+
+    *(char**)(ptr + size) = *(char**)ptr;
+    ((size_t*)(ptr + size))[1] = avail - size;
+  }
+
+  // std::cout << " = ptr: " << (void*)ptr << "\n";
+  return (void*)ptr;
+}
+
+void 
+Huge_page_pool::deallocate(void* return_ptr, size_t size)
+{
+  // std::cout << "deallocate " << size << " " << return_ptr << "\n";
+  if (size < 2*sizeof(char*))
+    size = 2*sizeof(char*);
+
+  char*  prev  = 0;
+  char*  ptr   = free_;
+
+  while (ptr && ptr < return_ptr)
+  {
+    prev  = ptr;
+    ptr   = *(char**)ptr;
+  }
+
+  if (ptr == 0)
+  {
+    // std::cout << " - free list empty\n";
+    ((size_t*)(return_ptr))[1] = size;
+    free_ = (char*)return_ptr;
+  }
+  else if (prev == 0)
+  {
+    assert(free_ == ptr);
+    assert(size <= ptr-(char*)return_ptr);
+    if (size == ptr - (char*)return_ptr)
+    {
+      // std::cout << " - insert at front of free list (merge)\n";
+      *(char**)(return_ptr)      = *(char**)ptr;
+      ((size_t*)(return_ptr))[1] = size + ((size_t*)(ptr))[1];
+      free_ = (char*)return_ptr;
+    }
+    else
+    {
+      // std::cout << " - insert at front of free list (no merge)\n";
+      *(char**)(return_ptr)      = ptr;
+      ((size_t*)(return_ptr))[1] = size;
+      free_ = (char*)return_ptr;
+    }
+  }
+  else
+  {
+    assert(size <= ptr-(char*)return_ptr);
+    if (size == ptr - (char*)return_ptr)
+    {
+      // std::cout << " - insert in middle of free list (merge)\n";
+      *(char**)(return_ptr)      = *(char**)ptr;
+      ((size_t*)(return_ptr))[1] = size + ((size_t*)(ptr))[1];
+    }
+    else
+    {
+      // std::cout << " - insert in middle of free list (no merge)\n";
+      *(char**)(return_ptr)      = ptr;
+      ((size_t*)(return_ptr))[1] = size;
+    }
+
+    size_t prev_size = ((size_t*)prev)[1];
+
+    if (prev_size == (char*)return_ptr - prev)
+    {
+      // std::cout << " + merge with prev\n";
+      *(char**)(prev) = *(char**)return_ptr;
+      ((size_t*)(prev))[1] = size + ((size_t*)(return_ptr))[1];
+    }
+    else
+      // std::cout << " + no merge with prev\n";
+      *(char**)(prev) = (char*)return_ptr;
+  }
+
+  total_avail_ += size;
+}
+
+char const* 
+Huge_page_pool::name()
+{
+  return "Huge_page_pool";
+}
+
+} // namespace vsip::impl
+
+} // namespace vsip
Index: src/vsip/core/parallel/local_map.hpp
===================================================================
--- src/vsip/core/parallel/local_map.hpp	(revision 191870)
+++ src/vsip/core/parallel/local_map.hpp	(working copy)
@@ -18,6 +18,7 @@
 #include <vsip/core/value_iterator.hpp>
 #include <vsip/core/parallel/services.hpp>
 #include <vsip/core/parallel/map_traits.hpp>
+#include <vsip/core/pool.hpp>
 
 
 
@@ -53,7 +54,7 @@
 
   // Constructor.
 public:
-  Local_map() {}
+  Local_map() : pool_(vsip::impl::default_pool) {}
 
   template <dimension_type Dim>
   Local_map(Local_or_global_map<Dim> const&) {}
@@ -122,7 +123,11 @@
   processor_type impl_proc_from_rank(index_type idx) const
     { assert(idx == 0); return local_processor(); }
 
-  // No member data.
+  impl::Pool* impl_pool() const { return pool_; }
+
+  // Member data.
+private:
+  impl::Pool* pool_;
 };
 
 namespace impl
Index: src/vsip/core/aligned_pool.cpp
===================================================================
--- src/vsip/core/aligned_pool.cpp	(revision 0)
+++ src/vsip/core/aligned_pool.cpp	(revision 0)
@@ -0,0 +1,66 @@
+/* Copyright (c) 2007 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/aligned_pool.cpp
+    @author  Jules Bergmann
+    @date    2007-04-12
+    @brief   VSIPL++ Library: Memory allocation pool
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/core/config.hpp>
+#include <vsip/core/pool.hpp>
+#include <vsip/core/aligned_pool.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl 
+{
+
+Aligned_pool::Aligned_pool()
+{}
+
+Aligned_pool::~Aligned_pool()
+{}
+
+
+void*
+Aligned_pool::allocate(size_t size)
+{
+  // If size == 0, allocate 1 byte.
+  if (size == 0)
+    size = 1;
+  
+  void* ptr = (void*)alloc_align<char>(align, size);
+  if (ptr == 0)
+    VSIP_IMPL_THROW(std::bad_alloc());
+  return ptr;
+}
+
+void
+Aligned_pool::deallocate(void* ptr, size_t size)
+{
+  free_align((char*)ptr);
+}
+
+char const*
+Aligned_pool::name()
+{
+  return "Aligned_pool";
+}
+  
+  
+
+} // namespace vsip::impl
+
+} // namespace vsip
Index: benchmarks/loop.hpp
===================================================================
--- benchmarks/loop.hpp	(revision 191870)
+++ benchmarks/loop.hpp	(working copy)
@@ -27,6 +27,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/math.hpp>
 #include <vsip/parallel.hpp>
+#include <vsip/core/pool.hpp>
 
 #ifdef VSIP_IMPL_SOURCERY_VPP
 #  define PARALLEL_LOOP 1
@@ -133,7 +134,8 @@
     show_time_   (false),
     mode_        (sweep_mode),
     m_array_     (),
-    param_       ()
+    param_       (),
+    pool_        (0)
   {}
 
   template <typename Functor>
@@ -183,6 +185,7 @@
   bench_mode    mode_;
   std::vector<unsigned> m_array_;
   std::map<std::string, std::string> param_;
+  vsip::impl::Pool*                  pool_;
 };
 
 
@@ -284,6 +287,7 @@
   using vsip::Vector;
   using vsip::Dense;
   using vsip::row1_type;
+  using vsip::impl::Pool;
 
   size_t   loop, M;
   float    time;
@@ -321,7 +325,12 @@
     {
       old_loop = loop;
       BARRIER(comm);
-      fcn(M, loop, time);
+      {
+	Pool* cur_pool = vsip::impl::default_pool;
+	if (pool_) vsip::impl::default_pool = pool_;
+	fcn(M, loop, time);
+	vsip::impl::default_pool = cur_pool;
+      }
       BARRIER(comm);
 
       LOCAL(dist_time).put(0, time);
@@ -386,7 +395,12 @@
     for (unsigned j=0; j<n_time; ++j)
     {
       BARRIER(comm);
-      fcn(M, loop, time);
+      {
+	Pool* cur_pool = vsip::impl::default_pool;
+	if (pool_) vsip::impl::default_pool = pool_;
+	fcn(M, loop, time);
+	vsip::impl::default_pool = cur_pool;
+      }
       BARRIER(comm);
 
       LOCAL(dist_time).put(0, time);
@@ -479,6 +493,7 @@
   using vsip::Vector;
   using vsip::Dense;
   using vsip::row1_type;
+  using vsip::impl::Pool;
 
   size_t   loop, M;
   float    time;
@@ -532,7 +547,12 @@
     M = (1 << start_);
 
     BARRIER(comm);
-    fcn(M, loop, time);
+    {
+      Pool* cur_pool = vsip::impl::default_pool;
+      if (pool_) vsip::impl::default_pool = pool_;
+      fcn(M, loop, time);
+      vsip::impl::default_pool = cur_pool;
+    }
     BARRIER(comm);
 
     LOCAL(dist_time).put(0, time);
@@ -590,7 +610,12 @@
   COMMUNICATOR_TYPE& comm  = DEFAULT_COMMUNICATOR();
 
   BARRIER(comm);
-  fcn(M, loop, time);
+  {
+    vsip::impl::Pool* cur_pool = vsip::impl::default_pool;
+    if (pool_) vsip::impl::default_pool = pool_;
+    fcn(M, loop, time);
+    vsip::impl::default_pool = cur_pool;
+  }
   BARRIER(comm);
 }
 
Index: benchmarks/main.cpp
===================================================================
--- benchmarks/main.cpp	(revision 191870)
+++ benchmarks/main.cpp	(working copy)
@@ -23,6 +23,7 @@
 
 #include <vsip/initfin.hpp>
 #include <vsip/core/check_config.hpp>
+#include <vsip/core/huge_page_pool.hpp>
 
 #include "benchmarks.hpp"
 
@@ -156,6 +157,16 @@
       std::cout << vsip::impl::library_config();
       return 0;
     }
+    else if (!strcmp(argv[i], "-pool"))
+    {
+      ++i;
+      if (!strcmp(argv[i], "def"))
+	;
+      else if (!strcmp(argv[i], "huge"))
+	loop.pool_ = new vsip::impl::Huge_page_pool("/huge/benchmark.bin", 9);
+      else
+	std::cerr << "ERROR: Unknown pool type: " << argv[i] << std::endl;
+    }
     else
       std::cerr << "ERROR: Unknown argument: " << argv[i] << std::endl;
   }
