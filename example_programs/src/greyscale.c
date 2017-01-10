
#include "platform.h"

#define HSIZE 640
#define VSIZE 480

//#define DEBUG

static inline int max(int a, int b)
{
	if (a > b) return a;
	else return b;
}

static inline int min(int a, int b)
{
	if (a < b) return a;
	else return b;
}

unsigned int inbuf[HSIZE*VSIZE]; //you probably want to change this to something useful
unsigned int fb_mem[(HSIZE*VSIZE)+1024];
char strbuf[12];
int main()
{
    int i, x, y, filterX, filterY, inbufX, inbufY;
    unsigned int* fb;

	plat_init();
	fb = plat_video_init(HSIZE, VSIZE, 32, 0, fb_mem);

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

    return 0;
}


