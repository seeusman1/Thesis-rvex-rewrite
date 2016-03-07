
#define N 64

// results should be at DMEM address 0.
volatile int results[N];

int fib(int n)
{
  int a1=0, a2=1, retval=0, i;
  if (n <= 1)
    return n;
  for (i=0; i<n-1; ++i)
  {
      retval = a1+a2;
      a1 = a2;
      a2 = retval;
  }
  return retval;
}

int
main(void)
{
  int i;
  for(i=0; i<N; ++i)  
  {
    results[i] = fib(i);
  }
  *((volatile int*)0x80000004) = 1;
  return 0;
}
