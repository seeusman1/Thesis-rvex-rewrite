#include "common.h"


int abs(int x) {
  return x < 0 ? -x : x;
}

double fabs(double x) {
  return x < 0 ? -x : x;
}

void * memcpy(void * dest,const void *src,unsigned long count)
{
	char *tmp = (char *) dest, *s = (char *) src;

	while (count--)
		*tmp++ = *s++;

	return dest;
}


void *memset(void *ptr, int value, unsigned int num) {
  unsigned char *cptr = (unsigned char*)ptr;
  while (num--) {
    *cptr = value;
  }
  return ptr;
}

int strncmp(const char *s1, const char *s2, unsigned long n) {
  unsigned long i;
  for(i=0; i<n; i++) {
    if     ( s1[i] < s2[i] ) return -1;
    else if( s1[i] > s2[i] ) return +1;
  }
  return 0;
}

int rand(void) {
  static unsigned long next = 1;
  next = next * 1103515245 + 12345;
  return (unsigned int)(next/65536) % 32768;
}

double sin(double rad) {
  double app;
  double diff;
  int inc = 1;
  while( rad > 2*PI ) rad -= 2*PI;
  while( rad < -2*PI ) rad += 2*PI;
  app = diff = rad;
  diff = (diff * (-(rad*rad))) / ((2.0 * inc) * (2.0 * inc + 1.0));
  app = app + diff;
  inc++;
  while( fabs(diff) >= 0.00001 ) {
    diff = (diff * (-(rad*rad))) / ((2.0 * inc) * (2.0 * inc + 1.0));
    app = app + diff;
    inc++;
  }
  return app;
}

double cos(double rad) {
  double app;
  double diff;
  int inc = 1;
  rad += PI/2.0;
  while( rad > 2*PI ) rad -= 2*PI;
  while( rad < -2*PI ) rad += 2*PI;
  app = diff = rad;
  diff = (diff * (-(rad*rad))) / ((2.0 * inc) * (2.0 * inc + 1.0));
  app = app + diff;
  inc++;
  while( fabs(diff) >= 0.00001 ) {
    diff = (diff * (-(rad*rad))) / ((2.0 * inc) * (2.0 * inc + 1.0));
    app = app + diff;
    inc++;
  }
  return app;
}

double tan(double rad) {
  return sin(rad) / cos(rad);
}

double sqrt(double val) {
  double x = val/10;
  double dx;
  double diff;
  double min_tol = 0.00001;
  int i, flag;
  flag = 0;
  if( val == 0 ) {
    x = 0;
  }  
  else {
    for(i=1; i<20; i++) {
      if( !flag ) {
        dx = (val - (x*x)) / (2.0 * x);
        x = x + dx;
        diff = val - (x*x);
        if( fabs(diff) <= min_tol ) flag = 1;
      }
      else 
        x =x;
    }
  }
  return x;
}


int min(int a, int b) {
  return (a > b) ? b : a;
}

int max(int a, int b) {
  return (a > b) ? a : b;
}


