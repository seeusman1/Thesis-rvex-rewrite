
#include "simrvex_framebuffer.h"

//#define DEBUG

/* The following code is from Iodev.org, modified for integer */
#define filterWidth 5
#define filterHeight 5
#define HSIZE 256
#define VSIZE 256

//Converted to fixed-point using INT_FACTOR as 1.0
#define INT_FACTOR 768


int filter5x5[filterWidth][filterHeight] =
{
	 32, 32, 32, 32, 32,
	 32, 32, 32, 32, 32,
	 32, 32, 32, 32, 32,
	 32, 32, 32, 32, 32,
	 32, 32, 32, 32, 32
};


#if USE_FACTOR
int factor = 256;
int bias = 0;
#endif

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

char strbuf[12];
int main()
{
	//puts("convolution starting\n");

	int i, x, y, filterX, filterY, inbufX, inbufY;
	unsigned int* fb = (unsigned int*)FB_ADDRESS;
	unsigned int* inbuf = (unsigned int*)FB_ADDRESS; //you probably want to change this to something useful

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
	for(y = filterHeight/2; y < VSIZE-(filterHeight/2); y++)
	for(x = filterWidth /2; x < HSIZE -(filterWidth /2); x++)
	{
		int red = 0, green = 0, blue = 0;

		//multiply every value of the filter with corresponding inbuf pixel

		for(filterX = 0; filterX < filterWidth; filterX++)
//		#pragma unroll(4)
		for(filterY = 0; filterY < filterHeight; filterY++)
		{
//			inbufX = (x - filterWidth / 2 + filterX + HSIZE) % HSIZE;
//			inbufY = (y - filterHeight / 2 + filterY + VSIZE) % VSIZE;
			inbufX = (x - filterWidth / 2 + filterX);//% HSIZE;
			inbufY = (y - filterHeight / 2 + filterY);// % VSIZE;

			red   += (((signed int)((inbuf[inbufX + (inbufY*HSIZE)]>>16)&0xFF)) * filter5x5[filterX][filterY])/INT_FACTOR;
			green += (((signed int)((inbuf[inbufX + (inbufY*HSIZE)]>> 8)&0xFF)) * filter5x5[filterX][filterY])/INT_FACTOR;
			blue  +=  (((signed int)(inbuf[inbufX + (inbufY*HSIZE)]	 &0xFF)) * filter5x5[filterX][filterY])/INT_FACTOR;

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


	puts("Convolution 5x5 Finished\n");
	while (1) ; //loop, otherwise the simulator will exit and close the framebuffer window
	return 0;
}

