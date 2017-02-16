
Installation
============

You will need at least the following things (this list is probably not
complete):

 - A Linux environment. We use various versions of OpenSuSE in Delft. Cygwin
   may work kind of, but there's a lot of symlinks which you would need to
   handle somehow, and it has not been tested in any way for over a year.
 - Several GB of storage.
 - Xilinx ISE 14.7 for the Virtex-6 platforms (older versions are known to
   synthesize some things incorrectly) and/or Vivado 2015.4 for the Virtex-7
   platforms (other versions may work as well).
 - Modelsim. The system is tested using version SE 10.2a; older versions are
   known to crash when simulating the core.
 - Python 3.x
 - GNU make, GCC, diff/patch, wget, netcat, and probably some of the other usual
   dev tools.
 
If you would like to rebuild the toolchain from source (this can be done 
automatically from the tools/build-dir directory), you will need the following
packages:

 - For binutils:
   - binutils-devel
 - Additionally, for sim-rVEX:
   - binutils-devel
   - libX11
   - libX11-dev
   - libxpm
   - libxpm-dev

If you want to be able to (re)generate the documentation, you also need:

 - LaTeX, with these nonstandard packages:
    - import.sty
    - multirow.sty
    - tabto.sty
    - todonotes.sty
 - Perl

All the ρ-VEX specific things should™ work out of the box; they either come
precompiled or are simple C programs without any external dependencies. Some
things (for instance grlib and various source files) are not part of the release
archive itself, but will be downloaded from the TU Delft FTP automatically when
needed.


Quickstart tutorial: running your first ρ-VEX program
=====================================================

This section is a brief tutorial on how to run a program on the ρ-VEX. If
everything works as it should, this shouldn't take more than half an hour.
We will be using the program `ucbqsort` from the Powerstone benchmark suite,
and run it using simrvex, Modelsim, and (if you have an ML605) ml605-standalone.

Architecture simulation with simrvex
------------------------------------

Open a terminal and run the following commands. Only type the lines starting
with a `$` sign, without actually typing the `$`, and replace `<root>` with the
directory that contains this file.

    $ cd <root>/platform/simrvex
    $ make trace-ucbqsort
    ...
    ucbqsort: success

A framebuffer window will also be opened, which is not used by this program.
Press enter *in the terminal* to exit the simulator.

The `ucbqsort: success` line is produced by the ρ-VEX: specifically by the
`rvex_succeed("ucbqsort: success\n");` line in
`<root>/test-progs/src/ucbqsort.c`. Aside from showing the debug output, the
`trace` target also generates a trace file:
`<root>/platform/simrvex/test-progs/simtrace-ucbqsort`. This is a text file
with the full instruction trace of the program.


HDL simulation with Modelsim
----------------------------

To do a basic simulation in Modelsim, we will use the `cache-test` platform.
We will use the program `ucbqsort-fast` instead of `ucbqsort` here to speed up
simulation; `ucbqsort-fast` does exactly the same, but has a smaller input size.
If you don't mind waiting a little longer, you can of course use `ucbqsort` as
well. Xilinx ISE or Vivado is needed for its `unisim` and `unimacro` simulation
files.

    $ cd <root>/platform/cache-test
    # make sure that Modelsim is in $PATH
    # source Xilinx ISE 14.7 or Vivado environment script (settings64.sh)
    $ make vsim-ucbqsort-fast

This will launch the Modelsim GUI. This platform does not add any signals to the
waveform view by default, so let's add a useful signal now:

    VSIM 2> add wave sim:/testbench/rvex_inst/rv2sim

This is a simulation-only signal consisting of an array of strings that
represent what the ρ-VEX is doing. Its output is similar to the trace output
from simrvex, except embedded in the waveform view. The timing of the status
signal corresponds to the last pipeline stage of the core.

Now that we have the signal, we can run the simulation. `ucbqsort-fast` takes
about 100 microseconds simulation-time with the default compiler configuration.

    VSIM 2> run 100 us
    # ucbqsort-fast: success

As you can see, the debug output of the program is piped to the Modelsim
transcript, just like how the debug output is piped to the console when using
simrvex.


Running the program on the hardware
-----------------------------------

The release comes with ISE/Vivado projects and prebuilt bitstreams for the
Xilinx ML605 and VC707 development boards. If you don't have these boards, it
should be fairly easy to get something basic working, but this is nevertheless
out of the scope of this tutorial. For now, we will just use the
`ml605-standalone` or `vc707-standalone` bitstream, depending on which board
you have.

The first step is, of course, to program the bitstream. There are various ways
to do this, and I assume that you've done this before if you're reading this,
so I won't go into detail. The files are here:

    <root>/versions/release-ml605-standalone.bit
    <root>/versions/release-vc707-standalone.bit

