class outer
{
public:
	int		a;
	static int 	b;
};

class inner
{
public:
	int		ia;
	outer		iouter;
};

int outer::b __attribute__((section(".mysect")))= 0;

int main (void)
{
	static inner innerInst __attribute__((section(".mysect")));

	innerInst.ia = 1;
	innerInst.iouter.a = 1;
	innerInst.iouter.b = 2;
}




