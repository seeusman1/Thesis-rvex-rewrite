from __future__ import print_function

import common.templates

def generate(regs, trps, dirs):
    
    # Generate the control register section.
    regdefs = []
    for ent in regs['defs']:
        if ent[0] == 'section':
            regdefs.append('// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n')
            regdefs.append('// %s\n' % ent[1])
            regdefs.append('// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n')
            
        elif ent[0] == 'field':
            append_def(regdefs, ent[1] + '_BIT', "%d" % ent[2])
            append_def(regdefs, ent[1] + '_MASK', "0x%08X" % ent[3])
            regdefs.append('\n')
            
        elif ent[0] == 'reg':
            tcode = 'INT'
            if ent[2][2] == 'U':
                tcode = 'UINT'
            if ent[2][3] == 'B':
                tcode += '8_R'
            elif ent[2][3] == 'H':
                tcode += '16_R'
            else:
                tcode += '32_R'
            if ent[2][0] == 'W':
                tcode += 'W'
            append_def(regdefs, ent[1] + '_OFFSET', "(0x%03X)" % ent[3])
            append_def(regdefs, ent[1] + '_ADDR', "(CREG_BASE + %s_OFFSET)" % ent[1])
            append_def(regdefs, ent[1] + '_REL_ADDR(base)', "((base) + %s_OFFSET)" % ent[1])
            append_def(regdefs, ent[1] + '_REL(base)', "CREG_%s(%s_REL_ADDR(base))" % (tcode, ent[1]))
            append_def(regdefs, ent[1], "CREG_%s(%s_ADDR)" % (tcode, ent[1]))
            regdefs.append('\n')
        
        else:
            raise Exception('Unknown definition type %s.' % ent[0])
    
    # Generate the trap definition section.
    trapdefs = []
    for index, trap in enumerate(trps['table']):
        if trap is None:
            continue
        append_def(trapdefs, 'TRAP_' + trap['mnemonic'], '0x%02X' % index)
    
    trapdefs.append('\n// The following definitions are for compatibility with the older, more verbose\n')
    trapdefs.append('// definitions.\n')
    for index, trap in enumerate(trps['table']):
        if trap is None:
            continue
        append_def(trapdefs, 'RVEX_TRAP_' + trap['mnemonic'], 'TRAP_' + trap['mnemonic'])
    
    # Generate the file using the templating engine.
    common.templates.generate('c',
        dirs['tmpldir'] + '/rvex.h',
        dirs['outdir'] + '/rvex.h',
        {
            'CREGS': ''.join(regdefs),
            'TRAPS': ''.join(trapdefs),
        })

def append_def(data, key, value):
    if len(key) < 31:
        key = key + ' ' * (31 - len(key))
    data.append('#define ' + key + ' ' + value + '\n')


