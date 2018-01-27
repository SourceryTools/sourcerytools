Index: benchmarks/make.standalone
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/make.standalone,v
retrieving revision 1.2
diff -c -p -r1.2 make.standalone
*** benchmarks/make.standalone	27 Jan 2006 13:13:23 -0000	1.2
--- benchmarks/make.standalone	16 Mar 2006 17:42:26 -0000
*************** EXEEXT   =  
*** 56,62 ****
  # Variables in this section should not be modified.
  
  # Logic to call pkg-config with PREFIX, if specified.
! ifdef $PREFIX
     PC    = env PKG_CONFIG_PATH=$(PREFIX)/lib/pkgconfig \
  	   pkg-config --define-variable=prefix=$(PREFIX) $(PKG)
  else
--- 56,62 ----
  # Variables in this section should not be modified.
  
  # Logic to call pkg-config with PREFIX, if specified.
! ifdef PREFIX
     PC    = env PKG_CONFIG_PATH=$(PREFIX)/lib/pkgconfig \
  	   pkg-config --define-variable=prefix=$(PREFIX) $(PKG)
  else
*************** CXXFLAGS := $(shell $(PC) --cflags      
*** 69,81 ****
  	    $(shell $(PC) --variable=cxxflags )
  LIBS     := $(shell $(PC) --libs         )
  
- CXXFLAGS := $(CXXFLAGS) -I../tests
- 
  
  sources := $(wildcard *.cpp)
  objects := $(patsubst %.cpp, %.$(OBJEXT), $(sources))
  exes    := $(patsubst %.cpp, %$(EXEEXT),  $(sources))
- tests   := $(patsubst %.cpp, %.test,      $(sources))
  
  statics := $(patsubst %.cpp, %.static$(EXEEXT),  $(sources))
  
--- 69,78 ----
*************** exes_def_build := $(filter-out $(exes_sp
*** 88,104 ****
  # Targets
  ########################################################################
  
! all: $(tests)
  
! check: $(tests)
  
  vars:
  	@echo "CXX     : " $(CXX)
  	@echo "CXXFLAGS: " $(CXXFLAGS)
  	@echo "LIBS    : " $(LIBS)
  
  clean:
! 	rm -rf *.exe *.o
  
  
  
--- 85,102 ----
  # Targets
  ########################################################################
  
! all: $(exes_def_build)
  
! check: $(exes_def_build)
  
  vars:
+ 	@echo "PKG-CFG : " $(PC)
  	@echo "CXX     : " $(CXX)
  	@echo "CXXFLAGS: " $(CXXFLAGS)
  	@echo "LIBS    : " $(LIBS)
  
  clean:
! 	rm -rf $(exes_def_build) $(objects)
  
  
  
