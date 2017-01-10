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

// r-VEX debug UART peripheral.
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
  unsigned int tim3_val;
  unsigned int tim3_reload;
  unsigned int tim3_config;
  unsigned int tim3_latch;
  unsigned int tim4_val;
  unsigned int tim4_reload;
  unsigned int tim4_config;
  unsigned int tim4_latch;
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
/* PS/2                                                                       */
/******************************************************************************/

// PS/2 interface.
typedef struct {
  unsigned int data;
  unsigned int status;
  unsigned int control;
  unsigned int timer;
} apbps2_t;

#define PLAT_PS2(i)    ((volatile apbps2_t*)(0x80000000+(i<<8)))
#define PLAT_NUM_PS2   2

// Keyboard event buffer depth. Must be a power of two!
#define KBD_EVENT_BUFFER_DEPTH 256

// Subset of Windows virtual key codes plus a couple made up ones (because we
// only need to support EN-US thank god). Windows instead of Linux, because as
// I've found out, the Linux codes are just as insane as scan codes so you might
// as well not use them.
#define VK_A 'A' /* A */
#define VK_B 'B' /* B */
#define VK_C 'C' /* C */
#define VK_D 'D' /* D */
#define VK_E 'E' /* E */
#define VK_F 'F' /* F */
#define VK_G 'G' /* G */
#define VK_H 'H' /* H */
#define VK_I 'I' /* I */
#define VK_J 'J' /* J */
#define VK_K 'K' /* K */
#define VK_L 'L' /* L */
#define VK_M 'M' /* M */
#define VK_N 'N' /* N */
#define VK_O 'O' /* O */
#define VK_P 'P' /* P */
#define VK_Q 'Q' /* Q */
#define VK_R 'R' /* R */
#define VK_S 'S' /* S */
#define VK_T 'T' /* T */
#define VK_U 'U' /* U */
#define VK_V 'V' /* V */
#define VK_W 'W' /* W */
#define VK_X 'X' /* X */
#define VK_Y 'Y' /* Y */
#define VK_Z 'Z' /* Z */
#define VK_0 '0' /* 0 */
#define VK_1 '1' /* 1 */
#define VK_2 '2' /* 2 */
#define VK_3 '3' /* 3 */
#define VK_4 '4' /* 4 */
#define VK_5 '5' /* 5 */
#define VK_6 '6' /* 6 */
#define VK_7 '7' /* 7 */
#define VK_8 '8' /* 8 */
#define VK_9 '9' /* 9 */
#define VK_BACKQUOTE 0xC0 /* ` */
#define VK_DASH 0xBD /* - */
#define VK_EQUALS 0xBB /* = */
#define VK_BACKSLASH 0xDC /* \ */
#define VK_BACK 0x08 /* BKSP */
#define VK_SPACE 0x20 /* SPACE */
#define VK_TAB 0x09 /* TAB */
#define VK_CAPITAL 0x14 /* CAPS */
#define VK_LSHIFT 0xA0 /* LSHFT */
#define VK_LCONTROL 0xA2 /* LCTRL */
#define VK_LWIN 0x5B /* LGUI */
#define VK_LMENU 0xA4 /* LALT */
#define VK_RSHIFT 0xA1 /* RSHFT */
#define VK_RCONTROL 0xA3 /* RCTRL */
#define VK_RWIN 0x5C /* RGUI */
#define VK_RMENU 0xA5 /* RALT */
#define VK_APPS 0x5D /* APPS */
#define VK_RETURN 0x0D /* ENTER */
#define VK_ESCAPE 0x1B /* ESC */
#define VK_F1 0x70 /* F1 */
#define VK_F2 0x71 /* F2 */
#define VK_F3 0x72 /* F3 */
#define VK_F4 0x73 /* F4 */
#define VK_F5 0x74 /* F5 */
#define VK_F6 0x75 /* F6 */
#define VK_F7 0x76 /* F7 */
#define VK_F8 0x77 /* F8 */
#define VK_F9 0x78 /* F9 */
#define VK_F10 0x79 /* F10 */
#define VK_F11 0x7A /* F11 */
#define VK_F12 0x7B /* F12 */
#define VK_SCROLL 0x91 /* SCROLL */
#define VK_OPEN 0xDB /* [ */
#define VK_INSERT 0x2D /* INSERT */
#define VK_HOME 0x24 /* HOME */
#define VK_PRIOR 0x21 /* PGUP */
#define VK_DELETE 0x2E /* DELETE */
#define VK_END 0x23 /* END */
#define VK_NEXT 0x22 /* PGDN */
#define VK_UP 0x26 /* UARROW */
#define VK_LEFT 0x25 /* LARROW */
#define VK_DOWN 0x28 /* DARROW */
#define VK_RIGHT 0x27 /* RARROW */
#define VK_NUMLOCK 0x90 /* NUM */
#define VK_DIVIDE 0x6F /* KP/ */
#define VK_MULTIPLY 0x6A /* KP* */
#define VK_SUBTRACT 0x6D /* KP- */
#define VK_ADD 0x6B /* KP+ */
#define VK_DECIMAL 0x6E /* KP. */
#define VK_NUMPAD0 0x60 /* KP0 */
#define VK_NUMPAD1 0x61 /* KP1 */
#define VK_NUMPAD2 0x62 /* KP2 */
#define VK_NUMPAD3 0x63 /* KP3 */
#define VK_NUMPAD4 0x64 /* KP4 */
#define VK_NUMPAD5 0x65 /* KP5 */
#define VK_NUMPAD6 0x66 /* KP6 */
#define VK_NUMPAD7 0x67 /* KP7 */
#define VK_NUMPAD8 0x68 /* KP8 */
#define VK_NUMPAD9 0x69 /* KP9 */
#define VK_NUMPADRET 0x5E /* KPEN */
#define VK_CLOSE 0xDD /* ] */
#define VK_SEMICOL 0xBA /* ; */
#define VK_QUOTE 0xDE /* ' */
#define VK_COMMA 0xBC /* , */
#define VK_PERIOD 0xBE /* . */
#define VK_SLASH 0xBF /* / */

