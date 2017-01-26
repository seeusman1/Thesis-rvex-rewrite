
#include "platform.h"
#include "rvex.h"

static void plat_time_init(void);

/******************************************************************************/
/* COMMON                                                                     */
/******************************************************************************/

void plat_init(void) {
  plat_time_init();
  
  // Enable interrupts.
  PLAT_IRQMP->mask[CR_CID] = 0;
  CR_CCR = CR_CCR_IEN | CR_CCR_RFT;
  
}


void _stop(void);
int putchar(int character)        { plat_serial_putc(0, character); return 0; }
int puts(const char *str)         { plat_serial_puts(0, str);       return 0; }
int rvex_succeed(const char *str) { plat_serial_puts(0, str);       return 0; }
int rvex_fail(const char *str)    { plat_serial_puts(0, str);       return 0; }


/******************************************************************************/
/* INTERRUPTS                                                                 */
/******************************************************************************/

#define IRQ_COUNT 16
#define CTXT_COUNT 4

static void (*volatile irq_handlers[CTXT_COUNT * IRQ_COUNT])(unsigned long data);
static unsigned long irq_handlers_data[CTXT_COUNT * IRQ_COUNT];

/**
 * Interrupt callback from startup.
 */
void interrupt(int irq) {
  int h = CR_CID * IRQ_COUNT + irq;
  void (*handler)(unsigned long data) = irq_handlers[h];
  
  if (handler) {
    handler(irq_handlers_data[h]);
  }
}

/**
 * Registers the specified interrupt handler function for the specified IRQ.
 * Only one handler can be registered at a time.
 */
void plat_irq_register(
  int irq,
  void (*handler)(unsigned long data),
  unsigned long data
) {
  int h = CR_CID * IRQ_COUNT + irq;
  irq_handlers[h] = handler;
  irq_handlers_data[h] = data;
}

/**
 * Enables or masks an interrupt.
 */
void plat_irq_enable(int irq, int enable) {
  if (enable) {
    CR_CCR = CR_CCR_IEN_C;
    PLAT_IRQMP->mask[CR_CID] |= 1 << irq;
    CR_CCR = CR_CCR_IEN;
  } else {
    CR_CCR = CR_CCR_IEN_C;
    PLAT_IRQMP->mask[CR_CID] &= ~(1 << irq);
    CR_CCR = CR_CCR_IEN;
  }
}

/**
 * Returns whether the specified interrupt is pending.
 */
int plat_irq_ispending(int irq) {
  return (PLAT_IRQMP->pending & (1 << irq)) ? 1 : 0;
}

/**
 * Clears a pending interrupt.
 */
void plat_irq_clear(int irq) {
  PLAT_IRQMP->clear = 1 << irq;
}

/**
 * Forces the specified interrupt on the specified context.
 */
void plat_irq_force(int irq, int context) {
  PLAT_IRQMP->force[context] = 1 << irq;
}


/******************************************************************************/
/* SERIAL PORTS                                                               */
/******************************************************************************/

/**
 * Writes a character to the specified serial port. Blocking.
 */
void plat_serial_putc(int iface, char c) {
  
  if (iface == 0) {
    
#ifndef SIM
    // Wait for the TX data FIFO ready flag.
    while (!(PLAT_DEBUGUART_STAT & (1 << 1)));
#endif
    
    // Write to the UART.
    PLAT_DEBUGUART_DATA = c;
    
  }
}

/**
 * Writes a null-terminated string to the specified serial port. Blocking.
 */
void plat_serial_puts(int iface, const char *s) {
  while (*s) {
    plat_serial_putc(iface, (int)(*s++));
  }
}

/**
 * Writes a 32-bit hexadecimal value to the specified serial port. Blocking.
 */
void plat_serial_putx(int iface, int value) {
  unsigned int val = (unsigned int)value;
  int i;
  char c;
  
  plat_serial_putc(iface, '0');
  plat_serial_putc(iface, 'x');
  for (i = 0; i < 8; i++) {
    c = (char)(val >> 28);
    c = (c < 10) ? ('0' + c) : ('A' + c - 10);
    plat_serial_putc(iface, c);
    val <<= 4;
  }
  
}

/**
 * Writes a 32-bit signed decimal value to the specified serial port. Blocking.
 */
