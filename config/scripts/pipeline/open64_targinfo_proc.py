from __future__ import print_function

import opcodes
import common.templates

def generate(pl, dirs):
    
    constants = []
    for key in pl['defs']:
        line = '#define ' + key + ' ' + '%d\n' % (pl['defs'][key])
        constants.append(line)
    
    # Write the output file.
    common.templates.generate(
        'c',
        dirs['tmpldir'] + '/open64_targinfo_proc.h',
        dirs['outdir'] + '/open64_targinfo_proc.h',
        {'CONSTANTS': ''.join(constants)})
    

