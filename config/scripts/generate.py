
#-------------------------------------------------------------------------------
# Command line parsing
#-------------------------------------------------------------------------------
import sys

if len(sys.argv) != 8:
    print('Usage: python generate.py <opcdir> <regdir> <trapdir> <headdir> <corelibdir> <platdir> <outdir>')
    sys.exit(2)

dirs = {
    'opcdir':  sys.argv[1],
    'regdir':  sys.argv[2],
    'trapdir': sys.argv[3],
    'tmpldir': sys.argv[4],
    'libdir':  sys.argv[5],
    'platdir': sys.argv[6],
    'outdir':  sys.argv[7]
}


#-------------------------------------------------------------------------------
# Configuration file processing
#-------------------------------------------------------------------------------
print('Parsing input...')

# Parse opcode files.
import opcodes.opcodes
opc = opcodes.opcodes.parse(dirs['opcdir'])

# Parse registers.
import cregs.registers
regs = cregs.registers.parse(dirs['regdir'])

# Parse traps.
import traps.traps
trps = traps.traps.parse(dirs['trapdir'])

# TODO: Parse pipeline configuration.


#-------------------------------------------------------------------------------
# VHDL generation
#-------------------------------------------------------------------------------
print('Generating VHDL code...')

# Generate core_opcode_pkg.vhd.
import opcodes.opcodes_vhdl
opcodes.opcodes_vhdl.generate(opc, dirs)

# Generate core_ctrlRegs_pkg.vhd.
import cregs.core_ctrlRegs_pkg
cregs.core_ctrlRegs_pkg.generate(regs, dirs)

# Generate core_globalRegLogic.vhd and core_contextRegLogic.vhd.
import cregs.core_regLogic
cregs.core_regLogic.generate(regs, dirs)

# TODO: Generate core_trap_pkg.vhd.

# TODO: Generate core_pipeline_pkg.vhd.

# Generate the conformance test runner.
import cregs.core_tb
cregs.core_tb.generate(regs, dirs)


#-------------------------------------------------------------------------------
# Simulator source generation
#-------------------------------------------------------------------------------

# TODO


#-------------------------------------------------------------------------------
# C/assembly header file generation
#-------------------------------------------------------------------------------
print('Generating header files...')

# Generate rvex.h.
import headers.rvex_h
headers.rvex_h.generate(regs, trps, dirs)


#-------------------------------------------------------------------------------
# rvd memory map generation
#-------------------------------------------------------------------------------
print('Generating memory.map files...')

# TODO


#-------------------------------------------------------------------------------
# LaTeX documentation generation
#-------------------------------------------------------------------------------
print('Generating LaTeX documentation...')

# Generate opcode documentation.
import opcodes.opcodes_latex
opcodes.opcodes_latex.generate(opc, dirs)

# Generate control register documentation.
import cregs.registers_latex
cregs.registers_latex.generate(regs, dirs)

# Generate trap documentation.
import traps.traps_latex
traps.traps_latex.generate(trps, dirs)

# TODO: instruction delays