void plat_serial_putd(int iface, int value) {
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
    plat_serial_putc(iface, '-');
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
    plat_serial_putc(iface, '0');
  } else {
    for (; i < 10; i++) {
      int dec = decades[i];
      c = '0';
      if (val >= (dec<<3)) { val -= (dec<<3); c += 8; }
      if (val >= (dec<<2)) { val -= (dec<<2); c += 4; }
      if (val >= (dec<<1)) { val -= (dec<<1); c += 2; }
      if (val >= (dec<<0)) { val -= (dec<<0); c += 1; }
      plat_serial_putc(iface, c);
    }
  }
  
}

/**
 * Writes a data buffer to the specified serial port. Non-blocking, same
 * interface as POSIX write.
 */
int plat_serial_write(int iface, const void *buf, int count) {
  const char *cbuf = (const char*)buf;
  int res = 0;
  if (iface == 0) {
    while (count) {
      
      // Stop if the TX data FIFO ready flag is not set.
      if (!(PLAT_DEBUGUART_STAT & (1 << 1))) {
        break;
      }
      
      // Write the next character.
      PLAT_DEBUGUART_DATA = *cbuf++;
      count -= 1;
      res += 1;
      
    }
  } else {
    res = -1;
  }
  return res;
}

/**
 * Reads from the specified serial port into the data buffer. Non-blocking, same
 * interface as POSIX read.
 */
int plat_serial_read(int iface, void *buf, int count) {
  char *cbuf = (char*)buf;
  int res = 0;
  if (iface == 0) {
    while (count) {
      
      // Stop if the RX data FIFO ready flag is not set.
      if (!(PLAT_DEBUGUART_STAT & (1 << 3))) {
        break;
      }
      
      // Read the next character.
      *cbuf++ = PLAT_DEBUGUART_DATA;
      count -= 1;
      res += 1;
      
    }
  } else {
    res = -1;
  }
  return res;
}


/******************************************************************************/
/* TIMING                                                                     */
/******************************************************************************/

static int frequency_khz;

/**
 * Initializes the timer.
 */
static void plat_time_init(void) {
  
  // Determine the frequency using the PS/2 clock prescaler register, which is
  // set such that the PS/2 clock is 10 kHz.
  frequency_khz = PLAT_PS2(0)->timer * 10;
  
  // Set the timer1 prescaler such that it rolls over approximately every
  // microsecond.
  PLAT_GPTIMER1->scaler_reload = (frequency_khz - 500) / 1000;
  PLAT_GPTIMER1->scaler_val = 0;
  
  // Configure the second counter.
  PLAT_GPTIMER1->tim2_val    = 0xFFFFFFFF;
  PLAT_GPTIMER1->tim2_reload = 0xFFFFFFFF;
  PLAT_GPTIMER1->tim2_config = 0x23;
  
  // Configure the microsecond counter.
  PLAT_GPTIMER1->tim1_val    = 999999;
  PLAT_GPTIMER1->tim1_reload = 999999;
  PLAT_GPTIMER1->tim1_config = 0x03;
  
  // Have timer2 divide by 2, which is the minimum because there are two timers
  // in the peripheral (this is a thing apparently).
  PLAT_GPTIMER2->scaler_reload = 1;
  PLAT_GPTIMER2->scaler_val = 0;
  
  // Configure the audio samplerate timer to approximately 44.1 kHz.
  plat_audio_setsamplerate(44100);
  
}

/**
 * Like CSL gettimeofday(). Starts at 0, guaranteed monotone between calls to
 * plat_settimeofday. THIS IS MERELY APPROXIMATE if the platform clock frequency
 * in MHz is not an integer.
 */
void plat_gettimeofday(int *sec, int *usec) {
  int s1, s2, us;
  
  // Query the timer. The seconds are queried twice to check for microsecond
  // overflow.
  s1 = PLAT_GPTIMER1->tim2_val;
  us = PLAT_GPTIMER1->tim1_val;
  s2 = PLAT_GPTIMER1->tim2_val;
  
  // If the microsecond timer overflowed while checking, assume 0 and use the
  // second query of the seconds. This will necessarily represent a time between
  // the two seconds queries.
  if (s1 != s2) {
    *usec = 0;
  } else {
    *usec = 999999 - us;
  }
  *sec = ~s2;
  
}

