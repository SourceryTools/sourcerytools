CFLAGS   = -S -c -g -Wall -O2
CXXFLAGS = -Wall
progs    =  test_select
prefix   =  /usr
DESTDIR  =

all : $(progs).o
	gcc $(progs).s -lpthread

$(progs).o: $(progs).c
	gcc $(CFLAGS) $(progs).c

distclean clean :
	rm -f $(progs) $(progs).o

$(DESTDIR)/$(prefix)/bin:
	mkdir -p $@

%_static : %.c
	gcc -static $(CFLAGS) $< -o $@

