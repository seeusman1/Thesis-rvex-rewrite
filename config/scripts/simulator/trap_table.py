from __future__ import print_function

def generate(trps, header, source):
    output = []
    
    # Output the table entry typedef.
    header.append('typedef struct trapTableEntry_t {\n')
    header.append('    const char *name;\n')
    header.append('    unsigned int isDebugTrap : 1;\n')
    header.append('    unsigned int isInterrupt : 1;\n')
    header.append('} trapTableEntry_t;\n\n')

    # Output the lookup table.
    header.append('extern const trapTableEntry_t TRAP_TABLE[256];\n')
    source.append('const trapTableEntry_t TRAP_TABLE[256] = {\n')
    for index, trap in enumerate(trps['table']):
        if trap is None:
            name = 'trap %c@ (unknown)'
            debug = 0
            interrupt = 0
        else:
            name = 'trap %c: ' + trap['description']
            name = name.replace('\\at{}', '%@')
            name = name.replace('\\arg{x}', '%x')
            name = name.replace('\\arg{s}', '%d')
            name = name.replace('\\arg{u}', '%u')
            debug = 1 if 'debug' in trap else 0
            interrupt = 1 if 'interrupt' in trap else 0
        
        source.append('    { "%s", %d, %d }' % (name, debug, interrupt))
        source.append(',\n')
    source[-1] = '\n};\n'