/**
 * Sets the current time.
 */
void plat_settimeofday(int sec, int usec) {
  
  // Stop the timers while we do this.
  PLAT_GPTIMER1->tim1_config = 0x02;
  PLAT_GPTIMER1->tim2_config = 0x22;
  
  // Set the timer values.
  PLAT_GPTIMER1->tim1_val = 999999 - usec;
  PLAT_GPTIMER1->tim2_val = ~sec;
  
  // Restart the timers.
  PLAT_GPTIMER1->tim2_config = 0x23;
  PLAT_GPTIMER1->tim1_config = 0x03;
  
}

/**
 * Returns the frequency at which the platform is running in kHz.
 */
int plat_frequency(void) {
  return frequency_khz;
}

/**
 * Registers an (OS) tick handler. interval is specified in microseconds. This
 * is only APPROXIMATE when the clock frequency in MHz is not an integer.
 */
int plat_tick(
  int interval,
  void (*handler)(unsigned long data),
  unsigned long data
) {
  
  interval *= (plat_frequency() + 500) / 1000;
  
  if (handler) {
    
    // Register the interrupt,
    plat_irq_register(IRQ_TICK, handler, data);
    plat_irq_clear(IRQ_TICK);
    plat_irq_enable(IRQ_TICK, 1);
    
    // Configure the timer.
    PLAT_GPTIMER2->tim2_val    = interval - 1;
    PLAT_GPTIMER2->tim2_reload = interval - 1;
    PLAT_GPTIMER2->tim2_config = 0x0B;
    
  } else {
    
    // Disable the timer.
    PLAT_GPTIMER2->tim2_config = 0x00;
    
    // Unregister the interrupt.
    plat_irq_enable(IRQ_TICK, 0);
    plat_irq_register(IRQ_TICK, 0, 0);
    
  }
  
}


/******************************************************************************/
/* AUDIO                                                                      */
/******************************************************************************/

/**
 * Sets the audio samplerate. rate must be specified in Hz. The actual
 * samplerate will approximate the requested rate.
 */
int plat_audio_setsamplerate(int rate) {
  
  // (platform frequency / 2) / rate -> reload + 1
  int reload = (plat_frequency() * 500 + (rate >> 1)) / rate - 1;
  
  // Configure the audio samplerate timer.
  PLAT_GPTIMER2->tim1_reload = reload;
  PLAT_GPTIMER2->tim1_val = reload;
  
}

/**
 * Writes to the audio buffer. Same interface as POSIX write. Fills the buffer
 * up as far as possible given the input, doesn't block. Unsigned 8-bit mono
 * samples are expected.
 */
int plat_audio_write(const void *buf, int count) {
  const unsigned char *cbuf = (const unsigned char*)buf;
  int remain;
  count = min(count, plat_audio_avail());
  remain = count;
  while (remain--) {
    PLAT_AUDIO_DATA = *cbuf++;
  }
  return count;
}

/**
 * Returns the number of samples that can currently be written to the buffer.
 */
int plat_audio_avail(void) {
  return PLAT_AUDIO_FIFOLEN - PLAT_AUDIO_REMAIN;
}

/**
 * Returns the number of samples currently in the buffer.
 */
int plat_audio_remain(void) {
  return PLAT_AUDIO_REMAIN;
}


/******************************************************************************/
/* VIDEO                                                                      */
/******************************************************************************/

static const unsigned char plat_video_chrontel_init[] = {
  0x1c,  0x04,
  0x1d,  0x45,
  0x1e,  0xf0,
  0x1f,  0x88,
  0x20,  0x22,
  0x21,  0x09,
  0x23,  0x00,
  0x31,  0x80,
  0x33,  0x08,
  0x34,  0x16,
  0x35,  0x30,
  0x36,  0x60,
  0x37,  0x00,
  0x48,  0x18,
  0x49,  0xc0,
  0x4a,  0x95,
  0x4b,  0x17,
  0x56,  0x00,
  0
};

/**
 * Initializes the Chrontel DAC for VGA or DVI output (both work).
 */
void plat_video_chrontel(void) {
  const unsigned char *ptr = plat_video_chrontel_init;
  while (*ptr) {
    plat_i2c_write(PLAT_I2C_DVI, 0x76, *ptr, (const char*)(ptr+1), 1);
    ptr += 2;
  }
}

