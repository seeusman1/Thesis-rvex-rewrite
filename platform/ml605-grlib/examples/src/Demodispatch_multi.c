#include "rvex.h"
/*
 * At this point, every core has its own stack (_startpar.s).
 * Now we want to call each core's main function.
 */

//#define nr_threads 4 //now a user choice
#define HEIGHT 480



/* framebuffer stuff */


typedef  unsigned int __u32;

/*
 * from snapgear Linux:
 */

/* Interpretation of offset for color fields: All offsets are from the right,
 * inside a "pixel" value, which is exactly 'bits_per_pixel' wide (means: you
 * can use the offset as right argument to <<). A pixel afterwards is a bit
 * stream and is written to video memory as that unmodified. This implies
 * big-endian byte order if bits_per_pixel is greater than 8.
 */
struct fb_bitfield {
	__u32 offset;			/* beginning of bitfield	*/
	__u32 length;			/* length of bitfield		*/
	__u32 msb_right;		/* != 0 : Most significant bit is */
					/* right */
};

struct fb_var_screeninfo {
	__u32 xres;			/* visible resolution		*/
	__u32 yres;
	__u32 xres_virtual;		/* virtual resolution		*/
	__u32 yres_virtual;
	__u32 xoffset;			/* offset from virtual to visible */
	__u32 yoffset;			/* resolution			*/

	__u32 bits_per_pixel;		/* guess what			*/
	__u32 grayscale;		/* != 0 Graylevels instead of colors */

	struct fb_bitfield red;		/* bitfield in fb mem if true color, */
	struct fb_bitfield green;	/* else only length is significant */
	struct fb_bitfield blue;
	struct fb_bitfield transp;	/* transparency			*/

	__u32 nonstd;			/* != 0 Non standard pixel format */

	__u32 activate;			/* see FB_ACTIVATE_*		*/

	__u32 height;			/* height of picture in mm    */
	__u32 width;			/* width of picture in mm     */

	__u32 accel_flags;		/* (OBSOLETE) see fb_info.flags */

	/* Timing: All values in pixclocks, except pixclock (of course) */
	__u32 pixclock;			/* pixel clock in ps (pico seconds) */
	__u32 left_margin;		/* time from sync to picture	*/
	__u32 right_margin;		/* time from picture to sync	*/
	__u32 upper_margin;		/* time from sync to picture	*/
	__u32 lower_margin;
	__u32 hsync_len;		/* length of horizontal sync	*/
	__u32 vsync_len;		/* length of vertical sync	*/
	__u32 sync;			/* see FB_SYNC_*		*/
	__u32 vmode;			/* see FB_VMODE_*		*/
	__u32 rotate;			/* angle we rotate counter clockwise */
	__u32 reserved[5];		/* Reserved for future compatibility */
};



typedef struct {
  volatile unsigned int status; 				/* 0x00 */
  volatile unsigned int video_length; 	/* 0x04 */
  volatile unsigned int front_porch;		/* 0x08 */
  volatile unsigned int sync_length;		/* 0x0c */
  volatile unsigned int line_length;		/* 0x10 */
  volatile unsigned int fb_pos;					/* 0x14 */
  volatile unsigned int clk_vector[4];	/* 0x18 */
  volatile unsigned int clut;						/* 0x28 */
} LEON3_GRVGA_Regs_Map;



void init_vga()
{
	LEON3_GRVGA_Regs_Map *regs = (LEON3_GRVGA_Regs_Map*)0x80000600;
	int clk_sel = -1, func = 0, i;
	struct fb_var_screeninfo init_data;
	
	init_data.xres =			640,
    init_data.yres =			480,
    init_data.xres_virtual =	640,
    init_data.yres_virtual =	480,
    init_data.pixclock = 	    40000,
    init_data.left_margin =		48,
    init_data.right_margin =	16,
    init_data.upper_margin =	31,
    init_data.lower_margin =	11,
    init_data.hsync_len =		96,
    init_data.vsync_len =		2,
	
	init_data.bits_per_pixel = 8;

	regs->video_length = ((init_data.yres - 1) << 16)
			+ (init_data.xres - 1);
	regs->front_porch = (init_data.lower_margin << 16)
			+ (init_data.right_margin);
	regs->sync_length = (init_data.vsync_len << 16)
			+ (init_data.hsync_len);
	regs->line_length = ((init_data.yres
			+ init_data.lower_margin + init_data.upper_margin
			+ init_data.vsync_len - 1) << 16)
			+ (init_data.xres + init_data.right_margin
					+ init_data.left_margin
					+ init_data.hsync_len - 1);

	regs->fb_pos = 0x400000;
	clk_sel = 0; //3 for modelsim, 0 for board
	func = 3;
	regs->status = ((clk_sel << 6) | (func << 4)) | 1;

}

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

volatile char program_choice = '\0';
volatile char  nr_threads = 0;

int main(int argc, char* argv[])
{
	puts("starting dispatch program\n");
	char inputchar;
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
		while (program_choice != 'm' && program_choice != 'r' && program_choice != 'c' && program_choice != 'g')
		{
			if (core_ID == 0)
			{
				puts("Program to run (\"m\" for Mandelbrot, \"r\"for Raytracer, \"c\" for Convolution, \"g\" for Greyscale): \n");
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
		running_flags &= ~(1<<core_ID); //flag that we are finished
		while (running_flags != 0) //keep merging into other contexts until all contexts are finished
		{
			merge();
		}
		
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
	
	//find a context that is still active and is not us
	for (i = 0; i < 3; i++)
	{
		active_context = ((cur_config >> (i*4)) & 0xf);
		if ( active_context != core_ID && active_context != 0x8) //skip disabled lanes
			break;			
	}
	puts("found active context:\n");
	putc('0'+active_context);
	
	//now assign all lanes that are assigned to us to that context
	for (i = 0; i < 3; i++)
	{
		tmp = ((cur_config >> (i*4)) & 0xf);
		if (tmp == core_ID)
		{
			new_config &= ~(0xf << (i*4));
			new_config |= active_context << (i*4);
		}
	}
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
	if (program == 'g') return main_greyscale(start_height, end_height);
	if (program == 'c') return main_convolution(start_height, end_height);

	if (program = 'd') { //program = dijkstra
		int size = 100; //small = 20; large = 100;
		if (size % NR_THREADS == 0) {
			start = (size / NR_THREADS) * get_core_ID();
			end = start + (size / NR_THREADS);
		} else {
			excess = size % NR_THREADS;
			chunk = size / NR_THREADS;
			chunkPlus = chunk + 1;
			if (get_core_ID() < excess) {
				start = chunkPlus * get_core_ID();
				end = start + chunkPlus;
			} else {
				start = (chunk * get_core_ID()) + excess;
				end = start + chunk;
			}
		}
	}

}

inline int get_core_ID()
{
	return (int)CR_CID;
}


typedef int int32;
typedef long long int int64;
int32 _flip_32h_smul_32_16(int32 a, int32 b)  // __st220mulhhs()
{
  int64 t0 = a;
  int64 t1 = b;
  int64 t2 = ( t0 * ( t1 >> 16 ) ) >> 16;
  return t2;
} 

