#include "rvex.h"
#include "rvex_io.h"
#include "platform.h"

#define TIMER PLAT_GPTIMER1

typedef struct {
  int ms;
  int s;
  int m;
  int h;
} time_t;

volatile time_t current_time = { 0, 0, 0, 0 };
volatile int configuring = 0;
volatile int force_update = 1;
volatile int updating = 0;

void time_interrupt(unsigned long data);

// Select display type:

#define DISPLAY_LINES 4
const char *DISPLAY_ROM[DISPLAY_LINES] = {
  "\0"" _ \0""   \0"" _ \0"" _ \0""   \0"" _ \0"" _ \0"" _ \0"" _ \0"" _ \0""   \0""   \0"" |",
  "\0""| |\0""  |\0"" _|\0"" _|\0""|_|\0""|_ \0""|_ \0""  |\0""|_|\0""|_|\0"" . \0""   \0"" |",
  "\0""|_|\0""  |\0""|_ \0"" _|\0""  |\0"" _|\0""|_|\0""  |\0""|_|\0"" _|\0"" . \0""   \0"" |",
  "\0""___\0""___\0""___\0""___\0""___\0""___\0""___\0""___\0""___\0""___\0""___\0""___\0""/"
};

/*
#define DISPLAY_LINES 2
const char *DISPLAY_ROM[DISPLAY_LINES] = {
  "\0""0\0""1\0""2\0""3\0""4\0""5\0""6\0""7\0""8\0""9\0"":\0"" \0""|",
  "\0""-\0""-\0""-\0""-\0""-\0""-\0""-\0""-\0""-\0""-\0""-\0""-\0""'",
};
*/

const char *DISPLAY_CHARS = "0123456789: ";
int DISPLAY_CHAR_OFFSET[128];

void init_display_rom(void) {
  const char *p1 = DISPLAY_CHARS;
  const char *p2 = DISPLAY_ROM[0] + 1;
  int index = 1;
  while (*p1) {
    DISPLAY_CHAR_OFFSET[*p1] = index;
    while (*p2) {
      index++;
      p2++;
    }
    index++;
    p2++;
    p1++;
  }
  DISPLAY_CHAR_OFFSET[0] = index;
}

void render(const char *s) {
  int line;
  const char *p;
  
  // Save cursor position and move to origin.
  puts("\033[s\033[1;1H");
  
  for (line = 0; line < DISPLAY_LINES; line++) {
    p = s;
    while (*p) {
      puts(DISPLAY_ROM[line] + DISPLAY_CHAR_OFFSET[*p]);
      p++;
    }
    puts(DISPLAY_ROM[line] + DISPLAY_CHAR_OFFSET[0]);
    putchar('\n');
  }
  
  // Restore cursor position.
  puts("\033[u");
  
}




/**
 * C entry point.
 */