static resinfo_t m640x480 = {
  /*.clksel =          */0, /* pixclock = 40000 */
  /*.left_margin =    */48,
  /*.right_margin =   */16,
  /*.upper_margin =   */31,
  /*.lower_margin =   */11,
  /*.hsync_len =      */96,
  /*.vsync_len =       */2
};  

static resinfo_t m800x600 = {
  /*.clksel =          */3, /* pixclock = 25000 */
  /*.left_margin =    */88,
  /*.right_margin =   */40,
  /*.upper_margin =   */23,
  /*.lower_margin =    */1,
  /*.hsync_len =     */128,
  /*.vsync_len =       */4
};

/*
 * This platform does not support 1024x768, it needs a faster pixelclock.
 */

/**
 * Disable video output
 */
void plat_video_disable(void){
  PLAT_SVGA->status = 2;
}

/**
 * Initializes the VGA/DVI output.
 *  - w specifies the width in pixels.
 *  - h specifies the height in pixels.
 *  - bpp specifies the bits per pixel and must be 8, 16 or 32.
 *  - dvi should be nonzero to output a DVI signal or zero to output a VGA
 *    signal.
 *  - frame should point to the framebuffer, which must be w*h*bpp/8 + 1024 bytes in
 *    size. It will be aligned if necessary. The function can override the location
 * as some platforms have a specific memory regions instead of reading from main 
 * memory. The new framebuffer location will be passed using the return value.
 * 640x480 uses standard timing. Anything else results in non-standard
 * sync/porch timing and may or may not work. Returns a pointer to the 
 * framebuffer.
 */
void* plat_video_init(int w, int h, int bpp, int dvi, const void *frame) {
  
  resinfo_t *resinfo;
  int bdsel;
  
  // Align frambuffer
  void *aligned_framebuffer = (void*)(((unsigned int)frame + FB_ALIGN-1) & ~(FB_ALIGN-1));
  
  // Select bit depth
  if (bpp == 8)
    bdsel = 1;
  else if (bpp == 16)
    bdsel = 2;
  else
    bdsel = 3;
  
  // Select resolution
  if (w == 800 && h == 600)
    resinfo = &m800x600;
  else
    resinfo = &m640x480;
  
  // Reset the SVGA controller.
  PLAT_SVGA->status = 2;
  
  // Configure the Chrontel DAC
  plat_video_chrontel();
  
  // Configure the SVGA controller.
  PLAT_SVGA->vidlen  = ((h-1) << 16) + (w-1);
  PLAT_SVGA->fplen   = (resinfo->low_margin << 16) + resinfo->right_margin;
  PLAT_SVGA->synclen = (resinfo->vsync_len << 16) + resinfo->hsync_len;
  PLAT_SVGA->linelen = ((h + resinfo->low_margin + resinfo->upper_margin + resinfo->vsync_len -1) <<16) +
                 (w + resinfo->right_margin + resinfo->left_margin + resinfo->hsync_len -1);
  
  // Set the framebuffer pointer.
  PLAT_SVGA->framebuf = aligned_framebuffer;
  
  // Start the SVGA controller.
  PLAT_SVGA->status = 1 | (resinfo->clksel << 6) | (bdsel << 4);
  return aligned_framebuffer;
}

/**
 * Returns nonzero during vsyncs.
 */
int plat_video_isvsyncing(void) {
  return (PLAT_SVGA->status & 8) ? 1 : 0;
}

/**
 * Reassigns the framebuffer pointer.
 */
void plat_video_swap(const void *frame) {
  PLAT_SVGA->framebuf = frame;
}

/**
 * Assigns the given RGB value to the given palette index. All values must be
 * in the 0-255 range.
 */
void plat_video_palette(int index, int r, int g, int b) {
  PLAT_SVGA->clut = (index << 24) | (r << 16) | (g << 8) | b;
}


/******************************************************************************/
/* PS/2                                                                       */
/******************************************************************************/

