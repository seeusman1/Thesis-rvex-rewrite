
#ifdef PLATFORM
#define FB_ADDRESS 0x400000
#else
#define FB_ADDRESS 0x20100000
#endif


//#define DEBUG

/* The following code is from Iodev.org, modified for integer */
#define filterWidth 3
#define filterHeight 3
#define imageWidth 640
#define imageHeight 480


//Choose kernel here
/* Note: This matrix needs values between 0 and 256 (instead of 0 and 1 floating point) */
//#define DEFAULT
//#define EDGE
#define BLUR

#ifdef DEFAULT
#if filterWidth == 5
int filter[filterWidth][filterHeight] =
{
     0, 0, 0, 0, 0,
     0, 0, 0, 0, 0,
     0, 0, 256, 0, 0,
     0, 0, 0, 0, 0,
     0, 0, 0, 0, 0,
};
#endif
#if filterWidth == 3
int filter[filterWidth][filterHeight] =
{
     0, 0, 0,
     0, 256, 0,
     0, 0, 0,
};
#endif
#endif

#ifdef EDGE
#if filterWidth == 5
int filter[filterWidth][filterHeight] =
{
     -256, -256, -256, -256, -256,
     -256, -256, -256, -256, -256,
     -256, -256, 2048, -256, -256,
     -256, -256, -256, -256, -256,
     -256, -256, -256, -256, -256
};
#endif
#if filterWidth == 3
int filter[filterWidth][filterHeight] =
{
     -256, -256, -256,
     -256, 2048, -256,
     -256, -256, -256
};
#endif
#endif

#ifdef BLUR
#if filterWidth == 5
int filter[filterWidth][filterHeight] =
{
     32, 32, 32, 32, 32,
     32, 32, 32, 32, 32,
     32, 32, 32, 32, 32,
     32, 32, 32, 32, 32,
     32, 32, 32, 32, 32
};
#endif
#if filterWidth == 3
int filter[filterWidth][filterHeight] =
{
     32, 32, 32,
     32, 32, 32,
     32, 32, 32
};
#endif
#endif


extern inline int max(int a, int b);

extern inline int min(int a, int b);

int main_convolution(int start_height, int end_height)
{
    unsigned int* framebuffer = (unsigned int*)0x400000;
    unsigned int* image = (unsigned int*)0x800000;
    volatile int timerread;
    int i, x, y, filterX, filterY, imageX, imageY;
    
    //puts("convolution starting\n");

#ifdef DEBUG
    int runs;
#endif



	/* First write a test screen */
/*
	for (i = 0; i < 640*160; i++)
	{
		image[i] = 0x00FF0000 - ((((i%640)/3)&0xff)<<16);
	}

	for (; i < 640*320; i++)
	{
		image[i] = 0x0000FF00 - ((((i%640)/3)&0xff)<<8);
	}

	for (; i < 640*480; i++)
	{
		image[i] = 0x000000FF - (((i%640)/3)&0xff);
	}
*/

	timerread = *(int*)0x8000051c; //read the cycle counter to reset it

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
        int red = 0, green = 0, blue = 0;

        //multiply every value of the filter with corresponding image pixel
        for(filterX = 0; filterX < filterWidth; filterX++)
        for(filterY = 0; filterY < filterHeight; filterY++)
        {
//            imageX = (x - filterWidth / 2 + filterX + imageWidth) % imageWidth;
//            imageY = (y - filterHeight / 2 + filterY + imageHeight) % imageHeight;
            imageX = (x - filterWidth / 2 + filterX);// % imageWidth;
            imageY = (y - filterHeight / 2 + filterY);// % imageHeight;

            red   += (((signed int)((image[imageX + (imageY*imageWidth)]>>16)&0xFF)) * filter[filterX][filterY])/256;
            green += (((signed int)((image[imageX + (imageY*imageWidth)]>> 8)&0xFF)) * filter[filterX][filterY])/256;
            blue  +=  (((signed int)(image[imageX + (imageY*imageWidth)]     &0xFF)) * filter[filterX][filterY])/256;

#ifdef DEBUG
if(runs){
            puts("Old RGB:\n");
            tohex(strbuf, ((image[imageX + (imageY*imageWidth)]>>16)&0xFF));
            puts(strbuf);
            tohex(strbuf, ((image[imageX + (imageY*imageWidth)]>> 8)&0xFF));
            puts(strbuf);
            tohex(strbuf, (image[imageX + (imageY*imageWidth)]&0xFF));
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

        //truncate values smaller than zero and larger than 255
        framebuffer[(y*imageWidth)+x] = min(max(red, 0), 255)<<16
        | min(max(green, 0), 255)<<8
        | min(max(blue, 0), 255);
    }
#ifdef DEBUG
    } //runs
#endif

    //puts("Finished\n\r");


    return 0;
}

/*
int main() __attribute__((weak));
int main()
{
	main_convolution(0, imageHeight);
}
*/
