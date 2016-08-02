
#include "gfx.h"
#include "gfx_cfgpwr.h"
#include "rvex.h"
#include "platform.h"

#include "logo.inc"

extern const font_t sans12;
extern const font_t sans9;

void putx(unsigned int i) {
  int j;
  putchar('0');
  putchar('x');
  for (j = 28; j >= 0; j -= 4) {
    unsigned int k = (i >> j) & 0xF;
    putchar((k < 10) ? ('0' + k) : ('A' + k - 10));
  }
}

void int2str(int value, char *s) {
  unsigned int val;
  int i;
  char c;
  static const int decades[10] = {
    1000000000,
    100000000,
    10000000,
    1000000,
    100000,
    10000,
    1000,
    100,
    10,
    1
  };
  
  // Handle negative numbers.
  if (value < 0) {
    *s++ = '-';
    value = -value;
  }
  val = (unsigned int)value;
  
  // Divisions are really slow, so let's do without.
  c = '0';
  for (i = 0; i < 10; i++) {
    int dec = decades[i];
    if (val >= dec) {
      break;
    }
  }
  if (i == 10) {
    *s++ = '0';
  } else {
    for (; i < 10; i++) {
      int dec = decades[i];
      c = '0';
      if (val >= (dec<<3)) { val -= (dec<<3); c += 8; }
      if (val >= (dec<<2)) { val -= (dec<<2); c += 4; }
      if (val >= (dec<<1)) { val -= (dec<<1); c += 2; }
      if (val >= (dec<<0)) { val -= (dec<<0); c += 1; }
      *s++ = c;
    }
  }
  
  *s = 0;
}

void draw_logo(gfx_pixel_t *framebuf, int stride, int x, int y) {
  gfx_pixel_t *img = (gfx_pixel_t*)rvex_logo.pixel_data;
  framebuf += x + stride * y;
  stride -= rvex_logo.width;
  for (y = 0; y < rvex_logo.height; y++) {
    for (x = 0; x < rvex_logo.width; x++) {
      gfx_pixel_t p = *img++;
      p = (p << 8) | (p >> 8);
      *framebuf++ = p;
    }
    framebuf += stride;
  }
}

int get_power(void) {
  unsigned char data[2];
  short linear;
  int value;
  
  // Read the power data for the VCCINT rail.
  if (plat_i2c_read(PLAT_I2C_PMBUS, 0x34, 0x96, (char*)data, 2)) return -1;
  
  linear = (data[1] << 8) | data[0];
  if (linear == 0x0000) return -1;
  if (linear == 0xFFFF) return -1;
  
  // Convert the linear format (pretty much a float) to fixed 16.16 in W.
  value = linear;
  value <<= 32-11; // Shift the sign bit all the way to the left.
  value >>= 5;     // Shift right to get whole integers in 16.16.
  linear >>= 11;   // Extract the exponent.
  if (linear > 0) {
    value <<= linear;
  } else {
    value >>= -linear;
  }
  
  return value;
  
}

void delay(void) {
  static int init = 0;
  static int prev;
  int cur;
  
  if (!init) {
    prev = CR_CNT;
    init = 1;
  }
  
  while (1) {
    cur = CR_CNT;
    if (cur - prev > (25 * 1000) * 20 /*ms*/) {
      prev = cur;
      return;
    }
  }
}

static gfx_pixel_t *framebuf;
static graph_t g;

#define CURCFG_X 168
#define CURCFG_Y 270
#define CUR_CFG_LW 20
#define CUR_CFG_H 25

#define CURPWR_X 363
#define CURPWR_Y 270

#define CURTICK_X 490
#define CURTICK_Y 270

void update_current_cfg(int *lane) {
  static unsigned prev_lane[8] = {255, 255, 255, 255, 255, 255, 255, 255};
  int i;
  
  for (i = 0; i < 8; i++) {
    unsigned char t = lane[i];
    unsigned char pt = prev_lane[i];
    if (t != pt) {
      gfx_fillrect(framebuf, 640,
          CURCFG_X+CUR_CFG_LW*(i+0)+1, CURCFG_Y+1,
          CURCFG_X+CUR_CFG_LW*(i+1), CURCFG_Y+CUR_CFG_H,
          g.taskcol[t]);
    }
    if (i < 7) {
      unsigned char tp1 = lane[i+1];
      unsigned char ptp1 = prev_lane[i+1];
      if ((t != pt) || (tp1 != ptp1)) {
        gfx_fillrect(framebuf, 640,
            CURCFG_X+CUR_CFG_LW*(i+1),   CURCFG_Y+4,
            CURCFG_X+CUR_CFG_LW*(i+1)+1, CURCFG_Y+CUR_CFG_H-3,
            ((t == tp1) && (t != 255)) ? g.taskcol[t] : 0
        );
      }
    }
    prev_lane[i] = lane[i];
  }
}

