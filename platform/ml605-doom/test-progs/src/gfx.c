#include "gfx.h"

/**
 * Converts an RGB color into the 16-bit framebuffer colorspace.
 */
gfx_pixel_t gfx_rgb(unsigned char r, unsigned char g, unsigned char b) {
  return ((gfx_pixel_t)(r>>3)<<11) | ((gfx_pixel_t)(g>>2)<<5) | (b>>3);
}

/**
 * Converts an HTML color code to the 16-bit framebuffer colorspace.
 */
gfx_pixel_t gfx_rgbh(int html) {
  return gfx_rgb(html, html >> 8, html >> 16);
}

/**
 * Draws a line from (x1,y1) to (x2,y2) onto the framebuffer specified by buf
 * using the specified stride (framebuffer width).
 */
void gfx_drawline(gfx_pixel_t *buf, int stride, int x1, int y1, int x2, int y2, gfx_pixel_t color) {
  int dx, dy, i, e;
  int incx, incy, inc1, inc2;

  dx = x2 - x1;
  dy = y2 - y1;

  if (dx < 0) {
    dx = -dx;
  }
  if (dy < 0) {
    dy = -dy;
  }
  incx = (x2 < x1) ? -1 : 1;
  incy = (y2 < y1) ? -stride : stride;
  
  buf += x1;
  buf += y1 * stride;

  if (dx > dy) {
    *buf = color;
    e = 2*dy - dx;
    inc1 = 2*(dy-dx);
    inc2 = 2*dy;
    for (i = 0; i < dx; i++) {
      if (e >= 0) {
        buf += incy;
        e += inc1;
      } else {
        e += inc2;
      }
      buf += incx;
      *buf = color;
    }
  } else {
    *buf = color;
    e = 2*dx - dy;
    inc1 = 2*(dx - dy);
    inc2 = 2*dx;
    for (i = 0; i < dy; i++) {
      if (e >= 0) {
        buf += incx;
        e += inc1;
      } else {
        e += inc2;
      }
      buf += incy;
      *buf = color;
    }
  }
}

/**
 * Fills a rectangle from (x1,y1) to (x2,y2) onto the framebuffer specified by
 * buf using the specified stride (framebuffer width). x2 and y2 are
 * non-inclusive. x2 must be greater than or equal to x1. Same thing for y.
 */
void gfx_fillrect(gfx_pixel_t *buf, int stride, int x1, int y1, int x2, int y2, gfx_pixel_t color) {
  int x, y;
  for (y = y1; y < y2; y++) {
    gfx_pixel_t *ptr = buf + (stride*y + x1);
    for (x = x1; x < x2; x++) {
      *ptr++ = color;
    }
  }
}

/**
 * Draws the borders of a rectangle from (x1,y1) to (x2,y2) onto the framebuffer
 * specified by buf using the specified stride (framebuffer width). x2 and y2
 * are non-inclusive. x2 must be greater than or equal to x1. Same thing for y.
 */
void gfx_drawrect(gfx_pixel_t *buf, int stride, int x1, int y1, int x2, int y2, gfx_pixel_t color) {
  gfx_drawline(buf, stride, x1,   y1,   x2-1, y1,   color);
  gfx_drawline(buf, stride, x1,   y2-1, x2-1, y2-1, color);
  gfx_drawline(buf, stride, x1,   y1,   x1,   y2-1, color);
  gfx_drawline(buf, stride, x2-1, y1,   x2-1, y2-1, color);
}

/**
 * Draws the text specified by s starting from coordinate (x,y) (that's the
 * top-left coordinate) onto the framebuffer specified by buf using the
 * specified stride (framebuffer width).
 */
int gfx_drawtext(gfx_pixel_t *buf, int stride, int x, int y, const char *s, gfx_pixel_t color, const font_t *font) {
  gfx_pixel_t *ptr = buf + x + y*stride;
  while (*s) {
    if (*s == '\n') {
      
      // Go to the next line.
      y += font->height + 1;
      ptr = buf + x + y*stride;
      
    } else {
      
      // Get the width and data offset for this character.
      int o = font->info[*s];
      int w = o >> 11;
      const unsigned short *dptr = font->data + (o & 0x7FF);
      
      // For each vertical line...
      while (w--) {
        int d = *dptr++;
        gfx_pixel_t *lptr = ptr++;
        
        // For each pixel in the line...
        while (d) {
          if (d & 1) {
            *lptr = color;
          }
          lptr += stride;
          d >>= 1;
        }
      }
      
      // Add one vertical line spacing between characters.
      ptr++;
      
    }
    s++;
  }
}

/**
 * Figures out the size of a block of text on the screen.
 */
int gfx_textsize(const char *s, const font_t *font, int *w, int *h) {
  int lw = -1; // (ignore the spacing after the last character)
  *w = 0;
  *h = font->height;
  while (*s) {
    if (*s == '\n') {
      
      // Record the line width.
      if (lw > *w) {
        *w = lw;
      }
      
      // Go to the next line.
      *h += font->height + 1;
      lw = 0;
      
    } else {
      
      // Add the width of this character plus one pixel spacing.
      int cw = font->info[*s] >> 11;
      lw += cw + 1;
      
    }
    s++;
  }
  
  // Record the line width.
  if (lw > *w) {
    *w = lw;
  }
  
}

/**
 * Draws the text specified by s starting from coordinate (x,y) onto the
 * framebuffer specified by buf using the specified stride (framebuffer width).
 * ax and ay specify the anchor position. 0,0 means (x,y) is the top-left
 * coordinate, 128,128 means it is the bottom-right coordinate. Note that the
 * text itself is ALWAYS LEFT-ALIGNED; this method just calculates the
 * dimensions of the text block and then translates the (x,y) coordinates before
 * rendering.
 */
int gfx_drawtext2(gfx_pixel_t *buf, int stride, int x, int y, int ax, int ay, const char *s, gfx_pixel_t color, const font_t *font) {
  int w, h;
  gfx_textsize(s, font, &w, &h);
  x -= ((w * ax) + 64) >> 7;
  y -= ((h * ay) + 64) >> 7;
  gfx_drawtext(buf, stride, x, y, s, color, font);
}
