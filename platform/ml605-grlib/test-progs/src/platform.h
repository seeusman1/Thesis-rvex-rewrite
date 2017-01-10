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

#define PLAT_IRQMP ((volatile irqmp_t*)0x80000200)

// Interrupt sources.
#define IRQ_TICK      1
#define IRQ_DBG_UART  2
#define IRQ_AUDIO     5
#define IRQ_PS20      6
#define IRQ_PS21      7
#define IRQ_TIM1A     8
#define IRQ_TIM1B     9
#define IRQ_GPIO      10
#define IRQ_I2C_DVI   11
#define IRQ_I2C_PMBUS 12
#define IRQ_I2C_ZEBRO 13

/**
 * Registers the specified interrupt handler function for the specified IRQ.
 * Only one handler can be registered at a time. data is passed to the handler.
 */
void plat_irq_register(
  int irq,
  void (*handler)(unsigned long data),
  unsigned long data
);

/**
 * Enables or masks an interrupt.
 */
void plat_irq_enable(int irq, int enable);

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

// Assuming 37.5MHz clock frequency  
#define CLOCK_FREQ_KHZ 37500

// rVEX debug UART peripheral.
#define PLAT_DEBUGUART_DATA (*((volatile unsigned char *)(0xD1000000)))
#define PLAT_DEBUGUART_STAT (*((volatile unsigned char *)(0xD1000004)))
#define PLAT_DEBUGUART_CTRL (*((volatile unsigned char *)(0xD1000008)))

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
} gptimer_t;

#define PLAT_GPTIMER1 ((volatile gptimer_t*)0x80000300)
#define PLAT_GPTIMER2 ((volatile gptimer_t*)0x80000400)

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
int plat_tick(
  int interval,
  void (*handler)(unsigned long data),
  unsigned long data
);


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

typedef struct {
  unsigned int clksel;
  unsigned int left_margin;
  unsigned int right_margin;
  unsigned int upper_margin;
  unsigned int low_margin;
  unsigned int hsync_len;
  unsigned int vsync_len;
} resinfo_t;

#define PLAT_SVGA ((volatile svgactrl_t*)(0x80000600))
#define FB_ALIGN  1024

/**
 * Initializes the Chrontel DAC for VGA or DVI output.
 */
void plat_video_chrontel(void);

/**
 * Disable video output
 */
void plat_video_disable(void);

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
void* plat_video_init(int w, int h, int bpp, int dvi, const void *frame);

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
/* I2C                                                                        */
/******************************************************************************/

// GRLIB I2C master peripheral.
typedef struct {
  unsigned int prescale;
  unsigned int ctrl;
  unsigned int data;
  unsigned int cmdstat;
} i2cmst_t;

#define PLAT_I2C_DVI   ((volatile i2cmst_t*)0x80000900)
#define PLAT_I2C_MAIN  ((volatile i2cmst_t*)0x80000c00)

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
int plat_i2c_read(volatile i2cmst_t *p, int addr, int reg, char *data, int count);

#endif
