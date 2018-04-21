Index: ChangeLog
===================================================================
--- ChangeLog	(revision 223485)
+++ ChangeLog	(working copy)
@@ -1,3 +1,13 @@
+2008-10-02  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/cbe/ppu/task_manager.hpp: Add split-complex vmmul task.
+	  Support for verbose task reporting.
+	* src/vsip/opt/cbe/ppu/bindings.hpp: Handle split-complex vmmul.
+	* src/vsip/opt/cbe/ppu/bindings.cpp: Likewise.
+	* src/vsip/opt/cbe/vmmul_params.h: Likewise.
+	* src/vsip/opt/cbe/ppu/alf.hpp: Support for verbose task reporting.
+	* src/vsip/opt/cbe/ppu/task_manager.cpp: Likewise.
+
 2008-10-01  Brooks Moses  <brooks@codesourcery.com>
 
 	* src/vsip/opt/cbe/spu/alf_fft_split_c.c: Include assert.h.
Index: src/vsip/opt/cbe/ppu/task_manager.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/task_manager.hpp	(revision 223485)
+++ src/vsip/opt/cbe/ppu/task_manager.hpp	(working copy)
@@ -59,6 +59,7 @@
   static void initialize(int& argc, char**&argv)
   {
     unsigned int num_spes = VSIP_IMPL_CBE_NUM_SPES;
+    bool         verbose  = false;
     for (int i=1; i < argc; ++i)
     {
       if (!strcmp(argv[i], "--svpp-num-spes"))
@@ -67,9 +68,15 @@
 	shift_argv(argc, argv, i, 2);
 	i -= 1;
       }
+      else if (!strcmp(argv[i], "--svpp-tm-verbose"))
+      {
+        verbose = true;
+        shift_argv(argc, argv, i, 1);
+        i -= 1;
+      }
     }
     
-    instance_ = new Task_manager(num_spes);
+    instance_ = new Task_manager(num_spes, verbose);
   }
   static void finalize() { delete instance_; instance_ = 0;}
 
@@ -92,7 +99,7 @@
   ALF* alf_handle() { return alf_; }
 
 private:
-  Task_manager(unsigned int num_spes);
+  Task_manager(unsigned int num_spes, bool verbose);
   Task_manager(Task_manager const &);
   ~Task_manager();
   Task_manager &operator= (Task_manager const &);
@@ -101,6 +108,7 @@
 
   ALF*        alf_;
   length_type num_spes_;
+  bool        verbose_;
 };
 
 } // namespace vsip::impl::cbe
@@ -131,5 +139,6 @@
 DEFINE_TASK(Fastconvm_tag, void(std::complex<float>, std::complex<float>), fconvm_c)
 DEFINE_TASK(Fastconvm_tag, void(split_float_type, split_float_type), fconvm_split_c)
 DEFINE_TASK(Vmmul_tag, std::complex<float>(std::complex<float>, std::complex<float>), vmmul_c)
+DEFINE_TASK(Vmmul_tag, split_float_type(split_float_type, split_float_type), vmmul_split_c)
 DEFINE_TASK(Pwarp_tag, void(unsigned char, unsigned char), pwarp_ub)
 #endif // VSIP_OPT_CBE_PPU_TASK_MANAGER_HPP
Index: src/vsip/opt/cbe/ppu/bindings.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.hpp	(revision 223485)
+++ src/vsip/opt/cbe/ppu/bindings.hpp	(working copy)
@@ -50,7 +50,15 @@
 template <typename T> void vmmul(T const* V, T const* M, T* R, 
   stride_type m_stride, stride_type r_stride, length_type length, length_type lines);
 
+template <typename T>
+void vmmul(
+  std::pair<T*, T*> const& V,
+  std::pair<T*, T*> const& M,
+  std::pair<T*, T*> const&             R,
+  stride_type m_stride, stride_type r_stride, 
+  length_type lines, length_type length);
 
+
 template <template <typename, typename> class Operator,
 	  typename DstBlock,
 	  typename LBlock,
@@ -213,9 +221,8 @@
   static bool const ct_valid = 
     !Is_expr_block<VBlock>::value &&
     !Is_expr_block<MBlock>::value &&
-    !Is_split_block<DstBlock>::value &&
-    !Is_split_block<VBlock>::value &&
-    !Is_split_block<MBlock>::value &&
+    (Is_split_block<DstBlock>::value == Is_split_block<VBlock>::value) &&
+    (Is_split_block<DstBlock>::value == Is_split_block<MBlock>::value) &&
      Type_equal<dst_type, v_type>::value &&
      Type_equal<dst_type, m_type>::value &&
      Type_equal<dst_type, std::complex<float> >::value &&
