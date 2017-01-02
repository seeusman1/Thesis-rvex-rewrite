
#include "simrvex_framebuffer.h"

#define INTEGER

#define HSIZE 1280
#define VSIZE 1024

//#define DEBUG

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

unsigned int inbuf[HSIZE*VSIZE]; //you probably want to change this to something useful
char strbuf[12];
int main()
{

	unsigned int timerread;
    unsigned int* fb = (unsigned int*)FB_ADDRESS;
	puts("greyscale starting\n");

    int i, x, y, filterX, filterY, inbufX, inbufY;

	*((volatile unsigned long *)FB_WIDTH_REG)   = HSIZE;
	*((volatile unsigned long *)FB_HEIGHT_REG)  = VSIZE;
	*((volatile unsigned long *)FB_DEPTH_REG)   = 32;
	*((volatile unsigned long *)FB_COMMAND_REG) = 1;

	/* write a test screen */
#define CEILING(x,y) (((x) + (y) - 1) / (y))
	for (i = 0; i < HSIZE*(VSIZE/3); i++)
	{
		inbuf[i] = 0x00FF0000 - ((((i%HSIZE)/CEILING(HSIZE,256))&0xff)<<16);
	}

	for (; i < HSIZE*2*(VSIZE/3); i++)
	{
		inbuf[i] = 0x0000FF00 - ((((i%HSIZE)/CEILING(HSIZE,256))&0xff)<<8);
	}

	for (; i < HSIZE*VSIZE; i++)
	{
		inbuf[i] = 0x000000FF - (((i%HSIZE)/CEILING(HSIZE,256))&0xff);
	}
	
	/* Clear framebuffer */
	for (i = 0; i < HSIZE*VSIZE; i++)
	{
		fb[i] = 0;
	}

#ifdef DEBUG
    int runs;
    for (runs = 0; runs < 2; runs++){
#endif
    //apply the filter
    for(y = 0; y < VSIZE; y++)
    for(x = 0; x < HSIZE; x++)
    {
    	unsigned int greyscale;
    	unsigned int rgb = inbuf[x + (y*HSIZE)];
        unsigned char highest = (unsigned int) (max(max(rgb&0xff, (rgb>>8)&0xff), (rgb>>16)&0xff) & 0xff);

        
#ifdef DEBUG
if(runs){
        puts("RGB values:\n");
        tohex(strbuf, rgb);
        puts(strbuf);
}
#endif

		greyscale = highest <<16 | highest <<8 | highest;
        fb[(y*HSIZE)+x] = greyscale;
        
#ifdef DEBUG
if(runs){
        puts("Greyscale:\n");
        tohex(strbuf, greyscale);
        puts(strbuf);
}
#endif

    }
#ifdef DEBUG
    } //runs
#endif


	puts("greyscale finished\n");
	while (1) ; //loop, otherwise the simulator will exit and close the fb window
    return 0;
}


