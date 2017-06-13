
#include "platform.h"

#ifndef HPVEX

// If defined, the colors look nicer at the cost of larger lookup tables.
// FPS is not affected.
#define HIGH_QUALITY_COLORS

// If defined, proper rounding is used after each iteration. If not defined,
// values are rounded to negative infinity. This costs extra computation time
// for pretty much no visual benefit.
#undef PROPER_ROUNDING


#ifdef HIGH_QUALITY_COLORS

#define COLOR_SCALE 4
//                                                                  COLOR_SCALE
//                                                                       vv
// [int(round((1 - math.log(math.log(math.sqrt((i+16)/4.)))/math.log(2))*16)) for i in range(128)]
const unsigned char smooth_color[128] = {
24, 23, 23, 22, 21, 20, 20, 19, 19, 18, 18, 17, 17, 16, 16, 15, 15, 15, 14, 14, 
14, 14, 13, 13, 13, 13, 12, 12, 12, 12, 11, 11, 11, 11, 11, 10, 10, 10, 10, 10, 
10, 9, 9, 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 
6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 
4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
3, 3, 3, 3, 3, 3, 3, 3 };

// a = [int(round(((1+math.cos(min(i/220., 1.)*math.pi*2.))/2.)*255)) for i in range(256)]
// [a[i] + a[(i+84)%256]*256 + a[(i+168)%256]*65536 for i in range(256)]
#define RAINBOW_SIZE 256
const int rainbow[256] = {
9052927, 9314303, 9575935, 9772031, 10033406, 10229502, 10491133, 10687228, 
10948860, 11145211, 11406842, 11603193, 11799288, 12061174, 12257269, 12453619, 
12649970, 12846320, 13042671, 13239277, 13435627, 13631977, 13828583, 14024932, 
14156002, 14352608, 14483677, 14680283, 14811352, 14942422, 15139283, 15270352, 
15401677, 15533002, 15664071, 15729860, 15861185, 15926974, 16058299, 16124344, 
16255668, 16321713, 16387502, 16453546, 16519335, 16519843, 16585888, 16651932, 
16652441, 16718741, 16719250, 16719758, 16720522, 16721031, 16721795, 16722304, 
16723068, 16723832, 16724597, 16725361, 16726125, 16726890, 16727654, 16728419, 
16729183, 16729948, 16730968, 16731733, 16732497, 16733518, 16734283, 16735303, 
16736068, 16737089, 16737854, 16738875, 16739640, 16740661, 16741682, 16742447, 
16743468, 16744233, 16745255, 16746276, 16747042, 16748063, 16749085, 16749851, 
16750872, 16751638, 16752660, 16753426, 16688912, 16689679, 16625165, 16560396, 
16561162, 16496649, 16431879, 16367110, 16302341, 16172036, 16107267, 15976963, 
15912194, 15781889, 15717121, 15586816, 15456256, 15325952, 15195392, 14999552, 
14868992, 14738432, 14542593, 14412033, 14215938, 14085379, 13889283, 13692932, 
13496837, 13300486, 13104391, 12908041, 12711946, 12515596, 12319245, 12122895, 
11861008, 11664402, 11468052, 11206166, 11009560, 10747675, 10551069, 10288927, 
10092322, 9830180, 9633575, 9371433, 9109292, 8912687, 8650546, 8453941, 
8191800, 7929659, 7733054, 7470913, 7208772, 7012167, 6750027, 6553422, 6291281, 
6094677, 5832536, 5635932, 5373791, 5177187, 4980582, 4718442, 4521837, 4325233, 
4128629, 3932024, 3735420, 3538815, 3342211, 3145607, 2949002, 2752398, 2621330, 
2424725, 2293657, 2097052, 1965984, 1834915, 1638055, 1506986, 1375662, 1244337, 
1113268, 1047480, 916155, 850366, 719041, 652996, 521671, 455626, 389837, 
323792, 258003, 257494, 191448, 125403, 124893, 58592, 58082, 57572, 56807, 
56297, 55531, 55021, 119791, 119024, 183794, 248563, 247797, 312566, 377336, 
442105, 506874, 637179, 701692, 831996, 896765, 1026814, 1091582, 1221631, 
1351935, 1481983, 1612287, 1807871, 1938175, 2068223, 2263807, 2394111, 2589695, 
2719999, 2915583, 3111167, 3307007, 3502591, 3698175, 3894015, 4089599, 4285439, 
4481023, 4676863, 4937983, 5133823, 5329407, 5590783, 5786623, 6047743, 6243583, 
6504959, 6700799, 6962175, 7158015, 7419391, 7680767, 7876607, 8137983, 8333823, 
8595455, 8856831};

