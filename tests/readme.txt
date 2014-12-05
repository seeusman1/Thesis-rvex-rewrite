This directory contains test suites for rvex_tb.vhd. rvex_tb will read the
index.suite file (by default) and will then open the *.test files listed in it
one by one and run them. The simulation will report notes for successful tests
and errors for failed tests. Of course you can also trace any signal in the
rvex to see what went wrong.

index.suite
-----------
index.suite is just a *.test file listing. The simulation will parse any
nonempty line which does not start with -- as a filename relative to the path
to index.suite. If it fails to open a file, it will report a warning.

*.test
------
These files specify a test case for the processor. Every line which is nonempty
or does not start with -- will be parsed as one of the commands below. If
parsing fails, the simulation will report a warning. All available commands are
listed below. They are case insensitive. Valid numeric data entry methods are
listed below that.

Valid test commands
-------------------
name <name>
  Sets the name of the test case. This is shown in simulation and in all
  related simulation report statements. When name is not set, it defaults to
  the filename.

config <key> <value> [<mask>]
  Fail if the specified key in CFG has a different value. <mask> specifies an
  optional bitmask (useful in particular for numContexts). Boolean keys should
  be matched against 0 or 1. Available keys are:
   - numLanes
   - numLaneGroups
   - numContexts
   - genBundleSize
   - multiplierLanes
   - memLaneRevIndex
   - branchLaneRevIndex
   - numBreakpoints
   - forwarding
   - limmhFromNeighbor
   - limmhFromPreviousPair
   - reg63isLink
   - cregStartAddress

init imem <imem size> dmem <dmem size>
  Initializes the instruction and data memories with all zeros. The sizes
  specify the desired sizes of the instruction and memories in number of WORDS.
  Also sets instruction memory loading pointer to 0.

at <ptr>
  Set instruction memory loading pointer to the given value.

load <assembly syllable>
  Assemble <assembly syllable> and load into instruction memory at the loading
  pointer, then increment the loading pointer. Assembly syntax is based upon
  the syntax fields in rvex_opcode_pkg.vhd.

loadhex <value>
  Same as load, but without the assembly step; just loads the given value into
  the instruction memory.

fillnops <ptr>
  Same as at, but inserts NOPs from the current loading pointer up to <ptr>.

wait <cycles> [memw <ptr> [or fail] [<value> [or fail]] | meml <ptr> [or fail]]
  Waits for at least <cycles> cycles. If memw or meml is not specified, the
  wait will succeed, otherwise it will fail unless a memory write or memory
  load to the specified location occurs within that time. When the expected
  memory write/load occurs, execution will continue without waiting for the
  timeout. If "or fail" is specified after the address, any write/read to
  ANOTHER address will cause failure. Same logic applies to the value. The
  checks are insensitive to which memory port requested the operation or to the
  access size.

write [dbg] <word|half|byte> <ptr> <value>
read [dbg] <word|half|byte> <ptr> <expected>
  Set memory at <ptr> to <value> or check that the value at that location is
  <expected>. If dbg is specified, the debug bus is accessed instead of the
  data memory, which takes a cycle to complete.

fault <set|clear> <imem|dmem> <ptr>
  Marks the given memory location as faulty or clears the marking. When a fauly
  memory location is accessed, the fault signal to the rvex will be asserted.

rctrl <ctxt> int <id>
  Assert irq pin for context <ctxt> with irqID set to <id>. The irq pin is
  released automatically when irqAck goes high.

rctrl <ctxt> reset
  Resets the specified context. Takes one cycle to complete.

rctrl <ctxt> halt
  Releases the run flag for the specified context.

rctrl <ctxt> run
  Asserts the run flag for the specified context.

rctrl <ctxt> chk [not] <idle|done|irq>
  Ensures that the given context is (not) idle/done, fails otherwise.

reset
  Resets the entire processor. Waits for a couple cycles to ensure 

Numeric data entry
------------------
Numerical values may be specified as follows:
 - In decimal.
 - In hexadecimal, by prefixing the number with 0x.
 - In binary, by prefixing the number with 0b.
 - As any CR_* word address (rvex_ctrlRegs_pkg), which will be converted to
   a byte address relative to address 0. This is useful for debug bus accesses.

