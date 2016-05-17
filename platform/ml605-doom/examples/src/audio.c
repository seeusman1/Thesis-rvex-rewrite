
#include "rvex.h"
#include "platform.h"

// http://www.coranac.com/2009/07/sines/
int isin_S4(int x) {
  int c, x2, y;
  static const int qN= 13, qA= 12, B=19900, C=3516;

  c= x<<(30-qN);              // Semi-circle info into carry.
  x -= 1<<qN;                 // sine -> cosine calc

  x= x<<(31-qN);              // Mask with PI
  x= x>>(31-qN);              // Note: SIGNED shift! (to qN)
  x= x*x>>(2*qN-14);          // x=x^2 To Q14

  y= B - (x*C>>14);           // B - x^2*C
  y= (1<<qA)-(x*y>>16);       // A - x^2*(B-x^2*C)

  return c>=0 ? y : -y;
}

#define SAMPLE_BUFFER_SIZE 1024
static unsigned char sample_buffer[SAMPLE_BUFFER_SIZE];

static int prescale = 0;
static int time = 0;
static int time2 = 0;

static ps2kbdstate_t kbdstate;

unsigned char sample(void) {
  int val;
  
  prescale++;
  if (prescale == 100) {
    prescale = 0;
    time2 += 1;
  }
  if (time2 == 1000) {
    time2 = 0;
  }
  
  time += time2 + 40;// 327; // 440 Hz?
  val = isin_S4(time);
  val >>= 6;
  val += 128;
  return (unsigned char)val;
}

void update_audio(unsigned long data) {
  int i;
  int remain;
  unsigned char *ptr;
  
  for (i = 0; i < SAMPLE_BUFFER_SIZE; i++) {
    sample_buffer[i] = sample();
  }
  
  ptr = sample_buffer;
  remain = SAMPLE_BUFFER_SIZE;
  while (remain) {
    int count = plat_audio_write(ptr, remain);
    ptr += count;
    remain -= count;
  }
  
  plat_irq_clear(IRQ_AUDIO);
}

int main(void) {
  plat_init();
  
  if (0) {
    plat_serial_puts(0, "Hello World!\n");
    plat_serial_putx(0, 0x12345678); plat_serial_putc(0, '\n');
    plat_serial_putx(0, 0xDEADBEEF); plat_serial_putc(0, '\n');
    plat_serial_putx(0, 0x00000000); plat_serial_putc(0, '\n');
    plat_serial_putx(0, 0xFFFFFFFF); plat_serial_putc(0, '\n');
    plat_serial_putd(0,  305419896); plat_serial_putc(0, '\n');
    plat_serial_putd(0, -559038242); plat_serial_putc(0, '\n');
    plat_serial_putd(0,          0); plat_serial_putc(0, '\n');
    plat_serial_putd(0,      -3333); plat_serial_putc(0, '\n');
  }
  
  if (0) {
    char ls[] = "these simple parts of mine are interchangeable\nunlimited connections when you're digital\nbecoming one with wires is sensational\ngo out with the old and in with the new\nmy hunger for perfection is insatiable\na prototype that's fully operational\nthis armored alloy shell is unbreakable\nmy existence is irreplaceable\n";
    const char *ptr = ls;
    int remain = strlen(ptr);
    while (remain) {
      int count = plat_serial_write(0, ptr, remain);
      ptr += count;
      remain -= count;
    }
  }
  
  while (0) {
    int sec, usec;
    plat_gettimeofday(&sec, &usec);
    plat_serial_putd(0, sec);
    plat_serial_puts(0, ", ");
    plat_serial_putd(0, usec);
    plat_serial_puts(0, "\n");
  }
  
  if (0) {
    plat_irq_register(IRQ_AUDIO, update_audio, 0);
    plat_irq_enable(IRQ_AUDIO, 1);
  }
  
  if (1) {
    plat_ps2_kb_init(&kbdstate, 0);
    while (1) {
      int i = plat_ps2_kb_pop(&kbdstate);
      if (i >= 0) {
        plat_serial_puts(0, plat_ps2_kb_key2name(i & 0xFF));
        if (i & 0x100) {
          plat_serial_puts(0, " down\n");
        } else {
          plat_serial_puts(0, " up\n");
        }
      }
    }
  }
  
  while (1);
  
//   int state = 0;
//   int val = 0;
//   
//   while (1) {
//     while (COUNT > 64);
//     while (COUNT < 128) {
//       state+=5;
//       if (state >= 510) {
//         state -= 510;
//       }
//       if (state > 255) {
//         val = 510 - state;
//       } else {
//         val = state;
//       }
//       DATA = (unsigned char)val;
//     }
//   }
  
}
