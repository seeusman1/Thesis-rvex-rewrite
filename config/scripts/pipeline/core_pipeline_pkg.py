from __future__ import print_function

import opcodes
import common.templates

def generate(pl, dirs):
    
    constants = []
    for key in pl['defs']:
        line = 'constant ' + key + ' '*30
        line = '%s: natural := %d;\n' % (line[:30], pl['defs'][key])
        constants.append(line)
    
    # Write the output file.
    common.templates.generate(
        'vhdl',
        dirs['tmpldir'] + '/core_pipeline_pkg.vhd',
        dirs['outdir'] + '/core_pipeline_pkg.vhd',
        {'CONSTANTS': ''.join(constants)})
    

