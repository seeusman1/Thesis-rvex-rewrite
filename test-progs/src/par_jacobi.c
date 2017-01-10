//#include <math.h>


#include "rvex.h"
#include "io.h"

#ifndef N
#define N 1024
#endif

int n = N;
int m = N;
int iter_max = 10;


float *A;
float *Anew;
float *y0;
float *aux;

int main(int argc, char** argv){

		int i, j;
		int iter = 0;
//        int N = 1024-2, 
        int start, end, chunk, chunkPlus, excess;
		uint64_t start_time, end_time, time_spent;

        //args: 
        //argv[1] = start; argv[2] = end; argv[3] = get_core_ID();


        //int start = atoi(argv[1]);
        //int end = atoi(argv[2]);
        //int core_id = atoi(argv[3]);

        
        int core_id = CR_CID;

        const float pi  = 2.0f * asinf(1.0f);

        if(N%NTHREADS == 0){
                start = (N/NTHREADS) * core_id;
                end = start + (N/NTHREADS);
        }else{
                excess = N%NTHREADS;
                chunk = N/NTHREADS;
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
//        		printf("Starting Jacobi; A 0x%x, Anew 0x%x, y0 0x%x\n", A, Anew, y0);
        		
        		A = malloc(sizeof(float)*m*n);
				Anew = malloc(sizeof(float)*m*n);
				y0 = malloc(sizeof(float)*n);
        		
                memset(A, 0, n * m * sizeof(float));
                for(i = 0; i < m; i++){
                        A[i]   = 0.f;
                        A[((n-1)*m)+i] = 0.f;
                        y0[i] = sinf(pi * i / (n-1));
                        A[(i*n)] = y0[i];
                        A[(i*n)+m-1] = y0[i]*expf(-pi);        
                        Anew[i] = 0.f;
                        Anew[((n-1)*n)+i] = 0.f;
                        Anew[i*n] = y0[i];
                        Anew[(i*n)+m-1] = y0[i]*expf(-pi);
                }
                
				start_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
				CR_CRR = MULTI_CONFIG; //enable all contexts
        }

        for(iter=0;iter<iter_max;iter++){
                for(j = start; j < end; j++){
                        for(i = 1; i < m-1; i++ ){
                            Anew[(j*n)+i] = 0.25f * ( A[(j*n)+i+1] + A[(j*n)+i-1]+ A[((j-1)*n)+i] + A[((j+1)*n)+i]);
                        }
                }

//	signalbarrier(0);
	mergebarrier(0);
				

                if(core_id == MASTER){
                        aux = A;
                        A = Anew;
                        Anew = aux;
                        barrier[1] = BARRIERVAL(1);
                }
                waitbarrier(1);
        }

	if (core_id == MASTER)
	{
		end_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
		time_spent = end_time - start_time;
	    //printMatrix(A); //To print a matrix, uncomment this line.
//	    printf("jacobi,%d,",N);
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

/* Insert this code inside of the demodispatch

if(program = 'j'){ //program = jacobi
        int N = 1024-2, start, end, chunk, chunkPlus, excess;
        if(N%NTHREADS == 0){
                start = (N/NTHREADS) * get_core_ID();
                end = start + (N/NTHREADS);
        }else{
                excess = N%NTHREADS;
                chunk = N/NTHREADS;
                chunkPlus = chunk+1;
                if(get_core_ID() < excess){
                        start = chunkPlus*get_core_ID();
                        end = start + chunkPlus;
                }else{
                        start = (chunk*get_core_ID())+excess;
                        end = start + chunk;
                }
        }
        //args: 
        //argv[1] = start; argv[2] = end; argv[3] = get_core_ID();
    }
    */