Index: src/vsip/opt/cbe/ppu/alf.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/alf.hpp	(revision 223485)
+++ src/vsip/opt/cbe/ppu/alf.hpp	(working copy)
@@ -143,16 +143,19 @@
 class ALF
 {
 public:
-  ALF(unsigned int num_accelerators)
+  ALF(unsigned int num_accelerators, bool verbose)
     : num_accelerators_(0)
   {
-    int   argc = 3;
-    char* argv[3];
-    char  number[256];
+    int   argc = 5;
+    char* argv[5];
+    char  number[256], t_verbose[256];
     sprintf(number, "%u", num_accelerators);
+    sprintf(t_verbose, "%u", verbose ? 1 : 0);
     argv[0] = "VSIPL++";
     argv[1] = "--cml-num-spes";
     argv[2] = number;
+    argv[3] = "--cml-verbose";
+    argv[4] = t_verbose;
     cml_init_argv(&argc, argv);
     alf_ = cml_impl_alf_handle();
     num_accelerators_ = cml_impl_alf_num_spes();
Index: src/vsip/opt/cbe/ppu/task_manager.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/task_manager.cpp	(revision 223485)
+++ src/vsip/opt/cbe/ppu/task_manager.cpp	(working copy)
@@ -15,7 +15,6 @@
 ***********************************************************************/
 
 #include <vsip/opt/cbe/ppu/task_manager.hpp>
-#include <iostream>
 
 namespace vsip
 {
@@ -26,8 +25,8 @@
 
 Task_manager *Task_manager::instance_ = 0;
 
-Task_manager::Task_manager(unsigned int num_spes)
-  : alf_     (new ALF(num_spes)),
+Task_manager::Task_manager(unsigned int num_spes, bool verbose)
+  : alf_     (new ALF(num_spes, verbose)),
     num_spes_(num_spes)
 {
 }
Index: src/vsip/opt/cbe/ppu/bindings.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.cpp	(revision 223485)
+++ src/vsip/opt/cbe/ppu/bindings.cpp	(working copy)
@@ -186,6 +186,79 @@
   std::complex<float> const* V, std::complex<float> const* M, std::complex<float>* R, 
   stride_type m_stride, stride_type r_stride, length_type length, length_type lines);
 
+
+
+// Split-complex vmmul
+
+template <typename T>
+void vmmul(
+  std::pair<T*, T*> const& V,
+  std::pair<T*, T*> const& M,
+  std::pair<T*, T*> const& R,
+  stride_type              m_stride,
+  stride_type              r_stride, 
+  length_type              lines,
+  length_type              length)
+// Result R = V * M
+//   where
+//   - m_stride is the distance between input rows (or cols)
+//   - r_stride is the distance between output rows (or cols)
+//   - lines expresses the number of rows (cols)
+//   - length is the size of the input vector 
+{
+  Vmmul_split_params params;
+  params.length = length;
+  assert(length >= VSIP_IMPL_MIN_VMMUL_SIZE);
+  assert(length <= VSIP_IMPL_MAX_VMMUL_SIZE);
+
+  params.command = VSIP_IMPL_VMMUL_RELOAD_VECTOR;
+  params.input_stride = m_stride;
+  params.output_stride = r_stride;
+  params.ea_input_vector_re  = ea_from_ptr(V.first);
+  params.ea_input_vector_im  = ea_from_ptr(V.second);
+  params.ea_input_matrix_re  = ea_from_ptr(M.first);
+  params.ea_input_matrix_im  = ea_from_ptr(M.second);
+  params.ea_output_matrix_re = ea_from_ptr(R.first);
+  params.ea_output_matrix_im = ea_from_ptr(R.second);
+
+  Task_manager* mgr = Task_manager::instance();
+  length_type psize = sizeof(Vmmul_split_params);
+  // 081002 - maximum stack size is set based on inter-complex size.
+  length_type stack_size = 1024*4;
+
+  typedef std::pair<T*,T*> split_type;
+  Task task = mgr->reserve<Vmmul_tag, split_type(split_type, split_type)>
+    (stack_size, psize, 2*sizeof(T)*length, 2*sizeof(T)*length, 8);
+
+  length_type spes   = mgr->num_spes();
+  length_type vectors_per_spe = lines / spes;
+  assert(vectors_per_spe * spes <= lines);
+
+  for (index_type i=0; i<spes && i<lines; ++i)
+  {
+    // If chunks don't divide evenly, give the first SPEs one extra.
+    length_type lines_per_spe = (i < lines % spes) ? vectors_per_spe + 1
+                                                   : vectors_per_spe;
+
+    Workblock block = task.create_workblock(lines_per_spe);
+    block.set_parameters(params);
+    block.enqueue();
+
+    params.ea_input_matrix_re  += sizeof(T) * lines_per_spe * m_stride;
+    params.ea_input_matrix_im  += sizeof(T) * lines_per_spe * m_stride;
+    params.ea_output_matrix_re += sizeof(T) * lines_per_spe * r_stride;
+    params.ea_output_matrix_im += sizeof(T) * lines_per_spe * r_stride;
+  }
+  task.sync();
+}
+
+template
+void vmmul(
+  std::pair<float*, float*> const& V,
+  std::pair<float*, float*> const& M,
+  std::pair<float*, float*> const&             R,
+  stride_type m_stride, stride_type r_stride, 
+  length_type lines, length_type length);
 } // namespace vsip::impl::cbe
 } // namespace vsip::impl
 } // namespace vsip
Index: src/vsip/opt/cbe/vmmul_params.h
===================================================================
--- src/vsip/opt/cbe/vmmul_params.h	(revision 223485)
+++ src/vsip/opt/cbe/vmmul_params.h	(working copy)
@@ -56,7 +56,23 @@
   unsigned long long unused_padding;
 } Vmmul_params;
 
+typedef struct
+{
+  unsigned int length;
+  unsigned int command;
+  unsigned int input_stride;
+  unsigned int output_stride;
 
+  unsigned long long ea_input_vector_re;
+  unsigned long long ea_input_vector_im;
+  unsigned long long ea_input_matrix_re;
+  unsigned long long ea_input_matrix_im;
+
+  unsigned long long ea_output_matrix_re;
+  unsigned long long ea_output_matrix_im;
+} Vmmul_split_params;
+
+
 #ifdef _cplusplus
 } // namespace vsip::impl::cbe
 } // namespace vsip::impl
