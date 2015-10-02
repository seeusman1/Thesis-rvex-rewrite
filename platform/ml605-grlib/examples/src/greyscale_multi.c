
#ifdef PLATFORM
#define FB_ADDRESS 0x400000
#else
#define FB_ADDRESS 0x20100000
#endif


//#define DEBUG


#define imageWidth 16
#define imageHeight 16


extern inline int max(int a, int b);


extern inline int min(int a, int b);

int main_greyscale(int start_height, int end_height)
{
    unsigned int* framebuffer = (unsigned int*)0x4000000;
    unsigned int* image = (unsigned int*)0x8000000;
    int i, x, y, filterX, filterY, imageX, imageY;
    
  	puts("greyscale starting\n");

#ifdef DEBUG
    int runs;
#endif



	/* First write a test screen */
/*
#ifdef DEBUG
	puts("writing test screen\n");
#endif
	for (i = 0; i < 640*160; i++)
	{
		image[i] = 0x00FF0000 - ((((i%640)/3)&0xff)<<16);
	}
	__asm__("nop");
#ifdef DEBUG
	puts("writing test screen 2\n");
#endif
	for (; i < 640*320; i++)
	{
		image[i] = 0x0000FF00 - ((((i%640)/3)&0xff)<<8);
	}
	__asm__("nop");
#ifdef DEBUG
	puts("writing test screen 3\n");
#endif
	for (; i < 640*480; i++)
	{
		image[i] = 0x000000FF - (((i%640)/3)&0xff);
	}
	__asm__("nop");
#ifdef DEBUG
	puts("Finished writing test screen\n");
#endif
*/

	//Clear the output image
	for (i = imageWidth*start_height; i < (imageWidth*end_height); i++)
		framebuffer[i] = 0;

#ifdef DEBUG
    for (runs = 0; runs < 2; runs++){
#endif
    //apply the filter
    for(y = start_height; y < end_height; y++)
    for(x = 0; x < imageWidth; x++)
    {
    	unsigned int greyscale;
    	unsigned int rgb = image[x + (y*imageWidth)];
        unsigned char highest = (unsigned int) (max(max(rgb&0xff, (rgb>>8)&0xff), (rgb>>16)&0xff) & 0xff);

        
#ifdef DEBUG
if(runs){
        puts("RGB values:\n");
        tohex(strbuf, rgb);
        puts(strbuf);
}
#endif

		greyscale = highest <<16 | highest <<8 | highest;
        framebuffer[(y*imageWidth)+x] = greyscale;
        
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


	//puts("Finished\n");

    return 0;
}


