from __future__ import print_function

import common.interpreter
import common.bitfields
import copy
import pprint
interpreter = common.interpreter
bitfields = common.bitfields

from code_except import *
from code_types import *
from code_environment import *

def parse(indir):
    """Parses the control register .tex files.
    
    TODO: write documentation.
    """
    
    result = {}
    
    # Parse the files.
    cmds = interpreter.parse_files(indir, {
        
        # Interface declarations.
        'contextInterface': (0, True),
        'globalInterface':  (0, True),
        'ifaceGroup':       (1, True),  # (name), documentation
        'ifaceSubGroup':    (0, True),  # documentation
        'ifaceIn':          (3, False), # (unit, name, type)
        'ifaceOut':         (4, False), # (unit, name, type, reset value expression)
        'ifaceInCtxt':      (3, False), # (unit, name, type)
        'ifaceOutCtxt':     (4, False), # (unit, name, type, reset value expression)
        
        # Implementation templates.
        'defineTemplate': (2, True, {'code': True}), # (name, param_list)
        
        # Register specification.
        'register': (3, True),       # (mnemonic, name, offset), documentation
        'registergen': (5, True),    # (python range, mnemonic, name, offset, stride), documentation
        
        # Field specification.
        'field': (2, True),          # (range, identifier), documentation
        'reset': (1, False),         # (reset bits for documentation)
        'signed': (0, False),
        'id': (1, False),            # (alternate standalone identifier)
        
        # Field declarations.
        'declaration': (0, True),
        'declRegister': (3, False),  # (name, type, reset value expression)
        'declVariable': (2, False),  # (name, type)
        'declConstant': (3, False),  # (name, type, value)
        
        # Field implementation.
        'implementation': (0, True, {'code': True}),
        'resetImplementation': (0, True, {'code': True})
        
    })
    
    # Enforce and apply command hierarchy.
    cmds = interpreter.hierarchy(cmds, [
        
        (None,
            ['contextInterface*', 'globalInterface*', 'register*', 'registergen*']),
        
        (['contextInterface', 'globalInterface'],
            ['ifaceGroup*']),
        
        (['ifaceGroup'],
            ['ifaceSubGroup*']),
        
        (['ifaceSubGroup'],
            ['ifaceIn*', 'ifaceOut*', 'ifaceInCtxt*', 'ifaceOutCtxt*']),
        
        (['register', 'registergen'],
            ['field*']),
        
        (['field'],
            ['reset?', 'signed?', 'id*', 'declaration?', 'implementation!', 'resetImplementation?']),
        
        (['declaration'],
            ['declRegister*', 'declVariable*', 'declConstant*'])
        
    ])['subcmds']
    
    # Construct the global constant variable environment which can be used by
    # user code.
    env = Environment()
    env.declare(Object('', 'CFG', PredefinedConstant(CfgVectType())))
    pipeline_stage_defs = ['S_FIRST', 'S_IF', 'L_IF', 'L_IF_MEM', 'S_PCP1',
        'S_BTGT', 'S_STOP', 'S_LIMM', 'S_TRAP', 'S_RD', 'L_RD', 'S_SRD', 'S_FW',
        'S_SFW', 'S_BR', 'S_ALU', 'L_ALU1', 'L_ALU2', 'L_ALU', 'S_MUL',
        'L_MUL1', 'L_MUL2', 'L_MUL', 'S_MEM', 'L_MEM', 'S_BRK', 'L_BRK', 'S_WB',
        'L_WB', 'S_SWB', 'S_LTRP', 'S_LAST']
    for d in pipeline_stage_defs:
        env.declare(Object('', d, PredefinedConstant(CfgVectType())))
    
    # Parse global register file interface.
    gbiface, gbenv = parse_iface('gbreg', env,
        [cmd for cmd in cmds if cmd['cmd'][0] == 'globalInterface'])
    result['gbiface'] = gbiface
    
    # Parse context register file interface.
    cxiface, cxenv = parse_iface('cxreg', env,
        [cmd for cmd in cmds if cmd['cmd'][0] == 'contextInterface'])
    result['cxiface'] = cxiface
    
    # Extract register commands from the command list.
    regcmds = [cmd for cmd in cmds
               if cmd['cmd'][0] in ['register', 'registergen']]
    
    # Parse bitfields.
    for regcmd in regcmds:
        parse_bitfields(regcmd)
    
    # Expand and check register commands.
    regmap, regdoc = parse_registers(regcmds)
    result['regmap'] = regmap
    result['regdoc'] = regdoc
    
    # Check register and field name validity.
    check_reg_names(regmap)
    
    # Generate register/field definition list for headers.
    result['defs'] = gen_defs(regdoc)
    
    # Gather all declarations.
    result['gbdecl'] = []
    result['cxdecl'] = []
    for reg in regmap:
        if reg is None:
            continue
        if 'glob' in reg:
            regtyp = 'gb'
        elif 'ctxt' in reg:
            regtyp = 'cx'
        else:
            raise CodeError('Unknown register type for CR_%s.' % reg['mnemonic'])
        result[regtyp + 'decl'] += gather_declarations(reg)
    for ob in result['gbdecl']:
        gbenv.declare(ob)
    for ob in result['cxdecl']:
        cxenv.declare(ob)
    
    # Parse reset/init specifications.
    gbenv.parse_init()
    cxenv.parse_init()
    
    return result