#else

#define COLOR_SCALE 3
//                                                                  COLOR_SCALE
//                                                                       v
// [int(round((1 - math.log(math.log(math.sqrt((i+16)/4.)))/math.log(2))*8)) for i in range(128)]
const unsigned char smooth_color[128] = {
12, 12, 11, 11, 11, 10, 10, 10, 9, 9, 9, 9, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7, 7, 7, 
6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 
4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 
2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1 };

// a = [int(round(((1+math.cos(min(i/110., 1.)*math.pi*2.))/2.)*255)) for i in range(128)]
// [a[i] + a[(i+42)%128]*256 + a[(i+84)%128]*65536 for i in range(128)]
#define RAINBOW_SIZE 128
const int rainbow[128] = {
9052927, 9575935, 10033406, 10491133, 10948860, 11406842, 11799288, 12257269, 
12649970, 13042671, 13435627, 13828583, 14156002, 14483677, 14811352, 15139283, 
15401677, 15664071, 15861185, 16058299, 16255668, 16387502, 16519335, 16585888, 
16652441, 16719250, 16720522, 16721795, 16723068, 16724597, 16726125, 16727654, 
16729183, 16730968, 16732497, 16734283, 16736068, 16737854, 16739640, 16741682, 
16743468, 16745255, 16747042, 16749085, 16750872, 16752660, 16688912, 16625165, 
16561162, 16431879, 16302341, 16107267, 15912194, 15717121, 15456256, 15195392, 
14868992, 14542593, 14215938, 13889283, 13496837, 13104391, 12711946, 12319245, 
11861008, 11468052, 11009560, 10551069, 10092322, 9633575, 9109292, 8650546, 
8191800, 7733054, 7208772, 6750027, 6291281, 5832536, 5373791, 4980582, 4521837, 
4128629, 3735420, 3342211, 2949002, 2621330, 2293657, 1965984, 1638055, 1375662, 
1113268, 916155, 719041, 521671, 389837, 258003, 191448, 124893, 58082, 56807, 
55531, 119791, 183794, 247797, 377336, 506874, 701692, 896765, 1091582, 1351935, 
1612287, 1938175, 2263807, 2589695, 2915583, 3307007, 3698175, 4089599, 4481023, 
4937983, 5329407, 5786623, 6243583, 6700799, 7158015, 7680767, 8137983, 8595455
};

#endif

// This is a 1 bpp bitmap that maps to -1.5 to 0.5 re, 1 to 0 im. When a bit
// is set, it is assumed that all values within that square are in the
// mandelbrot set. One bit is 1/32 wide and high.
const int known[64] = {
    0x07FFFFFF,0xFFFFFC00,
    0x007FFFFF,0xFFFFFF00,
    0x007FFE7F,0xFFFFFFC0,
    0x003FFC7F,0xFFFFFFC0,
    0x001FF87F,0xFFFFFFE0,
    0x000FF07F,0xFFFFFFE0,
    0x000FF03F,0xFFFFFFE0,
    0x0000003F,0xFFFFFFE0,
    0x0000003F,0xFFFFFFE0,
    0x0000001F,0xFFFFFFE0,
    0x0000000F,0xFFFFFFE0,
    0x0000000F,0xFFFFFFC0,
    0x00000007,0xFFFFFFC0,
    0x00000003,0xFFFFFF80,
    0x00000003,0xFFFFFF00,
    0x00000000,0xFFFFFF00,
    0x00000000,0xFFFFFC80,
    0x00000000,0xBFFFF840,
    0x00000001,0x07FFF000,
    0x00000000,0x00FF0000,
    0x00000000,0x00180000,
    0x00000000,0x00180000,
    0x00000000,0x003C0000,
    0x00000000,0x003C0000,
    0x00000000,0x003C0000,
    0x00000000,0x00180000,
    0x00000000,0x00080000,
    0x00000000,0x00000000,
    0x00000000,0x00000000,
    0x00000000,0x00000000,
    0x00000000,0x00000000,
    0x00000000,0x00000000
};

