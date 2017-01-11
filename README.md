
Installation
============

You will need at least the following things (this list is probably not
complete):

 - A linux environment. Cygwin may work kind of, but there's a lot of symlinks
   which you would need to handle somehow.
 - Xilinx ISE 14.7 for the Virtex-6 platforms (older versions are known to
   synthesize some things incorrectly) and/or Vivado 2015.4 for the Virtex-7
   platforms (other versions may work as well).
 - Modelsim. The system is tested using version SE 10.2a; older versions are
   known to crash when simulating the core.
 - Python 3.x
 - GNU make, GCC, diff/patch, wget, and probably some of the other usual dev
   tools.

All the ρ-VEX specific things should™ work out of the box; they either come
precompiled or are simple C programs without any external dependencies. Some
things (for instance grlib) are not part of the release archive itself, but
will be downloaded from the TU Delft FTP automatically when referred to by the
makefiles.


Directory structure
===================

This section describes the directory structure of the ρ-VEX release in no
particular order.


doc/
----

This directory contains the ρ-VEX user manual, its LaTeX sources, and any other
documentation we have. The user manual is special in that parts of it are
auto-generated based on configuration files. That is, if you for instance change
the ρ-VEX control registers or move opcodes around, the user manual should
update accordingly (assuming, of course, that the inline documentation in the
configuration files is kept up-to-date).


lib/
----

This directory contains the VHDL code of the ρ-VEX and peripherals.


grlib/
------

This directory contains logic to download the right version of the grlib GPL
hardware IP library from the TU Delft FTP, and patch it to allow it to use the
ρ-VEX.


config/
-------

This directory contains configuration files for some key components of the core.
The idea is that these files can be used to generate as many different things as
possible.

Running make will first of all patch source code. Then it will try to regenerate
the PDF documentation, which may fail if you don't have LaTeX along with all the
packages that are used.

The scripts and templates folders contain the source files needed to generate
everything. The other folders contain the actual configuration files (.tex or
.ini files).


platform/
---------

This directory contains a number of hardware and simulation systems that use the
ρ-VEX in some way. A non-exhaustive list is given in the "platforms" section.


test-progs/
-----------

TODO


tools/
------

TODO


versions/
---------

TODO


Platforms
=========

This section lists some of the provided ρ-VEX, along with some basic usage
instructions. For more informations on these platforms or the undocumented ones,
running make without an argument should always list the available commands.
Reading the makefiles and HDL sources is the next best thing.

simrvex
-------

This "platform" encapsulates the simrvex architectural simulator. simrvex is
very fast in comparison to modelsim, running at similar speeds as an ρ-VEX core
at ~10MHz. To simulate a program, do the following.

    $ cd platform/simrvex
    $ make sim-<test program name>

There is also a command that batch runs a number of test programs at once to
check if they run correctly:

    $ make simtestall


core-tests
----------

This simulation-only platform serves as a basic conformance test for the ρ-VEX
core. The conformance test is run as follows:

    $ cd platform/core-tests
    # source Modelsim environment script
    # source Xilinx ISE 14.7 or Vivado environment script
    $ make conformance -j

This will eventually return a pass or fail in the console. Log files for each
tested core configuration are saved in the calling directory. If some tests
fail, the conformance test can be run in the Modelsim GUI as follows:

    $ cd <core configuration directory>
    $ make vsim

The simulation will start automatically, with the ρ-VEX debug output and some
outputs from the conformance test runner added to the waveform for debugging.


cache-test
----------

This simulation-only platform is used to test the ρ-VEX cache, and may be used
to debug simple ρ-VEX applications using Modelsim. The process is as follows:

    $ cd platform/cache-test
    # source Modelsim environment script
    # source Xilinx ISE 14.7 or Vivado environment script
    $ make vsim-<test program name>

Test program name must be set to the test program that you want to use. Running
make with no argument will among other things list the known programs. The
fastest realistic program is named ucbqsort-fast.

