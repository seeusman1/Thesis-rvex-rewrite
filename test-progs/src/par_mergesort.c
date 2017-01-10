/*
 * Sequential mergesort
 */

#ifdef RVEX
#include "rvex.h"
#include "io.h"
#else
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#ifdef _OPENMP
#include <omp.h>
#endif
#endif

//#define RVEX

//#define PRINT

#ifdef RVEX
#ifndef N
#define N 320000
#endif

#define DYNCORE

#define CACHESIZE 1024 // One rVEX cache block
#define CUTOFF (CACHESIZE*4/2) //*4 because the work will be divided in 4 parts, /2 because the buffer needs to fit into the cache twice (inbuf, outbuf) 
//#define IMPROVE_CACHE_LOCALITY
//#define MERGE //merge into larger core when thread finishes

volatile int finished1;
volatile int taskPending[4];
char strbuf[20];

enum ttype {TASK_SPLIT, TASK_MERGE};
struct task {
	int task_type;
	int begin, middle, end;
	int *invector, *outvector;
	volatile int *barrier;
	int barrierval;
};

struct task taskinfo[4];

#else
#define N 640000000
#define CUTOFF 2000
#endif

#define PARPROG 4
#if PARPROG == 4
#define OPTIMIZE_BUFFERS //depends on PARGPROG == 4
#endif

#ifdef RVEX
static inline void requestConfig(int config);
void runOnCore(int core, int *invector, int *outvector, enum ttype task_type, int begin, int middle, int end, int barrierval);
void runTask(int context);
#endif

void merge_sort(int *invector, int *outvector);
void merge_sort_split(int *invector, int *outvector, int begin, int end);
void merge_sort_merge(int *invector, int *outvector, int begin, int middle, int end);

void parmerge_sort(int *invector, int *outvector);
void parmerge_sort_split(int *invector, int *outvector, int begin, int end);

void createInput(int *vector)
{
	int i;
#pragma unroll(0)
	for (i = 0; i < N; i++)
	{
		vector[i] = N - i;
	}
}

void print_vector(int *vector)
{
	int i;
#pragma unroll(0)
	for (i = 0; i < N; i++)
	{
		printf("%d ", vector[i]);
	}
	printf("\n");
}
/*
void readFile(FILE *input, int *A)
{
	int i, j;
	for (i = 0; i < N; i++)
	{
		for (j = 0; j < N; j++)
		{
			fscanf(input, "%d", &A[(i * N) + j]);
		}
	}
}
*/
void copyvect(int *in, int *out, int start, int end)
{
	int i;
	for (i = start; i < end; i++)
	{
		out[i] = in[i];
	}
}

