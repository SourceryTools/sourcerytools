
Index: benchmarks/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/GNUmakefile.inc.in,v
retrieving revision 1.5
diff -c -p -r1.5 GNUmakefile.inc.in
*** benchmarks/GNUmakefile.inc.in	2 May 2006 15:15:31 -0000	1.5
--- benchmarks/GNUmakefile.inc.in	17 Jun 2006 00:27:54 -0000
*************** benchmarks_CXXFLAGS := $(benchmarks_CXXI
*** 18,24 ****
  benchmarks_cxx_sources := $(wildcard $(srcdir)/benchmarks/*.cpp)
  benchmarks_cxx_exclude := # $(srcdir)/benchmarks/sumval-func.cpp
  
! # Do not build tests requireing parallel services if library does not
  # provide any.
  benchmarks_cxx_sources := $(filter-out $(benchmarks_cxx_par),		\
                                         $(benchmarks_cxx_sources))
--- 18,24 ----
  benchmarks_cxx_sources := $(wildcard $(srcdir)/benchmarks/*.cpp)
  benchmarks_cxx_exclude := # $(srcdir)/benchmarks/sumval-func.cpp
  
! # Do not build tests requiring parallel services if library does not
  # provide any.
  benchmarks_cxx_sources := $(filter-out $(benchmarks_cxx_par),		\
                                         $(benchmarks_cxx_sources))
*************** benchmarks_cxx_exes_special   := benchma
*** 34,54 ****
  benchmarks_cxx_exes_def_build := $(filter-out $(benchmarks_cxx_exes_special), \
                                                $(benchmarks_cxx_exes)) 
  
  # Do not build tests requiring packages that are unavailable
! benchmarks_cxx_exes_lapack := benchmarks/qrd$(EXEEXT) 
  ifndef VSIP_IMPL_HAVE_LAPACK
    benchmarks_cxx_exes_def_build := $(filter-out 	\
  	$(benchmarks_cxx_exes_lapack), $(benchmarks_cxx_exes_def_build)) 
  endif 
  
- benchmarks_cxx_exes_ipp := benchmarks/conv_ipp$(EXEEXT)			\
- 	benchmarks/fft_ipp$(EXEEXT) benchmarks/fft_ext_ipp$(EXEEXT)	\
- 	benchmarks/vmul_ipp$(EXEEXT)
  ifndef VSIP_IMPL_HAVE_IPP
    benchmarks_cxx_exes_def_build := $(filter-out		\
  	$(benchmarks_cxx_exes_ipp), $(benchmarks_cxx_exes_def_build)) 
  endif
  
  cxx_sources += $(benchmarks_cxx_sources)
  
  benchmarks_cxx_statics_def_build :=				\
--- 34,69 ----
  benchmarks_cxx_exes_def_build := $(filter-out $(benchmarks_cxx_exes_special), \
                                                $(benchmarks_cxx_exes)) 
  
+ 
+ 
  # Do not build tests requiring packages that are unavailable
! benchmarks_cxx_srcs_lapack := $(wildcard $(srcdir)/benchmarks/*_lapack.cpp) \
!                                          $(srcdir)/benchmarks/qrd.cpp
! benchmarks_cxx_srcs_ipp    := $(wildcard $(srcdir)/benchmarks/*_ipp.cpp) 
! benchmarks_cxx_srcs_sal    := $(wildcard $(srcdir)/benchmarks/*_sal.cpp) 
! 
! benchmarks_cxx_exes_lapack := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT),  \
!                                 $(benchmarks_cxx_srcs_lapack))
! benchmarks_cxx_exes_ipp    := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT),  \
!                                 $(benchmarks_cxx_srcs_ipp))
! benchmarks_cxx_exes_sal    := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT),  \
!                                 $(benchmarks_cxx_srcs_sal))
! 
  ifndef VSIP_IMPL_HAVE_LAPACK
    benchmarks_cxx_exes_def_build := $(filter-out 	\
  	$(benchmarks_cxx_exes_lapack), $(benchmarks_cxx_exes_def_build)) 
  endif 
  
  ifndef VSIP_IMPL_HAVE_IPP
    benchmarks_cxx_exes_def_build := $(filter-out		\
  	$(benchmarks_cxx_exes_ipp), $(benchmarks_cxx_exes_def_build)) 
  endif
  
+ ifndef VSIP_IMPL_HAVE_SAL
+   benchmarks_cxx_exes_def_build := $(filter-out		\
+ 	$(benchmarks_cxx_exes_sal), $(benchmarks_cxx_exes_def_build)) 
+ endif
+ 
  cxx_sources += $(benchmarks_cxx_sources)
  
  benchmarks_cxx_statics_def_build :=				\
*************** benchmarks_cxx_statics_def_build :=				\
*** 60,66 ****
  # Rules
  ########################################################################
  
! bench:: $(benchmarks_cxx_exes_def_build)
  
  # Object files will be deleted by the parent clean rule.
  clean::
--- 75,81 ----
  # Rules
  ########################################################################
  
! benchmarks:: $(benchmarks_cxx_exes_def_build)
  
  # Object files will be deleted by the parent clean rule.
  clean::
Index: benchmarks/conv.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/conv.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 conv.cpp
*** benchmarks/conv.cpp	2 Jun 2006 02:21:50 -0000	1.5
--- benchmarks/conv.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 20,26 ****
  
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  #include "ops_info.hpp"
  
--- 20,26 ----
  
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  #include "ops_info.hpp"
  
Index: benchmarks/copy.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/copy.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 copy.cpp
*** benchmarks/copy.cpp	3 Mar 2006 14:30:53 -0000	1.2
--- benchmarks/copy.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 21,31 ****
  #include <vsip/map.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  using namespace vsip;
  
  
  
--- 21,32 ----
  #include <vsip/map.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  using namespace vsip;
+ using namespace vsip_csl;
  
  
  
Index: benchmarks/corr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/corr.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 corr.cpp
*** benchmarks/corr.cpp	7 Mar 2006 20:09:35 -0000	1.2
--- benchmarks/corr.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 20,26 ****
  
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  #include "ops_info.hpp"
  
--- 20,26 ----
  
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  #include "ops_info.hpp"
  
Index: benchmarks/dot.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/dot.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 dot.cpp
*** benchmarks/dot.cpp	2 May 2006 15:15:31 -0000	1.4
--- benchmarks/dot.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 20,26 ****
  
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  #include "ops_info.hpp"
  
--- 20,26 ----
  
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  #include "ops_info.hpp"
  
Index: benchmarks/fftm.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fftm.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 fftm.cpp
*** benchmarks/fftm.cpp	14 May 2006 02:21:04 -0000	1.3
--- benchmarks/fftm.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 19,28 ****
  #include <vsip/signal.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  
  using namespace vsip;
  
  
  
--- 19,29 ----
  #include <vsip/signal.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  
  using namespace vsip;
+ using namespace vsip_csl;
  
  
  
Index: benchmarks/fir.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fir.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 fir.cpp
*** benchmarks/fir.cpp	7 Mar 2006 20:09:35 -0000	1.2
--- benchmarks/fir.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 20,26 ****
  
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  #include "ops_info.hpp"
  
--- 20,26 ----
  
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  #include "ops_info.hpp"
  
Index: benchmarks/make.standalone
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/make.standalone,v
retrieving revision 1.3
diff -c -p -r1.3 make.standalone
*** benchmarks/make.standalone	21 Mar 2006 15:53:09 -0000	1.3
--- benchmarks/make.standalone	17 Jun 2006 00:27:54 -0000
***************
*** 1,4 ****
! ########################################################################
  #
  # File:   benchmarks/make.standalone
  # Author: Jules Bergmann
--- 1,4 ----
! ######################################################### -*-Makefile-*-
  #
  # File:   benchmarks/make.standalone
  # Author: Jules Bergmann
*************** endif
*** 66,72 ****
  
  CXX      := $(shell $(PC) --variable=cxx )
  CXXFLAGS := $(shell $(PC) --cflags       ) \
! 	    $(shell $(PC) --variable=cxxflags )
  LIBS     := $(shell $(PC) --libs         )
  
  
--- 66,73 ----
  
  CXX      := $(shell $(PC) --variable=cxx )
  CXXFLAGS := $(shell $(PC) --cflags       ) \
! 	    $(shell $(PC) --variable=cxxflags ) \
! 	    -I. -I./hpec_kernel -I../tests
  LIBS     := $(shell $(PC) --libs         )
  
  
*************** headers := $(wildcard *.hpp)
*** 77,92 ****
  
  statics := $(patsubst %.cpp, %.static$(EXEEXT),  $(sources))
  
! exes_special   := main$(EXEEXT)
! exes_def_build := $(filter-out $(exes_special), $(exes)) 
  
  
  
  ########################################################################
  # Targets
  ########################################################################
  
! all: $(exes_def_build) $(headers)
  
  check: $(exes_def_build) $(headers)
  
--- 78,111 ----
  
  statics := $(patsubst %.cpp, %.static$(EXEEXT),  $(sources))
  
! hpec_sources := $(wildcard hpec_kernel/*.cpp)
! hpec_objects := $(patsubst %.cpp, %.$(OBJEXT), $(hpec_sources))
! hpec_exes    := $(patsubst %.cpp, %$(EXEEXT),  $(hpec_sources))
! 
! hpec_exes_def_build := $(hpec_exes)
! 
! 
! # Do not automatically build tests requiring packages that 
! # may not be available
! srcs_lapack := $(wildcard *_lapack.cpp) qrd.cpp
! srcs_ipp    := $(wildcard *_ipp.cpp) 
! srcs_sal    := $(wildcard *_sal.cpp) 
  
+ exes_lapack := $(patsubst %.cpp, %$(EXEEXT),  $(srcs_lapack))
+ exes_ipp    := $(patsubst %.cpp, %$(EXEEXT),  $(srcs_ipp))
+ exes_sal    := $(patsubst %.cpp, %$(EXEEXT),  $(srcs_sal))
+ 
+ exes_special   := main$(EXEEXT) $(exes_lapack) $(exes_ipp) $(exes_sal)
+ exes_def_build := $(filter-out $(exes_special), $(exes)) 
  
  
  ########################################################################
  # Targets
  ########################################################################
  
! benchmarks: $(exes_def_build) $(headers)
! 
! hpec_kernel:  $(hpec_exes_def_build) $(headers)
  
  check: $(exes_def_build) $(headers)
  
*************** clean:
*** 111,116 ****
--- 130,138 ----
  $(exes_def_build): %$(EXEEXT) : %.$(OBJEXT) main.$(OBJEXT)
  	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
  
+ $(hpec_exes_def_build): hpec_kernel/%$(EXEEXT) : hpec_kernel/%.$(OBJEXT) main.$(OBJEXT)
+ 	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
+ 
  $(statics): %.static$(EXEEXT) : %.$(OBJEXT) main.$(OBJEXT)
  	$(CXX) -static $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
  
Index: benchmarks/mcopy.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/mcopy.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 mcopy.cpp
*** benchmarks/mcopy.cpp	3 Mar 2006 14:30:53 -0000	1.3
--- benchmarks/mcopy.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 22,34 ****
  #include <vsip/impl/profile.hpp>
  #include <vsip/impl/metaprogramming.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  #include "plainblock.hpp"
  
  using namespace vsip;
  
  using vsip::impl::ITE_Type;
  using vsip::impl::As_type;
--- 22,35 ----
  #include <vsip/impl/profile.hpp>
  #include <vsip/impl/metaprogramming.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  #include "plainblock.hpp"
  
  using namespace vsip;
+ using namespace vsip_csl;
  
  using vsip::impl::ITE_Type;
  using vsip::impl::As_type;
Index: benchmarks/mcopy_ipp.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/mcopy_ipp.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 mcopy_ipp.cpp
*** benchmarks/mcopy_ipp.cpp	2 May 2006 15:15:31 -0000	1.3
--- benchmarks/mcopy_ipp.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 24,37 ****
  #include <vsip/impl/profile.hpp>
  #include <vsip/impl/metaprogramming.hpp>
  
! #include "test.hpp"
! #include "output.hpp"
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  #include "plainblock.hpp"
  
  using namespace vsip;
  
  using vsip::impl::ITE_Type;
  using vsip::impl::As_type;
--- 24,38 ----
  #include <vsip/impl/profile.hpp>
  #include <vsip/impl/metaprogramming.hpp>
  
! #include <vsip_csl/test.hpp>
! #include <vsip_csl/output.hpp>
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  #include "plainblock.hpp"
  
  using namespace vsip;
+ using namespace vsip_csl;
  
  using vsip::impl::ITE_Type;
  using vsip::impl::As_type;
Index: benchmarks/mpi_alltoall.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/mpi_alltoall.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 mpi_alltoall.cpp
*** benchmarks/mpi_alltoall.cpp	12 Apr 2006 13:46:42 -0000	1.2
--- benchmarks/mpi_alltoall.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 19,29 ****
  #include <vsip/map.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  using namespace vsip;
  
  
  
--- 19,30 ----
  #include <vsip/map.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  using namespace vsip;
+ using namespace vsip_csl;
  
  
  
Index: benchmarks/prod.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/prod.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 prod.cpp
*** benchmarks/prod.cpp	7 Mar 2006 20:09:35 -0000	1.3
--- benchmarks/prod.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 20,26 ****
  
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  #include "ops_info.hpp"
  
--- 20,26 ----
  
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  #include "ops_info.hpp"
  
Index: benchmarks/prod_var.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/prod_var.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 prod_var.cpp
*** benchmarks/prod_var.cpp	7 Mar 2006 20:09:35 -0000	1.3
--- benchmarks/prod_var.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 20,29 ****
  
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
! #include "test-precision.hpp"
  #include "ref_matvec.hpp"
- #include "output.hpp"
  
  #include "loop.hpp"
  #include "ops_info.hpp"
--- 20,29 ----
  
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
! #include <vsip_csl/test-precision.hpp>
! #include <vsip_csl/output.hpp>
  #include "ref_matvec.hpp"
  
  #include "loop.hpp"
  #include "ops_info.hpp"
***************
*** 31,36 ****
--- 31,37 ----
  #define VERBOSE 1
  
  using namespace vsip;
+ using namespace vsip_csl;
  
  
  
Index: benchmarks/qrd.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/qrd.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 qrd.cpp
*** benchmarks/qrd.cpp	3 Mar 2006 14:30:53 -0000	1.3
--- benchmarks/qrd.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 20,26 ****
  
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  
  using namespace vsip;
--- 20,26 ----
  
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  
  using namespace vsip;
*************** struct t_qrd1
*** 82,88 ****
      // A = T(); A.diag() = T(1);
      randm(A);
  
!     impl::Qrd_impl<T, Blocked> qr(size, size, qrd_saveq);
      
      vsip::impl::profile::Timer t1;
      
--- 82,88 ----
      // A = T(); A.diag() = T(1);
      randm(A);
  
!     impl::Qrd_impl<T, Blocked, impl::Lapack_tag> qr(size, size, qrd_saveq);
      
      vsip::impl::profile::Timer t1;
      
Index: benchmarks/sumval.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/sumval.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 sumval.cpp
*** benchmarks/sumval.cpp	2 Jun 2006 02:21:50 -0000	1.4
--- benchmarks/sumval.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 17,26 ****
  #include <vsip/random.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  
  using namespace vsip;
  
  
  
--- 17,27 ----
  #include <vsip/random.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  
  using namespace vsip;
+ using namespace vsip_csl;
  
  
  
Index: benchmarks/vmmul.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/vmmul.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 vmmul.cpp
*** benchmarks/vmmul.cpp	7 Mar 2006 20:09:35 -0000	1.2
--- benchmarks/vmmul.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 19,29 ****
  #include <vsip/signal.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  using namespace vsip;
  
  
  
--- 19,30 ----
  #include <vsip/signal.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  using namespace vsip;
+ using namespace vsip_csl;
  
  
  
Index: benchmarks/vmul_c.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/vmul_c.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 vmul_c.cpp
*** benchmarks/vmul_c.cpp	2 Jun 2006 02:21:50 -0000	1.3
--- benchmarks/vmul_c.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 18,28 ****
  #include <vsip/math.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  using namespace vsip;
  
  using impl::Stride_unit_dense;
  using impl::Cmplx_inter_fmt;
--- 18,29 ----
  #include <vsip/math.hpp>
  #include <vsip/impl/profile.hpp>
  
! #include <vsip_csl/test.hpp>
  #include "loop.hpp"
  #include "ops_info.hpp"
  
  using namespace vsip;
+ using namespace vsip_csl;
  
  using impl::Stride_unit_dense;
  using impl::Cmplx_inter_fmt;
Index: benchmarks/hpec_kernel/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/hpec_kernel/GNUmakefile.inc.in,v
retrieving revision 1.1
diff -c -p -r1.1 GNUmakefile.inc.in
*** benchmarks/hpec_kernel/GNUmakefile.inc.in	8 May 2006 03:49:44 -0000	1.1
--- benchmarks/hpec_kernel/GNUmakefile.inc.in	17 Jun 2006 00:27:54 -0000
*************** hpec_cxx_exes_def_build := $(filter-out 
*** 32,38 ****
  # Rules
  ########################################################################
  
! hpec:: $(hpec_cxx_exes_def_build)
  
  # Object files will be deleted by the parent clean rule.
  clean::
--- 32,38 ----
  # Rules
  ########################################################################
  
! hpec_kernel:: $(hpec_cxx_exes_def_build)
  
  # Object files will be deleted by the parent clean rule.
  clean::
Index: benchmarks/hpec_kernel/firbank.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/hpec_kernel/firbank.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 firbank.cpp
*** benchmarks/hpec_kernel/firbank.cpp	25 May 2006 19:06:49 -0000	1.2
--- benchmarks/hpec_kernel/firbank.cpp	17 Jun 2006 00:27:54 -0000
***************
*** 5,10 ****
--- 5,16 ----
      @date    2006-01-26
      @brief   VSIPL++ Library: FIR Filter Bank - High Performance 
               Embedded Computing (HPEC) Kernel-Level Benchmarks
+ 
+     This benchmark demonstrates one of the fundamental operations used
+     in signal processing applications, the finite impulse response (FIR)
+     filter.  Two algorithms, one that works in time-domain and one that
+     uses FFT's, are implemented here.  The FFT-based fast convolution
+     is usually more efficient for larger filters.  
  */
  
  /***********************************************************************
*************** struct t_local_view
*** 91,96 ****
--- 97,129 ----
    ImplFull: built-in FIR 
  ***********************************************************************/
  
+ // This helper class holds an array of Fir objects 
+ 
+ template <typename T>
+ struct fir_vector : public std::vector<Fir<T, nonsym, state_no_save, 1>*>
+ {
+   typedef Fir<T, nonsym, state_no_save, 1> fir_type;
+   typedef std::vector<fir_type*> base_type;
+   typedef typename base_type::size_type size_type;
+   typedef typename base_type::iterator iterator;
+ 
+   fir_vector (size_type n) : base_type (n) 
+   {
+     for (iterator i = base_type::begin(); i != base_type::end(); ++i)
+       *i = NULL;
+   }
+ 
+   ~fir_vector () 
+   {
+     iterator i = base_type::end();
+     do 
+     {
+       delete *--i;
+     } while (i != base_type::begin());
+   }
+ };
+ 
+ 
  template <typename T>
  struct t_firbank_base<T, ImplFull> : public t_local_view<T>
  {
*************** struct t_firbank_base<T, ImplFull> : pub
*** 122,128 ****
      length_type N = inputs.row(0).size();
  
      typedef Fir<T, nonsym, state_no_save, 1> fir_type;
!     fir_type** fir = new fir_type*[local_M];
      for ( length_type i = 0; i < local_M; ++i )
        fir[i] = new fir_type(LOCAL(filters).row(i), N, 1);
  
--- 155,161 ----
      length_type N = inputs.row(0).size();
  
      typedef Fir<T, nonsym, state_no_save, 1> fir_type;
!     fir_vector<T> fir(local_M);
      for ( length_type i = 0; i < local_M; ++i )
        fir[i] = new fir_type(LOCAL(filters).row(i), N, 1);
  
*************** struct t_firbank_base<T, ImplFull> : pub
*** 141,151 ****
  
      // Verify data
      assert( view_equal(LOCAL(outputs), LOCAL(expected)) );
- 
-     // Clean up
-     for ( length_type i = 0; i < local_M; ++i )
-       delete fir[i];
-     delete[] fir;
    }
  
    t_firbank_base(length_type filters, length_type coeffs)
--- 174,179 ----
*************** struct t_firbank_sweep_n : public t_firb
*** 324,332 ****
  };
  
  
! #if PARALLEL_FIRBANK
  /***********************************************************************
    Generic front-end for using external data
  ***********************************************************************/
  
  template <typename T, typename ImplTag>
--- 352,362 ----
  };
  
  