Make will first compile the program using the default compiler configuration.
It will then start the Modelsim GUI. The simulation itself is not started
automatically, allowing you to add whatever signals you want. The most commonly
used signal is rv2sim. You can then start simulating using the run command.

    VSIM x> add wave sim:/testbench/rvex_inst/rv2sim
    VSIM x> run 100 ms

Serial/debug output from the program is piped to the transcript, so after some
time, you should see (for instance) the following appear:

    # ucbqsort-fast: success

You can change the core and cache configuration in design/testbench.vhd using
the RCFG and CCFG constants. If you've changed only VHDL and want to restart
the simulation, you can run

    VSIM x> do sim.do

to restart; otherwise, you should close Modelsim and run make again. Note that
significantly different configurations may require different compiler flags.
These are NOT automatically inferred. Check out test-progs/Makefile in the root
of the repository (the local platform-specific version links to the generic
version) for more information. Don't forget to clean when changing compiler
flags, make won't detect that and rebuild by itself.


ml605-standalone and vc707-standalone
-------------------------------------

These platforms consist of an ρ-VEX core, separate local memories for
instruction and data using block RAMs, a UART debug interface, and optionally a
cache (only useful for testing - the block RAMs are single cycle already unless
too many accesses are done at once). The block RAMs can be preloaded with a test
binary during synthesis, or they can be loaded dynamically using the debug
interface. The platforms are intended to be used for the ML605 and VC707
development boards from Xilinx respectively, but they should be easy to port to
different boards.

### Simulation

Starting a simulation using Modelsim works the same as it does in cache-test.
That is:

    $ cd platform/<board>-standalone
    # source Modelsim environment script
    # source Xilinx ISE 14.7 or Vivado environment script
    $ make vsim-<test program name>

Unlike cache-test, the standalone platforms will automatically add some signals
to the waveform to do with testing reconfiguration and interrupts, as well as
the usual rv2sim signal. Note that the signal paths differ between the cached
and no-cache versions. The do file will try to add both versions, so you will
always see errors in the transcript that you can safely ignore. The simulation
is started and application output is reported as follows:

    VSIM x> run 100 ms
    # Application UART: ucbqsort-fast: success

The toplevel VHDL file and simulation testbench are located in the design
folder. Particularly, the core and cache configuration can be changed at the
top of the architecture in ml605.vhd. Furthermore, if you want to test the debug
serial port, ml605_tb.vhd contains some commented-out code to help with that.
Like in cache-test, if you change any VHDL code you can restart the simulation
as follows:

    VSIM x> do sim.do

However, if you change C code you will need to run the make command again.

### Synthesis for ML605

There are two ways to synthesize ml605-standalone: manually through the ISE GUI
or directly from the command line. The latter will automatically assign a
version tag to the system and archive the sources, synthesis settings, and
accompanying synthesis results, which the GUI will not, but the GUI allows you
to change settings in a more intuitive way. Also, the automated scripts will
extract the VHDL file list from the GUI project. Therefore, let's start with the
GUI method.

To launch ISE, do the following:

    $ cd platform/ml605-standalone
    # source Xilinx ISE 14.7 environment script
    $ make ise[-<test program name>]

The program name is optional. If none is provided, the block RAMs will be
initialized with zeros. You can now synthesize the platform as you would
anything else.

Synthesis from the command line works as follows:

    $ cd platform/ml605-standalone
    # source Xilinx ISE 14.7 environment script
    $ make synth[-<test program name>]

This generates a working directory of the form `synth-<timestamp>`, which
contains a copy of all the design files. This allows you to continue developing
while running synthesis, or to run synthesis for different configurations
simultaneously. When synthesis completes, you will see something like this:

    ############################################################################
    # Build complete and archived!
    # Archive file: ml605-standalone-w-ckpTv-<...>-core-L9TgS-t.tar.gz
    # Stored in: <r-VEX install path>/versions/platforms
    ############################################################################