int main()
{
#ifndef RVEX
	struct timeval t;
	double start_time, end_time, time_spent;
#else
	uint64_t start_time, end_time, time_spent;
	int cid = CR_CID;

	if (cid != 0)
	{
#pragma unroll(0)
		while (1)
		{
		/*
		 * We're not the master context, so we should have been assigned a task every time we get here.
		 * Find out what it is and execute it. After finishing, stop the context.
		 */
			runTask(cid);

//			__asm volatile ("stop"); //there's no way to resume a core by the processor itself
#pragma unroll(0)
			while (!taskPending[cid]) WAIT;
		}
	}

	requestConfig(0);

#endif

	int *invector  = (int*) malloc(sizeof(int) * N);
	int *outvector = (int*) malloc(sizeof(int) * N);
	//FILE *input = fopen("niks", "r");
	//readFile(input, invector);

	printf("starting mergesort with N = %d \n", N);
#ifdef MERGE
	printf("MERGE\n");
#else
	printf("NORMAL\n");
#endif

	createInput(invector);


	printf("starting Sequential mergesort\n");

#ifdef PRINT
//	print_vector(invector);
#endif

#if PARPROG == 2 && !defined(RVEX)
	omp_set_nested(1);
	omp_set_num_threads(4);
#endif

#ifndef RVEX
	gettimeofday(&t, NULL);
	start_time = (t.tv_usec*1.0e-6)+t.tv_sec;
#else
	start_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
#endif

	/*********************
	 * Sequential version
	 *********************/
	//merge_sort(invector, outvector);

#ifndef RVEX
	gettimeofday(&t, NULL);
	end_time = (t.tv_usec*1.0e-6)+t.tv_sec;
#else
	end_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
#endif

	time_spent = end_time - start_time;

#ifndef RVEX
	printf("Sequential: %f seconds\n", time_spent);
#else
	printf("Sequential: 0x%08x%08x cycles\n", ((uint32_t)(time_spent>>32)), (uint32_t)time_spent);
#endif

#ifdef PRINT
	print_vector(invector);
#endif


	createInput(invector);
	
	printf("starting Parallel mergesort\n");

#ifndef RVEX
	gettimeofday(&t, NULL);
	start_time = (t.tv_usec*1.0e-6)+t.tv_sec;
#else
	start_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
#endif

	/*********************
	 * Parallel version
	 *********************/

	parmerge_sort(invector, outvector);

	requestConfig(0);

#ifndef RVEX
	gettimeofday(&t, NULL);
	end_time = (t.tv_usec*1.0e-6)+t.tv_sec;
#else
	end_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
#endif

	time_spent = end_time - start_time;

#ifndef RVEX
	printf("Parallel: %f seconds\n", time_spent);
#else
	printf("Parallel: 0x%08x%08x cycles\n", ((uint32_t)(time_spent>>32)), (uint32_t)time_spent);
#endif

#ifdef PRINT
	print_vector(invector);
#endif
}

/*
 * Merge sort function.
 * Uses Divide & conquer to sort the input array and writes the output into outvector
 *
 */
void merge_sort(int *invector, int *outvector)
{
	merge_sort_split(invector, outvector, 0, N);
}

void parmerge_sort(int *invector, int *outvector)
{
	parmerge_sort_split(invector, outvector, 0, N);
}

