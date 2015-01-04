To finish setting up the environment after cloning the git repo, copy or make
symlinks to the contents of the tools directory from the rvex release in
:/tools/. From this directory, you can do this from the command line as
follows:
   
(cd tools && ln -s <path to release dir>/tools/* .)
   
The path needs to be an absolute path or needs to be relative to the tools
directory, as the cd command would suggest.
   
There are currently 3 "platforms" for the rvex:


 - Unit test suite: :/platform/core-tests/
   
   This is a modelsim-only platform which runs unit tests on the rvex core. You
   can run the simulation as follows:
   
   (cd platform/core-tests && make sim)
   
   You will need to have sourced your modelsim environment setup script before
   doing so.
   
   
 - Standalone core design: :/platform/ml605-standalone
   
   This is a basic platform for the ML605 FPGA board containing only an rvex
   core, the rvex debug support unit (UART) and some basic clock generation.
   Here's a little tutorial to get you started, even if you're new to Linux.
   (Those who do know how things work can figure out what the commands do for
   themselves.)
   
   To open the design, source your local Xilinx ISE environment setup script
   and run:
   
   (cd platform/ml605-standalone/ise && ise rvex-rewrite.xise)
   
   The ISE project can be used to synthesize the core and simulate it (kinda)
   using ISIM; there is no decent testbench yet, nor is there a modelsim
   environment for this platform.
   
   Once programmed onto the board using the Xilinx toolchain, you can load
   program onto the board using the debug support unit. To do that, you first
   need to start the rvsrv daemon, which provides a bridge between the hardware
   and any scripted programs which may want to connect with it. You can start
   the server as follows:
   
   (cd tools/debug-interface && make server)
   
   If rvsrv won't start because it can't open the serial port, which it
   probably will, you'll need to change the configuration file. The file you're
   looking for is :/tools/debug-interface/configuration.cfg. You can edit this
   with any text editor. You need to change the SERIAL_PORT = line to the
   serial port which rvsrv is to use. This will probably need to be ttyUSB0
   since the ML605 board contains an USB to serial converter.
   
   Once started, rvsrv will run in the background. To stop it, you can run the
   following command (but you won't want to do this just yet):
   
   (cd tools/debug-interface && make stop)
   
   You should also set up the debugging environment at this point. Run the
   following command:
   
   (cd tools/debug-interface && make debug); source tools/debug-interface/debug
   
   You can now run the rvd command to give commands to the board. Running rvd
   without any parameters should tell you how to use it, so I won't get into
   it here.
   
   You can now upload the UART test program to the board to see if it works
   using the following command:
   
   (cd platform/ml605-standalone/examples && make uart-upload)
   
   If make complains that it can't find rvex-elf32-objcopy, running the
   following command will probably do the trick (naming conventions yay):
   
   (cd tools/build/bin && ln -s vex-objcopy rvex-elf32-objcopy)
   
   The UART program will echo anything sent to it back in all-caps. To open a
   UART terminal to communicate with the board, run:
   
   (cd tools/debug-interface && make monitor)
   
   You can press ctrl+C to exit the monitor program. Typing anything and
   pressing enter will send it to the board; anything received from the board
   will be shown in the terminal.
   
   To make a new, basic program for the platform, go to
   :/platform/ml605-standalone/examples/src in a file browser and make a new
   .c file. The name of the .c file will be the name of the program. You can
   use the uart.c file as an example. Note that <stdio.h> and the likes don't
   work (yet).
   
   When done, compile and upload your program in the same way that you uploaded
   the UART program, but replacing uart-upload with <your c file name>-upload.
   
   
 - GRLIB platform: :/platform/ml605-grlib
   
   This platform will run the rvex with instruction and data cache within a
   grlib environment. It doesn't work yet, but the grlib stuff is set up
   properly now, so the simulation runs at least. You can run the following
   command (after sourcing the xilinx and modelsim environment setup scripts
   for ISE 13.4 and Modelsim 10.2a) to run the simulation. It'll take a while
   for it to set everything up, but should eventually launch modelsim:
   
   cd platform/ml605-grlib && make sim
   
   Or you can run the following command to just set up the environment and
   dump some readme files to the console:
   
   cd platform/ml605-grlib && make && cat work/README.txt
   
   Note that you'll need to prefix all make targets with gr- if you're using
   the makefile in platform/ml605-grlib.
   
   