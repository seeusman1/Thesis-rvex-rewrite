
#define BASE 0x12340000
#define CREG 0xFFFFFC00

int main(void) {
  
  // Read pointers to the relevant control registers (these are set by the test
  // runner; normally these pointers would be fixed and put in a header).
  unsigned char *CR_CID = (*((unsigned char**)BASE)) + CREG;
  
  // Read our context ID.
  int me = *CR_CID;
  
  // Signal our presence.
  *((volatile unsigned char*)(BASE + 8 + me)) = *((volatile unsigned char*)(BASE + 4 + me));
  
  return 1;
  
}
