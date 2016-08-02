
#include "rvex.h"
#include "platform.h"

unsigned short buffer[256];

int main(void) {
  int i;
  
  for (i = 0; i < 256; i++) {
    buffer[i] = i;
  }
  
  plat_serial_puts(0, "Trying to write to CF...\n");
  if (!plat_cf_write(0, 1, buffer)) {
    plat_serial_puts(0, "  fail, sorry.\n");
    return 0;
  }
  
  for (i = 0; i < 256; i++) {
    buffer[i] = 0;
  }
  
  plat_serial_puts(0, "Trying to read from CF...\n");
  if (!plat_cf_read(0, 1, buffer)) {
    plat_serial_puts(0, "  fail, sorry.\n");
    return 0;
  }
  
  plat_serial_puts(0, "Verifying...\n");
  for (i = 0; i < 256; i++) {
    if (buffer[i] != i) {
      plat_serial_puts(0, "  fail, sorry.\n");
      return 0;
    }
  }
  
}

