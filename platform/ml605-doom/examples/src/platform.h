// platform TODO:
//  - IDF -> 0
//  - 4 timers instead of 3
//  - PMbus I2C for power measurement?
//  - gracectrl?
//  - serial port using the SMAs and a serial port using the remaning display
//    pins?

#ifndef _PLATFORM_H_
#define _PLATFORM_H_

/******************************************************************************/
/* COMMON                                                                     */
/******************************************************************************/

/**
 * This function initializes the platform and should be called at the start of
 * the main().
 */
void plat_init(void);

// Debugging stuff needed by start.o. These use serial port 0 (the debug port).
int putchar(int character);
int puts(const char *str);
int rvex_succeed(const char *str);
int rvex_fail(const char *str);

// Common functions and definitions.
void  memcpy(void *dest, const void *src, unsigned int num);
void *memmove(void *dest, const void *src, unsigned int num);
void  _bcopy(const void *src, void *dest, unsigned int num);
int   memcmp(const void *a, const void *b, unsigned int num);
int   memset(void *ptr, int value, unsigned int num);
void  strcpy(char *dest, const char *src);
int   strcmp(const char *a, const char *b);
int   strlen(const char *str);
int   min(int a, int b);
int   max(int a, int b);


/******************************************************************************/
/* INTERRUPTS                                                                 */
/******************************************************************************/

// Interrupt controller interface.
typedef struct {
  unsigned int level;
  unsigned int pending;
  unsigned int RESERVED_A;
  unsigned int clear;
  unsigned int mp_status;
  unsigned int broadcast;
  unsigned int RESERVED_B[10];
  unsigned int mask[16];
  unsigned int force[16];
  unsigned int ext_ack[16];
} irqmp_t;

#define PLAT_IRQMP ((volatile irqmp_t*)0x80000000)

// Interrupt sources.
#define IRQ_TICK      1
#define IRQ_DBG_UART  4
#define IRQ_AUDIO     5
#define IRQ_PS20      6
#define IRQ_PS21      7
#define IRQ_I2C       8
#define IRQ_GPIO      9

/**
 * Registers the specified interrupt handler function for the specified IRQ.
 * Only one handler can be registered at a time.
 */
void plat_irq_register(int irq, void (*handler)(void));

/**
 * Masks or unmasks an interrupt.
 */
void plat_irq_mask(int irq, int enable);

/**
 * Returns whether the specified interrupt is pending.
 */
int plat_irq_ispending(int irq);

/**
 * Clears a pending interrupt.
 */
void plat_irq_clear(int irq);

/**
 * Forces the specified interrupt on the specified context.
 */
void plat_irq_force(int irq, int context);


/******************************************************************************/
/* SERIAL PORTS                                                               */
/******************************************************************************/

// r-VEX debug UART peripheral.
#define PLAT_DEBUGUART_DATA (*((volatile unsigned char *)(0xD1000000)))
#define PLAT_DEBUGUART_STAT (*((volatile unsigned char *)(0xD1000004)))

#define PLAT_NUM_SERIAL 1

/**
 * Writes a character to the specified serial port. Blocking.
 */
void plat_serial_putc(int iface, char c);

/**
 * Writes a null-terminated string to the specified serial port. Blocking.
 */
void plat_serial_puts(int iface, const char *s);

/**
 * Writes a 32-bit hexadecimal value to the specified serial port. Blocking.
 */
void plat_serial_putx(int iface, int value);

/**
 * Writes a 32-bit signed decimal value to the specified serial port. Blocking.
 */
void plat_serial_putd(int iface, int value);

/**
 * Writes a data buffer to the specified serial port. Non-blocking, same
 * interface as POSIX write.
 */
int plat_serial_write(int iface, const void *buf, int count);

/**
 * Reads from the specified serial port into the data buffer. Non-blocking, same
 * interface as POSIX read.
 */
int plat_serial_read(int iface, void *buf, int count);


/******************************************************************************/
/* TIMING                                                                     */
/******************************************************************************/

// GRLIB general purpose timer peripheral.
typedef struct {
  unsigned int scaler_val;
  unsigned int scaler_reload;
  unsigned int config;
  unsigned int latchsel;
  unsigned int tim1_val;
  unsigned int tim1_reload;
  unsigned int tim1_config;
  unsigned int tim1_latch;
  unsigned int tim2_val;
  unsigned int tim2_reload;
  unsigned int tim2_config;
  unsigned int tim2_latch;
  unsigned int tim3_val;
  unsigned int tim3_reload;
  unsigned int tim3_config;
  unsigned int tim3_latch;
  unsigned int tim4_val;
  unsigned int tim4_reload;
  unsigned int tim4_config;
  unsigned int tim4_latch;
} gptimer_t;

#define PLAT_GPTIMER ((volatile gptimer_t*)0x80000300)

/**
 * Like CSL gettimeofday(). Starts at 0, guaranteed monotone between calls to
 * plat_settimeofday. THIS IS MERELY APPROXIMATE if the platform clock frequency
 * in MHz is not an integer.
 */
void plat_gettimeofday(int *sec, int *usec);

/**
 * Sets the current time.
 */
