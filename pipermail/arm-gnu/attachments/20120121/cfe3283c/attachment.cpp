//@!	test: arm-none-eabi-g++ this_file 

template<class t1, class t2>
class outer
{
public:
	t1		a;
	static t2	b;
};

template<class t1, class t2>
#if 1
	// error: t.cpp:31:59: error: innerInst causes a section type conflict
	t2 outer<t1, t2>::b
		__attribute__((section(".mysect")));
#else
	// ok: just a warning about no entry point _start
	t2 outer<t1, t2>::b;
#endif

class inner
{
public:
	int		ia;
	outer<int, int>	iouter;
};


int main (void)
{
	static inner innerInst __attribute__((section(".mysect")));  // li:31

	// random code...
	innerInst.ia = 1;
	innerInst.iouter.a = 1;

	/* access to "b" (read or write) causes error if #if 1 above */
	if (innerInst.iouter.b == 2)
		innerInst.ia++;
}