// Scan code to Windows virtual key code lookup table.
static const unsigned char scan2key[] = {
  0,      0x78,   0,      0x74,   0x72,   0x70,   0x71,   0x7B,
  0,      0x79,   0x77,   0x75,   0x73,   0x09,   0xC0,   0,
  0,      0xA4,   0xA0,   0,      0xA2,   'Q',    '1',    0,
  0,      0,      'Z',    'S',    'A',    'W',    '2',    0,
  0,      'C',    'X',    'D',    'E',    '4',    '3',    0,
  0,      0x20,   'V',    'F',    'T',    'R',    '5',    0,
  0,      'N',    'B',    'H',    'G',    'Y',    '6',    0,
  0,      0,      'M',    'J',    'U',    '7',    '8',    0,
  0,      0xBC,   'K',    'I',    'O',    '0',    '9',    0,
  0,      0xBE,   0xBF,   'L',    0xBA,   'P',    0xBD,   0,
  0,      0,      0xDE,   0,      0xDB,   0xBB,   0,      0,
  0x14,   0xA1,   0x0D,   0xDD,   0,      0xDC,   0,      0,
  0,      0,      0,      0,      0,      0,      0x08,   0,
  0,      0x61,   0,      0x64,   0x67,   0,      0,      0,
  0x60,   0x6E,   0x62,   0x65,   0x66,   0x68,   0x1B,   0x90,
  0x7A,   0x6B,   0x63,   0x6D,   0x6A,   0x69,   0x91,   0,
  0,      0,      0,      0x76,   0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,

  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0xA5,   0,      0,      0xA3,   0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0x5B,
  0,      0,      0,      0,      0,      0,      0,      0x5C,
  0,      0,      0,      0,      0,      0,      0,      0x5D,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0x6F,   0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0x5E,   0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0x23,   0,      0x25,   0x24,   0,      0,      0,
  0x2D,   0x2E,   0x28,   0,      0x27,   0x26,   0,      0,
  0,      0,      0x22,   0,      0,      0x21,   0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
  0,      0,      0,      0,      0,      0,      0,      0,
};

// Interrupt handler for keyboards.
static void ps2_kb_handler(unsigned long data) {
  ps2kbdstate_t *state = (ps2kbdstate_t*)data;
  volatile apbps2_t *ps2 = state->ps2;
  
  while (ps2->status & 1) {
    int frame = ps2->data;
    int key, event;
    unsigned char k;
    int i;
    
    // Handle break and extended flags.
    if (frame == 0xE0) {
      state->ext = 1;
      continue;
    } else if (frame == 0xF0) {
      state->up = 1;
      continue;
    }
    
    // Decode the scan code and ignore unknown keys.
    key = scan2key[((int)state->ext) << 8 | frame];
    if (!key) {
      state->ext = 0;
      state->up = 0;
      continue;
    }
    
    // Update the key state table.
    k = state->events[key >> 3];
    if (state->up) {
      k &= ~(1 << (key & 7));
      event = key;
    } else {
      k |= 1 << (key & 7);
      event = key | 0x100;
    }
    state->events[key >> 3] = k;
    
    // Add the event to the FIFO if there's room.
    i = state->count;
    if (i < KBD_EVENT_BUFFER_DEPTH) {
      state->count = i + 1;
      i = state->widx;
      state->events[i] = event;
      state->widx = (i + 1) & (KBD_EVENT_BUFFER_DEPTH - 1);
    }
    
    // Reset the state for the next scan code sequence.
    state->ext = 0;
    state->up = 0;
    
  }
  
}

/**
 * Initializes PS/2 interface iface in keyboard mode. state must point to a
 * caller-allocated keyboard state record.
 */
void plat_ps2_kb_init(ps2kbdstate_t *state, int iface) {
  
  // Clear the state.
  memset(state, 0, sizeof(ps2kbdstate_t));
  
  // Get the IRQ number and peripheral address for this interface.
  state->ps2 = PLAT_PS2(iface);
  if (iface == 0) {
    state->irq = IRQ_PS20;
  } else {
    state->irq = IRQ_PS21;
  }
  
  // Empty the hardware receive buffer, just in case.
  while (state->ps2->status & 1) {
    volatile int dummy = state->ps2->data;
  }
  
  // Enable and set up the interrupt.
  plat_irq_register(state->irq, ps2_kb_handler, (unsigned long)state);
  plat_irq_clear(state->irq);
  plat_irq_enable(state->irq, 1);
  
  // Enable the peripheral.
  state->ps2->control = 7;
  
}

