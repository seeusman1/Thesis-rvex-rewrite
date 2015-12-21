from __future__ import print_function

from sys import argv
from sys import exit
import opcodes
import bitfields

# Parse command line.
if len(argv) != 4:
    print('Usage: python opcodes-vhdl.py <infile.tex> <template.vhd> <outfile.vhd>')
    exit(2)
infile = argv[1]
templatefile = argv[2]
outfile = argv[3]

# Parse the opcode configuration file.
sections, table, def_params = opcodes.parse(infile)

# Read the non-generated part of the file, i.e. everything until the "generated
# from here" line plus two subsequent lines.
with open(templatefile, 'r') as f:
    header = f.readlines()
for i, l in enumerate(header):
    if '-- ##################### GENERATED FROM HERE ONWARDS ##################### --' in l:
        header = header[:i+3]
        break
else:
    raise Exception('Could not find start marker.')
header = ''.join(header)

# The package footer is hardcoded here.
footer = """
end core_opcode_pkg;

package body core_opcode_pkg is
end core_opcode_pkg;
"""

def write_entry(f, r, syl, end=',', indent='      '):
    
    # Start the opcode definition.
    f.write(indent[:-2] + r + ' (\n')
    
    # Define the syntax and validity of the opcode.
    syntax_reg = 'unknown'
    syntax_imm = 'unknown'
    valid_reg = '0'
    valid_imm = '0'
    if 'opcode' in syl:
        if syl['opcode'][8] in ['0', '-']:
            syntax_reg = opcodes.format_syntax(syl['syntax'], 'vhdl', syl, 0)
            valid_reg = '1'
        if syl['opcode'][8] in ['1', '-']:
            syntax_imm = opcodes.format_syntax(syl['syntax'], 'vhdl', syl, 1)
            valid_imm = '1'
    syntax_reg = syntax_reg[:50]
    syntax_imm = syntax_imm[:50]
    while len(syntax_reg) < 50:
        syntax_reg += ' '
    while len(syntax_imm) < 50:
        syntax_imm += ' '
    f.write(indent + 'syntax_reg => "' + syntax_reg + '",\n')
    f.write(indent + 'syntax_imm => "' + syntax_imm + '",\n')
    s = 'valid => "' + valid_imm + valid_reg + '"'
    
    # Write decoding information.
    for unit in ['datapath', 'alu', 'branch', 'memory', 'multiplier']:
        s += ', ' + unit + 'Ctrl => ('
        first = True
        for field in syl[unit]:
            if first:
                first = False
            else:
                s += ', '
            s += field + ' => ' + syl[unit][field]
        s += ')'
    
    # Wrap the decoder information compactly.
    tokens = s.split(', ')
    line = indent
    s = ''
    for i, token in enumerate(tokens):
        if i == len(tokens) - 1:
            to_add = token.strip()
        else:
            to_add = token.strip() + ', '
        if len(line) + len(to_add.strip()) > 80:
            s += line + '\n'
            line = indent
        line += to_add
    f.write(s + line + '\n')
    
    # End the opcode definition.
    f.write(indent[:-2] + ')' + end + '\n')

def write_head(f, name):
    f.write('    \n')
    f.write('    ---------------------------------------------------------------------------\n')
    f.write('    -- ' + name + '\n')
    f.write('    ---------------------------------------------------------------------------\n')

# Write the output file.
with open(outfile, 'w') as f:
    f.write(header)
    
    f.write('  \n')
    f.write('  -----------------------------------------------------------------------------\n')
    f.write('  -- Undefined entries\n')
    f.write('  -----------------------------------------------------------------------------\n')
    write_entry(f, 'constant opcodeTableEntry_default : opcodeTableEntry_type :=', def_params, end=';', indent='    ')
    f.write('  \n')
    
    # Write the start of the opcode table.
    f.write('  constant OPCODE_TABLE : opcodeTable_type := (\n')
    
    # Determine the opcode ranges for each syllable.
    for opcode, syl in enumerate(table):
        if syl == None:
            continue
        if 'opcode-ranges' in syl:
            if syl['opcode-ranges'][-1][1] == opcode - 1:
                syl['opcode-ranges'][-1][1] = opcode
            else:
                syl['opcode-ranges'] += [[opcode, opcode]]
        else:
            syl['opcode-ranges'] = [[opcode, opcode]]
    
    # Write the opcodes to the file.
    for section in sections:
        write_head(f, section['name'])
        for syl in section['syllables']:
            for r in syl['opcode-ranges']:
                rs = str(r[0]) + ' to ' + str(r[1])
                if r[0] == r[1]:
                    rs = str(r[0])
                write_entry(f, rs + ' =>', syl)
    
    # Write the others clause and the end of the table.
    f.write('    others => opcodeTableEntry_default\n')
    f.write('  );\n')
    
    f.write(footer)
