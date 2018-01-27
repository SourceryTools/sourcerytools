Index: ChangeLog
===================================================================
--- ChangeLog	(revision 204788)
+++ ChangeLog	(working copy)
@@ -1,5 +1,48 @@
 2008-04-15  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/initfin.cpp: Initialize default pool.
+	* src/vsip/dense.hpp: Use pools for allocation.
+	* src/vsip/core/memory_pool.hpp: New file, Memory_pool virtual base
+	  class header.
+	* src/vsip/core/memory_pool.cpp: New file, Memory_pool virtual base
+	  class impl.
+	* src/vsip/core/huge_page_pool.hpp: New file, pool implementation
+          using huge page memory header.
+	* src/vsip/core/huge_page_pool.cpp:  New file, pool implementation
+          using huge page memory impl.
+	* src/vsip/core/aligned_pool.hpp: New file, pool implementation 
+          using alloc_align header.
+	* src/vsip/core/aligned_pool.cpp: New file, pool implementation 
+          using alloc_align impl.
+	* src/vsip/core/parallel/local_map.hpp: Hold pool.
+	* src/vsip/GNUmakefile.inc.in (cxx_sources): Optionally filter out
+	  huge_page_pool.
+	* GNUmakefile.in (VSIP_IMPL_HAVE_HUGE_PAGE_POOL): New variable.
+	* benchmarks/loop.hpp: Allow alternate pool to be used.
+	* benchmarks/main.cpp: Likewise.
+
+	* tests/fns_userelt.cpp: Add missing vsipl init.
+	* tests/selgen.cpp: Likewise.
+	* tests/matrix.cpp: Likewise.
+	* tests/lvalue-proxy.cpp: Likewise.
+	* tests/tensor.cpp: Likewise.
+	* tests/tensor_subview.cpp: Likewise.
+	* tests/appmap.cpp: Likewise.
+	* tests/user_storage.cpp: Likewise.
+	* tests/subblock.cpp: Likewise.
+	* tests/regressions/view_index.cpp: Likewise.
+	* tests/regressions/conv_to_subview.cpp: Likewise.
+	* tests/regressions/complex_proxy.cpp: Likewise.
+	* tests/view_operators.cpp: Likewise.
+	* tests/extdata.cpp: Likewise.
+	* tests/extdata-matadd.cpp: Likewise.
+	* tests/expression.cpp: Likewise.
+	* tests/vector.cpp: Likewise.
+	* tests/view.cpp: Likewise.
+	* tests/coverage_unary.cpp: Likewise.
+
+2008-04-15  Jules Bergmann  <jules@codesourcery.com>
+
 	* scripts/char.pl (-extra): Extra args for all benchmarks.
 	* scripts/datasheet.pl: Add section headers, prettier printing
 	  of time/call and time/point.
Index: src/vsip/initfin.cpp
===================================================================
--- src/vsip/initfin.cpp	(revision 191870)
+++ src/vsip/initfin.cpp	(working copy)
@@ -13,6 +13,7 @@
 #include <vsip/initfin.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/core/parallel/services.hpp>
+#include <vsip/core/memory_pool.hpp>
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
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/dense.hpp
     @author  Jules Bergmann
@@ -26,6 +26,7 @@
 #include <vsip/core/block_traits.hpp>
 #include <vsip/core/parallel/choose_dist_block.hpp>
 #include <vsip/domain.hpp>
+#include <vsip/core/memory_pool.hpp>
 
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
+  Dense_storage(Memory_pool*  pool,
+		length_type   size,
+		type          buffer = NULL)
     VSIP_THROW((std::bad_alloc))
-    : allocator_ (allocator),
-      alloc_data_(buffer == NULL),
-      data_      (alloc_data_ ? allocator_.allocate(size) : (T*)buffer)
+    : alloc_data_(buffer == NULL),
+      data_      (alloc_data_ ? pool->allocate<T>(size) : (T*)buffer)
   {}
 
