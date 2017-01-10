#include "rvex.h"


//#define INCLUDE

#ifdef INCLUDE
//#define SMALLSET
#ifdef SMALLSET
#define N 8
#else
#define N 100  //define this according to the input size of matrix
#endif
#endif

#ifdef INCLUDE
#include "par_lu.h"
short unsigned int c[N];
short unsigned int l[N];
#else
#include "io.h"
unsigned int *A;
short unsigned int *c, *l;
#endif

#ifndef N
#define N 100
#endif


/******************************
****** APPLICATION CODE *******
*******************************/


void sleep(int t)
{
	volatile int i;
	#pragma unroll(0)
	for (i = 0; i < t<<8; i++) ;
}

#ifndef INCLUDE
void povoaMatrix(int *input, unsigned int *A){
	int i, j;
	for(i=0;i<N;i++){
		for(j=0;j<N;j++){
			fscanf(input, "%d", &A[(i*N)+j]);
		}
	}
}
#endif

void printMatrix(int *M){
	int i, j;
	for(i=0;i<N;i++){
#pragma unroll(0)
		for(j=0;j<N;j++){
			printf("%08d\t", M[(i*N)+j]);
		}
		printf("\n");
	}
}

#if 0 //moved to io.c
/**
 * Loads a 40-bit, 48-bit or 56-bit performance counter value. Do not use this
 * when the counter size is set to 32-bit!
 */
uint64_t read_counter(
    volatile uint32_t *low,
    volatile uint32_t *high
) {
    
    // Perform the read.
    uint32_t l = *low;
    uint32_t h = *high;
    
    // Check if the counters have overflowed.
    if ((l >> 24) != (h & 0xFF)) {
        
        // There was an overflow, so clear the low value.
        l = 0;
        
    }
    
    // Combine the values and return.
    return ((uint64_t)h << 24) | l;
    
}
#endif

void LUdecomposition(unsigned int *A, short unsigned int *vectorPosition, int core_id, int totalThreads, short unsigned int *l, short unsigned int *c){
	
		//these variables should be private to each thread
		int i, j, k, iteracoes=0, pos;
		int somatorio=0;
		

		//only master thread compute the first line
		if(core_id == MASTER){

#if defined(RESOURCE_SHARE) || defined(MASTERMERGE)
		//CR_CRR = 0; //disable other contexts and claim all resources for ourselves
		reconf_keeptrying(0);
#endif					
			//printf("Computing first line\n");
				for(i=1;i<N;i++){
						A[i*N] = A[i*N]/A[0];
				}
#ifdef DUPWRITES
			barrier[1] = BARRIERVAL(1);
#endif
			barrier[1] = BARRIERVAL(1);
#if defined(RESOURCE_SHARE) || defined(MASTERMERGE)
		CR_CRR = MULTI_CONFIG;
#endif
		}

		waitbarrier(1);


		for(i=1;i<N;i++){
				//((char*)finished1)[core_id] = 0;


				//Only master thread do this
				if(core_id == MASTER){

#if defined(RESOURCE_SHARE) || defined(MASTERMERGE)
				//CR_CRR = 0;
				reconf_keeptrying(0);
#endif

				//printf("Computing somatorio %d\n", i);
				somatorio = 0.0;
				for(k=0;k<i;k++){
					somatorio += A[(i*N)+k] * A[(k*N)+i];
				}
				A[(i*N)+i] = A[(i*N)+i] - somatorio;
#ifdef DUPWRITES
				barrier[2] = BARRIERVAL(1);
#endif
				barrier[2] = BARRIERVAL(1);
#if defined(RESOURCE_SHARE) || defined(MASTERMERGE)
				CR_CRR = MULTI_CONFIG;
#endif
				}
				/*
				else
				{
				printf("sleeping\n");
				sleep(10);
				}
				*/

				//all threads wait until the end of the master thread operation
				waitbarrier(2);
				
				//((char*)finished2)[core_id] = 0;
				//#pragma unroll(0)
				//while (*finished2 != 0) ;

				if(core_id < totalThreads/2){ //Upper computation
						if(vectorPosition[(i*2)] != -1){
								for(k=vectorPosition[i*2];k<vectorPosition[(i*2)+1];k++){
										somatorio=0.0;
										for(j=l[k];j<i;j++){
												somatorio += A[(i*N)+j] * A[(j*N)+k];
										}
										if(somatorio != 0.0)
												A[(i*N)+k] = A[(i*N)+k] - somatorio;
								}
						}
				}else{ //Low Computation
						if(vectorPosition[i*2] != -1){
								for(k=vectorPosition[i*2];k<vectorPosition[(i*2)+1];k++){
										somatorio = 0.0;
										for(j=c[k];j<i;j++){
												somatorio += A[(k*N)+j] * A[(j*N)+i];
										}
										if(somatorio != 0.0)
												A[(k*N)+i] = (A[(k*N)+i] - somatorio)/A[(i*N)+i];
								}
						}
				}
//#ifdef RESOURCE_SHARE
//		merge(3);
//#endif
//This is necessary because after the multi config is restored in merge(), other context may still perform an "expired" new config request
//#ifdef RESOURCE_SHARE
//				reconf_keeptrying(MULTI_CONFIG); //enable all contexts
//#endif

				//all threads wait until the end of operation	
//				signalbarrier(3);
				mergebarrier(3);
				
		}
}