def parse_iface(unit, env, ifacecmds):
    """Flattens the interface command tree into a list of tuples for easy code
    output. Also does type parsing and name checking, so this might throw
    exceptions for the user. The output is a two-tuple.
    
    The first entry is list of these tuples:
    ('group', name) -> should map to the comment header for a signal group.
    ('doc', doc)    -> should map to a bit of documentation.
    ('space', None) -> should map to an empty line.
    ('ob', ob)      -> maps to an input or output Object.
    
    The second entry is an Environment() populated with the interface objects.
    """
    
    iface = []
    for ifacecmd in ifacecmds:
        for groupcmd in ifacecmd['subcmds']:
            iface += [('group', groupcmd['cmd'][1])]
            if groupcmd['doc'] != '':
                iface += [('space', None)]
                iface += [('doc', groupcmd['doc'])]
            for subgroupcmd in groupcmd['subcmds']:
                if subgroupcmd['doc'] != '':
                    iface += [('doc', subgroupcmd['doc'])]
                for portcmd in subgroupcmd['subcmds']:
                    origin = portcmd['origin']
                    
                    # Parse type and init/reset specification.
                    try:
                        typ = parse_type(portcmd['cmd'][3])
                        if portcmd['cmd'][0] in ['ifaceInCtxt', 'ifaceOutCtxt']:
                            typ = PerCtxt(typ)
                        if portcmd['cmd'][0] in ['ifaceOut', 'ifaceOutCtxt']:
                            atyp = Output(typ)
                            init = portcmd['cmd'][3]
                        else:
                            atyp = Input(typ)
                            init = None
                    except CodeError as e:
                        except_prefix(e, 'Type error in type %s, command \\%s{}, after line %s: ' %
                                      (portcmd['cmd'][3], portcmd['cmd'][0], origin))
                    
                    # Check name.
                    fmt = '%s2%%s_%%s' if portcmd['cmd'][0] in ['ifaceOut', 'ifaceOutCtxt'] else '%%s2%s_%%s'
                    fmt %= unit
                    name = fmt % (portcmd['cmd'][1], portcmd['cmd'][2])
                    if not re.match(r'[a-zA-Z0-9][a-zA-Z0-9_]*$', name):
                        raise CodeError('Name error in \\%s{} after line %s: invalid port name %s.' %
                                        (portcmd['cmd'][0], origin, name))
                    
                    # Make the object.
                    ob = Object('', name, atyp, origin, init)
                    iface += [('ob', ob)]
                    
                iface += [('space', None)]
    
    env = env.copy()
    for el in iface:
        if el[0] == 'ob':
            env.declare(el[1])
    
    return (iface, env)