int main(void) {
  
  // Dump welcome message.
  puts("Running \"time\".\n");
  puts("This will display the time in the top-left corner of your console.\n");
  puts("Use [enter] and the arrow keys to configure the time. Press q to exit.\n");
  puts("Be sure to use \"make monitor-nobuf\" to disable echo and line buffering!\n");
  
  // Configure the timer to generate an interrupt every second.
  TIMER->scaler_reload = 300 - 1; // Every 10 microseconds.
  TIMER->tim1_reload = 100 - 1; // Every millisecond.
  TIMER->tim1_config
    = (1 << 0)  // Enable timer.
    | (1 << 1)  // Auto-restart timer.
    | (1 << 2)  // Load the reload value now.
    | (1 << 3); // Enable the interrupt.
    
  // Register the interrupt handler
  plat_irq_register(IRQ_TIM1A, time_interrupt, 0);
  
  // Enable the interrupt for timer 1.
  PLAT_IRQMP->level = (1 << IRQ_TIM1A);
  PLAT_IRQMP->mask[CR_CID] |= (1 << IRQ_TIM1A);
  
  // Initialize the display renderer.
  init_display_rom();
  
  // Enable interrupts.
  CR_CCR = CR_CCR_IEN | CR_CCR_RFT;
  
  while (1) {
    unsigned char c;
    int sel;
    while (!plat_serial_read(0, &c, 1));
    
    switch (c) {
      
      case '\n': // Enter.
        if (configuring) {
          configuring = 0;
        } else {
          configuring = 1;
        }
        force_update = 1;
        break;
        
      case 'A': // Cursor up.
        CR_CCR = CR_CCR_IEN_C;
        switch (configuring) {
          case 1: // Hours.
            current_time.h++;
            if (current_time.h >= 23) {
              current_time.h = 0;
            }
            force_update = 1;
            break;
          case 2: // Minutes.
            current_time.m++;
            if (current_time.m >= 59) {
              current_time.m = 0;
            }
            force_update = 1;
            break;
          case 3: // Seconds.
            current_time.s++;
            if (current_time.s >= 59) {
              current_time.s = 0;
            }
            force_update = 1;
            break;
        }
        CR_CCR = CR_CCR_IEN;
        break;
        
      case 'B': // Cursor down.
        CR_CCR = CR_CCR_IEN_C;
        switch (configuring) {
          case 1: // Hours.
            current_time.h--;
            if (current_time.h < 0) {
              current_time.h = 23;
            }
            force_update = 1;
            break;
          case 2: // Minutes.
            current_time.m--;
            if (current_time.m < 0) {
              current_time.m = 59;
            }
            force_update = 1;
            break;
          case 3: // Seconds.
            current_time.s--;
            if (current_time.s < 0) {
              current_time.s = 59;
            }
            force_update = 1;
            break;
        }
        CR_CCR = CR_CCR_IEN;
        break;
        
      case 'C': // Cursor right.
        sel = configuring;
        if (sel && (sel < 3)) {
          configuring = sel + 1;
          force_update = 1;
        }
        break;
        
      case 'D': // Cursor left.
        sel = configuring;
        if (sel > 1) {
          configuring = sel - 1;
          force_update = 1;
        }
        break;
        
      case 'q': // Quit.
        CR_CCR = CR_CCR_IEN_C;
        puts("Quit.\n");
        return 0;
      
    }
    
  }
}

/**
 * Interrupt handler. This is called from assembly code when an interrupt
 * occurs.
 */
void time_interrupt(unsigned long data) {
  
  time_t t;
  
  // Clear the interrupt flag.
  TIMER->tim1_config
    = (1 << 0)  // Enable timer.
    | (1 << 1)  // Auto-restart timer.
    | (1 << 3)  // Enable the interrupt.
    | (1 << 4); // Clear the interrupt pending flag.
  
  // Load the current time from volatile memory to registers/local vars.
  t = current_time;
  
  // Increment the current time.
  t.ms++;
  if (t.ms >= 1000) {
    t.ms = 0;
    t.s++;
    if (t.s >= 60) {
      t.s = 0;
      t.m++;
      if (t.m >= 60) {
        t.m = 0;
        t.h++;
        if (t.h >= 24) {
          t.h = 0;
        }
      }
    }
  }
  
  // Save the current time.
  current_time = t;
  
  // Print the time while allowing interrupts to nest if t.ms is 0 or 500 or
  // if the main loop set the force_update flag.
  if ((t.ms == 0) || (t.ms == 500) || force_update) {
    if (!updating) {
      int forced = force_update;
      static char buf[9];
      char *bufPtr = buf;
      updating = 1;
      force_update = 0;
      CR_CCR = CR_CCR_IEN | CR_CCR_RFT;
      if ((t.ms < 500) && (configuring == 1) && !forced) {
        *bufPtr++ = ' ';
        *bufPtr++ = ' ';
      } else {
        *bufPtr++ = (t.h / 10 + '0');
        *bufPtr++ = (t.h % 10 + '0');
      }
      *bufPtr++ = ((t.ms < 500) ? ' ' : ':');
      if ((t.ms < 500) && (configuring == 2) && !forced) {
        *bufPtr++ = ' ';
        *bufPtr++ = ' ';
      } else {
        *bufPtr++ = (t.m / 10 + '0');
        *bufPtr++ = (t.m % 10 + '0');
      }
      *bufPtr++ = ((t.ms < 500) ? ' ' : ':');
      if ((t.ms < 500) && (configuring == 3) && !forced) {
        *bufPtr++ = ' ';
        *bufPtr++ = ' ';
      } else {
        *bufPtr++ = (t.s / 10 + '0');
        *bufPtr++ = (t.s % 10 + '0');
      }
      *bufPtr = 0;
      render(buf);
      CR_CCR = CR_CCR_IEN_C | CR_CCR_RFT_C;
      updating = 0;
    }
  }
  
  return;
  
}
