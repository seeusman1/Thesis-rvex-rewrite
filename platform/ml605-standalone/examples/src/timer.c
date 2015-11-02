#include "rvex.h"
#include "rvex_io.h"
#include "asm_offsets.h"

// Trap argument codes for interrupts.
#define IRQ_RIT                   1  /* Repetitive Interrupt Timer */

#define INIT_MAGIC 0x123987

/*#define FASTSWITCH*/
/* Use DEFS=FASTSWITCH in makefile */

extern unsigned char* __STACK_START;
int initialized = 0;

#ifdef FASTSWITCH
#define TRAP_HANDLER_ROUTINE _smartswitch
extern void _smartswitch();
unsigned long scratch; /* used to free up a register in the trap handler routine */
unsigned long spills[4]; /* used to free up a register in the trap handler routine */

#else
#define TRAP_HANDLER_ROUTINE _dumbswitch
extern void _dumbswitch();
int current_task_id = 0;
unsigned int start_func_addr;
unsigned int saved_SPs[4];
#endif

static void main_loop(void);


static void panicHandler(void) {
  putchar(CR_CID + 'A');
  while (1);
}

volatile unsigned int next_task[4];
volatile unsigned int active_tasks = 0xF;

static void construct_task_list(void) {
  // Construct a circular linked list of the active tasks. Each next_task will
  // point to the next active task modulo 4, or itself if there are no more
  // tasks.
  int cur, next;
  for (cur = 0; cur < 4; cur++) {
    next = cur;
    while (1) {
      next = (next + 1) & 3;
      if ((next == cur) || (active_tasks & (1 << next))) {
        next_task[cur] = next;
        break;
      }
    }
  }
}

int main(void) {
  
  int task, i;
  unsigned int *p;

  // Initialize if we're hardware context 0. This is always true for the
  // software context switch version, but the other soft contexts should never
  // get here.
  if (!CR_CID) {
  
    // Construct the task list.
    construct_task_list();
    
#ifndef FASTSWITCH
    // Push initial context-restore stack frames onto the stacks of the other
    // tasks.
    for (task = 1; task < 4; task++) {
      
      // Initialize the stack pointer.
      saved_SPs[task] = ((unsigned int)&__STACK_START) - task*0x1000;
      
      // Allocate the frame.
      saved_SPs[task] -= TRACEREG_SZ;
      
      // Initialize the frame with zeros.
      p = (unsigned int *)(saved_SPs[task]);
      for (i = 0; i < TRACEREG_SZ/4; i++) {
        *p++ = 0;
      }
      
      // Set the initial PC to the address of main_loop().
      p = (unsigned int *)(saved_SPs[task]);
      *(p + PT_PC/4) = (unsigned int)&main_loop;
      
    }
#endif
  }
  
  // Setup trap and panic handler and enable interrupts. Each hardware context
  // needs to do this.
  CR_TH = (unsigned int)&TRAP_HANDLER_ROUTINE;
  CR_PH = (unsigned int)&panicHandler;
  CR_CCR = (CR_CCR_RFT | CR_CCR_IEN);
  
  // Perform the task.
  main_loop();
  
}

static void main_loop(void) {
  int task;
  
  // Determine which task we are.
#ifdef FASTSWITCH
  task = CR_CID;
#else
  task = current_task_id;
#endif
  
  // Process our task.
  switch (task) {
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
  
  // Disable timer interrupt so we can poke around in the task switch
  // structures without potentially breaking things.
  CR_CCR = CR_CCR_IEN_C;
  
  // Unregister our task from the active tasks bitfield.
  active_tasks &= ~(1 << task);
  
  // If there are still other active tasks, reconstruct the task switch linked
  // list (this can be done more efficiently but it's nice and easy this way)
  // and call the task_complete() assembly method, which will cause a soft trap
  // in a while loop to trigger a task switch.
  if (active_tasks) {
    construct_task_list();
    task_complete();
  }
  
  // All tasks are complete.
  puts("\n");
  
  // Call the all_complete() assembly method, which will execute the STOP
  // instruction.
  all_complete();
  
}

