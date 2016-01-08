from __future__ import print_function

import common.templates

def generate(regs, dirs):
    for mo, mod, mode in [('gb', 'glob', 'global'), ('cx', 'ctxt', 'context')]:
        
        # Generate the ports.
        ports = generate_ports(regs[mo + 'iface'])
        
        # Write the output file.
        common.templates.generate('vhdl',
            dirs['tmpldir'] + '/core_%sRegLogic.vhd' % mode,
            dirs['outdir'] + '/core_%sRegLogic.vhd' % mode,
            {
                'PORT_DECL':  ports,
                'REG_DECL':   '',
                'VAR_DECL':   '',
                'REG_RESET':  '',
                'IMPL':       '',
                'RESET_IMPL': ''
            })

def generate_ports(iface):
    output = []
    for el in iface:
        if el[0] == 'group':
            output.append('-'*75 + '\n-- ' + el[1] + '\n' + '-'*75 + '\n')
        elif el[0] == 'doc':
            if el[1] != '':
                output.append(common.templates.rewrap(el[1], 75, '-- '))
        elif el[0] == 'space':
            output.append('\n')
        elif el[0] == 'ob':
            output.append(el[1].get_decl('vhdl'))
        else:
            raise Exception('Unknown element type %s.' % el[0])
    return ''.join(output)
