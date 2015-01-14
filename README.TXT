--=============================================================================
-- Installation
--=============================================================================

To finish setting up the environment after cloning the git repo, copy or make
symlinks to the contents of the tools directory from the rvex release in
:/tools/. From this directory, you can do this from the command line as
follows:

(cd tools && ln -s <path to release dir>/tools/* .)

The path needs to be an absolute path or needs to be relative to the tools
directory, as the cd command would suggest. In addition, if you want to compile
generic binaries, you should have python3 installed and link vexparse in the
tools directory as well:

(cd tools && ln -s <path to vexparse>/vexparse)

Aside from all that, you should have Xilinx ISE 14.7 and Modelsim SE 10.2a.
DO NOT USE OLDER ISE VERSIONS: ISE 13.4 at least synthesizes the rvex core
incorrectly for some reason, causing it to behave erratically when stalls
occur.


--=============================================================================
-- Basic platform usage
--=============================================================================

There are currently four maintained platforms for the rvex. Their purpose and
a small tutorial for each is listed below. The tutorial assumes you're working
from this directory for simplicity (for those who don't know much about Linux).
Those people who do know about Linux should probably not do more than skim over
this and just run "make" from the platform directory to get more detailed but
less guided usage information.

-------------------------------------------------------------------------------
-- Unit test suite: :/platform/core-tests/
-------------------------------------------------------------------------------

This is a modelsim-only platform which runs unit tests on the rvex core. You
can run the simulation as follows:

(cd platform/core-tests && make sim)

You will need to have sourced your modelsim environment setup script before
doing so.
   
-------------------------------------------------------------------------------
-- Cache/specific program testbench: :/platform/cache-test/
-------------------------------------------------------------------------------
   
This is a simulation-only platform which runs the specified program (from
examples) on a platform with the default rvex processor and reconfigurable
cache. Its primary purpose is to test the cache in a controlled environment,
but it also works nicely to test rvex programs in a full core simulation.

(cd platform/cache-test && make vsim-<prog>)

You will need to have sourced your modelsim environment setup script before
doing so. The following command lists which program names are valid (among
other things):

(cd platform/cache-test && make)

-------------------------------------------------------------------------------
-- Standalone core design: :/platform/ml605-standalone
-------------------------------------------------------------------------------

This is a basic platform for the ML605 FPGA board containing only an rvex
core, the rvex debug support unit (UART) and some basic clock generation.
Here's a little tutorial to get you started, even if you're new to Linux.
(Those who do know how things work can figure out what the commands do for
themselves.)

To simulate the design, source your local Modelsim AND Xilinx ISE
environment setup scripts and run:

(cd platform/ml605-standalone && make vsim-x264)

Initialization may take up to a couple minutes due to the size of the loaded
program. You can change "x264" into whatever program you want to, or to
"none" if you don't need a program loaded into the memory. The following
command lists which program names are valid (among other things):

(cd platform/ml605-standalone && make)

To start Xilinx ISE in order to synthesize the design, make sure you have
sourced the Xilinx ISE startup script and run:

(cd platform/ml605-standalone && make ise-none)

Use the usual Xilinx ISE GUI design flow to synthesize the design and
program the board.

Once programmed onto the board using the Xilinx toolchain, you can load
program onto the board using the debug support unit. To do that, you first
need to start the rvsrv daemon, which provides a bridge between the hardware
and any scripted programs which may want to connect with it. You can start
the server as follows:

(cd platform/ml605-standalone && make server)

If rvsrv won't start because it can't open the serial port, which it
probably will, you'll need to change the configuration file. The file you're
looking for is :/tools/debug-interface/configuration.cfg. You can edit this
with any text editor. You need to change the SERIAL_PORT = line to the
serial port which rvsrv is to use. This will probably need to be ttyUSB0
since the ML605 board contains an USB to serial converter.

Once started, rvsrv will run in the background. To stop it, you can run the
following command (but you won't want to do this just yet):

(cd platform/ml605-standalone && make stop)

You should also set up the debugging environment at this point. Run the
following command:

(cd platform/ml605-standalone && make debug); source platform/ml605-standalone/debug

You can now run the rvd command to give commands to the board. Running rvd
without any parameters should tell you how to use it, so I won't get into
it here.

You can now upload the UART test program to the board to see if it works
using the following command:

(cd platform/ml605-standalone && make upload-uart)

If make complains that it can't find rvex-elf32-objcopy, running the
following command will probably do the trick:

(cd tools/build/bin && ln -s vex-objcopy rvex-elf32-objcopy)

The UART program will echo anything sent to it back in all-caps. To open a
UART terminal to communicate with the board, run:

(cd platform/ml605-standalone && make monitor)

You can press ctrl+C to exit the monitor program. Typing anything and
pressing enter will send it to the board; anything received from the board
will be shown in the terminal.

-------------------------------------------------------------------------------
-- GRLIB platform: :/platform/ml605-grlib
-------------------------------------------------------------------------------

This platform will run the rvex with instruction and data cache within a
grlib environment. It probably doesn't work yet, so I haven't made a tutorial
for it yet. Run "make" from the platform directory to get up-to-date usage
information.


--=============================================================================
-- Hacking the core
--=============================================================================

The rvex core files are located in :/lib/rvex/core. The code should be self-
documenting; there's a lot of comments in there. Start with core.vhd.

There's also work in progress on a manual, located in :/doc/core.pdf. If the
file doesn't exist or you want to rebuild it for some other reason, run make
from that directory.

If you change things, please try to keep at least the documentation in the
VHDL comments up-to-date. If you make permanent changes to the debugging
interface (i.e. the control register map), be sure to update the rvd memory map
definitions in :/tools/debug-interface/src/default-memory.map. The next time
you run any make command to do with rvd, you will be queried to commit the new 
you run any make currently active memory map.

-------------------------------------------------------------------------------
-- Adding/modifying control registers
-------------------------------------------------------------------------------

The steps below explain how to properly add control registers to the rvex core.
Modifying/removing registers follows the same steps, pretty much.

 1. Add the mnemonics for the new registers to
    lib/rvex/core/core_ctrlRegs_pkg.vhd. While you're there, you might want to
    look over the subprograms in that file which can be used to easily make
    certain types of registers.
    
 2. Define the logic for your new registers in:
     - lib/rvex/core/core_contextRegLogic.vhd for context-specific registers
     - lib/rvex/core/core_globalRegLogic.vhd for context-specific registers

 3. Register the new mnemonics in the following files:
     - platform/core_tests/design/core_tb.vhd (bottom of the file)
     - examples/src/rvex.h
     - tools/debug-interface/src/default-memory.map

--=============================================================================
-- Adding programs
--=============================================================================

Adding a basic program to be run on the rvex is easy. Simply add a c source
file in :/examples/src/ and add the program name to the EXECUTABLES variable in
:/examples/Makefile. All the platform makefiles eventually use that makefile
for compilation, so your program should run on all platforms by just doing
those things. You can test your program with xstsim using just the makefile in
:/examples, or you can run it in a full hardware simulation with one of the
platforms. The cache-test platform is the best one for the job.