def parse_bitfields(regcmd):
    """Parses bitfield specifications in register and registergen commands.
    
    The implementation is not parsed, nor are registergen commands expanded. All
    this does is replace field subcmds with a 'fields' key for each
    register(gen) command, compliant with a normalized bitfield specification
    (see bitfields.py). In addition, each nonempty field will contain the keys
    generated by parse_bitfield().
    """

    # Extract some register stuff for error messages.
    rnam = regcmd['cmd'][2 if regcmd['cmd'][0] == 'registergen' else 1]
    rerr = 'register CR_%s defined on line %s' % (rnam, regcmd['origin'])
    
    # Parse the field specifications.
    fields = [parse_bitfield(x) for x in regcmd['subcmds']]
        
    # Parse and normalize the bitfield.
    try:
        fields = bitfields.parse(fields)
    except bitfields.FieldError as e:
        except_prefix(e, 'Error while parsing bitfields for %s: ' % rerr)
    
    # Perform some field post-processing now that the ranges have been
    # parsed.
    for field in fields:
        
        # Determine the bitcount and offset for this field.
        size = field['upper_bit'] - field['lower_bit'] + 1
        offset = field['lower_bit']
        
        # Ensure the existance of the 'reset' field and make sure its length
        # is right.
        reset = ('0' * size)
        if 'reset' in field:
            reset += field['reset']
        field['reset'] = reset[-size:]
        
        # Alternate IDs are only supported for 8-bit and 16-bit aligned
        # fields, so throw an error if IDs are specified for other fields.
        if 'defined' in field and len(field['alt_ids']) > 0:
            if (size not in [8, 16]) or (offset % size != 0):
                raise CodeError(('\\id{} command specified for field ' +
                                'defined on line %s which is not an ' +
                                'aligned byte or halfword register. ' +
                                'This is not supported.') % field['origin'])
    
    # Add the list of fields to the register(gen) command and remove the
    # subcmd.
    regcmd['fields'] = fields
    regcmd['subcmds'] = [cmd for cmd in regcmd['subcmds']
                            if cmd['cmd'][0] != 'field']


def parse_bitfield(fieldcmd):
    """Constructs a bitfield dictionary from a field command. This dictionary
    contains the following keys:
     - 'defined': key which always exists for defined fields.
     - 'doc': LaTeX multiline field documentation.
     - 'origin': where this field was defined in the config files.
     - 'reset': string with as many entries as there are bits in the field,
       defining the reset value for each bit.
     - 'signed': if this key exists, the field is signed.
     - 'alt_ids': list of (abbreviated) IDs for this field. This only works for
       8-bit and aligned 16-bit fields. They allow the field to be accessed as
       if it's an independent register.
     - 'decl': list of \decl*{} command dictionaries.
     - 'impl': list of two-tuples, where each first entry is an origin and each
       second entry is a line of implementation code.
     - 'resimpl': same as 'impl', but for the reset implementation.
    """

    # Extract the trivial stuff from the \field{} command and create a
    # field dictionary for it.
    fcmd = fieldcmd['cmd']
    fnam = fcmd[2].strip()
    field = {
        'defined': 'defined',
        'range':   fcmd[1].strip(),
        'name':    fnam,
        'doc':     fieldcmd['doc'],
        'origin':  fieldcmd['origin'],
        'alt_ids': [],
        'decl':    [],
        'resimpl': [],
    }
    
    # Parse the modifier commands.
    for modcmd in fieldcmd['subcmds']:
        mcmd = modcmd['cmd']
        
        if mcmd[0] == 'reset':
            # Add reset specification.
            field['reset'] = mcmd[1]
            
        elif mcmd[0] == 'signed':
            # Mark field as signed.
            field['signed'] = 'signed'
            
        elif mcmd[0] == 'id':
            # Add alternate ID to list.
            field['alt_ids'] += [mcmd[1].strip()]
            
        elif mcmd[0] == 'declaration':
            # Add declarations.
            field['decl'] = modcmd['subcmds']
            
        elif mcmd[0] == 'implementation':
            # Add implementation.
            field['impl'] = modcmd['code']
            
        elif mcmd[0] == 'resetImplementation':
            # Add reset implementation.
            field['resimpl'] = modcmd['code']
        
        else:
            raise CodeError('Unimplemented field modifier command %s.' %
                            mcmd[0])
    
    return field


