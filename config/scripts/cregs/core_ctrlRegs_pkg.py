from __future__ import print_function

import common.templates

def generate(regs, dirs):
    output = []
    
    # Write VHDL constants for all registers and fields.
    for ent in regs['defs']:
        if ent[0] == 'section':
            output.append('-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n')
            output.append('-- %s\n' % ent[1])
            output.append('-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n')
            
        elif ent[0] == 'field':
            append_def(output, ent[1] + '_H', 'natural := %d' % ent[4])
            append_def(output, ent[1] + '_L', 'natural := %d' % ent[2])
            output.append('\n')
            
        elif ent[0] == 'reg':
            if ent[2][3] != 'W':
                continue
            if ent[3] >= 512:
                append_def(output, ent[1], 'natural := {0:d}'.format(ent[3] // 4))
                append_def(output, ent[1] + '_V', 'std_logic_vector(8 downto 2) := "{0:07b}"'.format((ent[3] // 4) % 128))
            else:
                append_def(output, ent[1], 'natural := {0:d}'.format(ent[3] // 4))
                append_def(output, ent[1] + '_V', 'std_logic_vector(7 downto 2) := "{0:06b}"'.format((ent[3] // 4) % 64))
            output.append('\n')
        
        else:
            raise Exception('Unknown definition type %s.' % ent[0])
    
    # Write the output file.
    common.templates.generate(
        'vhdl',
        dirs['tmpldir'] + '/core_ctrlRegs_pkg.vhd',
        dirs['outdir'] + '/core_ctrlRegs_pkg.vhd',
        {'CREG_CONSTANTS': ''.join(output)})

def append_def(data, key, value):
    if len(key) < 21:
        key = key + ' ' * (21 - len(key))
    data.append('constant %s: %s;\n' % (key, value))
