#include "platform.h"
#include "rvex.h"

/******************************************************************************/
/* COMMON                                                                     */
/******************************************************************************/

void plat_init(void) {
  CR_CCR = CR_CCR_IEN | CR_CCR_RFT;
}


void _stop(void);
int putchar(int character)        { plat_serial_putc(0, character); return 0; }
int puts(const char *str)         { plat_serial_puts(0, str);       return 0; }
int rvex_succeed(const char *str) { plat_serial_puts(0, str);       return 0; }
int rvex_fail(const char *str)    { plat_serial_puts(0, str);       return 0; }


/******************************************************************************/
/* INTERRUPTS (Note that some GRLIB functionality may not be implemented yet) */
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


/* We prefer to use stderr to avoid mixing with trace output */
#define SIM_WRITE_FD 2

/**
 * Prints a character to whatever platform the program is compiled for, if the
 * platform supports an output stream. Prototype conforms to the <stdio.h>
 * method.
 */
void plat_serial_putc(int iface, char c) {
  if (iface == 0) {
    sim_write(SIM_WRITE_FD, &c, 1);
  }
}

/**
 * Same as putchar, but prints a null-terminated string. Prototype conforms to
 * the <stdio.h> method.
 */
void plat_serial_puts(int iface, const char *s) {
  if (iface == 0) {
    int len = 0;
    const char* orig = s;
    while(*s++) len++;
    sim_write(SIM_WRITE_FD, orig, len);
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

  // Assuming 37.5MHz clock frequency  
  frequency_khz = CLOCK_FREQ_KHZ; 
  
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
/* VIDEO                                                                      */
/******************************************************************************/

/**
 * Disable video output
 */
void plat_video_disable(void){
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
  *((volatile unsigned long *)FB_WIDTH_REG)   = w;
  *((volatile unsigned long *)FB_HEIGHT_REG)  = h;
  *((volatile unsigned long *)FB_DEPTH_REG)   = bpp;
  *((volatile unsigned long *)FB_COMMAND_REG) = 1;
  return (void*)FB_ADDRESS;
}

/**
 * Returns nonzero during vsyncs.
 */
int plat_video_isvsyncing(void) {
  return -1;
}

/**
 * Reassigns the framebuffer pointer.
 */
void plat_video_swap(const void *frame) {
}

/**
 * Assigns the given RGB value to the given palette index. All values must be
 * in the 0-255 range.
 */
void plat_video_palette(int index, int r, int g, int b) {
}

