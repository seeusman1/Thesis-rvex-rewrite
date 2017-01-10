
#include "gfx_cfgpwr.h"
#include "gfx.h"

/**
 * NOTE: refer to the header file for usage information.
 */

/**
 * Initializes a graph.
 */
void graph_init(graph_t *g, gfx_pixel_t *framebuf, int stride, int x, int y, int w, int h, const font_t *font) {
  g->framebuf = framebuf + x + stride*y;
  g->stride = stride;
  g->w = w;
  g->h = h;
  g->lgh = 6;
  g->inc = 5;
  g->ginc = 20;
  g->tw = 20;
  g->vtcount = 0;
  g->f = font;
  
  g->bgcol = gfx_rgb(255, 255, 255);
  g->axcol = gfx_rgb(0, 0, 0);
  g->grcol = gfx_rgb(128, 128, 128);
  g->txtcol = gfx_rgb(0, 0, 0);
  g->datcol = gfx_rgb(0, 0, 255);
  
  // Color codes for the tasks in the configuration bar.
  // Source: http://www.colorschemer.com/online.html, base color #FF6633.
  // Strided by 9 so tasks with similar indices have reasonably distinguishable
  // colors.
  g->taskcol[( 0 *9)%16] = gfx_rgbh(0xFF6633);
  g->taskcol[( 1 *9)%16] = gfx_rgbh(0xFFCC33);
  g->taskcol[( 2 *9)%16] = gfx_rgbh(0xCCFF33);
  g->taskcol[( 3 *9)%16] = gfx_rgbh(0x66FF33);
  g->taskcol[( 4 *9)%16] = gfx_rgbh(0xFF3366);
  g->taskcol[( 5 *9)%16] = gfx_rgbh(0xF53D00);
  g->taskcol[( 6 *9)%16] = gfx_rgbh(0xB82E00);
  g->taskcol[( 7 *9)%16] = gfx_rgbh(0x33FF66);
  g->taskcol[( 8 *9)%16] = gfx_rgbh(0xFF33CC);
  g->taskcol[( 9 *9)%16] = gfx_rgbh(0x008AB8);
  g->taskcol[(10 *9)%16] = gfx_rgbh(0x00B8F5);
  g->taskcol[(11 *9)%16] = gfx_rgbh(0x33FFCC);
  g->taskcol[(12 *9)%16] = gfx_rgbh(0xCC33FF);
  g->taskcol[(13 *9)%16] = gfx_rgbh(0x6633FF);
  g->taskcol[(14 *9)%16] = gfx_rgbh(0x3366FF);
  g->taskcol[(15 *9)%16] = gfx_rgbh(0x33CCFF);
  g->taskcol[255] = gfx_rgb(255, 255, 255);
  g->tbcol = gfx_rgb(0, 0, 0);
  
}

/**
 * Adds a tickmark to an initialized graph.
 */
void graph_addtick(graph_t *g, unsigned char val, const char *text) {
  g->vty[g->vtcount] = g->h - 1 - val;
  g->vtc[g->vtcount] = text;
  g->vtcount++;
}

/**
 * Resets the graph data for the given graph and (re)renders it.
 */
void graph_reset(graph_t *g) {
  int i, j, y;
  
  // Figure out the number of data points that can be displayed.
  g->ndp = (g->w - g->tw) / g->inc;
  
  // Reset the data.
  for (i = 0; i < GRAPH_DATA_BUF_SIZE; i++) {
    g->power[i] = 255;
  }
  for (i = 0; i < GRAPH_DATA_BUF_SIZE; i++) {
    g->config[i] = 0xFFFFFFFF;
  }
  g->idx = 0;
  
  // Refresh the graph area: override with white.
  gfx_fillrect(g->framebuf, g->stride, 0, 0, g->w, g->h, g->bgcol);
  
  // Draw the axes.
  gfx_drawline(g->framebuf, g->stride, g->tw, 0, g->tw, g->h-1, g->axcol);
  gfx_drawline(g->framebuf, g->stride, g->tw, g->h-1, g->w-1, g->h-1, g->axcol);
  
  // Draw the vertical axis ticks.
  for (i = 0; i < g->vtcount; i++) {
    y = g->vty[i];
    gfx_drawline(g->framebuf, g->stride, g->tw, y, g->tw-1, y, g->axcol);
    gfx_drawtext2(g->framebuf, g->stride, g->tw-3, y, 128, 64, g->vtc[i], g->txtcol, g->f);
  }
  y = 0;
  j = g->lgh;
  for (i = 0; i < 5; i++) {
    gfx_drawline(g->framebuf, g->stride, g->tw, y, g->tw-1, y, g->axcol);
    if (i == 2) {
      gfx_drawtext2(g->framebuf, g->stride, g->tw-3, y, 128, 64, "Cfg", g->txtcol, g->f);
    }
    y += j;
  }
  
  // Draw the background color for the configuration display.
  gfx_fillrect(g->framebuf, g->stride, g->tw+1, 0, g->tw+1+g->inc*g->ndp, g->lgh*4+1, g->taskcol[255]);
  
}