void plat_settimeofday(int sec, int usec);

/**
 * Returns the frequency at which the platform is running in units of 10kHz.
 */
int plat_frequency(void);

/**
 * Registers an (OS) tick handler. interval is specified in microseconds.
 */
int plat_tick(int interval, void (*handler)(void));


/******************************************************************************/
/* AUDIO                                                                      */
/******************************************************************************/

// Audio peripheral access.
#define PLAT_AUDIO_DATA    (*((volatile unsigned char*)0xD2000000))
#define PLAT_AUDIO_REMAIN  (*((const volatile int*)0xD2000000))
#define PLAT_AUDIO_FIFOLEN 4095

/**
 * Sets the audio samplerate. rate must be specified in Hz. The actual
 * samplerate will approximate the requested rate.
 */
int plat_audio_setsamplerate(int rate);

/**
 * Writes to the audio buffer. Same interface as POSIX write. Fills the buffer
 * up as far as possible given the input, doesn't block. Unsigned 8-bit mono
 * samples are expected.
 */
int plat_audio_write(const void *buf, int count);

/**
 * Returns the number of samples that can currently be written to the buffer.
 */
int plat_audio_avail(void);

/**
 * Returns the number of samples currently in the buffer.
 */
int plat_audio_remain(void);


/******************************************************************************/
/* VIDEO                                                                      */
/******************************************************************************/

// SVGA control interface.
typedef struct {
  unsigned int status;
  unsigned int vidlen;
  unsigned int fplen;
  unsigned int synclen;
  unsigned int linelen;
  const void *framebuf;
  const unsigned int clocks[4];
  unsigned int clut;
} svgactrl_t;

#define PLAT_SVGA ((volatile svgactrl_t*)(0x80000400))

/**
 * Initializes the VGA/DVI output.
 *  - w specifies the width in pixels.
 *  - h specifies the height in pixels.
 *  - bpp specifies the bits per pixel and must be 8, 16 or 32.
 *  - dvi should be nonzero to output a DVI signal or zero to output a VGA
 *    signal.
 *  - frame should point to the framebuffer, which must be w*h*bpp/8 bytes in
 *    size.
 * 640x480 uses standard timing. Anything else results in non-standard
 * sync/porch timing and may or may not work. Returns 0 on success or -1 if an
 * I2C error occurs.
 */
int plat_video_init(int w, int h, int bpp, int dvi, const void *frame);

/**
 * Returns nonzero during vsyncs.
 */
int plat_video_isvsyncing(void);

/**
 * Reassigns the framebuffer pointer.
 */
void plat_video_swap(const void *frame);

/**
 * Assigns the given RGB value to the given palette index. All values must be
 * in the 0-255 range.
 */
void plat_video_palette(int index, int r, int g, int b);


/******************************************************************************/
/* PS/2                                                                       */
/******************************************************************************/

// Random Linux kernel source with key codes.
#include "input-event-codes.h"

// PS/2 interface.
typedef struct {
  unsigned int data;
  unsigned int status;
  unsigned int control;
  unsigned int timer;
} apbps2_t;

#define PLAT_PS2(i)    ((volatile apbps2_t*)(0x80000100+(i<<8)))
#define PLAT_NUM_PS2   2

/**
 * Initializes PS/2 interface iface in keyboard mode. handler is called from
 * the trap handler when a key is pressed, typematic'd or released. key
 * represents one of the KEY_* definitions from input-event-codes.h.
 */
void plat_ps2_kb_init(int iface, void (*handler)(int key, int up));

/**
 * Sets the keyboard LEDs.
 */
void plat_ps2_kb_setleds(int iface, int leds);

/**
 * Initializes PS/2 interface iface in mouse mode. handler is called from the
 * trap handler when an update is received from the mouse.
 */
void plat_ps2_mouse_init(int iface, void (*handler)(int dx, int dy, int btns));


/******************************************************************************/
/* I2C                                                                        */
/******************************************************************************/

// GRLIB I2C master peripheral.
typedef struct {
  unsigned int prescale;
  unsigned int ctrl;
  unsigned int data;
  unsigned int cmdstat;
} i2cmst_t;

#define PLAT_I2C_DVI ((volatile i2cmst_t*)0x80000500)

/**
 * Writes to an I2C device (blocking).
 *  - p must be set to the I2C peripheral address.
 *  - addr is the 7-bit I2C address (in bit 6..0).
 *  - reg is the I2C device register offset (first byte that is sent).
 *  - data and count specify the values to be written (second and later bytes).
 * Returns 0 if successful or -1 if the slave did not acknowledge somthing.
 */
int plat_i2c_write(volatile i2cmst_t *p, int addr, int reg, const char *data, int count);

/**
 * Reads from an I2C device (blocking).
 *  - p must be set to the I2C peripheral address.
 *  - addr is the 7-bit I2C address (in bit 6..0).
 *  - reg is the I2C device register offset.
 *  - data and count specify the values to be read.
 * Returns 0 if successful or -1 if the slave did not acknowledge somthing.
 */
int plat_i2c_read(volatile i2cmst_t *p, int addr, int reg, const char *data, int count);

#endif