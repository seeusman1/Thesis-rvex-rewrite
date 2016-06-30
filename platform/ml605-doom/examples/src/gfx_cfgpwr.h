#ifndef _GFX_CFGPWR_H_
#define _GFX_CFGPWR_H_

#include "gfx.h"

/**
 * Rolling X axis configuration + power graph for r-VEX demos.
 * 
 * Usage:
 *  - Create a graph_t structure somewhere to store the data needed to render
 *    the graph.
 *  - Initialize the structure using graph_init().
 *  - Optionally, add Y tickmarks using graph_addtick() and/or change parameters
 *    not part of the graph_init() function by modifying the graph_t structure
 *    directly.
 *  - Draw the static portions of the graph by calling graph_reset().
 *  - When new data is available, add it to and refresh the graph using
 *    graph_data().
 *  - graph_reset() can be used to clear the graph without needing to completely
 *    re-initialize.
 */

/**
 * Size of the data buffer of the graph. Must be a power of 2.
 */
#define GRAPH_DATA_BUF_SIZE 1024

/**
 * Size of the vertical tick buffer.
 */
#define GRAPH_VTICK_SIZE 16

/**
 * Graph data structure.
 */
typedef struct graph_t {
  
  // Power data. Note that a byte is more resolution than what can be put on the
  // screen, so it's plenty.
  unsigned char power[GRAPH_DATA_BUF_SIZE];
  
  // Configuration data. Each byte of the word represents a lane group, the byte
  // should map to the task ID or 255 for power-down.
  unsigned int config[GRAPH_DATA_BUF_SIZE];
  
  // Index into the buffer for the rightmost (newest) datapoint.
  int idx;
  
  // Should point to the top-left pixel of the graph.
  gfx_pixel_t *framebuf;
  
  // Framebuffer stride (horizontal screen width).
  int stride;
  
  // Graph size.
  int w;
  int h;
  
  // Amount of height allocated per lane group for configuration visualization.
  int lgh;
  
  // Amount of horizontal pixels per datapoint.
  int inc;
  
  // Amount of horizontal pixels per grid point.
  int ginc;
  
  // Number of data points that fit in the graph area.
  int ndp;
  
  // Amount of space reserved for vertical ticks.
  int tw;
  
  // Vertical tick information.
  int vtcount;
  int vty[GRAPH_VTICK_SIZE];
  const char *vtc[GRAPH_VTICK_SIZE];
  
  // Font to use for tick text.
  const font_t *f;
  
  // Colors to use.
  gfx_pixel_t bgcol;        // General background (clear color).
  gfx_pixel_t axcol;        // Axis color.
  gfx_pixel_t grcol;        // Grid color.
  gfx_pixel_t txtcol;       // Label color.
  gfx_pixel_t datcol;       // Power graph color.
  gfx_pixel_t taskcol[256]; // Task colors. Color 255 is used for no task/idle
                            // as well as the background color.
  gfx_pixel_t tbcol;        // Task border color, used to accentuate the
                            // different tasks/lane groups.
  
} graph_t;

/**
 * Initializes a graph:
 *  - g:        the graph context to initialize.
 *  - framebuf: pointer to the (16-bit per pixel) framebuffer.
 *  - stride:   width of the framebuffer in pixels.
 *  - x:        leftmost coordinate of the graph.
 *  - y:        topmost coordinate of the graph.
 *  - w:        width of the graph in pixels.
 *  - h:        height of the graph in pixels.
 *  - font:     font to use for the Y tick labels.
 * 
 * Notes:
 *  - By default, 20 pixels are reserved on the left for the tickmarks. This can
 *    be changed between _init and _reset by modifying g->tw.
 *  - By default, 25 pixels are reserved at the top for the configuration
 *    display. This can be changed between _init and _reset by modifying g->lgh,
 *    which specifies the number of pixels per lane group. The total height is
 *    g->lgh*4+1.
 *  - The maximum usable graph area is the height minus g->lgh*4+1, though you
 *    probably want some spacing there.
 *  - The default amount of horizontal pixels per datapoint is 5. This can be
 *    changed between _init and _reset by modifying g->inc.
 *  - Note that the maximum y value of the power graph is 255 because bytes are
 *    used for the data buffer.
 *  - The colors used by the graph are configurable between _init and _reset
 *    using the g->*col variables. Refer to the structure above for more info.
 *    By default, the first 16 colors for configuration information are
 *    populated, in addition to white for representing idle.
 *  - The Y tickmarks can be set up between _init and _reset using _addtick.
 */
void graph_init(
  graph_t *g,
  gfx_pixel_t *framebuf,
  int stride,
  int x, int y,
  int w, int h,
  const font_t *font
);

/**
 * Adds a Y tickmark to an initialized graph.
 *  - g:    the graph context to modify.
 *  - val:  the power value to add the tickmark for. The bottom of the graph is
 *          zero, and the units are pixels.
 *  - text: the tickmark label.
 */
void graph_addtick(
  graph_t *g,
  unsigned char val,
  const char *text
);

/**
 * Resets the graph data for the given graph and (re)renders it.
 *  - g: the graph context to reset and render.
 */
void graph_reset(
  graph_t *g
);

/**
 * Adds data to a graph and rerenders it.
 *  - g:     the graph context to update and refresh.
 *  - power: the power data point. The bottom of the graph is zero, and the
 *           units are pixels.
 *  - cfg:   representation of what each lane group is doing. -1 represents
 *           idle, 0-15 can (with the default colors) be used for task IDs,
 *           context IDs, etc.. More colors can be added if needed, to a maximum
 *           of 255 different colors/tasks.
 */
void graph_data(
  graph_t *g,
  int power,
  int *cfg
);

#endif