/**
 * Adds data to a graph and rerenders it.
 */
void graph_data(
  graph_t *g,
  int power,
  int *cfg
) {
  int i, idx, x;
  int gx = g->tw + g->ginc;
  unsigned int config;
  
  // Add the data.
  config = (unsigned int)(cfg[0] & 0xFF);
  config |= ((unsigned int)(cfg[1] & 0xFF)) << 8;
  config |= ((unsigned int)(cfg[2] & 0xFF)) << 16;
  config |= ((unsigned int)(cfg[3] & 0xFF)) << 24;
  g->power[g->idx] = (unsigned char)power;
  g->config[g->idx] = config;
  g->idx++;
  g->idx &= (GRAPH_DATA_BUF_SIZE-1);
  
  // Re-render the data from left to right.
  idx = g->idx - g->ndp - 2;
  x = g->tw - g->inc + 1;
  for (i = -g->ndp; i <= 0; i++) {
    int cidx, cp, cy;
    int pidx, pp, py;
    unsigned int cc, pc;
    int nodata;
    
    // Compute indices.
    pidx = idx & (GRAPH_DATA_BUF_SIZE-1);
    idx++;
    cidx = idx & (GRAPH_DATA_BUF_SIZE-1);
    
    // Get the data.
    pp = g->power[pidx];
    cp = g->power[cidx];
    py = g->h - 1 - pp;
    cy = g->h - 1 - cp;
    pc = g->config[pidx];
    cc = g->config[cidx];
    nodata = (pp == 255) || (cp == 255);
    
    // Redraw power information.
    if ((i < 0) && !nodata) {
      gfx_drawline(g->framebuf, g->stride, x+g->inc, py, x+g->inc*2, cy, g->bgcol);
      if (!pp || !cc) {
        gfx_drawline(g->framebuf, g->stride, x+g->inc, g->h-1, x+g->inc*2, g->h-1, g->axcol);
      }
    }
    if (i > -g->ndp) {
      int y, j;
      
      if (!nodata) {
        gfx_drawline(g->framebuf, g->stride, x, py, x+g->inc, cy, g->datcol);
      }
      
      // Redraw configuration information.
      if (pc != cc) {
        int k = 255;
        y = 0;
        for (j = 0; j < 4; j++) {
          unsigned char pt, ct;
          pt = (unsigned char)pc;
          ct = (unsigned char)cc;
          pc >>= 8;
          cc >>= 8;
          
          if (k == ct) {
            
            // Previous lane group has the same task as this lane group.
            gfx_fillrect(g->framebuf, g->stride, x, y, x+g->inc, y+g->lgh, g->taskcol[ct]);
            
          } else {
            
            // Previous lane group has a different task. Accentuate with a
            // border.
            gfx_drawline(g->framebuf, g->stride, x, y, x+g->inc-1, y, g->tbcol);
            gfx_fillrect(g->framebuf, g->stride, x, y+1, x+g->inc, y+g->lgh, g->taskcol[ct]);
            
          }
          
          // Accentuate task switches with a border.
          if ((i > 1-g->ndp) && (pt != ct)) {
            gfx_drawline(g->framebuf, g->stride, x-1, y, x-1, y+g->lgh, g->tbcol);
          }
          
          k = ct;
          y += g->lgh;
          
          // Draw the bottom border.
          if (j == 3) {
            gfx_drawline(g->framebuf, g->stride, x, y, x+g->inc-1, y, (ct == 255) ? g->taskcol[255] : g->tbcol);
          }
            
        }
      }
    }
    
    x += g->inc;
    
    // Redraw grid.
    while (x > gx) {
      gfx_pixel_t *gptrx = g->framebuf + gx;
      int j;
      gx += g->ginc;
      for (j = 0; j < g->vtcount; j++) {
        gfx_pixel_t *gptr;
        int y = g->vty[j];
        if (y < g->h-1) {
          gptr = gptrx + y * g->stride;
          *gptr = g->grcol;
        }
      }
    }
    
  }
  
}