The archive file that it refers to contains the following:

 - the generated bit file
 - all VHDL source files and the constraints file
 - synthesis settings
 - Xilinx logs

The name of the archive is derived from the platform version tag (in this case
`w-ckpTv`) and the core version tag (in this case `L9TgS-t`). The platform
version tag this platform is a hash of all the source and configuration files.
The core version tag is an intelligent hash of the files in lib/rvex/core that
ignores changes in VHDL comments. These tags are baked into the generated
hardware and can be read out using the serial debug interface, allowing an
unidentified bit file to be retraced to its source files.

### Synthesis for VC707

There is currently no command-line synthesis option for the VC707, you need to
use the Vivado GUI. You can start the GUI as follows:

    $ cd platform/vc707-standalone
    # source Vivado environment script
    $ make vivado[-<test program name>]

The program name is optional. If none is provided, the block RAMs will be
initialized with zeros. You can now synthesize the platform as you would
anything else.

### Using the FPGA design

You can communicate with the processor using rvd. Refer to the section on rvd
and rvsrv below for more information.


ml605-grlib, ml605-grlib-bare, and ml605-doom
---------------------------------------------

These platforms are various systems that use the GRLIB GPL hardware IP library
as peripherals. Roughly:

 - ml605-grlib is a very basic port of the ML605 LEON3 example platform from
   GRLIB. It essentially replaces the quad-core version of the platform with a
   single cached quad-context reconfigurable ρ-VEX using bus bridges and an
   interrupt controller bridge, and replaces the primary GRLIB serial peripheral
   with the ρ-VEX debug serial peripheral.

 - ml605-bare is a modified version of ml605-grlib where almost all peripherals
   except for the JTAG and DDR controller are removed, in an attempt to speed up
   synthesis time.

 - ml605-doom is the platform that we use internally for our demos. It has a
   toplevel file that is written from scratch instead of being derived from the
   LEON3 example project, with the following peripherals:
    - DDR memory
    - GRLIB interrupt controller
    - Four timers
    - VGA output
    - Mono PWM audio output
    - Two PS/2 interfaces
    - 3 I2C interfaces (VGA/DVI, PMbus, external)
   The PS/2 and external I2C interfaces are broken out using the LCD connector,
   so it is advisable to remove the LCD. The audio output is done using one of
   the LEDs and its associated header pin.

The platforms all work in the same way. A patch file is provided that can be
applied to the LEON3 example project from GRLIB to turn the example project into
the ρ-VEX platform. The scripts take care of this for you:

    $ cd platform/<platform name>
    $ make work

This generates the `work` directory that contains most project files. You can
update the patch file if need be using:

    $ make update-patch

Finally, you can completely clean everything, INCLUDING any changes made to the
work directory, using:

    $ make very-clean

That basically just deletes the work directory entirely.


### Simulation

### Synthesis








OLD STUFF BELOW HERE, TODO
=======================================================================================================





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
can run the test suite in command line mode as follows:

(cd platform/core-tests && make -j conformance)

You will need to have sourced your modelsim environment setup script before
doing so. Should a test case fail, you'll probably want to run modelsim in GUI
mode to see why; to do this, start the simulation as follows instead:
   
(cd platform/core-tests/<configuration> && make vsim)

You will need to replace <configuration> with the core configuration which you
want to test. The following command lists the valid configurations:

(cd platform/core-tests && make list-configs)

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

(cd platform/ml605-standalone && make vsim-ucbqsort-fast)

Initialization may take up to a couple minutes due to the size of the loaded
program. You can change "ucbqsort-fast" into whatever program you want to, or
to "none" if you don't need a program loaded into the memory. The following
command lists which program names are valid (among other things):

(cd platform/ml605-standalone && make)

You have two options to synthesize the design. You can either do it manually
in the Xilinx ISE GUI, or from the command line. To launch the GUI, make sure
you have sourced the Xilinx ISE startup script and run:

(cd platform/ml605-standalone && make ise-none)

Use the usual Xilinx ISE GUI design flow to synthesize the design and
program the board.

To synthesize from the command line, use the following command.

(cd platform/ml605-standalone && make synth-none NAME=<name>)

Substitute <name> with something arbitrary but unique. <name> will be used to
generate a build directory, so you can run the synthesis tools multiple times
in parallel. The VHDL source files are copied into the build directory
immediately after the command is given, so you can safely modify the sources
without messing up an ongoing synthesis run. By the way, if you don't want to
have to get creative with names, you can ommit the whole NAME=<name> part, in
which case the current timestamp will be used instead.

To program a synthesized design to the ML605 development board, run the
following:

(cd platform/ml605-standalone && make prog-<name>)

You will need to substitute <name> with the same thing you specified when
synthesizing. Alternatively, if you want to program the FPGA manually, the bit
file is stored in platform/ml605-standalone/synth-<name>/routed.bit.

Once the FPGA has been configured, you can load a program onto the board using
the debug support unit. To do that, you first need to start the rvsrv daemon,
which provides a bridge between the hardware and any scripted programs which
may want to connect with it. You can start the server as follows:

(cd platform/ml605-standalone && make server)

If rvsrv won't start because it can't open the serial port, which it
probably will, you'll need to change the configuration file. The file you're
looking for is tools/debug-interface/configuration.cfg. You can edit this
with any text editor. You need to change the SERIAL_PORT = line to the
serial port which rvsrv is to use. This will probably need to be ttyUSB0
since the ML605 board contains an USB to serial converter.

Once started, rvsrv will run in the background. To stop it, you can run the
following command (but you won't want to do this just yet):

(cd platform/ml605-standalone && make stop)

You should also set up the debugging environment at this point. Run the
following commands:

(cd platform/ml605-standalone && make debug)
source platform/ml605-standalone/debug

You can now run the rvd command to give commands to the board. Running rvd
without any parameters should tell you how to use it.

You can now upload the UART test program to the board to see if it works
using the following command:

(cd platform/ml605-standalone && make upload-uart)

The UART program will echo anything sent to it back in all-caps. To open a
UART terminal to communicate with the board, run:

(cd platform/ml605-standalone && make monitor)

You can press ctrl+C to exit the monitor program. Typing anything and
pressing enter will send it to the board; anything received from the board
will be shown in the terminal.

The platform makefile and rvd support a lot more than what's specified here.
For more information, run:

(cd platform/ml605-standalone && make)

-------------------------------------------------------------------------------
-- GRLIB platform: :/platform/ml605-grlib
-------------------------------------------------------------------------------

This platform contains the rvex with instruction and data cache within a grlib
environment. It is based on the leon3mp example project from grlib. A lot of
the commands for this platform are virtually identical to those in the
ml605-standalone platform (just substitute standalone with grlib), so I'm only
going to note the differences.

First of all, simulation. The command is the same. However, if you're going to
restart simulation after only changing VHDL files, you'll probably want to use
"resim" instead of "vsim" to save a bit of time. Also, the startup script is
set up such that it will automatically run the DDR3 controller initialization
procedure and save a checkpoint before giving you control. When you would
normally restart simulation (for example because you forgot to add some signal)
you should in stead run the following TCL command in modelsim:

restore modelsim/cpt

This will restore the simulation state to just after the DDR controller
initialization.

Secondly, synthesis. This can only be done from the command line, as follows:

(cd platform/ml605-grlib && make synth)

You can't run multiple synthesis runs at the same time like in the standalone
platform. If you want to do that, you'll probably need to make copies of the
entire tree.

There is no special command to program the FPGA at this time. Instead, run

impact

and load the bit file from platform/ml605-grlib/work/leon3mp.bit manually.

Finally, the program uploading and debugging commands are similar to the
standalone platform.

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


