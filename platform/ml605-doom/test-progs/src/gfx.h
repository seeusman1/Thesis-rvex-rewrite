#ifndef _GFX_H_
#define _GFX_H_

typedef unsigned short gfx_pixel_t;

typedef struct font_t {
  
  // Font height.
  int height;
  
  // Character information. The 5 MSBs represent the width of the character,
  // the 11 LSBs index into the data array for the first line of the character.
  unsigned short info[256];
  
  // Character data. Each entry represents some vertical line of some character,
  // with the LSB being the topmost pixel.
  const unsigned short *data;
  
} font_t;

/**
 * Converts an RGB color into the 16-bit framebuffer colorspace.
 */
gfx_pixel_t gfx_rgb(
  unsigned char r,
  unsigned char g,
  unsigned char b
);

/**
 * Converts an HTML color code to the 16-bit framebuffer colorspace.
 */
gfx_pixel_t gfx_rgbh(
  int html
);

/**
 * Draws a line from (x1,y1) to (x2,y2) onto the framebuffer specified by buf
 * using the specified stride (framebuffer width).
 */
void gfx_drawline(
  gfx_pixel_t *buf, int stride,
  int x1, int y1,
  int x2, int y2,
  gfx_pixel_t color
);

/**
 * Fills a rectangle from (x1,y1) to (x2,y2) onto the framebuffer specified by
 * buf using the specified stride (framebuffer width). x2 and y2 are
 * non-inclusive. x2 must be greater than or equal to x1. Same thing for y.
 */
void gfx_fillrect(
  gfx_pixel_t *buf, int stride,
  int x1, int y1,
  int x2, int y2,
  gfx_pixel_t color
);

/**
 * Draws the borders of a rectangle from (x1,y1) to (x2,y2) onto the framebuffer
 * specified by buf using the specified stride (framebuffer width). x2 and y2
 * are non-inclusive. x2 must be greater than or equal to x1. Same thing for y.
 */
void gfx_drawrect(
  gfx_pixel_t *buf, int stride,
  int x1, int y1,
  int x2, int y2,
  gfx_pixel_t color
);

/**
 * Draws the text specified by s starting from coordinate (x,y) (that's the
 * top-left coordinate) onto the framebuffer specified by buf using the
 * specified stride (framebuffer width).
 */
int gfx_drawtext(
  gfx_pixel_t *buf, int stride, 
  int x, int y, 
  const char *s,
  gfx_pixel_t color,
  const font_t *font
);

/**
 * Figures out the size of a block of text on the screen.
 */
int gfx_textsize(
  const char *s,
  const font_t *font,
  int *w, int *h
);

/**
 * Draws the text specified by s starting from coordinate (x,y) onto the
 * framebuffer specified by buf using the specified stride (framebuffer width).
 * ax and ay specify the anchor position. 0,0 means (x,y) is the top-left
 * coordinate, 128,128 means it is the bottom-right coordinate. Note that the
 * text itself is ALWAYS LEFT-ALIGNED; this method just calculates the
 * dimensions of the text block and then translates the (x,y) coordinates before
 * rendering.
 */
int gfx_drawtext2(
  gfx_pixel_t *buf, int stride,
  int x, int y,
  int ax, int ay,
  const char *s,
  gfx_pixel_t color,
  const font_t *font
);

#endif