/**
 * Returns whether a given key (KEY_*, input-event-codes.h) is currently down.
 * This is multi-context safe as it does not write to the state record.
 */
int plat_ps2_kb_getkey(const ps2kbdstate_t *state, unsigned char key) {
  unsigned char k = state->events[key >> 3];
  return (k >> (key & 7)) & 1;
}

/**
 * Gets the next keyboard event from the event buffer. Returns -1 if the buffer
 * is empty. Otherwise, bit 7..0 contain the Linux key code. Bit 8 is set if the
 * key was pressed (or typematic'd by the keyboard) and is cleared when it is
 * released. This is not multi-context safe.
 */
int plat_ps2_kb_pop(ps2kbdstate_t *state) {
  int count, ridx, event;
  
  // Disable interrupts while we access the FIFO.
  CR_CCR = CR_CCR_IEN_C;
  count = state->count;
  if (count) {
    ridx = state->ridx;
    state->count = count - 1;
    state->ridx = (ridx + 1) & (KBD_EVENT_BUFFER_DEPTH-1);
    event = state->events[ridx];
  } else {
    event = -1;
  }
  CR_CCR = CR_CCR_IEN;
  
  return event;
}

// Key to name data.
static const char *key2namestr = "?\0A\0B\0C\0D\0E\0F\0G\0H\0I\0J\0K\0L\0M\0N\0"
"O\0P\0Q\0R\0S\0T\0U\0V\0W\0X\0Y\0Z\0000\0001\0002\0003\0004\0005\0006\0007\08"
"\09\0BACKQUOTE\0DASH\0EQUALS\0BACKSLASH\0BACK\0SPACE\0TAB\0CAPITAL\0LSHIFT\0LC"
"ONTROL\0LWIN\0LMENU\0RSHIFT\0RCONTROL\0RWIN\0RMENU\0APPS\0RETURN\0ESCAPE\0F1\0"
"F2\0F3\0F4\0F5\0F6\0F7\0F8\0F9\0F10\0F11\0F12\0SCROLL\0OPEN\0INSERT\0HOME\0PRI"
"OR\0DELETE\0END\0NEXT\0UP\0LEFT\0DOWN\0RIGHT\0NUMLOCK\0DIVIDE\0MULTIPLY\0SUBTR"
"ACT\0ADD\0DECIMAL\0NUMPAD0\0NUMPAD1\0NUMPAD2\0NUMPAD3\0NUMPAD4\0NUMPAD5\0NUMPA"
"D6\0NUMPAD7\0NUMPAD8\0NUMPAD9\0NUMPADRET\0CLOSE\0SEMICOL\0QUOTE\0COMMA\0PERIOD"
"\0SLASH";

static const unsigned char key2nameidx[] = {
  0,   0,   0,   0,   0,   0,   0,   0,   53,  58,  0,   0,   0,   94,  0,   0,
  0,   0,   0,   0,   60,  0,   0,   0,   0,   0,   0,   97,  0,   0,   0,   0,
  55,  132, 141, 139, 130, 145, 143, 150, 147, 0,   0,   0,   0,   126, 135, 0,
  27,  28,  29,  30,  31,  32,  33,  34,  35,  36,  0,   0,   0,   0,   0,   0,
  0,   1,   2,   3,   4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  14,  15,
  16,  17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  72,  86,  91,  215, 0,
  175, 179, 183, 187, 191, 195, 199, 203, 207, 211, 160, 169, 0,   165, 171, 157,
  101, 102, 104, 105, 107, 108, 110, 111, 113, 114, 116, 118, 0,   0,   0,   0,
  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
  153, 120, 0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
  64,  78,  68,  81,  75,  88,  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   223, 44,  230, 42,  233, 237,
  37,  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   124, 48,  220, 227, 0,
  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
};

/**
 * Converts a key code to a string representing the name of the key for
 * debugging.
 */
const char *plat_ps2_kb_key2name(unsigned char key) {
  const char *name = key2namestr + (((int)key2nameidx[key])<<1);
  if (!*name) {
    name++;
  }
  return name;
}

/**
 * Sets the keyboard LEDs.
 */
void plat_ps2_kb_setleds(ps2kbdstate_t *state, int leds) {
  
  while (state->ps2->status & (1 << 5));
  state->ps2->data = 0xED;
  while (state->ps2->status & (1 << 5));
  state->ps2->data = leds;
  
}