-  Dense_storage(length_type   size,
+  Dense_storage(Memory_pool*  pool,
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
+      data_      (alloc_data_ ? pool->allocate<T>(size) : (T*)buffer)
   {
     for (index_type i=0; i<size; ++i)
       data_[i] = val;
@@ -337,13 +335,13 @@
 
   // Accessors.
 protected:
-  void impl_rebind(length_type size, type buffer);
+  void impl_rebind(Memory_pool* pool, length_type size, type buffer);
 
-  void deallocate(length_type size)
+  void deallocate(Memory_pool* pool, length_type size)
   {
     if (alloc_data_)
     {
-      allocator_.deallocate(data_, size);
+      pool->deallocate(data_, size);
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
+  Dense_storage(Memory_pool*  pool,
+		length_type   size,
+		type          buffer    = type(0, 0))
     VSIP_THROW((std::bad_alloc))
-    : allocator_ (allocator),
-      alloc_data_(buffer.first == NULL || buffer.second == NULL),
-      real_data_ (alloc_data_ ? allocator_.allocate(size) : buffer.first),
-      imag_data_ (alloc_data_ ? allocator_.allocate(size) : buffer.second)
+    : alloc_data_(buffer.first == NULL || buffer.second == NULL),
+      real_data_ (alloc_data_ ? pool->allocate<T>(size) : buffer.first),
+      imag_data_ (alloc_data_ ? pool->allocate<T>(size) : buffer.second)
   {}
 
-  Dense_storage(length_type      size,
+  Dense_storage(Memory_pool*     pool,
+		length_type      size,
 		vsip::complex<T> val,
 		type buffer = type(0, 0))
     VSIP_THROW((std::bad_alloc))
     : alloc_data_(buffer.first == NULL || buffer.second == NULL),
-      real_data_ (alloc_data_ ? allocator_.allocate(size) : buffer.first),
-      imag_data_ (alloc_data_ ? allocator_.allocate(size) : buffer.second)
+      real_data_ (alloc_data_ ? pool->allocate<T>(size) : buffer.first),
+      imag_data_ (alloc_data_ ? pool->allocate<T>(size) : buffer.second)
   {
     for (index_type i=0; i<size; ++i)
       real_data_[i] = val.real();
@@ -414,14 +410,14 @@
 
   // Accessors.
 protected:
-  void impl_rebind(length_type size, type buffer);
+  void impl_rebind(Memory_pool* pool, length_type size, type buffer);
 
-  void deallocate(length_type size)
+  void deallocate(Memory_pool* pool, length_type size)
   {
     if (alloc_data_)
     {
-      allocator_.deallocate(real_data_, size);
-      allocator_.deallocate(imag_data_, size);
+      pool->deallocate(real_data_, size);
+      pool->deallocate(imag_data_, size);
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
-  length_type size,
-  type        buffer)
+Dense_storage<ComplexFmt, T>::impl_rebind(
+  Memory_pool* pool,
+  length_type  size,
+  type         buffer)
 {
   if (buffer != NULL)
   {
     if (alloc_data_)
-      allocator_.deallocate(data_, size);
+      pool->deallocate<T>(data_, size);
     
     alloc_data_ = false;
     data_       = buffer;
@@ -1293,7 +1288,7 @@
     if (!alloc_data_)
     {
       alloc_data_ = true;
-      data_ = allocator_.allocate(size);
+      data_ = pool->allocate<T>(size);
     }
     /* else do nothing - we already own our data */
   }
@@ -1306,19 +1301,19 @@
 /// Requires:
 ///   SIZE to be size object was constructed with.
 
-template <typename T,
-	  typename AllocT>
+template <typename T>
 void
-Dense_storage<Cmplx_split_fmt, vsip::complex<T>, AllocT>::impl_rebind(
-  length_type size,
-  type        buffer)
+Dense_storage<Cmplx_split_fmt, vsip::complex<T> >::impl_rebind(
+  Memory_pool* pool,
+  length_type  size,
+  type         buffer)
 {
   if (buffer.first != NULL && buffer.second != NULL)
   {
     if (alloc_data_)
     {
-      allocator_.deallocate(real_data_, size);
-      allocator_.deallocate(imag_data_, size);
+      pool->deallocate(real_data_, size);
+      pool->deallocate(imag_data_, size);
     }
     
     alloc_data_ = false;
@@ -1330,8 +1325,8 @@
     if (!alloc_data_)
     {
       alloc_data_ = true;
-      real_data_ = allocator_.allocate(size);
-      imag_data_ = allocator_.allocate(size);
+      real_data_ = pool->allocate<T>(size);
+      imag_data_ = pool->allocate<T>(size);
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
+		map_.impl_pool(), layout_.total_size(),
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
 
 
Index: src/vsip/core/memory_pool.hpp
===================================================================
--- src/vsip/core/memory_pool.hpp	(revision 0)
+++ src/vsip/core/memory_pool.hpp	(revision 0)
@@ -0,0 +1,72 @@
+/* Copyright (c) 2007, 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/memory_pool.hpp
+    @author  Jules Bergmann
+    @date    2007-04-11
+    @brief   VSIPL++ Library: Memory allocation pool
+*/
+
+#ifndef VSIP_CORE_MEMORY_POOL_HPP
+#define VSIP_CORE_MEMORY_POOL_HPP
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
+/// Memory_pool base class.
+
+class Memory_pool
+{
+public:
+  Memory_pool() {}
+  virtual ~Memory_pool();
+
+  virtual void* impl_allocate(size_t size) = 0;
+  virtual void  impl_deallocate(void* ptr, size_t size) = 0;
+
+  virtual char const* name() = 0;
+
+  // Convenience functions
+  template <typename T>
+  T* allocate(length_type size)
+  { return (T*)(impl_allocate(size * sizeof(T))); }
+
+  template <typename T>
+  void deallocate(
+    T*           ptr,
+    length_type  size)
+  {
+    impl_deallocate(ptr, size * sizeof(T));
+  }
+};
+
+
+extern Memory_pool* default_pool;
+
+void initialize_default_pool(int& argc, char**&argv);
+
+
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_CORE_POOL_HPP
Index: src/vsip/core/memory_pool.cpp
===================================================================
--- src/vsip/core/memory_pool.cpp	(revision 0)
+++ src/vsip/core/memory_pool.cpp	(revision 0)
@@ -0,0 +1,43 @@
+/* Copyright (c) 2007, 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/memory_pool.cpp
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
+#include <vsip/core/memory_pool.hpp>
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
+Memory_pool::~Memory_pool()
+{}
+
+Memory_pool* default_pool = 0;
+
+void initialize_default_pool(int& /*argc*/, char**& /*argv*/)
+{
+  default_pool = new Aligned_pool();
+}
+
+} // namespace vsip::impl
+
+} // namespace vsip
Index: src/vsip/core/huge_page_pool.hpp
===================================================================
--- src/vsip/core/huge_page_pool.hpp	(revision 0)
+++ src/vsip/core/huge_page_pool.hpp	(revision 0)
@@ -0,0 +1,74 @@
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
+#include <vsip/core/memory_pool.hpp>
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
+#if VSIP_IMPL_ENABLE_HUGE_PAGE_POOL
+class Huge_page_pool : public Memory_pool
+{
+public:
+  static size_t const align = 128;
+
+  // Constructors and destructor.
+public:
+  Huge_page_pool(const char* file, int pages);
+  ~Huge_page_pool();
+
+  // Memory_pool accessors.
+public:
+  void* impl_allocate(size_t size);
+  void  impl_deallocate(void* ptr, size_t size);
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
+#else
+typedef Aligned_pool Huge_page_pool;
+#endif
+
+
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_CORE_HUGE_PAGE_POOL_HPP
Index: src/vsip/core/huge_page_pool.cpp
===================================================================
--- src/vsip/core/huge_page_pool.cpp	(revision 0)
+++ src/vsip/core/huge_page_pool.cpp	(revision 0)
@@ -0,0 +1,234 @@
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
+#if VSIP_IMPL_ENABLE_HUGE_PAGE_POOL
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
+Huge_page_pool::impl_allocate(size_t size)
+{
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
+    prev  = ptr;
+    ptr   = *(char**)ptr;
+    avail = ptr ? ((size_t*)ptr)[1] : 0;
+  }
+
+  if (ptr == 0)
+    VSIP_IMPL_THROW(std::bad_alloc());
+
+  total_avail_ -= size;
+
+  if (avail == size)
+  {
+    // Exact match.
+    if (prev == 0)
+      free_ = *(char**)ptr;
+    else
+      *(char**)prev = *(char**)ptr;
+  }
+  else
+  {
+    // Larger match, carve out chunk.
+    if (prev == 0)
+    {
+      free_ = ptr + size;
+    }
+    else
+    {
+      *(char**)prev = ptr + size;
+    }
+
+    *(char**)(ptr + size) = *(char**)ptr;
+    ((size_t*)(ptr + size))[1] = avail - size;
+  }
+
+  return (void*)ptr;
+}
+
+void 
+Huge_page_pool::impl_deallocate(void* return_ptr, size_t size)
+{
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
+    // Free list empty.
+    ((size_t*)(return_ptr))[1] = size;
+    free_ = (char*)return_ptr;
+  }
+  else if (prev == 0)
+  {
+    assert(free_ == ptr);
+    assert(ptr-(char*)return_ptr >= (ptrdiff_t)size);
+    if ((ptrdiff_t)size == ptr - (char*)return_ptr)
+    {
+      // Insert at front of free list, merge with next entry.
+      *(char**)(return_ptr)      = *(char**)ptr;
+      ((size_t*)(return_ptr))[1] = size + ((size_t*)(ptr))[1];
+      free_ = (char*)return_ptr;
+    }
+    else
+    {
+      // Insert at front of free list, no merge.
+      *(char**)(return_ptr)      = ptr;
+      ((size_t*)(return_ptr))[1] = size;
+      free_ = (char*)return_ptr;
+    }
+  }
+  else
+  {
+    assert(ptr-(char*)return_ptr >= (ptrdiff_t)size);
+    if ((ptrdiff_t)size == ptr - (char*)return_ptr)
+    {
+      // Insert in middle of free list, merge
+      *(char**)(return_ptr)      = *(char**)ptr;
+      ((size_t*)(return_ptr))[1] = size + ((size_t*)(ptr))[1];
+    }
+    else
+    {
+      // Insert in middle of free list, no merge
+      *(char**)(return_ptr)      = ptr;
+      ((size_t*)(return_ptr))[1] = size;
+    }
+
+    size_t prev_size = ((size_t*)prev)[1];
+
+    if ((ptrdiff_t)prev_size == (char*)return_ptr - prev)
+    {
+      // Merge with prev.
+      *(char**)(prev) = *(char**)return_ptr;
+      ((size_t*)(prev))[1] = size + ((size_t*)(return_ptr))[1];
+    }
+    else
+      // No merge with prev.
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
+
+#endif // VSIP_IMPL_ENABLE_HUGE_PAGE_POOL
Index: src/vsip/core/aligned_pool.hpp
===================================================================
--- src/vsip/core/aligned_pool.hpp	(revision 0)
+++ src/vsip/core/aligned_pool.hpp	(revision 0)
@@ -0,0 +1,60 @@
+/* Copyright (c) 2007, 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/aligned_pool.hpp
+    @author  Jules Bergmann
+    @date    2007-04-12
+    @brief   VSIPL++ Library: Aligned memory allocation pool
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
+#include <vsip/core/memory_pool.hpp>
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
+  : public Memory_pool
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
+  void* impl_allocate(size_t size);
+  void  impl_deallocate(void* ptr, size_t size);
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
Index: src/vsip/core/aligned_pool.cpp
===================================================================
--- src/vsip/core/aligned_pool.cpp	(revision 0)
+++ src/vsip/core/aligned_pool.cpp	(revision 0)
@@ -0,0 +1,66 @@
+/* Copyright (c) 2007, 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/aligned_pool.cpp
+    @author  Jules Bergmann
+    @date    2007-04-12
+    @brief   VSIPL++ Library: Aligned memory allocation pool
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/core/config.hpp>
+#include <vsip/core/memory_pool.hpp>
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
+Aligned_pool::impl_allocate(size_t size)
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
+Aligned_pool::impl_deallocate(void* ptr, size_t /*size*/)
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
Index: src/vsip/core/parallel/local_map.hpp
===================================================================
--- src/vsip/core/parallel/local_map.hpp	(revision 191870)
+++ src/vsip/core/parallel/local_map.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/parallel/local_map.hpp
     @author  Jules Bergmann
@@ -18,6 +18,7 @@
 #include <vsip/core/value_iterator.hpp>
 #include <vsip/core/parallel/services.hpp>
 #include <vsip/core/parallel/map_traits.hpp>
+#include <vsip/core/memory_pool.hpp>
 
 
 
@@ -53,13 +54,17 @@
 
   // Constructor.
 public:
-  Local_map() {}
+  Local_map() : pool_(vsip::impl::default_pool) {}
 
   template <dimension_type Dim>
-  Local_map(Local_or_global_map<Dim> const&) {}
+  Local_map(Local_or_global_map<Dim> const&)
+    : pool_(vsip::impl::default_pool)
+  {}
 
   template <dimension_type Dim>
-  Local_map(impl::Scalar_block_map<Dim> const&) {}
+  Local_map(impl::Scalar_block_map<Dim> const&)
+    : pool_(vsip::impl::default_pool)
+  {}
 
   // Accessors.
 public:
@@ -122,7 +127,11 @@
   processor_type impl_proc_from_rank(index_type idx) const
     { assert(idx == 0); return local_processor(); }
 
-  // No member data.
+  impl::Memory_pool* impl_pool() const { return pool_; }
+
+  // Member data.
+private:
+  impl::Memory_pool* pool_;
 };
 
 namespace impl
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 191870)
+++ GNUmakefile.in	(working copy)
@@ -129,6 +129,7 @@
 VSIP_IMPL_HAVE_MPI := @VSIP_IMPL_HAVE_MPI@
 VSIP_IMPL_HAVE_CVSIP := @VSIP_IMPL_HAVE_CVSIP@
 VSIP_IMPL_HAVE_CBE_SDK := @VSIP_IMPL_HAVE_CBE_SDK@
+VSIP_IMPL_HAVE_HUGE_PAGE_POOL := @VSIP_IMPL_HAVE_HUGE_PAGE_POOL@
 VSIP_IMPL_SAL_FFT := @VSIP_IMPL_SAL_FFT@
 VSIP_IMPL_IPP_FFT := @VSIP_IMPL_IPP_FFT@
 VSIP_IMPL_FFTW3 := @VSIP_IMPL_FFTW3@
Index: benchmarks/loop.hpp
===================================================================
--- benchmarks/loop.hpp	(revision 191870)
+++ benchmarks/loop.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -27,6 +27,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/math.hpp>
 #include <vsip/parallel.hpp>
+#include <vsip/core/memory_pool.hpp>
 
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
+  vsip::impl::Memory_pool*           pool_;
 };
 
 
@@ -284,6 +287,7 @@
   using vsip::Vector;
   using vsip::Dense;
   using vsip::row1_type;
+  using vsip::impl::Memory_pool;
 
   size_t   loop, M;
   float    time;
@@ -321,7 +325,12 @@
     {
       old_loop = loop;
       BARRIER(comm);
-      fcn(M, loop, time);
+      {
+	Memory_pool* cur_pool = vsip::impl::default_pool;
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
+	Memory_pool* cur_pool = vsip::impl::default_pool;
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
+  using vsip::impl::Memory_pool;
 
   size_t   loop, M;
   float    time;
@@ -532,7 +547,12 @@
     M = (1 << start_);
 
     BARRIER(comm);
-    fcn(M, loop, time);
+    {
+      Memory_pool* cur_pool = vsip::impl::default_pool;
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
+    vsip::impl::Memory_pool* cur_pool = vsip::impl::default_pool;
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
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -23,6 +23,7 @@
 
 #include <vsip/initfin.hpp>
 #include <vsip/core/check_config.hpp>
+#include <vsip/core/huge_page_pool.hpp>
 
 #include "benchmarks.hpp"
 
@@ -156,6 +157,18 @@
       std::cout << vsip::impl::library_config();
       return 0;
     }
+    else if (!strcmp(argv[i], "-pool"))
+    {
+      ++i;
+      if (!strcmp(argv[i], "def"))
+	;
+#if VSIP_IMPL_ENABLE_HUGE_PAGE_POOL
+      else if (!strcmp(argv[i], "huge"))
+	loop.pool_ = new vsip::impl::Huge_page_pool("/huge/benchmark.bin", 9);
+#endif
+      else
+	std::cerr << "ERROR: Unknown pool type: " << argv[i] << std::endl;
+    }
     else
       std::cerr << "ERROR: Unknown argument: " << argv[i] << std::endl;
   }
Index: tests/fns_userelt.cpp
===================================================================
--- tests/fns_userelt.cpp	(revision 191870)
+++ tests/fns_userelt.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -18,6 +18,8 @@
 
 #include <cassert>
 #include <complex>
+
+#include <vsip/initfin.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/math.hpp>
@@ -145,8 +147,11 @@
   test_assert(result.get(2) == my_ternary(input1(2), input2(2), input3(2)));
 }
 
-int main(int, char **)
+int
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   unary_funptr();
   unary_stdfunc();
   unary_func();
Index: tests/selgen.cpp
===================================================================
--- tests/selgen.cpp	(revision 191870)
+++ tests/selgen.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -17,6 +17,7 @@
 
 #include <cassert>
 #include <complex>
+#include <vsip/initfin.hpp>
 #include <vsip/selgen.hpp>
 #include <functional>
 #include <vsip_csl/test.hpp>
@@ -127,8 +128,10 @@
 }
 
 int 
-main(int, char **)
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_first();
   test_indexbool();
   test_gather_scatter();
Index: tests/matrix.cpp
===================================================================
--- tests/matrix.cpp	(revision 191870)
+++ tests/matrix.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -20,6 +20,8 @@
 
 #include <iostream>
 #include <cassert>
+
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip_csl/test.hpp>
@@ -795,8 +797,10 @@
 }
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_get(10, 10);
   test_getput(10, 10);
 
Index: tests/lvalue-proxy.cpp
===================================================================
--- tests/lvalue-proxy.cpp	(revision 191870)
+++ tests/lvalue-proxy.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -12,12 +12,14 @@
     Explicit instantiation of lvalue proxy objects and tests of their
     functionality.  */
 
-#include <vsip_csl/test.hpp>
 #include <vsip/core/lvalue_proxy.hpp>
 #include <vsip/core/static_assert.hpp>
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/dense.hpp>
+#include <vsip/initfin.hpp>
 
+#include <vsip_csl/test.hpp>
+
 using namespace vsip;
 using namespace vsip_csl;
 
@@ -375,8 +377,9 @@
 }
 
 int
-main(void)
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
 #if 0
   // Type equalities valid for any block.
   VSIP_IMPL_STATIC_ASSERT((
Index: tests/tensor.cpp
===================================================================
--- tests/tensor.cpp	(revision 191870)
+++ tests/tensor.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -20,6 +20,7 @@
 
 #include <iostream>
 #include <cassert>
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/tensor.hpp>
 #include <vsip_csl/test.hpp>
@@ -1041,8 +1042,10 @@
 }
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_get(10, 10, 10);
   test_getput(10, 10, 10);
 
Index: tests/tensor_subview.cpp
===================================================================
--- tests/tensor_subview.cpp	(revision 191870)
+++ tests/tensor_subview.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -16,6 +16,7 @@
 
 #include <cassert>
 
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/tensor.hpp>
 
@@ -323,8 +324,10 @@
 
 
 int
-main(void)
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_tensor_vector();
   test_tensor_matrix();
 }
Index: tests/appmap.cpp
===================================================================
--- tests/appmap.cpp	(revision 191870)
+++ tests/appmap.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -17,6 +17,7 @@
 #include <vsip/support.hpp>
 #include <vsip/map.hpp>
 #include <vsip/matrix.hpp>
+#include <vsip/initfin.hpp>
 #include <vsip/core/length.hpp>
 #include <vsip/core/domain_utils.hpp>
 #include <vsip_csl/test.hpp>
@@ -389,6 +390,8 @@
 int
 main()
 {
+  vsip::vsipl init;
+
   test_appmap();
 
   test_empty_subblocks();
Index: tests/user_storage.cpp
===================================================================
--- tests/user_storage.cpp	(revision 191870)
+++ tests/user_storage.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -16,6 +16,8 @@
 
 #include <iostream>
 #include <cassert>
+
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/core/domain_utils.hpp>
@@ -546,8 +548,10 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_array_format<float,          row1_type>(Domain<1>(50));
   test_array_format<complex<float>, row1_type>(Domain<1>(50));
 
Index: tests/subblock.cpp
===================================================================
--- tests/subblock.cpp	(revision 191870)
+++ tests/subblock.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -16,6 +16,8 @@
 
 #include <iostream>
 #include <cassert>
+
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/domain.hpp>
 #include <vsip/dense.hpp>
@@ -115,8 +117,10 @@
 }
   
 int
-main(void)
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_slices_1d<int>();
   test_slices_1d<float>();
 
Index: tests/regressions/view_index.cpp
===================================================================
--- tests/regressions/view_index.cpp	(revision 191870)
+++ tests/regressions/view_index.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -15,6 +15,8 @@
 ***********************************************************************/
 
 #include <cassert>
+
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
@@ -70,8 +72,10 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_vector<float>();		// OK
   test_vector<index_type>();	// Does not compile
 
Index: tests/regressions/conv_to_subview.cpp
===================================================================
--- tests/regressions/conv_to_subview.cpp	(revision 191870)
+++ tests/regressions/conv_to_subview.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -20,6 +20,7 @@
 #include <iostream>
 #include <cassert>
 
+#include <vsip/initfin.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/signal.hpp>
 
@@ -150,8 +151,10 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_conv_nonsym_split<float, support_min>(4, 0, 1, +1, +1);
   test_conv_nonsym_split<float, support_min>(5, 0, 1, +1, -1);
 
Index: tests/regressions/complex_proxy.cpp
===================================================================
--- tests/regressions/complex_proxy.cpp	(revision 191870)
+++ tests/regressions/complex_proxy.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -51,6 +51,7 @@
   Included Files
 ***********************************************************************/
 
+#include <vsip/initfin.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/core/lvalue_proxy.hpp>
 #include <vsip/core/static_assert.hpp>
@@ -122,8 +123,10 @@
 
 
 int
-main(void)
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_fun();
 
   return 0;
Index: tests/view_operators.cpp
===================================================================
--- tests/view_operators.cpp	(revision 191870)
+++ tests/view_operators.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -18,6 +18,8 @@
 
 #include <cassert>
 #include <complex>
+
+#include <vsip/initfin.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/dense.hpp>
@@ -291,8 +293,10 @@
 }
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   typedef Vector<float, Dense<1, float> > DVector;
   typedef const_Vector<float, Dense<1, float> > const_DVector;
   typedef Matrix<float, Dense<2, float> > DMatrix;
Index: tests/extdata.cpp
===================================================================
--- tests/extdata.cpp	(revision 191870)
+++ tests/extdata.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -16,6 +16,8 @@
 
 #include <iostream>
 #include <cassert>
+
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/vector.hpp>
@@ -582,8 +584,10 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   using vsip::impl::Direct_access_tag;
   using vsip::impl::Copy_access_tag;
 
Index: tests/extdata-matadd.cpp
===================================================================
--- tests/extdata-matadd.cpp	(revision 191870)
+++ tests/extdata-matadd.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -34,6 +34,7 @@
 
 #include <iostream>
 #include <cassert>
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/matrix.hpp>
@@ -452,8 +453,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
   test_matrix_add<row2_type, row2_type, row2_type>();
   test_matrix_add<row2_type, col2_type, row2_type>();
   test_matrix_add<row2_type, row2_type, col2_type>();
Index: tests/expression.cpp
===================================================================
--- tests/expression.cpp	(revision 191870)
+++ tests/expression.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -16,6 +16,7 @@
   Included Files
 ***********************************************************************/
 
+#include <vsip/initfin.hpp>
 #include <vsip/math.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/map.hpp>
@@ -143,7 +144,9 @@
 }
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_1d();
 }
Index: tests/vector.cpp
===================================================================
--- tests/vector.cpp	(revision 191870)
+++ tests/vector.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -20,6 +20,8 @@
 
 #include <iostream>
 #include <cassert>
+
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
 #include <vsip_csl/test.hpp>
@@ -641,8 +643,10 @@
 }
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_get(10);
   test_getput(10);
 
Index: tests/view.cpp
===================================================================
--- tests/view.cpp	(revision 191870)
+++ tests/view.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -21,6 +21,8 @@
 
 #include <iostream>
 #include <cassert>
+
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
@@ -1134,8 +1136,10 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_all(Domain<1>(1),   3);
   test_all(Domain<1>(10),  3);
   test_all(Domain<1>(257), 3);
Index: tests/coverage_unary.cpp
===================================================================
--- tests/coverage_unary.cpp	(revision 191870)
+++ tests/coverage_unary.cpp	(working copy)
@@ -14,7 +14,8 @@
   Included Files
 ***********************************************************************/
 
-#include <iostream>
+// VERBOSE is recognized by coverage_common.hpp
+#define VERBOSE 0
 
 #include <vsip/support.hpp>
 #include <vsip/initfin.hpp>
