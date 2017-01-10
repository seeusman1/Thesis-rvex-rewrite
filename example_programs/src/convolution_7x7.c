
#include "platform.h"

//#define DEBUG

/* The following code is from Iodev.org, modified for integer */
#define filterWidth 7
#define filterHeight 7
#define HSIZE 640
#define VSIZE 480

//Converted to fixed-point using INT_FACTOR as 1.0
#define INT_FACTOR 1536

int filter7x7[filterWidth][filterHeight] =
{
     32, 32, 32, 32, 32, 32, 32,
     32, 32, 32, 32, 32, 32, 32,
     32, 32, 32, 32, 32, 32, 32,
     32, 32, 32, 32, 32, 32, 32,
     32, 32, 32, 32, 32, 32, 32,
     32, 32, 32, 32, 32, 32, 32,
     32, 32, 32, 32, 32, 32, 32
};


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

#if USE_FACTOR
int factor = 256;
int bias = 0;
#endif

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
    for(y = filterHeight/2; y < VSIZE-(filterHeight/2); y++)
    for(x = filterWidth /2; x < HSIZE -(filterWidth /2); x++)
    {
        int red = 0, green = 0, blue = 0;

        //multiply every value of the filter with corresponding inbuf pixel

        for(filterX = 0; filterX < filterWidth; filterX++)
//        #pragma unroll(4)
        for(filterY = 0; filterY < filterHeight; filterY++)
        {
//            inbufX = (x - filterWidth / 2 + filterX + HSIZE) % HSIZE;
//            inbufY = (y - filterHeight / 2 + filterY + VSIZE) % VSIZE;
            inbufX = (x - filterWidth / 2 + filterX);// % HSIZE;
            inbufY = (y - filterHeight / 2 + filterY);// % VSIZE;

            red   += (((signed int)((inbuf[inbufX + (inbufY*HSIZE)]>>16)&0xFF)) * filter7x7[filterX][filterY])/INT_FACTOR;
            green += (((signed int)((inbuf[inbufX + (inbufY*HSIZE)]>> 8)&0xFF)) * filter7x7[filterX][filterY])/INT_FACTOR;
            blue  +=  (((signed int)(inbuf[inbufX + (inbufY*HSIZE)]     &0xFF)) * filter7x7[filterX][filterY])/INT_FACTOR;

#ifdef DEBUG
if(runs){
            puts("Old RGB:\n");
            tohex(strbuf, ((inbuf[inbufX + (inbufY*HSIZE)]>>16)&0xFF));
            puts(strbuf);
            tohex(strbuf, ((inbuf[inbufX + (inbufY*HSIZE)]>> 8)&0xFF));
            puts(strbuf);
            tohex(strbuf, (inbuf[inbufX + (inbufY*HSIZE)]&0xFF));
            puts(strbuf);

            puts("RGB additions:\n");
            tohex(strbuf, red);
            puts(strbuf);
            tohex(strbuf, green);
            puts(strbuf);
            tohex(strbuf, blue);
            puts(strbuf);
}
#endif

        }
#ifdef DEBUG
if(runs){
        puts("RGB values:\n");
        tohex(strbuf, red);
        puts(strbuf);
        tohex(strbuf, green);
        puts(strbuf);
        tohex(strbuf, blue);
        puts(strbuf);
}
#endif

#if USE_FACTOR
        //truncate values smaller than zero and larger than 255
        fb(y*HSIZE)+x] = min(max(int(factor * red + bias), 0), 255)<<16
		| min(max(int(factor * green + bias), 0), 255)<<8
        | min(max(int(factor * blue + bias), 0), 255);
#else
        //truncate values smaller than zero and larger than 255
        fb[(y*HSIZE)+x] = min(max(red, 0), 255)<<16
        | min(max(green, 0), 255)<<8
        | min(max(blue, 0), 255);
#endif //USE_FACTOR
    }
#ifdef DEBUG
    } //runs
#endif

    return 0;
}

