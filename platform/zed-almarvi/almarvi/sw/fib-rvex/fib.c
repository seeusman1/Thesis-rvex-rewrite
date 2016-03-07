
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
    int val = fib(i);
    val = ((val & 0xFF000000) >> 24)
        | ((val & 0x00FF0000) >> 8)
        | ((val & 0x0000FF00) << 8)
        | ((val & 0x000000FF) << 24);
    results[i] = val;
  }
  *((volatile int*)0x80000004) = 1;
  return 0;
}