void parmerge_sort_split(int *invector, int *outvector, int begin, int end)
{
	int middle, quarter1, quarter3;
	middle = begin + ((end - begin) / 2);

	quarter1 = begin + ((end - begin) / 4);
	quarter3 = middle + ((end - begin) / 4);


#ifndef RVEX
	if ((end - begin) * sizeof(int) < CUTOFF )
//	if (omp_get_num_threads() == 1)
	{
		return merge_sort_split(invector, outvector, begin, end);
	}

#if PARPROG == 2

#pragma omp parallel sections
{
#pragma omp section
	parmerge_sort_split(invector, outvector, begin, middle);
#pragma omp section
	parmerge_sort_split(invector, outvector, middle, end);
}
	merge_sort_merge(invector, invector, begin, middle, end);
//	print_vector(outvector);
	copyvect(outvector, invector, begin, end);

#else //PARPROG != 2

#pragma omp parallel sections
{
#pragma omp section
	parmerge_sort_split(invector, outvector, begin, quarter1);
#pragma omp section
	parmerge_sort_split(invector, outvector, quarter1, middle);
#pragma omp section
	parmerge_sort_split(invector, outvector, middle, quarter3);
#pragma omp section
	parmerge_sort_split(invector, outvector, quarter3, end);
}	
	merge_sort_merge(invector, outvector, begin, quarter1, middle);
	merge_sort_merge(invector, outvector, middle, quarter3, end);
#ifdef OPTIMIZE_BUFFERS
	merge_sort_merge(outvector, invector, begin, middle, end);
#else//OPTIMIZE_BUFFERS
	copyvect(outvector, invector, begin, end);
	merge_sort_merge(invector, outvector, begin, middle, end);
	copyvect(outvector, invector, begin, end);
#endif //OPTIMIZE_BUFFERS
#endif //PARPROG != 2

	
#else //RVEX

	/*
	 * When using the divconq arch to improve cache locality, keep recursing into the dataset
	 * Until the chunks fit into a cacheblock. Then, divide the chunks over 4 threads.
	 * Otherwise, divide the entire array over 4 threads immediately.
	 */
#ifdef IMPROVE_CACHE_LOCALITY
	if ((end - begin) * sizeof(int) > CUTOFF )
	{
		printf("Cutoff not reached yet; begin %d, q1 %d, middle %d, q3 %d, end %d\n", begin, quarter1, middle, quarter3, end);
		parmerge_sort_split(invector, outvector, begin, quarter1);
		parmerge_sort_split(invector, outvector, quarter1, middle);
		parmerge_sort_split(invector, outvector, middle, quarter3);
		parmerge_sort_split(invector, outvector, quarter3, end);
	/*
	 * The cache efficient part of the calculation has ended.
	 * We should be able to choose to finish the upper levels of the binary tree in single or multi threaded mode.
	 * We should measure which one is faster although I doubt there will be a noticeable difference.
	 * I don't know how to multithread this part yet, though (only to split the splits again to 8 instances and then start 4 threads on the merging).
	 */

		merge_sort_merge(invector, outvector, begin, quarter1, middle);
		merge_sort_merge(invector, outvector, middle, quarter3, end);
	#ifdef OPTIMIZE_BUFFERS
		merge_sort_merge(outvector, invector, begin, middle, end);
	#else
		copyvect(outvector, invector, begin, end);
		merge_sort_merge(invector, outvector, begin, middle, end);
		copyvect(outvector, invector, begin, end);
	#endif
		return;
	}


#endif //IMPROVE_CACHE_LOCALITY

	/*
	 * When the problem fits in the total cache (4 blocks), perform 4 sort instances in 2222 mode,
	 * Merge them in 44, then merge them in 8 mode.
	 * Cache must be twice the size of the array because we're not sorting in-place.
	 */

#ifdef PRINT
	printf("assigning chunks to threads;\n");
	printf("Thread 1: %d to %d\n", begin, quarter1);
	printf("Thread 2: %d to %d\n", quarter1, middle);
	printf("Thread 3: %d to %d\n", middle, quarter3);

	printf("master thread: %d to %d\n\n", quarter3, end);
#endif

	//assign the tasks
	runOnCore(1, invector, outvector, TASK_SPLIT, begin,    0, quarter1, 1);		//run task on context 1
	runOnCore(2, invector, outvector, TASK_SPLIT, quarter1, 0, middle, 1);			//run task on context 1
	runOnCore(3, invector, outvector, TASK_SPLIT, middle,   0, quarter3, 1);		//run task on context 1

	//split into 2222; mind the location of the thread wrt the next step!
	requestConfig(0x3210);

	merge_sort_split(invector, outvector, quarter3, end); 							//master context (0)

	//signal barrier
	((char*)&finished1)[0] = 1;
//	((char*)&finished1)[0] = 1;

	//Barrier
#pragma unroll(0)
	while (finished1 != 0x01010101) WAIT;

	finished1 = 0; //reset the barrier

	//assign the tasks
	runOnCore(3, invector, outvector, TASK_MERGE, begin, quarter1, middle, 2);		//run task on context 1

#ifdef MERGE
	//merge into 44
	requestConfig(0x3300);
#else
//	requestConfig(0x3880);
#endif

	merge_sort_merge(invector, outvector, middle, quarter3, end); 					//master context (0)

	//signal barrier
	((char*)&finished1)[0] = 2;

	//barrier
#pragma unroll(0)
	while (finished1 != 0x02000002) WAIT;

#ifdef MERGE
	//merge into 8
	requestConfig(0x0);
#else
//	requestConfig(0x8880);
#endif

#ifndef OPTIMIZE_BUFFERS
	copyvect(outvector, invector, begin, end);
	merge_sort_merge(invector, outvector, begin, middle, end);
//	print_vector(outvector);
	copyvect(outvector, invector, begin, end);
#else //OPTIMIZE_BUFFERS
	merge_sort_merge(outvector, invector, begin, middle, end);
#endif //OPTIMIZE_BUFFERS

#endif //RVEX

}