void calcWorkload(short unsigned int *vectorPosition, int core_id, int totalThreads){
		//All the variables should be private to each thread
		int firstProcRow, firstProcCol, lastProcRow, lastProcCol, totalProcRowCol = totalThreads/2;
		int proc, sum, cont, j, i, cinit, cfinal, rinit, rfinal, ir;
		firstProcRow = 0;
		firstProcCol = totalThreads/2;
		lastProcRow = (totalThreads/2)-1;
		lastProcCol = totalThreads-1;

		for(i=0;i<N;i++){
				vectorPosition[(i*2)] = -1;
				vectorPosition[(i*2)+1] = -1;
		}

		if(core_id < totalThreads/2){
				for(j=1;j<N;j++){		
						proc = firstProcRow;
						sum = 0;
						cont = (N-(j+1))/totalProcRowCol;
						cinit = j+1;
						for(i=j+1; i<N;i++){
								sum++;
								if((sum == cont) && (proc != lastProcRow)){
										cfinal = i;
										if(proc == core_id){
												vectorPosition[(j*2)] = cinit;
												vectorPosition[(j*2)+1] = cfinal;
												//printf("Line %d --> %d ate %d\n", j, vectorPosition[j*2], vectorPosition[(j*2)+1]);
										}
										cinit = i+1;
										proc = proc+1;
										sum=0;
								}
						}
						if(cinit < i){
								if(core_id == proc){
										vectorPosition[j*2] = cinit;
										vectorPosition[(j*2)+1] = i-1;
										//printf("Line %d --> %d ate %d\n", j, vectorPosition[j*2], vectorPosition[(j*2)+1]);

								}
						}
				}
		}else{
				for(i=1; i<N; i++){
						proc = firstProcCol;
						sum=0;
						cont = (N-(i+1))/totalProcRowCol;
						rinit=i+1;
						for(j=i+1; j<N;j++){
								sum++;
								if((sum == cont) && (proc != lastProcCol)){
										rfinal = j;
										if(core_id == proc){
												vectorPosition[i*2] = rinit;
												vectorPosition[(i*2)+1] = rfinal;
												//printf("Column %i --> %d ate %d\n", i, vectorPosition[i*2], vectorPosition[(i*2)+1]);
										}
										ir = ir+1;
										rinit = j+1;
										proc = proc + 1;
										sum=0;
								}
						}
						if(rinit < j){
								if(core_id == proc){
										vectorPosition[i*2] = rinit;
										vectorPosition[(i*2)+1] = j-1;
										//printf("Column %d --> %d ate %d\n", i, vectorPosition[i*2], vectorPosition[(i*2)+1]);
								}
						}
				}

		}
}

void defineVectorZero(unsigned int *A, short unsigned int *c, short unsigned int *l){
		int i, j, cont;
		for(i=0;i<N;i++){
				cont = 0;
				for(j=0;(j<i)&&(A[(i*N)+j] == 0); j++){
						cont++;
				}
				l[i] = cont;
		}
		for(j=0;j<N;j++){
				for(i=0; (i<=j) && (A[(i*N)+j] == 0); i++){
						cont++;
				}
				c[j] = cont;
		}
}

int main(int argc, char **argv){

	uint64_t start_time, end_time, time_spent;
#ifdef INCLUDE
	short unsigned int vectorPosition[N*2];
#endif

	int core_id = CR_CID;
	int totalThreads = NTHREADS;
	
	if (core_id == MASTER) CR_CRR = 0;
	
#ifndef	INCLUDE
	/*This variable should be private to each thread*/
	short unsigned int *vectorPosition;
	claim_lock(1);
	vectorPosition = malloc(sizeof(short int)*N*2);
	free_lock(1);
#endif

	/*Only master thread do this*/
	if(core_id == MASTER){
//			printf("Parallel LU Decomposition starting with matrix size %d, version %d.\n", N, MATRIXGEN);



			claim_lock(1);
#ifndef INCLUDE
			A = malloc(sizeof(int)*N*N);

			c = malloc(sizeof(int)*N);
			l = malloc(sizeof(int)*N);	

			int *input = fopen("niks", "r");
			povoaMatrix(input, A);
#endif
			defineVectorZero(A, l, c);

			free_lock(1);						

			start_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
			
			reconf_keeptrying(MULTI_CONFIG); //enable all contexts
	}
	
	//all threads wait until the end of the master thread operation
	//#pragma unroll(0)
	//while(barrier != 1) ;
	
	//((char*)finished1)[core_id] = 0;


	/* All threads do this --> workload calculation */
	calcWorkload(vectorPosition, core_id, totalThreads);

	
	//all threads wait here to start the LU decomposition together
	//((char*)finished1)[core_id] = 1;
	
//#ifdef RESOURCE_SHARE
//	merge(0);
//#endif

//	signalbarrier(0);
	mergebarrier(0);
	
	LUdecomposition(A, vectorPosition, core_id, totalThreads, l, c);
	
	if (core_id == MASTER)
	{
		end_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
		time_spent = end_time - start_time;
		//printMatrix(A); //To print a matrix, uncomment this line.
//		printf("lu_par,%d,",N);
#if defined(MASTERMERGE)
//		printf("MASTERMERGE,");
#elif defined(RESOURCE_SHARE)
//		printf("RESOURCE_SHARE,");
#else
//		printf("NORMAL,");
#endif
	    printf("%x%x", ((uint32_t)(time_spent>>32)), (uint32_t)time_spent);
	}
	
	return 0;
}