The next step is to get `rvsrv` up and running. `rvsrv` is a tool that bridges
the debug serial port peripheral to two TCP server sockets. This allows multiple
applications to essentially access the serial port simultaneously, and it also
allows you to use a boardserver easily. First, let's go to the right platform
directory in a terminal:

    $ cd <root>/platform/ml605-standalone
      OR
    $ cd <root>/platform/vc707-standalone

Before starting the server, you need to know what device file the UART bridge of
the development board is mapped to. Usually this will be `/dev/ttyUSB0`. This is
a system-specific thing, so I will leave this to you. To start the server, run
the following; of course replacing the serial port device file with whatever
it's called on your system if necessary.

    $ make server SERIAL_PORT=/dev/ttyUSB0

You should see these things, among other things:

    # Successfully opened serial port /dev/ttyUSB0 with baud rate 115200.
    # Trying to open TCP server socket at port 21078 for application access...
    # Now listening on port 21078.
    # Trying to open TCP server socket at port 21079 for debug access...
    # Now listening on port 21079.
    # Daemon process running now, moving log output to /var/tmp/rvsrv/rvsrv-p21079.log.

As the output implies, the tool daemonizes itself (i.e. runs in the background)
so you can use the same terminal for other things. If you want to stop the
server at some point, run `make stop` or something like `killall rvsrv`.

`rvsrv` by itself doesn't do anything - you need `rvd` to send debug commands to
the core. Again, `rvd` by itself does not have any knowledge of the target
platform, so you need to feed it configuration files that we colloquially call
memory maps, although they're more like a pattern-matching script. Don't worry
though: the makefiles will handle all this for you. All you need to do is:

    $ make debug
    $ source debug

This will set up an alias to `rvd` that contains all the necessary flags to tell
`rvd` what kind of platform it is talking to. To see it in action, run:

    $ rvd ?

This will give you a state dump of context 0, which should mostly be a lot of
zeros. So let's run the program now. `make` can handle this for you:

    $ make run-ucbqsort

You should first see the compilation steps, then the software upload to the
core, then the makefile will wait for program termination (it checks every
second; `ucbqsort` runs much faster than it looks from the makefile), and
finally dump the performance counters:

    # Performance counters for context 0:
    #
    #            Active cycles = 0x0000000003F9E6 =  260582 cycles
    #           Stalled cycles = 0x00000000000000 =       0 cycles
    #   Committed bundle count = 0x0000000002DBBA =  187322 bundles
    # Committed syllable count = 0x0000000006D9F8 =  449016 syllables
    #      Committed NOP count = 0x00000000018E87 =  102023 syllables

You'll notice that the debug output is nowhere to be found. For that, you need a
second terminal, where you run:

    $ cd <root>/platform/<board>-standalone
    $ make monitor
    ...
    # Connecting you to the rvex now, ctrl+c to exit. If you get an error, the server is probably not running.

All this does is run `netcat` for the "application" port of `rvsrv`. This TCP
socket emulates the serial port as the program sees it, with all the debug
packets filtered out. It works in both directions: if you type something in the
monitor and press enter the serial port peripheral will receive it. Most of the
programs don't use this though.

If you now go back to the other terminal and run `make run-ucbqsort` again, you
should see the debug output appear in the monitor.

    # ucbqsort: success


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


versions/
---------

When you synthesize most platforms using the makefiles, the scripts will
automatically store the output files, logs, and accompanying source files in an
archive in this directory. Such an archive is tagged by a so-called platform tag
and a core tag. The platform tag is (usually) random generated when synthesis
starts, whereas the core tag is a relatively intelligent hash of the files in
lib/rvex/core. These tags are also stored as ROM in the ρ-VEX global control
register file, allowing a loaded bitstream to be identified and traced back to
the archive. That way, if a problem is found with a bitstream generated earlier,
it can (hopefully) be traced back to the source and be fixed.


test-progs/
-----------

This directory contains the sources for a number of simple test programs for the
ρ-VEX, as well as a make include file that has all the ρ-VEX compile rules.
Compilation is done from the platform folders though, as each platform has
specific driver code, startup files, and/or linker scripts.


tools/
------

This directory contains the various tools needed for compilation, debugging,
etc., both as binaries and as source code where applicable.


grlib/
------

This directory contains logic to download the right version of the grlib GPL
hardware IP library from the TU Delft FTP, and patch it to allow it to use the
ρ-VEX.


Platforms
=========

This section lists some of the provided ρ-VEX, along with some basic usage
instructions. For more informations on these platforms or the undocumented ones,
running make without an argument should always list the available commands.
Reading the makefiles and HDL sources is the next best thing.


simrvex
-------

