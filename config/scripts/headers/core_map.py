from __future__ import print_function

import common.templates

def generate(regs, trps, dirs):
    
    memmap = []
    for ent in regs['defs']:
        if ent[0] == 'reg':
            name = ent[1]
            if name.startswith('CR_'):
                name = name[3:]
                if ent[3] < 256:
                    memmap.append('all:%s { CREG_GLOB + 0x%03X }\n' % (name, ent[3]))
                elif ent[3] >= 512:
                    memmap.append('all:%s { CREG_CTXT + 0x%03X }\n' % (name, ent[3] - 512))
                else:
                    raise Exception('Unknown register type at address 0x%03X.' % ent[3])
            
        elif ent[0] == 'field':
            name = ent[1]
            if name.startswith('CR_'):
                name = 'FIELD_' + name[3:]
                memmap.append('all:%s { (val & 0x%08X) >> %d }\n' % (name, ent[3], ent[2]))
    
    # Generate the file.
    common.templates.generate('memmap',
        dirs['tmpldir'] + '/core.map',
        dirs['outdir'] + '/core.map',
        {'REGISTER_DEFINITIONS': ''.join(memmap)})
