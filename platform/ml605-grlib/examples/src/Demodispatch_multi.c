#include "rvex.h"
#include "grvga.h"
/*
 * At this point, every core has its own stack (_startpar.s).
 * Now we want to call each core's main function.
 */

//#define nr_threads 4 //now a user choice
#define HEIGHT 480


inline int max(int a, int b)
{
	if (a > b) return a;
	else return b;
}

inline int min(int a, int b)
{
	if (a < b) return a;
	else return b;
}


int get_core_ID();
int run_program(char program, int nr_threads);
void merge();

int running_flags;
int finished_flags[4];

volatile char program_choice = '\0';
volatile char  nr_threads = 0;

//volatile char program_choice = 'M';
//volatile char  nr_threads = 3;


char strbuf[12];

int main(int argc, char* argv[])
{
	//puts("starting dispatch program\n");
	char inputchar;
	int i;
	int core_ID = get_core_ID();


	if (core_ID == 0)
	{
		nr_threads = -1;
		program_choice = -1;
		init_vga();
	}
	
	//get user's choice from UART
	while (1) 
	{
		while (program_choice != 'm' && program_choice != 'r')
		{
			if (core_ID == 0)
			{
				puts("Program to run (\"m\" for Mandelbrot, \"r\"for Raytracer): \n");
				inputchar = getchar();
				program_choice = inputchar;
			}
		}	
		
		while (nr_threads <= 0 || nr_threads > 4)
		{
			if (core_ID == 0)
			{
				puts("Number of threads: (please specify a number between 1 and 4)\n");
				inputchar = getchar();
				nr_threads = inputchar - '0';
			}
		}

		if (core_ID == 0)
		{
		switch (nr_threads){
		
		case 4 : 
			CR_CRR = 0x3210;
			break;
		case 3 :
			CR_CRR = 0x2100;
			break;
		case 2 : 
			CR_CRR = 0x1100;
			break;
		default : 
			CR_CRR = 0x0000;
			break;
		}
		}

		running_flags |= (1<< core_ID); //flag that we are running
		run_program(program_choice, nr_threads);
		//running_flags &= ~(1<<core_ID); //flag that we are finished
		finished_flags[core_ID] = 1;
		
		
		//merge(); //give our processing resources to other threads that are still active
		
		
		
		//puts("current config:\n");
		//for (i = 0; i < 4; i++)
		//{
			//putc('0' + (CR_CC>>(i*4)&0xf));
		//}
		
		//move back to context 0 in 8-issue;
		CR_CRR = 0;
		
		program_choice = nr_threads = -1; //reset the vars so we must choose again
	
	}

}

void merge()
{
	int i;
	int active_context;
	int new_config, tmp;
	int cur_config = new_config = CR_CC;
	int core_ID = (int)CR_CID;
	int active_threadcnt;
	int active_thread[4];

/*
	puts("current config:\n");
	for (i = 0; i < 4; i++)
	{
		putc('0' + (cur_config>>(i*4)&0xf));
	}
	putc('\n');
*/

	/*
	 * At this point, there can be either 3, 2 or 1 busy thread.
	 * when 3, just merge into our neighbouring lanepair.
	 * when 2, split the work over 2 4-issue cores.
	 */
	 
	 active_threadcnt = 0;
	 for (i = 0; i < nr_threads; i++)
	 	if (!finished_flags[i])
	 	{
	 		active_thread[active_threadcnt] = i; 
	 		active_threadcnt++;
	 	}
	 
	 if (active_threadcnt == 3)
	 {
	 	switch (core_ID) //we know all the others are still active, choose the config that keeps the other contexts in their current lanes
	 	{
	 		case 0:
	 			new_config = 0x3211; break;
	 		case 1:
	 			new_config = 0x3200; break;
	 		case 2:
	 			new_config = 0x3310; break;
	 		default:
	 			new_config = 0x2210; break;
	 	}
	}
	else if (active_threadcnt == 2) //we don't know which others are active, get the ones from the active_thread array
	{
		new_config = ( (active_thread[1]<<12) | (active_thread[1]<<8) | (active_thread[0]<<4) | (active_thread[0]));
	}
	else //must be 1
	{
		new_config = ( (active_thread[0]<<12) | (active_thread[0]<<8) | (active_thread[0]<<4) | (active_thread[0]));
	}
	
/*
	puts("new config:\n");
	for (i = 0; i < 4; i++)
	{
		putc('0' + (new_config>>(i*4)&0xf));
	}
	putc('\n');
*/

	CR_CRR = new_config;
	
	return;
}

int run_program(char program, int nr_threads)
{
	int start_height, end_height;
	int chunk, chunkPlus, excess;
	
	//Calculations to divide the workload among all threads
	if(HEIGHT%nr_threads == 0){
			start_height = (HEIGHT/nr_threads) * get_core_ID();
			end_height = start_height + (HEIGHT/nr_threads);
	}else{
			excess = HEIGHT%nr_threads;
			chunk = HEIGHT/nr_threads;
			chunkPlus = chunk+1;
			if(get_core_ID() < excess){
					start_height = chunkPlus*get_core_ID();
					end_height = start_height + chunkPlus;
			}else{
					start_height = (chunk*get_core_ID())+excess;
					end_height = start_height + chunk;
			}
	}
	//End of calculations to divide the workload among all threads
	

	if (program == 'm') return main_Mandelbrot(start_height, end_height);
	if (program == 'r') return main_Raytracer(start_height, end_height);

}

inline int get_core_ID()
{
	return (int)CR_CID;
}


