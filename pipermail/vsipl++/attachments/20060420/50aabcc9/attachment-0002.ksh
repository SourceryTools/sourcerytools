CPP_SRC       = main.cpp
PROG_NAME     = matrix_test

CPP_OBJS      = $(CPP_SRC:%.cpp=obj/%.o)

CSAL_ROOT     = $(HOME)/work/checkout/mercury/csal
VSIP_ROOT     = $(srcdir)
VSIP_BUILD_RT = $(srcdir)/../../build/vpp_temp
CC            = g++

CFLAGS        = -g -O2 \
                -DVSIP_IMPL_USE_SAL_SOL \
                -I$(VSIP_ROOT)/src -I$(VSIP_BUILD_RT)/src \
		-I$(VSIP_ROOT)/vendor/atlas/include \
                -I$(CSAL_ROOT)/include
LDFLAGS       = -L$(VSIP_BUILD_RT)/src/vsip -lvsip \
                -L$(VSIP_BUILD_RT)/vendor/atlas/lib \
		-L$(VSIP_BUILD_RT)/lib \
		-llapack -lcblas -latlas -lg2c \
                -L$(CSAL_ROOT)/lib -lcsal

all: final/$(PROG_NAME)

obj/%.o: %.cpp
	$(CC) -c $< -o $@ $(CFLAGS)

final:
	mkdir final

obj:
	mkdir obj

final/$(PROG_NAME): final obj $(CPP_OBJS)
	$(CC) -o $@ $(CPP_OBJS) $(LDFLAGS)

clean:
	rm -rf obj final