void update_current_power(int power) {
  static char buf[32] = {0};
  
  // Erase the previous value.
  gfx_drawtext(framebuf, 640, CURPWR_X, CURPWR_Y, buf, gfx_rgb(255, 255, 255), &sans12);
  
  // Decode the current value.
  if (power == -1) {
    buf[0] = 'P';
    buf[1] = 'M';
    buf[2] = 'b';
    buf[3] = 'u';
    buf[4] = 's';
    buf[5] = ' ';
    buf[6] = 'e';
    buf[7] = 'r';
    buf[8] = 'r';
    buf[9] = 'o';
    buf[10] = 'r';
    buf[11] = 0;
  } else {
    int i;
    unsigned int p = power;
    for (i = 0; i < 5; i++) {
      unsigned int c = p >> 16;
      p = (p & 0xFFFF) * 10;
      if (c < 10) {
        buf[i] = '0' + c;
      } else {
        buf[i] = '?';
      }
      if (i == 0) {
        i++;
        buf[1] = '.';
      }
    }
    buf[5] = 'W';
    buf[6] = 0;
  }
  
  // Draw the new value.
  gfx_drawtext(framebuf, 640, CURPWR_X, CURPWR_Y, buf, gfx_rgb(0, 0, 0), &sans12);
  
}

void update_current_tick() {
  static int prev_heartbeat = 0;
  static int tick = 0;
  static char buf[32] = {0};
  static int col = 0;
  
  gfx_pixel_t heartbeat = framebuf[(CURTICK_X+110) + (CURTICK_Y+5) * 640];
  
  if (heartbeat != prev_heartbeat) {
    prev_heartbeat = heartbeat;
    tick++;
    
    // Erase the previous value.
    gfx_drawtext(framebuf, 640, CURTICK_X, CURTICK_Y, buf, gfx_rgb(255, 255, 255), &sans12);
    
    // Decode the current value.
    int2str(tick, buf);
    
    // Draw the new value.
    gfx_drawtext(framebuf, 640, CURTICK_X, CURTICK_Y, buf, gfx_rgb(0, 0, 0), &sans12);
    
  }
}

unsigned int *MAIN_CFG = (unsigned int*)0xD0000008;

