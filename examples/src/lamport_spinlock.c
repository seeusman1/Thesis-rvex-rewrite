#include "rvex.h"

#define NTHREADS 4
#define ADDITIONS 25

volatile int counter1;
volatile int counter2;


volatile int entering[NTHREADS];
volatile int ticket[NTHREADS];

void claim_lock()
{
	int i, max;
	int thread_id = CR_CID;
	entering[thread_id] = 1;
	
	for (i = 0, max = 0; i < NTHREADS; i++)
	{
		if (ticket[i] > max) max = ticket[i];
	}
	ticket[thread_id] = max + 1;
	entering[thread_id] = 0;
	
	for (i = 0; i < NTHREADS; i++)
	{
		if (i != thread_id)
		{
			#pragma unroll(0)
			while (entering[i]) ; //whait while other threads picks a turn
			#pragma unroll(0)
			while (ticket[i] && ((ticket[thread_id] > ticket[i]) || (ticket[thread_id] == ticket[i] && thread_id > i))) ;			
		}
	}
}

void free_lock()
{
	ticket[CR_CID] = 0;
}

int main()
{
	int i;
	CR_CRR = 0x3210;
	
	for (i = 0; i < ADDITIONS; i++)
	{
		counter1++;
	}
	
	if (CR_CID == 0)
	printf("ctr1 = %d\n", counter1);
	
	for (i = 0; i < ADDITIONS; i++)
	{
		claim_lock();
		counter2++;
		free_lock();
	}
	
	if (CR_CID == 0)
	printf("ctr2 = %d\n", counter2);

}
