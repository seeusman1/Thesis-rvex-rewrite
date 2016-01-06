from __future__ import print_function

import common.templates

def generate(regs, dirs):
    for mo, mod, mode in [('gb', 'glob', 'global'), ('cx', 'ctxt', 'context')]:
        
        # TODO
        
        # Write the output file.
        common.templates.generate('vhdl',
            dirs['tmpldir'] + '/core_%sRegLogic.vhd' % mode,
            dirs['outdir'] + '/core_%sRegLogic.vhd' % mode,
            {
                'PORT_DECL':  '',
                'REG_DECL':   '',
                'VAR_DECL':   '',
                'REG_RESET':  '',
                'IMPL':       '',
                'RESET_IMPL': ''
            })

