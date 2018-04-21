#include "config.h"

int foo_1(void)
{
	return 0;
}

#ifdef DEF
  int foo_2(void)
  {
	return 0;
  }
#endif

int main(void)
{
	foo_1();

	return foo_2();
}
