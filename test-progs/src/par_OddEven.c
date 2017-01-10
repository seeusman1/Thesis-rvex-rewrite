#include "rvex.h"
#include "io.h"

#ifndef N
//#define N 150000
#define N 32768
#endif

int vector[N];

void sortOddEven(int *vector, int iniOdd, int endOdd, int iniEven, int endEven){
		int i, k;
		int aux;
		int core_id = CR_CID;
		
//		printf("Sorting with N %d, iniOdd %d, endOdd %d, iniEven %d, endEven %d\n", N, iniOdd, endOdd, iniEven, endEven);
			for(k=0;k<(N+1)/2;k++){ //need 1 extra run for odd N

					for(i=iniEven;i<endEven;i=i+2){
							if(vector[i] > vector[i+1]){
									aux = vector[i];
									vector[i] = vector[i+1];
									vector[i+1] = aux;
							}
					}
//signalbarrier(0);
mergebarrier(0);

					for(i=iniOdd;i<endOdd;i=i+2){
							if(vector[i] > vector[i+1]){
									aux = vector[i];
									vector[i] = vector[i+1];
									vector[i+1] = aux;
							}
					}
//signalbarrier(1);
mergebarrier(1);
		}
}

void readInput(int *vector){
		static int shift = 0;
		int i;
#pragma unroll(0)
		for(i=0;i<N;i++){
				vector[i] = N-i;
//				vector[i] = ((*(unsigned char*)0x80000313 << 8) | *(unsigned char*)0x80000313) << (shift++ & 0x7); //lowest 8 bits from timer (randomish)
		}
}

void print_vector(int *vector){
		int i;
#pragma unroll(0)
		for(i=0;i<N;i++){
				printf("%02d ", vector[i]);
		}
		printf("\n");
}

int main(int argc, char **argv){
		
		int i;
		/* When using Demodispatch
		int iniOdd = atoi(argv[1]);
		int endOdd = atoi(argv[2]);
		int iniEven = atoi(argv[3]);
		int endEven = atoi(argv[4]);
		*/
		
		uint64_t start_time, end_time, time_spent;
		int core_id = CR_CID;
		
		
		
		int nChanges = N/2;
		int chunk, excess, chunkPlus, iniOdd, iniEven, endOdd, endEven;
		//Adjusting even
		if(nChanges%NTHREADS == 0){
				iniEven = ((nChanges/NTHREADS)*core_id)*2;
				endEven = iniEven + ((nChanges/NTHREADS))*2;
		}else{
				excess = nChanges%NTHREADS;
				chunk = nChanges/NTHREADS;
				chunkPlus = chunk+1;
				if(core_id < excess){
						iniEven = chunkPlus*core_id*2;
						endEven = iniEven+(chunkPlus*2);
				}else{
						iniEven = ((chunk*core_id)+excess)*2;
						endEven = iniEven+(chunk*2);
				}
		}
		//Adjusting odd
		nChanges = (N-1)/2;

		if(nChanges == 0)
				nChanges = 1;
		if(nChanges%NTHREADS == 0 && nChanges > 1){
				iniOdd = (((nChanges/NTHREADS)*core_id)*2)+1;
				endOdd = iniOdd+((nChanges/NTHREADS)*2);
		}else{
				chunk = nChanges/NTHREADS;
				chunkPlus = chunk+1;
				excess = nChanges%NTHREADS;
				if(core_id < excess){
						iniOdd = (core_id*(chunkPlus*2))+1;
						endOdd = iniOdd + (chunkPlus*2);
				}else{
						iniOdd = (((chunk*core_id) + excess)*2)+1;
						endOdd = iniOdd + (chunk*2);
				}
		}
		
		//vector = malloc(sizeof(int)*N);
		//only thread MASTER should execute the function readInput
		if(core_id == MASTER){
//			printf("Starting parallel Odd-Even sort\n");
			readInput(vector);
//			print_vector(vector);

			start_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
			CR_CRR = MULTI_CONFIG; //enable all contexts
		}
		
		sortOddEven(vector, iniOdd, endOdd, iniEven, endEven);
		
    if (core_id == MASTER)
	{
		end_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
		time_spent = end_time - start_time;
	    //printMatrix(A); //To print a matrix, uncomment this line.
//	    printf("OddEven,%d,",N);
#if defined(MASTERMERGE)
//		printf("MASTERMERGE,");
#elif defined(RESOURCE_SHARE)
//		printf("RESOURCE_SHARE,");
#else
//		printf("NORMAL,");
#endif
	    printf("%x%x", ((uint32_t)(time_spent>>32)), (uint32_t)time_spent);
//		print_vector(vector);
	}
		
		return 0;
}

