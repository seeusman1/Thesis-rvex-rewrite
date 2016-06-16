from __future__ import print_function

import opcodes
import common.templates

def generate(trps, dirs):
    
    table = []
    
    # Initialize code segments.
    causes = []
    table = ['constant TRAP_TABLE : trapTable_type := (\n\n']
    
    # Append the traps.
    for index, trap in enumerate(trps['table']):
        if trap is None:
            continue
        
        # Generate the trap cause constant.
        const = 'RVEX_TRAP_' + trap['mnemonic'].upper()
        const += ' ' * max(29 - len(const), 0)
        const = 'constant %s: natural := %d;\n' % (const[:38], index)
        causes.append(const)
        
        # Generate the table entry.
        debug = 1 if 'debug' in trap else 0
        interrupt = 1 if 'interrupt' in trap else 0
        fmt = 'trap %c: ' + trap['description']
        fmt = fmt.replace('\\at{}', '@')
        fmt = fmt.replace('\\arg{x}', '%x')
        fmt = fmt.replace('\\arg{s}', '%d')
        fmt = fmt.replace('\\arg{u}', '%u')
        table.append('  RVEX_TRAP_%s => (\n' % trap['mnemonic'].upper() +
                     '    name => "%s",\n' % (fmt + ' '*50)[:50] +
                     '    isDebugTrap => \'%d\',\n' % debug +
                     '    isInterrupt => \'%d\'\n' % interrupt +
                     '  ),\n\n')
    
    # Append the table footer.
    table.append('  others => (\n' +
                 '    name => "trap %c@ (unknown)                                ",\n' +
                 '    isDebugTrap => \'0\',\n' +
                 '    isInterrupt => \'0\'\n' +
                 '  )\n' +
                 ');\n')
    
    # Write the output file.
    common.templates.generate(
        'vhdl',
        dirs['tmpldir'] + '/core_trap_pkg.vhd',
        dirs['outdir'] + '/core_trap_pkg.vhd',
        {   'TRAP_CAUSES': ''.join(causes),
            'TRAP_TABLE':  ''.join(table)})
    