// This function returns the pixel color for the given point in the mandelbrot.
// cr is the real value, ci is the imaginary value; both are in 8.24 fixed
// point. max_iter specifies the maximum amount of iterations.
int mandel_pt(int cr, int ci, int max_iter)
{
    
    // Formats:
    //   c = complex 8.24 signed
    //   z = complex 4.28 signed (assumed to fit in 3.28)
    //   zasq = real 8.2 signed
    //   zrr, zri, zii = real 8.56 signed
    //   zp = complex 8.56 signed
    int zr = 0, zi = 0;
    int zasq;
    long long zrr, zri, zii, zpr, zpi;
    int i;
    
    // Check the known array.
    int im = ci >= 0 ? ci : -ci;
    int re = cr + (3 << 23);
    if ((im >= 0) && (im < (1 << 24))) {
        if ((re >= 0) && (re < (2 << 24))) {
            im >>= 24 - 5;
            re >>= 24 - 5;
            int ar = (im << 1) + (re >> 5);
            int mask = 0x80000000u >> (re & 31);
            int ent = known[ar];
            if (ent & mask) {
                return 0;
            }
        }
    }
    
    max_iter <<= COLOR_SCALE;
    for (i = 0; i < max_iter; i+=(1<<COLOR_SCALE))
    {
        
        // Compute zr*zr, zr*zi, and zi*zi.
        zrr = (long long)(zr) * (volatile long long)(zr);
        zri = (long long)(zr) * (long long)(zi);
        zii = (long long)(zi) * (volatile long long)(zi);
        
        // zasq = |z|^2 +/- 1
        zasq = ((zrr >> 32) + (zii >> 32)) >> 22;
        
        // zp = z^2
        zpr = zrr - zii;
        zpi = zri << 1;
        
        // zp += c
        zpr += ((long long)cr) << 32;
        zpi += ((long long)ci) << 32;
        
        // Convert zp to z.
#       ifdef PROPER_ROUNDING
        zr = zpr >> 27;
        zi = zpi >> 27;
        zr += 1;
        zi += 1;
        zr >>= 1;
        zi >>= 1;
#       else
        zr = zpr >> 28;
        zi = zpi >> 28;
#       endif
        
        // See if zasq > 4.
        if (zasq >= 4 << 2)
        {
            int x = zasq - 16;
            x = i + smooth_color[x];
            x = rainbow[x&(RAINBOW_SIZE-1)];
            return x;
        }
        
    }
    
    return 0;
    
}

// This function draws a mandelbrot figure to the given framebuffer. fb is the
// framebuffer pointer at the top-left pixel coordinate of the figure, s is the
// width of the framebuffer, w and h are the size of the figure, crleft and
// citop specify the topleft real/imaginary components of the mandelbrot point
// in 8.24 fixed point, cs specifies the width/height of a pixel in the
// mandelbrot coordinate system.
int mandel(int *fb, int s, int w, int h, int crleft, int citop, int cs)
{
    int x, y, cr, ci;
    
    ci = citop;
    for (y = 0; y < h; y++)
    {
        cr = crleft;
        for (x = 0; x < w; x++)
        {
            int col = mandel_pt(cr, ci, 24);
            cr += cs;
            *fb++ = col;
        }
        ci += cs;
        fb += s - w;
    }
}

int fb_mem[640*480+1024];

int main(void)
{
    puts("initializing framebuffer...\n");
    int *fb = (int*)plat_video_init(640, 480, 32, 1, fb_mem);
    puts("rendering...\n");
    mandel(fb, 640, 640, 480, -2 << 24, -1 << 24, 9 << 13);
    puts("mandel complete\n");
}

#else

int main(void)
{
    puts("mandel requires 64-bit integers. Please compile with O64.\n");
}

#endif
