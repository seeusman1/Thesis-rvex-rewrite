from __future__ import print_function

def generate(regs, trps, dirs):
    template_file = dirs['tmpldir'] + '/rvex.h'
    with open(template_file, 'r') as f:
        template = f.readlines()
    with open(dirs['outdir'] + '/rvex.h', 'w') as f:
        for i, line in enumerate(template):
            line_nr = i+1
            line = line.strip()
            if line.startswith('@'):
                if line == '@CREGS':
                    print_reg_defs(f, regs)
                elif line == '@TRAPS':
                    print_trap_defs(f, trps)
                else:
                    raise Exception('Unknown template command %s on line %s:%d.' %
                                    (line, template_file, line_nr))
            else:
                f.write(line.strip() + '\n')

def print_def(f, key, value):
    if len(key) < 31:
        key = key + ' ' * (31 - len(key))
    f.write('#define ' + key + ' ' + value + '\n')

def print_reg_defs(f, regs):
    for ent in regs['defs']:
        if ent[0] == 'section':
            f.write('// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n')
            f.write('// %s\n' % ent[1])
            f.write('// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n')
            
        elif ent[0] == 'field':
            print_def(f, ent[1] + '_BIT', "%d" % ent[2])
            print_def(f, ent[1] + '_MASK', "0x%08X" % ent[3])
            f.write('\n')
            
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
            print_def(f, ent[1] + '_ADDR', "(CREG_BASE + 0x%03X)" % ent[3])
            print_def(f, ent[1], "CREG_%s(%s_ADDR)" % (tcode, ent[1]))
            f.write('\n')
        
        else:
            raise Exception('Unknown definition type %s.' % ent[0])

def print_trap_defs(f, trps):
    traptable = trps['table']
    for index, trap in enumerate(traptable):
        if trap is None:
            continue
        print_def(f, 'TRAP_' + trap['mnemonic'], '0x%02X' % index)
    
    f.write('\n// The following definitions are for compatibility with the older, more verbose\n')
    f.write('// definitions.\n')
    for index, trap in enumerate(traptable):
        if trap is None:
            continue
        print_def(f, 'RVEX_TRAP_' + trap['mnemonic'], 'TRAP_' + trap['mnemonic'])