int main(void) {
  int i;
  
  // SVGA initialization. If it is already initialized, don't do anything.
  i = 0;
  if (!(PLAT_SVGA->status & 1)) {
    PLAT_SVGA->status   = 2;
    PLAT_SVGA->vidlen   = (480-1 << 16) + 640-1;
    PLAT_SVGA->fplen    = (10 << 16) + 16;
    PLAT_SVGA->synclen  = (2 << 16) + 96;
    PLAT_SVGA->linelen  = ((45+480) << 16) + (160+640);
    PLAT_SVGA->framebuf = (void*)0x01000000;
    PLAT_SVGA->status   = 1 | (0 << 6) | (2 << 4);
    i = 1;
  }
  
  // Initialize the Chrontel DAC.
  plat_video_chrontel();
  
  // Get the framebuffer pointer from the peripheral.
  framebuf = (gfx_pixel_t*)PLAT_SVGA->framebuf;
  
  // Clear the screen.
  if (i) {
    gfx_fillrect(framebuf, 640, 0, 0, 640, 240, gfx_rgb(64, 64, 64));
  }
  gfx_fillrect(framebuf, 640, 0, 240, 640, 241, gfx_rgb(0, 0, 0));
  gfx_fillrect(framebuf, 640, 0, 241, 640, 480, gfx_rgb(255, 255, 255));
  
  // Draw the logo.
  draw_logo(framebuf, 640, 15, 250);
  
  // Initialize the graph.
  graph_init(&g, framebuf, 640, 20, 320, 600, 135, &sans9);
  /* // >>10
  graph_addtick(&g, 0,  "2.5W");
  graph_addtick(&g, 19, "2.8W");
  graph_addtick(&g, 38, "3.1W");
  graph_addtick(&g, 58, "3.4W");
  graph_addtick(&g, 77, "3.7W");
  graph_addtick(&g, 96, "4.0W");
  //*/
  /* // >>9
  graph_addtick(&g, 0,  "2.5W");
  graph_addtick(&g, 25, "2.7W");
  graph_addtick(&g, 51, "2.9W");
  graph_addtick(&g, 76, "3.1W");
  graph_addtick(&g, 102, "3.3W");
  //*/
  // *3 >>10
  graph_addtick(&g, 0,  "2.3W");
  graph_addtick(&g, 19, "2.4W");
  graph_addtick(&g, 38, "2.5W");
  graph_addtick(&g, 58, "2.6W");
  graph_addtick(&g, 77, "2.7W");
  graph_addtick(&g, 96, "2.8W");
  //*/
  /* // >>9
  graph_addtick(&g, 0,  "2.7W");
  graph_addtick(&g, 25, "2.9W");
  graph_addtick(&g, 51, "3.1W");
  graph_addtick(&g, 76, "3.3W");
  graph_addtick(&g, 102, "3.5W");
  //*/
  /* // >>9   Voltvreter...
  graph_addtick(&g, 0,  "4.4W");
  graph_addtick(&g, 25, "4.6W");
  graph_addtick(&g, 51, "4.8W");
  graph_addtick(&g, 76, "5.0W");
  graph_addtick(&g, 102, "5.2W");
  //*/
  
  g.inc = 1;
  graph_reset(&g);
  
  //putx(g.taskcol[0]); puts("\n");
  //putx(g.taskcol[1]); puts("\n");
  //putx(g.taskcol[2]); puts("\n");
  //putx(g.taskcol[3]); puts("\n");
  
  // Initialize the current config. display.
  gfx_drawtext(framebuf, 640, CURCFG_X, CURCFG_Y-20, "Current lane mapping:", gfx_rgb(0, 0, 0), &sans12);
  gfx_drawline(framebuf, 640, CURCFG_X, CURCFG_Y, CURCFG_X+CUR_CFG_LW*8, CURCFG_Y, 0);
  gfx_drawline(framebuf, 640, CURCFG_X, CURCFG_Y+CUR_CFG_H, CURCFG_X+CUR_CFG_LW*8, CURCFG_Y+CUR_CFG_H, 0);
  for (i = 0; i < 9; i++) {
    gfx_drawline(framebuf, 640, CURCFG_X+CUR_CFG_LW*i, CURCFG_Y, CURCFG_X+CUR_CFG_LW*i, CURCFG_Y+CUR_CFG_H, 0);
  }
  
  // Initialize the current power display.
  gfx_drawtext(framebuf, 640, CURPWR_X, CURPWR_Y-20, "Current power:", gfx_rgb(0, 0, 0), &sans12);
  gfx_drawtext(framebuf, 640, CURPWR_X, CURPWR_Y+18, "(2.2W typ. unconfigured)", gfx_rgb(128, 128, 128), &sans9);
  
  // Initialize the current tick.
  gfx_drawtext(framebuf, 640, CURTICK_X, CURTICK_Y-20, "Current FreeRTOS tick:", gfx_rgb(0, 0, 0), &sans12);
  gfx_drawrect(framebuf, 640, CURTICK_X+90, CURTICK_Y, CURTICK_X+131, CURTICK_Y+25, gfx_rgb(0, 0, 0));
  
  gfx_fillrect(framebuf, 640, 581, 271, 620, 294, gfx_rgb(255, 0, 255));
  
  while (1) {
    int accum, error, power, cfg;
    int graph_cfg[4];
    int lane_cfg[8];
    
    accum = 0;
    error = 0;
    for (i = 0; i < 8; i++) {
      int j;
      
      // Synchronize with the cycle counter.
      delay();
      
      // Do a power sample.
      power = get_power();
      if (power < 0) {
        error = 1;
      } else {
        accum += power;
      }
      
      // Decode the configuration.
      cfg = *MAIN_CFG;
      for (j = 0; j < 4; j++) {
        int x = ((cfg >> (j*4)) & 0xF);
        if (x & 0x8) {
          x = 255;
        }
        if (i == 4) {
          graph_cfg[j] = x;
        }
        lane_cfg[(j<<1)+0] = x;
        lane_cfg[(j<<1)+1] = x;
      }
      
      // Update the configuration display.
      update_current_cfg(lane_cfg);
      
      // Synchronize with the cycle counter.
      delay();
      
      // Do a power sample.
      power = get_power();
      if (power < 0) {
        error = 1;
      } else {
        accum += power;
      }
      
      // Update the current tick display.
      update_current_tick();
      
    }
    
    // Get the average power of the past n samples.
    if (error) {
      power = -1;
    } else {
      power = accum >> 4;
    }
    
    // Update the power display.
    update_current_power(power);
    
    // Update the graph.
    if (power == -1) {
      power = 255;
    } else {
      power -= 0x24CCC;
      power *= 3;
      power >>= 10;
      //power -= 0x46666; // Voltvreter
      //power *= 3;
      //power >>= 10;
      if (power < 0) {
        power = 0;
      } else if (power > 107) {
        power = 107;
      }
    }
    graph_data(&g, power, graph_cfg);
    
  }
  
}


