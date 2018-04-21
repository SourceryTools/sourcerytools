#ifdef USE_NS /* If a namespace is desired, use these definitions:  */
#define NS_BEGIN namespace pooma {
#define NS_NAME pooma::
#define NS_END }

#else /* If a namespace is not desired, use these definitions: */
#define NS_BEGIN 
#define NS_NAME 
#define NS_END 
#endif // USE_NS

NS_BEGIN
struct Foo {
  void foo ();
};
NS_END

void NS_NAME Foo::foo () { /* do nothing */ }

int main ()
{
  /* Most user code will hopefully be written without using the macros
     since the user will know if namespaces are supported or not.
     Despite that, we show one way to support both types of code.  */
#if USE_NS
#define POOMA_NS pooma::
#else
#define POOMA_NS
#endif

  POOMA_NS Foo f;
  f.foo ();
}
