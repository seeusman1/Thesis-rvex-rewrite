
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
 - GNU make, GCC, diff/patch, wget, and probably some of the other usual dev
   tools.

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

This directory contains the sources for a number of simple test programs for the
ρ-VEX, as well as a make include file that has all the ρ-VEX compile rules.
Compilation is done from the platform folders though, as each platform has
specific driver code, startup files, and/or linker scripts.


tools/
------

This directory contains the various tools needed for compilation, debugging,
etc., both as binaries and as source code where applicable.


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

You can communicate with the processor using rvd. Refer to the debugging section
of the user manual (doc folder) for usage information.


ml605-grlib, ml605-grlib-bare, and ml605-doom
---------------------------------------------

These platforms are various systems that use the GRLIB GPL hardware IP library
as peripherals. Roughly:

 - ml605-grlib is a very basic port of the ML605 LEON3 example platform from
   GRLIB. It essentially replaces the quad-core version of the platform with a
   single cached quad-context reconfigurable ρ-VEX using bus bridges and an
   interrupt controller bridge, and replaces the primary GRLIB serial peripheral
   with the ρ-VEX debug serial peripheral. It ONLY works with the 512MB DDR3
   version of the ML605 board; the later board revisions with 1GB DDR3 may not
   be initialized properly by the platform. This has been fixed for the others.

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


### Configuration

The ρ-VEX and clock configurations are stored in `work/config.vhd`. *Normally*
this file also controls the peripherals, and may be modified using a GUI tool
from grlib, but we have never used this feature and as such it will most likely
break things when used.


### Simulation

If necessary, the grlib platforms can be simulated using:

    $ cd platform/ml605-<platform name>
    # source Modelsim environment script
    # source Xilinx ISE 14.7 or Vivado environment script
    $ make sim-<test program name>

After the first run, the following should also work (it's a little bit faster):

    $ make resim-<test program name>

This will eventually open modelsim. The simulation itself works a little bit
different between the three platforms. ml605-grlib simulates everything down to
the DDR controller. ml605-grlib-bare and ml605-doom have slightly modified DDR
controllers however, which do not seem to work with the existing simulation
model (almost no time was spent trying to debug this though). As a workaround,
these platforms have a simplified memory model, which has the side effect of
them also simulating significantly faster.

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
    # source Xilinx ISE 14.7 environment script
    $ make synth

### Using the FPGA design

You can communicate with the processor using rvd. Refer to the debugging section
of the user manual (doc folder) for usage information. For bulk memory transfers
you can also use grmon2 with the JTAG interface using the `-xilusb` option; it
is 10-100x faster than the UART we use. grmon2 is not redistributable and is
therefore not included; you can download an evaluation version from
[www.gaisler.com].


