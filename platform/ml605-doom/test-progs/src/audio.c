
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
  
  /*static int s = 0, t = 10000;
  s++;
  if (s >= sizeof(incomingtransmission)) {
    s = 0;
  }
  t++;
  if (t >= sizeof(incomingtransmission)) {
    t = 0;
  }
  return (incomingtransmission[t] >> 1) + (incomingtransmission[s] >> 2);*/
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
  int kbdleds = 0;
  
  plat_init();
  
  // Do something with the audio output. This uses an interrupt; you can also
  // just fill the buffer at most every 100ms or so.
  plat_audio_setsamplerate(48000);
  plat_irq_register(IRQ_AUDIO, update_audio, 0);
  plat_irq_enable(IRQ_AUDIO, 1);
  
  // Do keyboard stuff.
  plat_ps2_kb_init(&kbdstate, 0);
  plat_ps2_kb_setleds(&kbdstate, kbdleds);
  while (1) {
    int i = plat_ps2_kb_pop(&kbdstate);
    if (i >= 0) {
      plat_serial_puts(0, plat_ps2_kb_key2name(i & 0xFF));
      
      // Always print the key that was pressed/released.
      if (i & 0x100) {
        plat_serial_puts(0, " down\n");
      } else {
        plat_serial_puts(0, " up\n");
      }
      
      // If the user releases the enter key, print the time of day as well.
      if (i == VK_RETURN) {
        int sec, usec;
        plat_gettimeofday(&sec, &usec);
        plat_serial_putd(0, sec);
        plat_serial_puts(0, ", ");
        plat_serial_putd(0, usec);
        plat_serial_puts(0, "\n");
      }
      
      // Toggle capslock when caps lock is released.
      if (i == VK_CAPITAL) {
        kbdleds ^= PLAT_PS2_LED_CAPSLOCK;
        plat_ps2_kb_setleds(&kbdstate, kbdleds);
      }
      
      // Toggle capslock when caps lock is released.
      if (i == VK_NUMLOCK) {
        kbdleds ^= PLAT_PS2_LED_NUMLOCK;
        plat_ps2_kb_setleds(&kbdstate, kbdleds);
      }
      
    }
  }
  
}
