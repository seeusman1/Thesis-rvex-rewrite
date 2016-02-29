#define __global__ __attribute__((address_space(5)))
#define __param__ __attribute__((address_space(6)))
#include "tceops.h"

#define N 64
volatile __global__ int results[N];

volatile __param__ int done = 0;

int fib(int n)
{
  int a1=0, a2=1, retval;
  if (n <= 1)
    return n;
  for (int i=0; i<n-1; ++i)
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
  for(int i=0; i<N; ++i)  
  {
    results[i] = fib(i);
  }
  done = 1;
  return 0;
}
