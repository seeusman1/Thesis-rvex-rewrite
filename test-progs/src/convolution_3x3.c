
#include "platform.h"

//Optimization that forces the compiler to keep the filter in registers
//#define REGISTER_OPT


//#define DEBUG

/* The following code is from Iodev.org, modified for integer */
#define filterWidth 3
#define filterHeight 3
#define HSIZE 640
#define VSIZE 480

//Converted to fixed-point using INT_FACTOR as 1.0
#define INT_FACTOR 256

#ifndef REGISTER_OPT
//Choose kernel here
/* Note: This matrix needs values between 0 and 256 (instead of 0 and 1 floating point) */
//#define DEFAULT
//#define EDGE
#define BLUR

#ifdef DEFAULT
int filter[filterWidth][filterHeight] =
{
	 0, 0, 0,
	 0, 256, 0,
	 0, 0, 0,
};
#endif

#ifdef EDGE
int filter[filterWidth][filterHeight] =
{
	 -256, -256, -256,
	 -256, 2048, -256,
	 -256, -256, -256
};
#endif

#ifdef BLUR
int filter[filterWidth][filterHeight] =
	{
		 32, 32, 32,
		 32, 32, 32,
		 32, 32, 32
	};
#endif

#endif //REGISTER_OPT

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


#ifdef REGISTER_OPT
	register int filter[filterWidth][filterHeight] =
	{
		 32, 32, 32,
		 32, 32, 32,
		 32, 32, 32
	};
#endif

#ifdef DEBUG
	int runs;
#endif

#ifdef DEBUG
	for (runs = 0; runs < 2; runs++){
#endif
	//apply the filter
	for(y = filterHeight/2; y < VSIZE-(filterHeight/2); y++)
	for(x = filterWidth /2; x < HSIZE -(filterWidth /2); x++)
	{
		int red = 0, green = 0, blue = 0;
		int curPix;

		//multiply every value of the filter with corresponding inbuf pixel
#ifndef REGISTER_OPT
		for(filterX = 0; filterX < filterWidth; filterX++)
//		#pragma unroll(4)
		for(filterY = 0; filterY < filterHeight; filterY++)
		{
//			inbufX = (x - filterWidth / 2 + filterX + HSIZE) % HSIZE;
//			inbufY = (y - filterHeight / 2 + filterY + VSIZE) % VSIZE;
			inbufX = (x - filterWidth / 2 + filterX);// % HSIZE;
			inbufY = (y - filterHeight / 2 + filterY);// % VSIZE;

			curPix = inbuf[inbufX + (inbufY*HSIZE)];
			
			red   += (((unsigned int)((curPix>>16)&0xFF)) * filter[filterX][filterY])/INT_FACTOR;
			green += (((unsigned int)((curPix>> 8)&0xFF)) * filter[filterX][filterY])/INT_FACTOR;
			blue  +=  (((unsigned int)(curPix	 &0xFF)) * filter[filterX][filterY])/INT_FACTOR;
		}
#else //REGISTER_OPT
			/*
			 * We really want to keep the filter window in registers, so we write this out fully
			 */
			red   += (((unsigned int)((inbuf[x-1 + (y-1*HSIZE)]>>16)&0xFF)) * filter[0][0])/INT_FACTOR;
			green += (((unsigned int)((inbuf[x-1 + (y-1*HSIZE)]>> 8)&0xFF)) * filter[0][0])/INT_FACTOR;
			blue  +=  (((unsigned int)(inbuf[x-1 + (y-1*HSIZE)]	 &0xFF)) * filter[0][0])/INT_FACTOR;
			
			red   += (((unsigned int)((inbuf[x + (y-1*HSIZE)]>>16)&0xFF)) * filter[0][1])/INT_FACTOR;
			green += (((unsigned int)((inbuf[x + (y-1*HSIZE)]>> 8)&0xFF)) * filter[0][1])/INT_FACTOR;
			blue  +=  (((unsigned int)(inbuf[x + (y-1*HSIZE)]	 &0xFF)) * filter[0][1])/INT_FACTOR;
			
			red   += (((unsigned int)((inbuf[x+1 + (y-1*HSIZE)]>>16)&0xFF)) * filter[0][2])/INT_FACTOR;
			green += (((unsigned int)((inbuf[x+1 + (y-1*HSIZE)]>> 8)&0xFF)) * filter[0][2])/INT_FACTOR;
			blue  +=  (((unsigned int)(inbuf[x+1 + (y-1*HSIZE)]	 &0xFF)) * filter[0][2])/INT_FACTOR;
			
			red   += (((unsigned int)((inbuf[x-1 + (y*HSIZE)]>>16)&0xFF)) * filter[1][0])/INT_FACTOR;
			green += (((unsigned int)((inbuf[x-1 + (y*HSIZE)]>> 8)&0xFF)) * filter[1][0])/INT_FACTOR;
			blue  +=  (((unsigned int)(inbuf[x-1 + (y*HSIZE)]	 &0xFF)) * filter[1][0])/INT_FACTOR;
			
			red   += (((unsigned int)((inbuf[x + (y*HSIZE)]>>16)&0xFF)) * filter[1][1])/INT_FACTOR;
			green += (((unsigned int)((inbuf[x + (y*HSIZE)]>> 8)&0xFF)) * filter[1][1])/INT_FACTOR;
			blue  +=  (((unsigned int)(inbuf[x + (y*HSIZE)]	 &0xFF)) * filter[1][1])/INT_FACTOR;
			
			red   += (((unsigned int)((inbuf[x+1 + (y*HSIZE)]>>16)&0xFF)) * filter[1][2])/INT_FACTOR;
			green += (((unsigned int)((inbuf[x+1 + (y*HSIZE)]>> 8)&0xFF)) * filter[1][2])/INT_FACTOR;
			blue  +=  (((unsigned int)(inbuf[x+1 + (y*HSIZE)]	 &0xFF)) * filter[1][2])/INT_FACTOR;
			
			red   += (((unsigned int)((inbuf[x-1 + (y+1*HSIZE)]>>16)&0xFF)) * filter[2][0])/INT_FACTOR;
			green += (((unsigned int)((inbuf[x-1 + (y+1*HSIZE)]>> 8)&0xFF)) * filter[2][0])/INT_FACTOR;
			blue  +=  (((unsigned int)(inbuf[x-1 + (y+1*HSIZE)]	 &0xFF)) * filter[2][0])/INT_FACTOR;
			
			red   += (((unsigned int)((inbuf[x + (y+1*HSIZE)]>>16)&0xFF)) * filter[2][1])/INT_FACTOR;
			green += (((unsigned int)((inbuf[x + (y+1*HSIZE)]>> 8)&0xFF)) * filter[2][1])/INT_FACTOR;
			blue  +=  (((unsigned int)(inbuf[x + (y+1*HSIZE)]	 &0xFF)) * filter[2][1])/INT_FACTOR;
			
			red   += (((unsigned int)((inbuf[x+1 + (y+1*HSIZE)]>>16)&0xFF)) * filter[2][2])/INT_FACTOR;
			green += (((unsigned int)((inbuf[x+1 + (y+1*HSIZE)]>> 8)&0xFF)) * filter[2][2])/INT_FACTOR;
			blue  +=  (((unsigned int)(inbuf[x+1 + (y+1*HSIZE)]	 &0xFF)) * filter[2][2])/INT_FACTOR;
#endif //REGISTER_OPT
			
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

//		}
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
		fb[(y*HSIZE)+x] = min(max(int(factor * red + bias), 0), 255)<<16
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