void merge_sort_split(int *invector, int *outvector, int begin, int end)
{
	int middle, quarter1, quarter3;
	middle = begin + ((end - begin) / 2);
#if PARPROG == 2
	if ((end - begin) < 2 )
	{
		return;
	}

	merge_sort_split(invector, outvector, begin, middle);
	merge_sort_split(invector, outvector, middle, end);
	merge_sort_merge(invector, outvector, begin, middle, end);
	//print_vector(outvector);
	copyvect(outvector, invector, begin, end);

#else
	if ((end - begin) < 4 )
	{
		return;
	}

	quarter1 = begin + ((end - begin) / 4);
	quarter3 = middle + ((end - begin) / 4);
	merge_sort_split(invector, outvector, begin, quarter1);
	merge_sort_split(invector, outvector, quarter1, middle);
	merge_sort_split(invector, outvector, middle, quarter3);
	merge_sort_split(invector, outvector, quarter3, end);

	merge_sort_merge(invector, outvector, begin, quarter1, middle);
	merge_sort_merge(invector, outvector, middle, quarter3, end);
#ifdef OPTIMIZE_BUFFERS
	merge_sort_merge(outvector, invector, begin, middle, end);
#else
	copyvect(outvector, invector, begin, end);
	merge_sort_merge(invector, outvector, begin, middle, end);
	copyvect(outvector, invector, begin, end);
#endif
#endif
}

void merge_sort_merge(int *invector, int *outvector, int begin, int middle, int end)
{
	int i, bindex, mindex;
	bindex = begin;
	mindex = middle;

	int val1 = invector[bindex];
	int val2 = invector[mindex];

	for (i = begin; i < end; i++)
	{
		//if lower part still has elements and it's currently indexed element is smaller or equal to the upper part's currently indexed element or the upper part is out of elements
		if ( (bindex < middle) && ((val1 <= val2) || mindex >= end))
		{
			outvector[i] = invector[bindex];
			bindex++;
		}
		else
		{
			outvector[i] = invector[mindex];
			mindex++;
		}
	}

}

#ifdef RVEX

/*
 * Request the dynamic core to change into a new configuration.
 * When not using a dynamic core, ignore.
 */
static inline void requestConfig(int config)
{
#ifdef DYNCORE
	CR_CRR = config;
#endif
}


void runOnCore(int core, int *invector, int *outvector, enum ttype task_type, int begin, int middle, int end, int barrierval)
{
	taskinfo[core].invector = invector;
	taskinfo[core].outvector = outvector;

	taskinfo[core].barrier = &finished1;
	taskinfo[core].barrierval = barrierval;

	taskinfo[core].begin = begin;
	taskinfo[core].middle = middle;
	taskinfo[core].end = end;

	taskinfo[core].task_type = task_type;

	taskPending[core] = 1;
}

void runTask(int context)
{
	if (taskinfo[context].task_type == TASK_SPLIT)
	{
		merge_sort_split(taskinfo[context].invector, taskinfo[context].invector, taskinfo[context].begin, taskinfo[context].end);
	}
	else
	{
		merge_sort_merge(taskinfo[context].invector, taskinfo[context].invector, taskinfo[context].begin, taskinfo[context].middle, taskinfo[context].end);
	}

	taskPending[context] = 0;
	((char*)taskinfo[context].barrier)[context] = taskinfo[context].barrierval;
//	((char*)taskinfo[context].barrier)[context] = taskinfo[context].barrierval;

}
#endif //RVEX
