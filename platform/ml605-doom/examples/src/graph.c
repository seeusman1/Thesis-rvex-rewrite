
#include "rvex.h"
#include "platform.h"
#include "gfx.h"
#include "gfx_cfgpwr.h"

extern const font_t sans12;
extern const font_t sans9;

gfx_pixel_t *framebuf = (unsigned short*)0x10000000;


int main(void) {
  graph_t g;
  int tasks[4] = {-1, -1, -1, -1};
  int random;
  
  CR_CRR = 0x8880;
  
  plat_init();
  plat_video_init(640, 480, 16, 1, framebuf);
  gfx_fillrect(framebuf, 640, 0, 0, 640, 480, gfx_rgb(255,255,255));
  gfx_drawtext(framebuf, 640, 50, 50, "Hello! I'm a text renderer.\nI can display information about the r-VEX!", gfx_rgb(0, 0, 0), &sans12);
  gfx_drawtext(framebuf, 640, 50, 100, "abcdefghijklmnopqrstuvwxyz\nABCDEFGHIJKLMNOPQRSTUVWXYZ\n0123456789\n`~!@#$%^&*()-_=+[]{}\\|;:'\",<.>/?", gfx_rgb(0, 0, 0), &sans12);
  gfx_drawtext(framebuf, 640, 50, 180, "Multiple fonts are supported, too.", gfx_rgb(0, 0, 0), &sans9);
  gfx_drawtext(framebuf, 640, 50, 200, "abcdefghijklmnopqrstuvwxyz\nABCDEFGHIJKLMNOPQRSTUVWXYZ\n0123456789\n`~!@#$%^&*()-_=+[]{}\\|;:'\",<.>/?", gfx_rgb(0, 0, 0), &sans9);
  
  graph_init(&g, framebuf, 640, 40, 310, 560, 130, &sans9);
  graph_addtick(&g, 0, "0W");
  graph_addtick(&g, 20, "1W");
  graph_addtick(&g, 40, "2W");
  graph_addtick(&g, 60, "3W");
  graph_addtick(&g, 80, "4W");
  graph_addtick(&g, 100, "5W");
  g.inc = 1;
  graph_reset(&g);
  
  while (1) {
    volatile int i;
    int cycles;
    
    // Generate random mockup data.
    int power = 18;
    random += CR_CNT;
    random *= 2654435761;
    if ((random & 0xFF) < 100) { // Random chance.
      int t = (random >> 8) & 0x3; // Change a random task.
      switch ((random >> 10) & 0x3) {
        case 0:
          if (t != 0) {
            // Copy from above.
            tasks[t] = tasks[t-1];
            break;
          }
        case 1:
          if (t != 3) {
            // Copy from below.
            tasks[t] = tasks[t+1];
            break;
          }
        case 2:
          // Disable.
          tasks[t] = -1;
          break;
        case 3:
          // Assign a random task.
          tasks[t] = (random >> 16) & 0xF;
          break;
      }
    }
    for (i = 0; i < 4; i++) {
      if (tasks[i] != -1) {
        power += 20 + tasks[i] >> 1;
      }
    }
    power += random & 0x3;
    
    // Time the update.
    cycles = CR_CNT;
    
    // Update the graph.
    graph_data(&g, power, tasks[0], tasks[1], tasks[2], tasks[3]);
    
    // Time the update.
    cycles = CR_CNT - cycles;
    plat_serial_puts(0, "Update took ");
    plat_serial_putd(0, cycles);
    plat_serial_puts(0, " cycles = ");
    plat_serial_putd(0, (cycles * 1000) / plat_frequency());
    plat_serial_puts(0, " microseconds on 2-way...\n");
    
    // Delay for some time.
    for (i = 0; i < 200000; i++);
    
  }
  
}