def parse_registers(regcmds):
    """Parses and expands register(gen) commands, assumed to have their fields
    preprocessed by parse_bitfields().
    
    Returns a two-tuple.
    
    The first entry represents the register map as a list, with each register
    indexed by its WORD offset. Each register is represented as a dictionary:
     - 'origin': where this register was defined.
     - 'doc': reference to an entry in the second tuple entry.
     - 'offset': byte offset for the register.
     - 'mnemonic': mnemonic of the register.
     - 'fields': bitfields for this register. This is compliant to a normalized
       bitfield for bitfields.py. Each field contains the following keys:
        - 'upper_bit': high bit index.
        - 'lower_bit': low bit index.
        - 'name': field mnemonic template.
        - 'reset': reset value for each bit in the field.
       Bitfields with a function additionally contain the following keys:
        - 'defined': exists to mark that this is a defined field.
        - 'origin': where this field was defined in the config files.
        - 'reset': string with as many entries as there are bits in the field,
          defining the reset value for each bit.
        - 'signed': if this key exists, the field is signed.
        - 'alt_ids': list of (abbreviated) IDs for this field. This only works
          for 8-bit and aligned 16-bit fields. They allow the field to be
          accessed as if it's an independent register.
        - 'decl': list of \decl*{} command dictionaries.
        - 'impl': list of two-tuples, where each first entry is an origin and
          each second entry is a line of implementation code.
        - 'resimpl': same as 'impl', but for the reset implementation.
    
    The second entry is a list of register groups, where each group is generated
    by a single \register or \registergen command. It is intended for
    documentation generation. Each group is represented as a dictionary:
     - 'origin': where this group was defined.
     - 'title': register group title.
     - 'doc': LaTeX register group documentation.
     - 'mnemonic': LaTeX register group mnemonic template.
     - 'ctxt': exists only if this register group contains context-specific
       registers.
     - 'glob': exists only if this register group contains global registers.
     - 'registers': list of registers in this group. References into the
       register table, as specified above.
     - 'fields': bitfield template for this register group. This is compliant to
       a normalized bitfield for bitfields.py. Each field contains the following
       keys:
        - 'upper_bit': high bit index.
        - 'lower_bit': low bit index.
        - 'name': field mnemonic template.
        - 'reset': reset value for each bit in the field.
       Bitfields with a function may additionally contain the following keys:
        - 'defined': exists to mark that this is a defined field.
        - 'doc': LaTeX field documentation.
        - 'alt_ids': list of templates for alternate identifiers for the field.
    """
    
    # Initialize the register tables.
    num_words = 256
    regmap = [None] * num_words
    regdoc = [None] * num_words
    
    # Loop over all register commands.
    for cmd in regcmds:
        
        # Load and parse the command arguments.
        orig   = cmd['origin']
        doc    = cmd['doc']
        fields = cmd['fields']
        try:
            if cmd['cmd'][0] == 'register':
                ns     = [0]
                mnem   = cmd['cmd'][1].strip()
                title  = cmd['cmd'][2].strip()
                offs   = int(cmd['cmd'][3].strip(), 0)
                stride = 0
            elif cmd['cmd'][0] == 'registergen':
                try:
                    ns = list(eval(cmd['cmd'][1]))
                except Exception as e:
                    raise CodeError('Error parsing python range %s: %s.' %
                                    (cmd['cmd'][1], str(e)))
                mnem   = cmd['cmd'][2].strip()
                title  = cmd['cmd'][3].strip()
                offs   = int(cmd['cmd'][4].strip(), 0)
                stride = int(cmd['cmd'][5].strip(), 0)
            else:
                raise CodeError('Unimplemented command %s on line %s.' %
                                (cmd['cmd'][0], orig))
        except ValueError:
            raise CodeError('Offset or stride could not be parsed on line %s.' %
                            orig)
        rerr = 'register CR_%s on line %s' % (mnem, orig)
        
        # Check validity of the register offsets.
        for n in ns:
            roffs = offs + n * stride
            if reg_type(roffs) is None:
                raise CodeError('Invalid register offset 0x%03X in %s.' %
                                (roffs, rerr))
            if regmap[roffs // 4] is not None:
                raise CodeError('Overlapping register offsets')
        
        # Create the documentation dictionary and add it to the regdoc table:
        #  - List of sub-registers which we'll generate in a bit.
        regs = []
        
        #  - Create a copy of the fields list wherein \n{} is replaced
        #    appropriately. Only the things which are needed for the
        #    documentation are copied.
        fields_n = []
        for field in fields:
            field_n = {
                'upper_bit': field['upper_bit'],
                'lower_bit': field['lower_bit'],
                'name':      interpreter.generate(field['name']),
                'reset':     field['reset']
            }
            if 'defined' in field:
                field_n['defined'] = 'defined'
                field_n['doc'] = interpreter.generate(field['doc'])
                field_n['alt_ids'] = [interpreter.generate(x) for x in field['alt_ids']]
            fields_n += [field_n]
        
        #  - Create the dictionary.
        doc = {
            'origin':    orig,
            'title':     interpreter.generate(title),
            'doc':       interpreter.generate(doc),
            'mnemonic':  interpreter.generate(mnem, default='%s'),
            'registers': regs,
            'fields':    fields_n
        }
        
        #  - Append register type tags to the dictionary.
        for n in ns:
            rt = reg_type(offs + n * stride)
            doc[rt] = rt
        
        #  - Add the dictionary to the table.
        regdoc[(offs + ns[0] * stride) // 4] = doc
        
        # Generate the registers.
        for n in ns:
            roffs = offs + n * stride
            
            # Generate the fields.
            fields_n = []
            for field in fields:
                field_n = field.copy()
                if 'doc' in field_n:
                    del field_n['doc']
                field_n['name'] = interpreter.generate(
                    field_n['name'], values={'n': n}, default='%s')
                if 'defined' in field_n:
                    field_n['alt_ids'] = [
                        interpreter.generate(x, values={'n': n}, default='%s')
                        for x in field_n['alt_ids']]
                fields_n += [field_n]
            
            # Create the register dictionary.
            rtyp = reg_type(roffs)
            reg = {
                'doc':      doc,
                'origin':   orig,
                'offset':   roffs,
                'mnemonic': interpreter.generate(mnem, values={'n': n}, default='%s'),
                'fields':   fields_n,
                rtyp:       rtyp
            }
            
            # Add the register.
            regmap[roffs // 4] = reg
            regs += [reg]
        
        
    # We don't need the regdoc table to be indexed by the word offset of a
    # register, we just want it to be ordered by offset. We can achieve this
    # very easily by just filtering out the None entries.
    regdoc = [x for x in regdoc if x is not None]
    
    return (regmap, regdoc)


def reg_type(offset):
    """Returns the register type for the given byte offset.
    
    Return value:
     - If offset is 0x000, 0x004, ..., 0x0FC, then 'gb' is returned, indicating
       that this is a global control register.
     - If offset is 0x200, 0x204, ..., 0x3FC, then 'cx' is returned, indicating
       that this is a context control register.
     - Otherwise, None is returned.
    """
    if offset in xrange(0x000, 0x100, 4):
        return 'glob'
    elif offset in xrange(0x200, 0x400, 4):
        return 'ctxt'
    else:
        return None


def check_reg_names(regmap):
    """Checks the uniqueness and validity of all register and field mnemonics.
    Friendly exceptions are thrown if there are problems."""
    
    # Loop over all registers.
    rnams = set()
    for reg in regmap:
        if reg is None:
            continue
        
        # Make sure the register mnemonic is valid.
        rnam = reg['mnemonic']
        if not re.match(r'[A-Z0-9]+$', rnam):
            raise CodeError(('Invalid register mnemonic %s on line %s. ' + 
                            'Only A-Z and 0-9 are permitted.') %
                            (rnam, reg['origin']))
        if len(rnam) > 8:
            raise CodeError(('Invalid register mnemonic %s on line %s. ' + 
                            'A mnemonic is supposed to be short... The ' +
                            'documentation template supports up to 8 ' +
                            'characters only.') % (rnam, reg['origin']))
        if rnam in rnams:
            raise CodeError('Duplicate register mnemonic %s on line %s.' %
                            (rnam, reg['origin']))
        rnams.add(rnam)
        
        # Construct register identification message for field error messages.
        rerr = 'register CR_%s defined on line %s' % (rnam, reg['origin'])
        
        # Loop over all fields.
        fnams = set()
        for field in reg['fields']:
            if 'defined' not in field:
                continue
            
            # Make sure the field mnemonic is valid.
            fnam = field['name']
            if not re.match(r'[A-Z0-9]+$', fnam):
                raise CodeError(('Invalid field mnemonic %s in %s.' + 
                                'Only A-Z and 0-9 are permitted.')
                                % (fnam, rerr))
            size = field['upper_bit'] - field['lower_bit'] + 1
            if len(fnam) > (size * 2) - 1 or len(fnam) > 8:
                raise CodeError(('Invalid field mnemonic %s in %s. ' + 
                                'A mnemonic is supposed to be short... The ' +
                                'documentation template supports up to 8 ' +
                                'characters max, and up to 2s-1 characters ' +
                                'for bitcount s.') % (fnam, reg['origin']))
            if fnam in fnams:
                raise CodeError('Duplicate field mnemonic %s in %s.' %
                                (fnam, rerr))
            fnams.add(fnam)
            
            # While we're checking stuff anyway, also throw an error when
            # resetImplementation is specified for global registers.
            if 'glob' in reg and len(field['resimpl']) != 0:
                raise CodeError(('Reset implementation specified for field %s' +
                                'in global register %s. Only context ' +
                                'registers support this.') % (fnam, rerr))
            
            # Check alternate IDs.
            for anam in field['alt_ids']:
                if not re.match(r'[A-Z0-9]+$', anam):
                    raise CodeError(('Invalid field ID %s in %s. ' + 
                                    'Only A-Z and 0-9 are permitted.') %
                                    (anam, rerr))
                if anam in rnams:
                    raise CodeError(('Duplicate register mnemonic %s' +
                                    'due to field ID in %s.') %
                                    (anam, rerr))
                rnams.add(anam)
    

def gen_defs(regdoc):
    """Generates a list of tuples for header file generation. The possible
    tuples are:
    
    ('section', name) -> start of a definition section (for code readability).
    ('reg', name, type, offs) -> a register definition:
     - name is the CR_<reg> definition name.
     - type is a string of 4 characters:
        - char 0: 'W' if core can write, 'R' if it can't.
        - char 1: 'W' if debug bus can write, 'R' if it can't.
        - char 2: 'S' for signed, 'U' for unsigned.
        - char 3: 'W' for 32-bit, 'H' for 16-bit, 'B' for 8-bit.
     - offs is the byte offset of the register.
    ('field', name, low, mask, high) -> a field definition:
     - name is the CR_<reg>_<field> definition name.
     - low is the low order bit index of the field.
     - mask is the unshifted bitmask for the field.
     - high is the high order bit index of the field.
    """
    
    defs = []
    
    # Loop over all register groups.
    for doc in regdoc:
        
        # Add a section for each register group.
        defs += [('section', doc['title'])]
        
        # Loop over the registers in the group.
        for reg in doc['registers']:
            rnam = 'CR_' + reg['mnemonic']
            fields = reg['fields']
            
            # Output the register definition.
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
            defs += [(
                'reg',
                rnam,
                core + debug + signedness + 'W',
                reg['offset'])
            ]
            
            # Loop over the fields in the register.
            for field in fields:
                if 'defined' not in field:
                    continue
                fnam = rnam + '_' + field['name']
                
                # Compute field metrics.
                low = field['lower_bit']
                high = field['upper_bit']
                mask = (1 << high + 1) - 1
                mask -= (1 << low) - 1
                size = high - low + 1
                core = 'W' if 'core' in field else 'R'
                debug = 'W' if 'debug' in field else 'R'
                signedness = 'S' if 'signed' in field else 'U'
                sizename = 'H' if size == 16 else 'B'
                fieldtyp = core + debug + signedness + sizename
                foffs = reg['offset'] + 3 - (low // 8)
                
                # Output the field definition.
                defs += [('field', fnam, low, mask, high)]
                
                # Output alternate IDs.
                if size in [16, 8] and low % size == 0:
                    for alt_id in field['alt_ids']:
                        defs += [(
                            'reg',
                            'CR_' + alt_id,
                            fieldtyp,
                            foffs)
                        ]
    
    return defs


def gather_declarations(reg):
    """Returns a list of objects representing the declarations for the given
    register."""
    decls = []
    for field in reg['fields']:
        if 'defined' not in field:
            continue
        owner = ('cr_%s_%s' % (reg['mnemonic'], field['name'])).lower()
        for declcmd in field['decl']:
            
            # Parse the declaration command.
            origin   = declcmd['origin']
            atypspec = declcmd['cmd'][0]
            name     = declcmd['cmd'][1].strip()
            typspec  = declcmd['cmd'][2].strip()
            if len(declcmd['cmd']) >= 4:
                init = declcmd['cmd'][3].strip()
            else:
                init = None
            
            # Check the name.
            if not re.match(r'_[a-zA-Z0-9_]+', name):
                raise CodeError(('Invalid local name \'%s\' after line %s. ' +
                                'Local names must start with an underscore.') %
                                (name, origin))
            
            # Parse the type.
            try:
                typ = parse_type(typspec)
            except TypError as e:
                raise CodeError('Error parsing type \'%s\' after line %s: %s' %
                                (typspec, origin, str(e)))
            
            # If this is a context-specific field, make the type per context.
            if 'ctxt' in reg:
                typ = PerCtxt(typ)
            
            # Create the access type.
            if atypspec == 'declRegister':
                atyp = Register(typ)
            elif atypspec == 'declVariable':
                atyp = Variable(typ)
            elif atypspec == 'declConstant':
                atyp = Constant(typ)
            else:
                raise CodeError('Unknown declaration command \\%s.' % atypspec)
            
            # Construct and add the object.
            ob = Object(owner, name, atyp, origin, init)
            decls.append(ob)
    
    return decls



