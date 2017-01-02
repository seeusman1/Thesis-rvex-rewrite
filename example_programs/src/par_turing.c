#include "rvex.h"
#include "io.h"

#ifndef N
#define N 10
#endif

struct ring{
        int X;
        int Y;
};
typedef struct ring TypeRing;
TypeRing *game, *aux;

void initializeMatrix(TypeRing *game, int predator, int prey, TypeRing *newMatrix){
        int i, j;
        for(i=0;i<N;i++){
#pragma unroll(0)
                for(j=0;j<N;j++){
                        game[(i*N)+j].X = predator;
                        game[(i*N)+j].Y = prey;
                        newMatrix[(i*N)+j].X = 0;
                        newMatrix[(i*N)+j].Y = 0;
                }
        }
}

void zeraAux(TypeRing *newMatrix){
        int i, j;
        for(i=0;i<N;i++){
#pragma unroll(0)
                for(j=0;j<N;j++){
                        newMatrix[(i*N)+j].X = 0;
                        newMatrix[(i*N)+j].Y = 0;
                }
        }

}

void printMatrix(TypeRing *game){
        int i, j;
        printf("\n");
        for(i=0;i<N;i++){
#pragma unroll(0)
                for(j=0;j<N;j++){
                        printf("%d | %d\t",game[(i*N)+j].X, game[(i*N)+j].Y);
                }
                printf("\n");
        }

}

void playGame(TypeRing *game, int i, int j, TypeRing *newMatrix){
        int Xm=0, XM=0, Ym=0, YM=0, X, Y;
        float rx = 0.0798; 
        float ax = 0.0123; 
        float bx = 0.0377; 
        float u = 0.12; 
        float ry = 0.0178; 
        float ay = 0.0998; 
        float by = 0.0100; 
        float v = 0.13; 

        float popX1, popY1, popX2, popY2;
        float fxy, gxy;

        X = game[(i*N)+j].X;
        Y = game[(i*N)+j].Y;

        fxy = X*(rx + (ax * X) + (bx * Y));
        gxy = Y*(ry + (ay * X) + (by * Y));

    	// verificando  posicao anterior
    	if ((i-1) < 0) {
    		Xm =  game[((N-1)*N)+j].X;
    	} else {
    		Xm = game[((i-1)*N)+j].X;
    	}

    	if ((i+1) > (N-1)) {
    		XM = game[j].X;
    	} else {
    		XM = game[((i+1)*N)+j].X;
    	}

    	popX1 = fxy +  u*(Xm - (2* X) + XM);
    	popY1 = gxy +  v*(Ym - (2* Y) + YM);

    	// verifica posicao final
    	if ((j-1) < 0) {
    		Ym =  game[(i*N)+N-1].Y;
    	} else {
    		Ym = game[(i*N)+j-1].Y;
    	}

    	if ((j+1) > (N-1)) {
    		YM = game[i*N].Y;
    	} else {
    		YM = game[(i*N)+j+1].Y;
    	}

    	popX2 = fxy +  u*(Xm - (2* X) + XM);
    	popY2 = gxy +  v*(Ym - (2* Y) + YM);

    	float Xfinal = (popX1 + popX2)/2;
    	float Yfinal = (popY1 + popY2)/2;

        newMatrix[(i*N)+j].X = Xfinal;
        newMatrix[(i*N)+j].Y = Yfinal;
}

int main(int argc, char **argv){
/*
        int N = atoi(argv[1]);
        int start = atoi(argv[2]);
        int end = atoi(argv[3]);
*/
		int start, end, chunk, chunkPlus, excess;
		uint64_t start_time, end_time, time_spent;

        int x = 0;
        int i, row, column;
        int prey = 100;
        int predator = 100;
        
        int core_id = CR_CID;
        
        
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


        if(core_id == MASTER){
				game = malloc(sizeof(TypeRing)*N*N);
				aux = malloc(sizeof(TypeRing)*N*N);     
                initializeMatrix(game,predator,prey, aux);
                zeraAux(aux);
                
                start_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
                CR_CRR = MULTI_CONFIG; //start other contexts
        }
       
       for(x=0;x< ((N*2)-1); x++){
                for(row=start;row<end;row++){
                        for(column=0;column<N;column++){
                                if(row + column == x){
                                        playGame(game, row,column,aux);
                                }

                        }
                }
	
//	signalbarrier(0);
	mergebarrier(0);
                
                for(row=start;row<end;row++){
                        for(column=0;column<N;column++){
                                if(row + column == x){
                                        game[(row*N)+column].X = aux[(row*N)+column].X;
                                        game[(row*N)+column].Y = aux[(row*N)+column].Y;
                                }

                        }
                }
//	signalbarrier(1);
	waitbarrier(1);
					
//					if (core_id == MASTER)
//					{
//						printf("Round complete: \n");
//						printMatrix(game);
//
//						barrier[2] = BARRIERVAL(1);
//					}
//		waitbarrier(2);
        }
        
    if (core_id == MASTER)
	{
		end_time = read_counter(CR_CNT_ADDR, CR_CNTH_ADDR);
		time_spent = end_time - start_time;
		//printMatrix(A); //To print a matrix, uncomment this line.
//		printf("turing,%d,",N);
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

