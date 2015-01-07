#include "rvex.h"

#define FRAME_BUFFER
#ifdef FRAME_BUFFER

#define ALIGNMENT          4
#define MAGIC_REG          0x20000000
#define COMMAND_REG        (MAGIC_REG + ALIGNMENT)
#define WIDTH_REG          (MAGIC_REG + 2 * ALIGNMENT)
#define HEIGHT_REG         (MAGIC_REG + 3 * ALIGNMENT)
#define DEPTH_REG          (MAGIC_REG + 4 * ALIGNMENT)
#define FREEZE_REG         (MAGIC_REG + 5 * ALIGNMENT)
#define LEDS_REG           0x20001000
#define ALPHA0_REG         0x20002000
#define NUM_OF_ALPHA_REGS  32
#define MEM_BASE           0x20100000

#define ALPHA_REG(i)  (ALPHA0_REG + ALIGNMENT * (i))


/*
 * Use these examples when using the framebuffer in xstsim
 */
 
#if 0
  *((unsigned long *)WIDTH_REG)   = horizontal_size;
  *((unsigned long *)HEIGHT_REG)  = vertical_size;
  *((unsigned long *)DEPTH_REG)   = 24;
  *((unsigned long *)COMMAND_REG) = 1;

void Display_Frame(unsigned char *src[], int frame_number, heap_t *heap_all, frame_t *frame)
{
  char buffer[128];
  unsigned long width  = *((volatile unsigned long *)WIDTH_REG);
  unsigned long height = *((volatile unsigned long *)HEIGHT_REG);
  unsigned int hsize   = heap->horizontal_size,
               vsize   = heap->vertical_size,
               i,
               j;

  sprintf(buffer, "Frame %u", frame_number);

  alpha_print(buffer);

  if ((hsize > width) || (vsize > height))
    exit(-1);

//  *((unsigned long *)FREEZE_REG) = 1;

  for (i = 0; i < hsize; i++)
    for (j = 0; j < vsize; j++)
    {
      long r = src[j * hsize + i],
           g = src[j * hsize + i + 1],
           b = src[j * hsize + i + 2], //you should test this
      if (r < 0)
        r = 0;

      if (b < 0)
        b = 0;

      if (g < 0)
        g = 0;

      color = swap_bytes_32((b & 0xff) + ((g & 0xff) << 8) + ((r & 0xff) << 16));
      ((unsigned long *)MEM_BASE)[j * width + i] = color;
    }

//  *((unsigned long *)FREEZE_REG) = 0;
}
#endif



static void alpha_print(const char *str)
{
  const char *p = str;
  unsigned int i;

  for (i = 0; i < NUM_OF_ALPHA_REGS; i++)
  {
    while ((*p) == '\n')
      p++;

    if ((*p) == '\0')
      *(unsigned long *)(ALPHA_REG(i)) = (unsigned long)(' ');
    else
      *(unsigned long *)(ALPHA_REG(i)) = (unsigned long)(*p);

    if ((*p) != '\0')
      p++;
  }
}

#endif    /* #ifdef FRAME_BUFFER */

/**
 * Prints a character to whatever platform the program is compiled for, if the
 * platform supports an output stream. Prototype conforms to the <stdio.h>
 * method.
 */
int putchar(int character){
  static int pos = 0;
  if (character == '\0')
    *(unsigned long *)(ALPHA_REG(pos)) = (unsigned long)(' ');
  else if (character == '\n')
    pos = 0;
  else
  {
    *(unsigned long *)(ALPHA_REG(pos)) = (unsigned long)(character);
    pos += 1;
    if (pos >= NUM_OF_ALPHA_REGS) pos = 0;
  }
  return 0;
}

/**
 * Same as putchar, but prints a null-terminated string. Prototype conforms to
 * the <stdio.h> method.
 */
int puts(const char *str) {
  while (*str) putchar(*str++);
//  alpha_print(str); //This function is nicer but it does a \n for every string
  return 0;
}

/**
 * Prints the string presented to it to the standard output of the platform,
 * and in addition reports success or failure, if supported by the platform.
 */
int rvex_succeed(const char *str) {
  puts("success: ");
  puts(str);
  while (1)
  {
  /*
   * Crashing the core so you can read the output on the Framebuffer's alphanumeric display. just press ctrl-c to stop simulation.
   * It would be nicer to pause the simulator but I don't know if thats possible from within the simulated code.
   */
   }
  return 0;
}
int rvex_fail(const char *str) {
  puts("failure: ");
  puts(str);
  while (1) ;
  return 0;
}

/**
 * Reads a character from whatever input stream the platform has available,
 * waiting until one is available. Prototype conforms to the <stdio.h> method.
 */
int getchar(void) {
  while (1) ;
  return 0;
}