// PS/2 keyboard state record.
typedef struct ps2kbdstate_t {

  // Pointer to the PS/2 peripheral address space.
  volatile apbps2_t* ps2;

  // Interrupt number.
  int irq;

  // Protocol decoder state.
  unsigned char ext, up;

  // Key states: high bit means button down, low bit means button up.
  unsigned char keystates[32*PLAT_NUM_PS2];

  // Key event FIFO. Bit 7..0 is the Linux key code, bit 8 is high for down and
  // low for up.
  unsigned short events[KBD_EVENT_BUFFER_DEPTH];
  int widx, ridx, count;

} ps2kbdstate_t;

/**
 * Initializes PS/2 interface iface in keyboard mode. state must point to a
 * caller-allocated keyboard state record.
 */
void plat_ps2_kb_init(ps2kbdstate_t *state, int iface);

/**
 * Returns whether a given key (VK_*, input-event-codes.h) is currently down.
 * This is multi-context safe as it does not write to the state record.
 */
int plat_ps2_kb_getkey(const ps2kbdstate_t *state, unsigned char key);

/**
 * Gets the next keyboard event from the event buffer. Returns -1 if the buffer
 * is empty. Otherwise, bit 7..0 contain the Linux key code. Bit 8 is set if the
 * key was pressed (or typematic'd by the keyboard) and is cleared when it is
 * released. This is not multi-context safe.
 */
int plat_ps2_kb_pop(ps2kbdstate_t *state);

/**
 * Converts a key code to a string representing the name of the key for
 * debugging.
 */
const char *plat_ps2_kb_key2name(unsigned char key);

/**
 * Sets the keyboard LEDs.
 */
void plat_ps2_kb_setleds(ps2kbdstate_t *state, int leds);

// Keyboard LED codes.
#define PLAT_PS2_LED_SCROLL   0x01
#define PLAT_PS2_LED_NUMLOCK  0x02
#define PLAT_PS2_LED_CAPSLOCK 0x04

/**
 * Initializes PS/2 interface iface in mouse mode. handler is called from the
 * trap handler when an update is received from the mouse.
 */
//void plat_ps2_mouse_init(int iface, void (*handler)(int dx, int dy, int btns)); TODO


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

#define PLAT_I2C_DVI   ((volatile i2cmst_t*)0x80000700)
#define PLAT_I2C_PMBUS ((volatile i2cmst_t*)0x80000800)
#define PLAT_I2C_ZEBRO ((volatile i2cmst_t*)0x80000900)

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
