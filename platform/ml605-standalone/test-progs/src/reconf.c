#include "rvex.h"
#include "rvex_io.h"

static void panicHandler(void) {
  putchar(CR_CID + '0');
  while (1);
}

int main(void) {
  
  // Setup the panic handler.
  CR_PH = (unsigned int)&panicHandler;
  
  // Perform a different task in each context.
  while (1) {
    switch (CR_CID) {
        case 0:
        mainengine();
        break;
        
        case 1:
        mainmatrix();
        break;
        
        case 2:
        maindes();
        break;
        
        case 3:
        mainblit();
        break;
    }
  }
  
}
