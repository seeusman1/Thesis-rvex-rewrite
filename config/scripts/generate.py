
#-------------------------------------------------------------------------------
# Command line parsing
#-------------------------------------------------------------------------------
import sys

if len(sys.argv) != 7:
    print('Usage: python generate.py <opcdir> <regdir> <trapdir> <pldir> <tmpldir> <outdir>')
    sys.exit(2)

dirs = {
    'opcdir':   sys.argv[1],
    'regdir':   sys.argv[2],
    'trapdir':  sys.argv[3],
    'pldir':    sys.argv[4],
    'tmpldir':  sys.argv[5],
    'outdir':   sys.argv[6]
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

# Parse pipeline configuration.
import pipeline.pipeline
pl = pipeline.pipeline.parse(dirs['pldir'])


#-------------------------------------------------------------------------------
# VHDL generation
#-------------------------------------------------------------------------------
print('Generating VHDL code...')

# Generate core_opcode_pkg.vhd.
import opcodes.core_opcode_pkg
opcodes.core_opcode_pkg.generate(opc, dirs)

# Generate core_ctrlRegs_pkg.vhd.
import cregs.core_ctrlRegs_pkg
cregs.core_ctrlRegs_pkg.generate(regs, dirs)

# Generate core_globalRegLogic.vhd and core_contextRegLogic.vhd.
import cregs.core_regLogic
cregs.core_regLogic.generate(regs, dirs)

# Generate core_trap_pkg.vhd.
import traps.core_trap_pkg
traps.core_trap_pkg.generate(trps, dirs)

# Generate core_pipeline_pkg.vhd.
import pipeline.core_pipeline_pkg
pipeline.core_pipeline_pkg.generate(pl, dirs)

# Generate the conformance test runner.
import cregs.core_tb
cregs.core_tb.generate(regs, dirs)


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

# Generate memory map.
import headers.core_map
headers.core_map.generate(regs, trps, dirs)

import headers.core_map_py
headers.core_map_py.generate(regs, trps, dirs)

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
