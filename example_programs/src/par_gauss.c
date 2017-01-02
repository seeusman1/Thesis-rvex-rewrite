#include "rvex.h"
#include "io.h"

#ifndef N
#define N 64
#endif
#define maxIter 10


/******************************
****** APPLICATION CODE *******
*******************************/


double *dx, *b, *A, *x;

void print_results()
{
	int i;
#pragma unroll(0)
	for (i = 0; i < N; i++)
	{
		printf("0x%08x\n", x[i]);
	}
	printf("\n");
}

//int main(int argc, char **argv){
int main(){
		
		int i, j, k;
		int start, end, chunk, chunkPlus, excess;
		
		uint64_t start_time, end_time, time_spent;

		//volatile int c = 0;
		int size = N;		
		int core_id = (int)CR_CID;

		
		
		if(size%NTHREADS == 0){
			start = (size/NTHREADS) * core_id;
			end = start + (size/NTHREADS);
		}else{
			excess = size%NTHREADS;
			chunk = size/NTHREADS;
			chunkPlus = chunk+1;
			if(core_id < excess){
				start = chunkPlus*core_id;
				end = start + chunkPlus;
			}else{
				start = (chunk*core_id)+excess;
				end = start + chunk;
			}
		}

		
		//Only the master thread do this
		if(core_id == MASTER){
		
//		printf("Starting Gauss_parallel; num %d, start %d, end %d\n", N, start, end);

		
			/* If starting from Demodispatch:
			N = atoi(argv[1]);
			start = atoi(argv[2]);
			end = atoi(argv[3]);
			*/			

			dx = malloc(sizeof(double)*N);
			b = malloc(sizeof(double)*N);
			A = malloc(sizeof(double)*N*N);
			x = malloc(sizeof(double)*N);

//			printf("dx %p, b %p, A %p, x %p\n", dx, b, A, x);

				for(i=0;i<N;i++){
						x[i] = 0;
						b[i] = 2*N;
						for(j=0;j<N;j++){
								A[(i*N)+j] = 1;
						}
						A[(i*N)+i] = N+1;
				}
				
				start_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
				
				CR_CRR = MULTI_CONFIG; //Start the other contexts
		}


		for(k=0;k<maxIter;k++){
				//printf("s %d/%d, start %d, end %d\n", k, maxIter, start, end);
				
				for(i=start;i<end;i++){
						//printf("i %d\n", i);
						dx[i] = b[i];
						for(j=0;j<N;j++){
								dx[i] -= A[(i*N)+j]*x[j];
						}
						dx[i] /= A[(i*N)+i];
						x[i] += dx[i]; 
				}

//	signalbarrier(0);
	mergebarrier(0);
		}
		
		CR_CRR = MULTI_CONFIG;
		
	if (core_id == MASTER)
	{
		end_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
		time_spent = end_time - start_time;
	    //printMatrix(A); //To print a matrix, uncomment this line.
//	    printf("gauss,%d,",N);
#if defined(MASTERMERGE)
//		printf("MASTERMERGE,");
#elif defined(RESOURCE_SHARE)
//		printf("RESOURCE_SHARE,");
#else
//		printf("NORMAL,");
#endif
		printf("%x%x", ((uint32_t)(time_spent>>32)), (uint32_t)time_spent);
	}
		
		//printf("Program Finished\n");
		//print_results();
		return 0;
}

