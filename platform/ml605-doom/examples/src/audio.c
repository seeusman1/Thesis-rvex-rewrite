
#define DATA (*((volatile unsigned char *)(0xD2000000)))
#define COUNT (*((volatile unsigned int *)(0xD2000000)))

int main(void) {
  
  int state = 0;
  int val = 0;
  
  while (1) {
    while (COUNT > 64);
    while (COUNT < 128) {
      state+=5;
      if (state >= 510) {
        state -= 510;
      }
      if (state > 255) {
        val = 510 - state;
      } else {
        val = state;
      }
      DATA = (unsigned char)val;
    }
  }
  
}
