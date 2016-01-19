from __future__ import print_function

import common.templates

def generate(regs, dirs):
    
    vhdl = []
    for ent in regs['defs']:
        if ent[0] == 'reg':
            vhdl.append('registerCtrlReg("%s", 16#%03X#);\n' % (ent[1], ent[3]))
    
    # Generate the file.
    common.templates.generate('vhdl',
        dirs['tmpldir'] + '/core_tb.vhd',
        dirs['outdir'] + '/core_tb.vhd',
        {'REGISTER_DEFINITIONS': ''.join(vhdl)})
    