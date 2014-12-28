#include "_basic_io.h"

int main(void) {
  unsigned char c;
  while (1) {
    c = getchar();
    if ((c >= 'a') && (c <= 'z')) {
      c += 'A' - 'a';
    }
    putchar(c);
  }
}
