/*
 * VEXdiv.c
 *
 *  Created on: November 30, 2016
 *      Author: jjhoozemans
 *
 * C Implementation of division functions. Note that 
 * an optimized assembly version is available (VEXdiv.S).
 * To compile this, you need to use the HP VEX compiler
 * although 64-bit types are not supported (so those functions will not work)
 */

int __divuw(unsigned long n,  unsigned long base)
{
	return ((unsigned long) n) / (unsigned) base;
}
int _i_udiv(unsigned long n,  unsigned long base)
{
	return ((unsigned long) n) / (unsigned) base;
}

int __divw(long n,  long base)
{
	return ((long) n) / base;
}
int _i_div(long n,  long base)
{
	return ((long) n) / base;
}

int __moduw(unsigned long n,  unsigned long base)
{
	return ((unsigned long) n % (unsigned) base);
}

int __modw(long n, long base)
{
	return ((long) n % base);
}

int _i_rem(long n, long base)
{
	return ((long) n % base);
}

int _i_urem(unsigned long n,  unsigned long base)
{
	return ((unsigned long) n % (unsigned) base);
}

/*
 * The following functions are 64-bits
 */

long long __modul(unsigned long long n,  unsigned long long base)
{
	return n % base;
}

long long __divul(unsigned long long n,  unsigned long long base)
{
	return n / base;
}

long long __divl(long long n,  long long base)
{
	return n / base;
}

long long __modl(long long n, long long base)
{
	return n % base;
}

