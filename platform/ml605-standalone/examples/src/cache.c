#include "common.h"

// This program runs qurt for 5 seconds and then runs jpeg for 5 seconds,
// assuming 10 MHz clock and then stops. It is written such that resetting
// the rvex with GSR will restart execution. Don't use any other means of
// resetting; if you do this CR_CNT won't be properly initialized, which is
// used for the timing.
//
// Whenever a RIT timer interrupt occurs, the core reconfigures, switching
// between two configurations. The way in which this is done depends on the
// values in the following memory locations (they should map to the last four
// words of the data memory):
//   0x3FFFFFF0: configuration A
//   0x3FFFFFF4: configuration B
//   0x3FFFFFF8: -1     -> interrupt and program in cx0
//               others -> interrupt in cx0, program in cx1
//                         wakeup configuration A
//   0x3FFFFFFC: wakeup configuration B
//
// Example A: switch between group 0 and groups 2:3 with a single hwctxt
//   0x3FFFFFF0: 0x8880
//   0x3FFFFFF4: 0x0088
//   0x3FFFFFF8: -1
//   0x3FFFFFFC: don't care
//
// Example B: same as above, but use a different hwctxt for handling the
// interrupt
//   0x3FFFFFF0: 0x8881
//   0x3FFFFFF4: 0x1188
//   0x3FFFFFF8: 0x8808
//   0x3FFFFFFC: 0x8808
//
// Example C: same as above, but without actually interrupting the benchmarks
//   0x3FFFFFF0: 0x8881
//   0x3FFFFFF4: 0x1188
//   0x3FFFFFF8: 0x8801
//   0x3FFFFFFC: 0x1108
//
// The purpose of the program is to test cache + reconfiguration performance.
//
// Wait for completion by sleeping; with fast interrupt rates it may not finish.
//
// The following registers are (ab)used for returning information:
//   c0 CR_RSC1:  number of interrupts serviced
//   c0 CR_RET:   0x00 -> finished
//                0x01 -> execution error in qurt
//                0x02 -> execution error in jpeg
//                0xFF -> did not finish
//   cx CR_SCRP1: number of qurt runs
//   cx CR_SCRP2: number of cycles spent on qurt runs
//   cx CR_SCRP3: number of jpeg runs
//   cx CR_SCRP4: number of cycles spent on jpeg runs
//
// x = the context that runs the benchmarks; depends on the values in
//   0x3FFFFFF0..0x3FFFFFFB

volatile long *config = 0x3FFFFFF0;
#define CONFIG_A      config[0]
#define CONFIG_B      config[1]
#define CONFIG_X(i)   config[i]
#define USE_WAKE      (config[2] >= 0)
#define WAKE_CFG_A    config[2]
#define WAKE_CFG_B    config[3]
#define WAKE_CFG_X(i) config[i+2]

int run_qurt_once(void);
int run_jpeg_once(void);
void _stop(void);
void interrupt(int id);
void _wakeup_trap_handler(void);
volatile char state;

volatile int current_mode;

void consistency_check(void);

int main(void) {
	
	long start;
	
	state = 0;
	
	// Skip ahead to running the program if we're in a context other than 0.
	if (!CR_CID) {
		
		CR_RSC1 = 0;
		
		// Set the current configuration to A.
		current_mode = 0;
		
		// In wakeup mode: wait for the first timer interrupt (it will already
		// be pending because it is free running before the core is reset).
		if (USE_WAKE) {
			
			// Wait for the first timer interrupt.
			CR_TH = (long)_wakeup_trap_handler;
			CR_CCR = CR_CCR_IEN | CR_CCR_RFT;
			while (1);
			
		}
		
		// Normal mode. Reconfigure to the first configuration.
		CR_CRR = CONFIG_A;
		while (CR_GSR & CR_GSR_B_MASK);
		
		// Enable interrupts.
		CR_CCR = CR_CCR_IEN | CR_CCR_RFT;
		
	}
	
	//puts("Cons...");
	//consistency_check();
	//puts("FAIL");
	
	// Run qurt.
	puts("\n\nQurt... ");
	start = CR_CNT;
	while (CR_CNT < 50000000) {
		if (run_qurt_once()) {
			puts("\nQurt failed!\n");
			state = ~1;
			CR_RET = 1;
			_stop();
		}
		puts("q");
		CR_SCRP1++;
	}
	CR_SCRP2 = CR_CNT - start;
	
	// Run jpeg.
	puts("\nJPEG... ");
	start = CR_CNT;
	while (CR_CNT < 100000000) {
		if (run_jpeg_once()) {
			puts("\nJPEG failed!\n");
			state = ~2;
			CR_RET = 2;
			_stop();
		}
		puts("j");
		CR_SCRP3++;
	}
	CR_SCRP4 = CR_CNT - start;
	
	// Complete.
	puts("\nDone!\n");
	state = ~0;
	CR_RET = 0;
	_stop();
	
}

// Timer interrupt in normal mode.
void interrupt(int id) {
	
	// Record the number of interrupts serviced.
	CR_RSC1++;
	
	// Toggle configuration.
	current_mode = !current_mode;
	CR_CRR = CONFIG_X(current_mode);
	
}

// Timer interrupt in wakeup mode.
void wake_interrupt(void) {
	
	// Stop context 0 as well if context 1 completes.
	if (state) {
		CR_RET = ~state;
		_stop();
	}
	
	// Record the number of interrupts serviced.
	CR_RSC1++;
	
	// Toggle configuration.
	current_mode = !current_mode;
	
	// Enable the wakeup system.
	CR_WCFG = WAKE_CFG_X(current_mode);
	CR_SAWC = 1;
	
	// Reconfigure.
	CR_CRR = CONFIG_X(current_mode);
	
	// Wait for interrupt by waiting until a wakeup is triggered.
	while (CR_SAWC & CR_SAWC_S_MASK);
	
	// Enable interrupts and wait for it to be serviced.
	CR_CCR = CR_CCR_IEN | CR_CCR_RFT;
	while (1);
	
}
