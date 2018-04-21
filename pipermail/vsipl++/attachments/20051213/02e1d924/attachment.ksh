Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.333
diff -c -p -r1.333 ChangeLog
*** ChangeLog	12 Dec 2005 17:47:50 -0000	1.333
--- ChangeLog	13 Dec 2005 20:29:09 -0000
***************
*** 1,3 ****
--- 1,12 ----
+ 2005-12-13 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* benchmarks/GNUmakefile.inc.in: Use EXEEXT and OBJEXT.
+ 	* benchmarks/loop.hpp: Add missing include, use parallel.hpp
+ 	  instead of impl/global_map.
+ 	* src/vsip/impl/setup-assign.hpp: Make Holder_base destructor
+ 	  inline.
+ 	* tests/test.hpp: Fix test_assert to work with Greenhills.
+ 
  2005-12-12 Jules Bergmann  <jules@codesourcery.com>
  
  	Implement 2-D correlation.
Index: benchmarks/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/GNUmakefile.inc.in,v
retrieving revision 1.1
diff -c -p -r1.1 GNUmakefile.inc.in
*** benchmarks/GNUmakefile.inc.in	12 Aug 2005 13:39:46 -0000	1.1
--- benchmarks/GNUmakefile.inc.in	13 Dec 2005 20:29:09 -0000
*************** benchmarks_cxx_exclude := # $(srcdir)/be
*** 23,36 ****
  benchmarks_cxx_sources := $(filter-out $(benchmarks_cxx_par),		\
                                         $(benchmarks_cxx_sources))
  
! benchmarks_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.o,		\
                                       $(benchmarks_cxx_sources))
! benchmarks_cxx_exes    := $(patsubst $(srcdir)/%.cpp, %.exe,		\
                                       $(benchmarks_cxx_sources))
  benchmarks_cxx_tests   := $(patsubst $(srcdir)/%.cpp, %.test,		\
                                       $(benchmarks_cxx_sources))
  
! benchmarks_cxx_exes_special   := benchmarks/main.exe
  benchmarks_cxx_exes_def_build := $(filter-out $(benchmarks_cxx_exes_special), \
                                                $(benchmarks_cxx_exes)) 
  
--- 23,36 ----
  benchmarks_cxx_sources := $(filter-out $(benchmarks_cxx_par),		\
                                         $(benchmarks_cxx_sources))
  
! benchmarks_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT),	\
                                       $(benchmarks_cxx_sources))
! benchmarks_cxx_exes    := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT),	\
                                       $(benchmarks_cxx_sources))
  benchmarks_cxx_tests   := $(patsubst $(srcdir)/%.cpp, %.test,		\
                                       $(benchmarks_cxx_sources))
  
! benchmarks_cxx_exes_special   := benchmarks/main$(EXEEXT)
  benchmarks_cxx_exes_def_build := $(filter-out $(benchmarks_cxx_exes_special), \
                                                $(benchmarks_cxx_exes)) 
  
*************** bench:: $(benchmarks_cxx_exec)
*** 47,64 ****
  clean::
  	rm -f $(benchmarks_cxx_exes)
  
! $(benchmarks_cxx_exes_def_build): %.exe : %.o benchmarks/main.o src/vsip/libvsip.a
  	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
  
- # benchmarks/sumval.exe: %.exe : %.o benchmarks/sumval-func.o src/vsip/libvsip.a
- #	 $(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
- 
- # benchmarks/c-sumval.o: $(srcdir)/benchmarks/c-sumval.c
- # 	$(CC) $(CFLAGS) -c -o $@ $<
- 
- $(benchmarks_cxx_tests): %.test : %.exe
- 	@ ($< && echo "PASS: $<") || echo "FAIL: $<"
- 
  xyz:
  	@echo $(benchmarks_cxx_exes)
  	@echo "--------------------------------------------------"
--- 47,55 ----
  clean::
  	rm -f $(benchmarks_cxx_exes)
  
! $(benchmarks_cxx_exes_def_build): %$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) src/vsip/libvsip.a
  	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
  
  xyz:
  	@echo $(benchmarks_cxx_exes)
  	@echo "--------------------------------------------------"
Index: benchmarks/loop.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/loop.hpp,v
retrieving revision 1.6
diff -c -p -r1.6 loop.hpp
*** benchmarks/loop.hpp	5 Dec 2005 19:19:18 -0000	1.6
--- benchmarks/loop.hpp	13 Dec 2005 20:29:09 -0000
***************
*** 19,26 ****
  
  #include <vsip/impl/profile.hpp>
  #include <vsip/vector.hpp>
  #include <vsip/map.hpp>
! #include <vsip/impl/global_map.hpp>
  
  
  
--- 19,27 ----
  
  #include <vsip/impl/profile.hpp>
  #include <vsip/vector.hpp>
+ #include <vsip/math.hpp>
  #include <vsip/map.hpp>
! #include <vsip/parallel.hpp>
  
  
  
Index: src/vsip/impl/setup-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/setup-assign.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 setup-assign.hpp
*** src/vsip/impl/setup-assign.hpp	5 Dec 2005 19:19:19 -0000	1.2
--- src/vsip/impl/setup-assign.hpp	13 Dec 2005 20:29:09 -0000
*************** private:
*** 36,42 ****
    class Holder_base
    {
    public:
!     virtual ~Holder_base();
      virtual void exec() = 0;
      virtual char* type() = 0;
    };
--- 36,42 ----
    class Holder_base
    {
    public:
!     virtual ~Holder_base() {}
      virtual void exec() = 0;
      virtual char* type() = 0;
    };
*************** private:
*** 253,261 ****
  
  };
  
- Setup_assign::Holder_base::~Holder_base()
- {}
- 
  } // namespace vsip
  
  #endif // VSIP_IMPL_SETUP_ASSIGN_HPP
--- 253,258 ----
Index: tests/test.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/test.hpp,v
retrieving revision 1.9
diff -c -p -r1.9 test.hpp
*** tests/test.hpp	12 Dec 2005 17:47:50 -0000	1.9
--- tests/test.hpp	13 Dec 2005 20:29:09 -0000
*************** test_assert_fail(
*** 183,188 ****
--- 183,189 ----
    abort();
  }
  
+ #if defined(__GNU__)
  # if defined __cplusplus ? __GNUC_PREREQ (2, 6) : __GNUC_PREREQ (2, 4)
  #   define TEST_ASSERT_FUNCTION    __PRETTY_FUNCTION__
  # else
*************** test_assert_fail(
*** 192,197 ****
--- 193,201 ----
  #   define TEST_ASSERT_FUNCTION    ((__const char *) 0)
  #  endif
  # endif
+ #else
+ # define TEST_ASSERT_FUNCTION    ((__const char *) 0)
+ #endif
  
  #define test_assert(expr)						\
    (static_cast<void>((expr) ? 0 :					\