This "platform" encapsulates the simrvex architectural simulator. simrvex is
very fast in comparison to Modelsim, running at similar speeds as an ρ-VEX core
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
    # make sure that Modelsim is in $PATH
    # source Xilinx ISE 14.7 or Vivado environment script (settings64.sh)
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
    # make sure that Modelsim is in $PATH
    # source Xilinx ISE 14.7 or Vivado environment script (settings64.sh)
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
    # make sure that Modelsim is in $PATH
    # source Xilinx ISE 14.7 or Vivado environment script (settings64.sh)
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
    # source Xilinx ISE 14.7 environment script (settings64.sh)
    $ make ise[-<test program name>]

The program name is optional. If none is provided, the block RAMs will be
initialized with zeros. You can now synthesize the platform as you would
anything else.

Synthesis from the command line works as follows:

    $ cd platform/ml605-standalone
    # source Xilinx ISE 14.7 environment script (settings64.sh)
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
    # source Vivado environment script (settings64.sh)
    $ make vivado[-<test program name>]

The program name is optional. If none is provided, the block RAMs will be
initialized with zeros. You can now synthesize the platform as you would
anything else.

### Using the FPGA design

You can communicate with the processor using rvd. Refer to the debugging section
of the user manual (doc folder) for usage information.


ml605-grlib and and ml605-doom
---------------------------------------------

These platforms use the GRLIB GPL hardware IP library as peripherals. Roughly:

 - ml605-grlib is a very basic port of the ML605 LEON3 example platform from
   GRLIB. It essentially replaces the quad-core version of the platform with a
   single cached quad-context reconfigurable ρ-VEX using bus bridges and an
   interrupt controller bridge, and replaces the primary GRLIB serial peripheral
   with the ρ-VEX debug serial peripheral. It ONLY works with the 512MB DDR3
   version of the ML605 board; the later board revisions with 1GB DDR3 may not
   be initialized properly by the platform. This has been fixed for the others.

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


### Configuration

The ρ-VEX and clock configurations are stored in `work/config.vhd`. *Normally*
this file also controls the peripherals, and may be modified using a GUI tool
from grlib, but we have never used this feature and as such it will most likely
break things when used.


### Simulation

If necessary, the grlib platforms can be simulated using:

    $ cd platform/ml605-<platform name>
    # make sure that Modelsim is in $PATH
    # source Xilinx ISE 14.7 or Vivado environment script (settings64.sh)
    $ make sim-<test program name>

After the first run, the following should also work (it's a little bit faster):

    $ make resim-<test program name>

This will eventually open Modelsim. The simulation itself works a little bit
different between the three platforms. ml605-grlib simulates everything down to
the DDR controller. ml605-doom has a slightly modified DDR controller however,
which do not seem to work with the existing simulation model (almost no time was
spent trying to debug this though). As a workaround, these platforms have a
simplified memory model, which has the side effect of them also simulating
significantly faster.

Each of these platforms simulates the UART completely, including its timing.
Therefore, debug output will slow down the simulation considerably. However,
the process that outputs UART data to the Modelsim console monitors the input
bus of the peripheral, not its output, and the peripheral has a 16-byte buffer.
Because of this, if an application outputs no more than 16 characters, it will
not be slowed down by the UART.

In order to facilitate testing the memory bus interface as seen from the
perspective of the ρ-VEX, these platforms have a memory-check function. This is
enabled by default for ml605-grlib and disabled for the other platforms; it is
controlled by the `CHECK_MEM` generic in the rvsys_grlib instantiation. When
enabled, any write that the ρ-VEX cache does is reported in the Modelsim
console, as is any read that returned an unexpected value.


### Synthesis

Synthesis of the grlib-based platforms should be done from the command line as
follows.

    $ cd platform/ml605-<platform name>
    # source Xilinx ISE 14.7 environment script (settings64.sh)
    $ make synth

### Using the FPGA design

You can communicate with the processor using rvd. Refer to the debugging section
of the user manual (doc folder) for usage information. For bulk memory transfers
you can also use grmon2 with the JTAG interface using the `-xilusb` option; it
is 10-100x faster than the UART we use. grmon2 is not redistributable and is
therefore not included; you can download an evaluation version from
[www.gaisler.com].


### Some notes on the Open64 Compiler

The release includes 3 pre-built versions of the open64 compiler; 2-issue, 
4-issue, and 8-issue (this compiler is not retargetable as HP VEX is).
This compiler has a GCC front-end so it should behave mostly as GCC would.
Normally, the Makefiles take care of linking startup code and libraries. 
The default behavior is to not include these automatically.
In order to compile larger programs, we have ported the newlib 
standard C library and added necessary floating point emulation, division,
and startup code into this toolchain. Because of this, it is often possible
to port an application to the rVEX by simply defining the CC variable in the
Makefile of the application as "rvex-gcc -mruntime=newlib". 
Other -mruntime options are "bare" (default) and "uclibc" (not available in 
this release).


