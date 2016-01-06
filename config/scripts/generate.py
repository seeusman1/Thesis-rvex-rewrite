
#-------------------------------------------------------------------------------
# Command line parsing
#-------------------------------------------------------------------------------
import sys

if len(sys.argv) != 7:
    print('Usage: python generate.py <opcdir> <regdir> <trapdir> <headdir> <corelibdir> <outdir>')
    sys.exit(2)

dirs = {
    'opcdir':  sys.argv[1],
    'regdir':  sys.argv[2],
    'trapdir': sys.argv[3],
    'tmpldir': sys.argv[4],
    'libdir':  sys.argv[5],
    'outdir':  sys.argv[6]
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

# TODO: pipeline configuration


#-------------------------------------------------------------------------------
# VHDL generation
#-------------------------------------------------------------------------------
print('Generating VHDL code...')

# Generate core_opcode_pkg.vhd.
import opcodes.opcodes_vhdl
opcodes.opcodes_vhdl.run(opc, dirs)

# TODO: core_trap_pkg.vhd
# TODO: control register stuff
# TODO: pipeline configuration


#-------------------------------------------------------------------------------
# Simulator source generation
#-------------------------------------------------------------------------------

# TODO: everything


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

# TODO: everything


#-------------------------------------------------------------------------------
# LaTeX documentation generation
#-------------------------------------------------------------------------------
print('Generating LaTeX documentation...')

# Generate opcode documentation.
import opcodes.opcodes_latex
opcodes.opcodes_latex.run(opc, dirs)

# Generate control register documentation.
import cregs.registers_latex
cregs.registers_latex.run(regs, dirs)

# Generate trap documentation.
import traps.traps_latex
traps.traps_latex.run(trps, dirs)

# TODO: instruction delays