/**
 * Initializes PS/2 interface iface in mouse mode. handler is called from the
 * trap handler when an update is received from the mouse.
 */
//void plat_ps2_mouse_init(int iface, void (*handler)(int dx, int dy, int btns)) {
//  // TODO
//}


/******************************************************************************/
/* I2C                                                                        */
/******************************************************************************/

// Command masks.
#define STA   0x80
#define STO   0x40
#define RD    0x20
#define WR    0x10
#define ACK   0x08

// Status masks.
#define RXACK 0x80
#define TIP   0x02

// Wait for transfer complete.
#define WAIT  while (p->cmdstat & TIP)

// Starts an I2C transfer.
static int i2c_start(volatile i2cmst_t *p, int addr) {
  
  // Send slave address.
  p->data = addr;
  p->cmdstat = STA | WR;
  WAIT;
  
  // Read acknowledgement.
  if (p->cmdstat & RXACK) {
    // This writes a dummy byte to a non-responsive slave. Don't know what else
    // to do, the manual doesn't specify.
    p->data = 0;
    p->cmdstat = STO | WR;
    WAIT;
    return -1;
  }
  
  return 0;
}

// Writes a byte. If last is nonzero, this will be the last transfer.
static int i2c_write(volatile i2cmst_t *p, int data, int last) {
  
  // Send data.
  p->data = data;
  if (last) {
    p->cmdstat = WR | STO;
  } else {
    p->cmdstat = WR;
  }
  WAIT;
  
  // Read acknowledgement.
  if (p->cmdstat & RXACK) {
    if (!last) {
      // This writes a dummy byte to a non-responsive slave. Don't know what else
      // to do, the manual doesn't specify.
      p->data = 0;
      p->cmdstat = STO | WR;
      WAIT;
    }
    return -1;
  }
  
  return 0;
}

// Reads a byte. If last is nonzero, this will be the last transfer.
static int i2c_read(volatile i2cmst_t *p, int last) {
  
  // Read data.
  if (last) {
    p->cmdstat = RD | ACK | STO;
  } else {
    p->cmdstat = RD;
  }
  WAIT;
  return p->data;
  
}

/**
 * Writes to an I2C device (blocking).
 *  - p must be set to the I2C peripheral address.
 *  - addr is the 7-bit I2C address (in bit 6..0).
 *  - reg is the I2C device register offset (first byte that is sent).
 *  - data and count specify the values to be written (second and later bytes).
 * Returns 0 if successful or -1 if the slave did not acknowledge somthing.
 */
int plat_i2c_write(volatile i2cmst_t *p, int addr, int reg, const char *data, int count) {
  
  // Make sure the peripheral is initialized.
  p->ctrl = 0x00;
  p->prescale = PLAT_PS2(0)->timer / 50;
  p->ctrl = 0x80;
  
  // Start the transfer.
  if (i2c_start(p, addr << 1)) return -1;
  
  // Send the register address.
  if (i2c_write(p, reg, count==0)) return -1;
  
  // Send the data.
  while (count--) {
    if (i2c_write(p, *data++, count==0)) return -1;
  }
  
  return 0;
  
}

/**
 * Reads from an I2C device (blocking).
 *  - p must be set to the I2C peripheral address.
 *  - addr is the 7-bit I2C address (in bit 6..0).
 *  - reg is the I2C device register offset.
 *  - data and count specify the values to be read.
 * Returns 0 if successful or -1 if the slave did not acknowledge somthing.
 */
int plat_i2c_read(volatile i2cmst_t *p, int addr, int reg, char *data, int count) {
  
  // Make sure the peripheral is initialized.
  p->ctrl = 0x00;
  p->prescale = PLAT_PS2(0)->timer / 50;
  p->ctrl = 0x80;
  
  // Start the transfer.
  if (i2c_start(p, addr << 1)) return -1;
  
  // Send the register address.
  if (i2c_write(p, reg, 0)) return -1;
  
  // Repeated start for the read.
  if (i2c_start(p, (addr << 1) | 1)) return -1;
  
  // Read the data.
  while (count--) {
    *data++ = (char)i2c_read(p, count==0);
  }
  
}