! #ifdef VSIP_IMPL_SOURCERY_VPP
  /***********************************************************************
    Generic front-end for using external data
+ 
+   Note: This option is supported using Sourcery VSIPL++ extensions.
  ***********************************************************************/
  
  template <typename T, typename ImplTag>
*************** struct t_firbank_from_file : public t_fi
*** 432,438 ****
  private:
    char * directory_;
  };
! #endif // PARALLEL_FIRBANK
  
  
  
--- 462,468 ----
  private:
    char * directory_;
  };
! #endif // #ifdef VSIP_IMPL_SOURCERY_VPP
  
  
  
*************** defaults(Loop1P& loop)
*** 447,456 ****
  }
  
  
- 
  int
  test(Loop1P& loop, int what)
  {
    switch (what)
    {
    case  1: loop(
--- 477,499 ----
  }
  
  
  int
  test(Loop1P& loop, int what)
  {
+   /* From PCA Kernel-Level Benchmarks Project Report:
+ 
+               FIR ﬁlter bank input parameters.
+   Parameter                                       Values
+     Name               Description             Set 1 Set 2
+      M      Number of ﬁlters                     64     20
+      N      Length of input and output vectors 4096   1024
+      K      Number of ﬁlter coefﬁcients         128     12
+      W      Workload (Mﬂop)                      34   1.97
+ 
+   Note: The workload calculations are given using the fast convolution
+   algorithm for Set 1 and using the time-domain algorithm for Set 2.
+   */
+ 
    switch (what)
    {
    case  1: loop(
*************** test(Loop1P& loop, int what)
*** 466,472 ****
      t_firbank_sweep_n<complex<float>, ImplFast>(20,  12));
      break;
  
! #if PARALLEL_FIRBANK
    case  21: loop(
      t_firbank_from_file<complex<float>, ImplFull> (64, 128, "data/set1"));
      break;
--- 509,515 ----
      t_firbank_sweep_n<complex<float>, ImplFast>(20,  12));
      break;
  
! #ifdef VSIP_IMPL_SOURCERY_VPP
    case  21: loop(
      t_firbank_from_file<complex<float>, ImplFull> (64, 128, "data/set1"));
      break;
Index: benchmarks/hpec_kernel/make.standalone
===================================================================
RCS file: benchmarks/hpec_kernel/make.standalone
diff -N benchmarks/hpec_kernel/make.standalone
*** benchmarks/hpec_kernel/make.standalone	8 May 2006 03:49:44 -0000	1.1
--- /dev/null	1 Jan 1970 00:00:00 -0000
***************
*** 1,49 ****
- ######################################################### -*-Makefile-*-
- #
- # File:   share/sourceryvsipl++/benchmarks/hpec_kernel/Makefile
- # Author: Don McCoy
- # Date:   2006-04-11
- #
- # Contents: Makefile for Sourcery VSIPL++-based High Performance 
- #           Embedded Computing (HPEC) Kernel-Level Benchmarks.
- #
- ########################################################################
- 
- ########################################################################
- # Variables
- ########################################################################
- 
- # This should point to the directory where Sourcery VSIPL++ is installed.
- prefix = /usr/local
- 
- # This selects the desired library.  Use '-debug' for building a version 
- # suitable for debugging or leave blank to use the optimized version.
- suffix = 
- 
- pkgcommand := PKG_CONFIG_PATH=$(prefix)/lib/pkgconfig 	\
-                      pkg-config vsipl++$(suffix) 	\
-                      --define-variable=prefix=$(prefix)
- 
- CXX      = $(shell ${pkgcommand} --variable=cxx)
- CXXFLAGS = $(shell ${pkgcommand} --cflags) \
- 	   $(shell ${pkgcommand} --variable=cxxflags) -I..
- LIBS     = $(shell ${pkgcommand} --libs)
-  
- 
- ########################################################################
- # Rules
- ########################################################################
- 
- all: firbank
- 
- firbank: firbank.o ../main.o
- 	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS) || rm -f $@
- 
- vars:
- 	@echo "PKG-CFG : " $(pkgcommand)
- 	@echo "CXX     : " $(CXX)
- 	@echo "CXXFLAGS: " $(CXXFLAGS)
- 	@echo "LIBS    : " $(LIBS)
- 
- 
- 
--- 0 ----
Index: src/vsip_csl/output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip_csl/output.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 output.hpp
*** src/vsip_csl/output.hpp	25 May 2006 19:06:49 -0000	1.2
--- src/vsip_csl/output.hpp	17 Jun 2006 00:27:54 -0000
*************** operator<<(
*** 114,119 ****
--- 114,161 ----
    return out;
  }
  
+ 
+ /// Write an Index to a stream.
+ 
+ template <vsip::dimension_type Dim>
+ inline
+ std::ostream&
+ operator<<(
+   std::ostream&		        out,
+   vsip::Index<Dim> const& idx)
+   VSIP_NOTHROW
+ {
+   out << "(";
+   for (vsip::dimension_type d=0; d<Dim; ++d)
+   {
+     if (d > 0) out << ", ";
+     out << idx[d];
+   }
+   out << ")";
+   return out;
+ }
+ 
+ 
+ /// Write a Length to a stream.
+ 
+ template <vsip::dimension_type Dim>
+ inline
+ std::ostream&
+ operator<<(
+   std::ostream&		         out,
+   vsip::impl::Length<Dim> const& idx)
+   VSIP_NOTHROW
+ {
+   out << "(";
+   for (vsip::dimension_type d=0; d<Dim; ++d)
+   {
+     if (d > 0) out << ", ";
+     out << idx[d];
+   }
+   out << ")";
+   return out;
+ }
+ 
  } // namespace vsip
  
  #endif // VSIP_CSL_OUTPUT_HPP
