/*
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
*/

/* framebuffer is initialized in Demodispatch_multi.c */

#define BARWIDTH 16


void colorbar(unsigned int* memloc)
{
	int i;
//	int* memloc = (int*)0x400000;

	for (i = 0; i < 640*160; i++)
	{
		memloc[i] = 0x00FF0000 - ((((i%640)/3)&0xff)<<16) ;
	}
	
	for (; i < 640*320; i++)
	{
		memloc[i] = 0x0000FF00 - ((((i%640)/3)&0xff)<<8);
	}
	
	for (; i < 640*480; i++)
	{
		memloc[i] = 0x000000FF - (((i%640)/3)&0xff);
	}
}

char str[12];
unsigned int* framebuffer = (unsigned int*) 0x4000000;
void color(int red, int green, int blue, int y, int x)
{

	int color = 0;
	if (x < 640-BARWIDTH)
	{
		color = (((char)red & 0xFF) << 16) | (((char)green & 0xFF) << 8) | ((char)blue & 0xFF);
		framebuffer[(y*640)+x] = color;
	}
	else 
		framebuffer[(y*640)+x] = 0xff<<(get_core_ID()*8);
//	framebuffer[((640*479)-y*640)+x] = color;
//    cursor++;
}



typedef unsigned long uint32;
typedef long int32;   
static float log2(float x)
{
    uint32 ix = (uint32)x;
    uint32 exp = (ix >> 23) & 0x7F;
//    int32 log2 = (int32)exp - 127;

    return (float)exp;
}


int main_Mandelbrot(int start_height, int end_height)
{
    int w = 640, h = 480, x, y; 
    //each iteration, it calculates: newz = oldz*oldz + p, where p is the current pixel, and oldz stars at the origin
    double pr, pi;                   //real and imaginary part of the pixel p
    double newRe, newIm, oldRe, oldIm;   //real and imaginary parts of new and old z
    double zoom, moveX = -1.55, moveY = 0; //you can change these to zoom and change position
    int maxIterations = 32;//after how much iterations the function should stop

    double time_spent;
    
    int i;
    
    if (start_height < 0 || start_height > 640) start_height = 0;
    if (end_height < 0 || end_height > 640) end_height = 640;

/*
	serial_init();
	serial_setbrg();
	serial_puts("starting Mandelbrot\n");
	*/
	
//	init_vga();
	colorbar(framebuffer);
	/*
	for (i = 0; i < 640*480; i++)
	{
		framebuffer[i] = 0;
	}
	*/

	//render the fractal a number of times with increasing zoom and shifting a bit to left at every iteration
    for (zoom = 1.0; zoom < 256; zoom*=2, moveX-=0.05/zoom)
    //loop through every pixel
    for(y = start_height; y < end_height; y++)
    for(x = 0; x < w; x++)
    {
        //"i" will represent the number of iterations
        int i;
    
        //calculate the initial real and imaginary part of z, based on the pixel location and zoom and position values
    pr = 1.5 * (x - w / 2) / (0.5 * zoom * w) + moveX;
        pi = (y - h / 2) / (0.5 * zoom * h) + moveY;
        newRe = newIm = oldRe = oldIm = 0; //these should start at 0,0

        //start the iteration process
        for(i = 0; i < maxIterations; i++)
        {
            //remember value of previous iteration
            oldRe = newRe;
            oldIm = newIm;
            //the actual iteration, the real and imaginary part are calculated
            newRe = oldRe * oldRe - oldIm * oldIm + pr;
            newIm = 2 * oldRe * oldIm + pi;
            //if the point is outside the circle with radius 2: stop
            if((newRe * newRe + newIm * newIm) > 4) break;
        }

        if(i == maxIterations)
        color(0, 0, 0, y, x); // black
    else
    {
//        double z = sqrt(newRe * newRe + newIm * newIm);
//        int brightness = 256. * log2(1.75 + i - log2(log2(z))) / log2((double)(maxIterations));

        double z = sqrt(newRe * newRe + newIm * newIm);
        int brightness = 256. * sqrt(1.75 + i - sqrt(sqrt(z))) / sqrt((double)(maxIterations));
        color(brightness, brightness, 255, y, x);
//	color(i, i, 255);
        //color(0, 0, 255);
    }

    }


    return 0;
}
