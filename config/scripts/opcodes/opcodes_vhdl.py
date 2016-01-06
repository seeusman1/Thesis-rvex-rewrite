from __future__ import print_function

import opcodes
import common.templates

def generate(opc, dirs):
    sections     = opc['sections']
    table        = opc['table']
    def_params   = opc['def_params']
    templatefile = dirs['libdir'] + '/core_opcode_pkg.vhd'
    outfile      = dirs['outdir'] + '/core_opcode_pkg.vhd'

    # Write the undefined entry.
    output = []
    output.append('  \n')
    output.append('  -----------------------------------------------------------------------------\n')
    output.append('  -- Undefined entries\n')
    output.append('  -----------------------------------------------------------------------------\n')
    write_entry(output, 'constant opcodeTableEntry_default : opcodeTableEntry_type :=', def_params, end=';', indent='    ')
    output.append('  \n')
    
    # Write the start of the opcode table.
    output.append('  constant OPCODE_TABLE : opcodeTable_type := (\n')
    
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
        write_head(output, section['name'])
        for syl in section['syllables']:
            for r in syl['opcode-ranges']:
                rs = str(r[0]) + ' to ' + str(r[1])
                if r[0] == r[1]:
                    rs = str(r[0])
                write_entry(output, rs + ' =>', syl)
    
    # Write the others clause and the end of the table.
    output.append('    others => opcodeTableEntry_default\n')
    output.append('  );\n')
    
    # Write the package footer.
    output.append('    \n')
    output.append('end core_opcode_pkg;\n')
    output.append('\n')
    output.append('package body core_opcode_pkg is\n')
    output.append('end core_opcode_pkg;\n')
    
    # Write the output file.
    common.templates.generate_footer('vhdl', templatefile, outfile, ''.join(output))
    

def write_entry(output, r, syl, end=',', indent='      '):
    
    # Start the opcode definition.
    output.append(indent[:-2] + r + ' (\n')
    
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
    output.append(indent + 'syntax_reg => "' + syntax_reg + '",\n')
    output.append(indent + 'syntax_imm => "' + syntax_imm + '",\n')
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
    output.append(s + line + '\n')
    
    # End the opcode definition.
    output.append(indent[:-2] + ')' + end + '\n')

def write_head(output, name):
    output.append('    \n')
    output.append('    ---------------------------------------------------------------------------\n')
    output.append('    -- ' + name + '\n')
    output.append('    ---------------------------------------------------------------------------\n')

