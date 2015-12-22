from __future__ import print_function

import interpreter
import copy
import bitfields
import pprint

def parse(fname):
    """Parses the cxreg.tex or gbreg.tex file.
    
    Arguments:
     - fname specifies the file to read.
      
    The return value is a two-tuple.
    
    The first entry of the result is a list with 256 entries, each containing 
    either a dictionary describing a register, or None. The list index
    represents the word address of the register. The register description
    dictionary contains the following entries:
     - 'offset': byte offset from the start of the register map.
     - 'mnemonic': name of the register.
     - 'fields': a list of dictionaries conforming to requirements of a
       normalized bitfield (see bitfields.py), possibly containing the following
       additional dictionary entries:
        - 'doc': LaTeX multiline documentation for the field.
        - 'reset': string with as many entries as there are bits in the field,
          defining the reset value for each bit. Will be prefixed with zeros to
          get to the right length.
        - 'debug': if this key exists, the debug bus may write to the field.
        - 'core': if this key exists, the core may write to the field.
    
    The second entry is a list of dictionaries and two-tuples. Each dictionary
    contains the following entries:
     - 'title': LaTeX title of the register (set).
     - 'doc': LaTeX multiline documentation for the register (set) as a whole.
     - 'registers': a list of dictionaries of the following form:
        - 'offset': byte offset from the start of the register map.
        - 'mnemonic': name of the register with \n{} expanded to the index.
        - 'fields': same as above.
     - 'fields': same as above.
    The two-tuples are key-type-value mappings belonging to the previously
    specified register (dictionary). The tuple maps from a mnemonic to an
    integer value, which should be made available to programs through rvex.h,
    the debug interface through core.map and the VHDL code through
    core_ctrlRegs_pkg.vhd. The following mappings are defined:
     - "CR_<mnemonic>" -> byte offset of a register w.r.t. the control
       register file vector.
     - "CR_<mnemonic>_<field>" -> byte offset of an aligned 16-bit field
       within a 32-bit register.
     - "CR_<mnemonic>_<field>" -> byte offset of an aligned 8-bit field
       within a 32-bit register.
     - "CR_<mnemonic>_<field>_BIT" -> start offset of a field within a register.
     - "CR_<mnemonic>_<field>_MASK" -> bitmask of a field within a register.
    The type part of the tuple (second element) may be:
     - '<core><debug><signedness><size>': element if a byte offset, pointing to
       a field or a register. <core> is 'W' if the core can write to any part of
       the field, and 'R' otherwise. Idem for <debug>. <signedness> is 'S' or
       'U' depending on whether the field is signed or not. <size> is 'W' for
       32-bit, 'H' for 16-bit and 'B' for 8-bit.
     - 'bit': element is a bit offset.
     - 'mask': element is a 32-bit bitmask.
    
    """
    
    # Parse the file.
    groups = interpreter.parse_file(fname, {
        'register': (3, True),
        'registergen': (5, True),
        'field': (2, True),
        'reset': (1, False),
        'debugCanWrite': (0, False),
        'coreCanWrite': (0, False),
        'signed': (0, False),
        'id': (1, False)
    })
    
    # Parse the fields and add them to their containing registers.
    reg_cmds = []
    for group in groups[1:]:
        if group['cmd'][0] == 'field':
            if len(reg_cmds) == 0:
                raise Exception('Field specified before register command ' +
                                'on line ' + str(group['line_nr']))
            field = {
                'range':   group['cmd'][1],
                'name':    group['cmd'][2],
                'doc':     group['doc'],
                'line_nr': group['line_nr']
            }
            for cmd in group['subcmds']:
                if cmd[0] == 'coreCanWrite':
                    field['core'] = 'canWrite'
                elif cmd[0] == 'debugCanWrite':
                    field['debug'] = 'canWrite'
                elif cmd[0] == 'signed':
                    field['signed'] = 'signed'
                elif cmd[0] == 'reset':
                    field['reset'] = cmd[1]
                elif cmd[0] == 'id':
                    field['alt_id'] = cmd[1]
                else:
                    raise Exception('Internal error: unknown field modifier ' +
                                    cmd[0] + ' after line ' +
                                    str(group['line_nr']))
            reg_cmds[-1]['fields'] += [field]
        else:
            if len(group['subcmds']) > 0:
                raise Exception('Field modifier specified before field ' +
                                'command after line ' +
                                str(group['line_nr']))
            del group['subcmds']
            group['fields'] = []
            reg_cmds += [group]
    
    # Parse and normalize the bitfield specifications.
    for cmd in reg_cmds:
        try:
            fields = bitfields.parse(cmd['fields'])
        except Exception as e:
            raise Exception('Error while parsing bitfields for the ' + 
                            'register specified on line ' +
                            str(cmd['line_nr']))
        for field in fields:
            size = field['upper_bit'] - field['lower_bit'] + 1
            reset = ('0' * size)
            if 'reset' in field:
                reset += field['reset']
            field['reset'] = reset[-size:]
        cmd['fields'] = fields
    
    # Generate the outputs.
    regmap = [None] * 256
    regdoc = []
    for cmd in reg_cmds:
        fields_n = copy.deepcopy(cmd['fields'])
        for field in fields_n:
            if 'name' in field:
                field['name'] = interpreter.generate(field['name'])
            if 'doc' in field:
                field['doc'] = interpreter.generate(field['doc'])
            if 'alt_id' in field:
                field['alt_id'] = interpreter.generate(field['alt_id'])
        doc = cmd['doc']
        try:
            if cmd['cmd'][0] == 'register':
                ns = [0]
                mnem = cmd['cmd'][1].strip()
                title = cmd['cmd'][2].strip()
                offs = int(cmd['cmd'][3].strip(), 0)
                stride = 0
            elif cmd['cmd'][0] == 'registergen':
                ns = eval(cmd['cmd'][1])
                mnem = cmd['cmd'][2].strip()
                title = cmd['cmd'][3].strip()
                offs = int(cmd['cmd'][4].strip(), 0)
                stride = int(cmd['cmd'][5].strip(), 0)
            else:
                raise Exception('Internal error: unknown group command ' +
                                cmd['cmd'][0] + ' on line ' + str(cmd['line_nr']))
        except ValueError:
            raise Exception('Offset or stride could not be parsed on line ' +
                            str(cmd['line_nr']))
        
        # Perform the operations per expanded register.
        subregs = []
        reg_defs = []
        for n in ns:
            
            fields = copy.deepcopy(cmd['fields'])
            for field in fields:
                if 'name' in field:
                    field['name'] = interpreter.generate(field['name'], values={'n': n}, default='%s')
                if 'doc' in field:
                    field['doc'] = interpreter.generate(field['doc'], values={'n': n}, default='%s')
            
            # Check validity.
            reg_offs = offs + n * stride
            if reg_offs % 4 != 0:
                raise Exception('Misaligned register offset or stride on line ' +
                                str(cmd['line_nr']))
            word_offs = reg_offs // 4
            if regmap[word_offs] is not None:
                raise Exception(('Overlapping registers on byte offset 0x%03X' %
                                reg_offs) + ' on line ' + str(cmd['line_nr']))
            subreg = {
                'offset': reg_offs,
                'mnemonic': interpreter.generate(mnem, values={'n': n}, default='%s'),
                'fields': fields
            }
            
            # Add to the map.
            regmap[word_offs] = subreg
            
            # Add to the subregs list for documentation.
            subregs += [subreg]
            
            # Add offset definition for the whole register.
            prefix = 'CR_' + interpreter.generate(mnem, values={'n': n})
            core = 'R'
            debug = 'R'
            signedness = 'U'
            for field in fields:
                if 'core' in field:
                    core = 'W'
                if 'debug' in field:
                    debug = 'W'
            if len(fields) == 1:
                if 'signed' in fields[0]:
                    signedness = 'S'
            reg_defs += [(prefix, core + debug + signedness + 'W', reg_offs)]
            
            # Add offset definitions for each field.
            for field in fields:
                
                # Skip undefined fields and full 32-bit fields.
                if field['name'] == '':
                    continue
                if field['upper_bit'] == 31 and field['lower_bit'] == 0:
                    continue
                
                # Field identifier.
                fieldid = prefix + '_' + field['name']
                
                # Add bit and mask definitions for the field.
                mask = (1 << field['upper_bit'] + 1) - 1
                mask -= (1 << field['lower_bit']) - 1
                reg_defs += [
                    (fieldid + '_BIT', 'bit', field['lower_bit']),
                    (fieldid + '_MASK', 'mask', mask),
                ]
                
                # Add offset definitions for aligned fields.
                for size, sizename in [(16, 'H'), (8, 'B')]:
                    if field['upper_bit'] - field['lower_bit'] + 1 != size:
                        continue
                    if field['lower_bit'] % size != 0:
                        continue
                    core = 'R'
                    debug = 'R'
                    signedness = 'U'
                    if 'core' in field:
                        core = 'W'
                    if 'debug' in field:
                        debug = 'W'
                    if 'signed' in field:
                        signedness = 'S'
                    tcode = core + debug + signedness + sizename
                    foffs = reg_offs + 3 - (field['lower_bit'] // 8)
                    reg_defs += [(fieldid, tcode, foffs)]
                    if 'alt_id' in field:
                        reg_defs += [('CR_' + interpreter.generate(field['alt_id'], values={'n': n}), tcode, foffs)]
        
        # Add to the documentation.
        regdoc += [{
            'title': interpreter.generate(title),
            'doc': interpreter.generate(doc),
            'mnemonic': interpreter.generate(mnem, default='%s'),
            'registers': subregs,
            'fields': fields_n
        }] + reg_defs
    
    return (regmap, regdoc)
