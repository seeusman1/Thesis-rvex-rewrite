int factorial(int i) {
  int r = 1;
  do {
    r *= i;
  } while (--i);
  return r;
}

int main(void) {
  int i;
  for (i = 1; i <= 12; i++) {
    ((int*)0)[i-1] = factorial(i);
  }
}
