from __future__ import print_function

import common.interpreter
import common.bitfields
import copy
interpreter = common.interpreter
bitfields = common.bitfields

def parse(indir):
    """Parses the opcodes .tex files.
    
    Arguments:
     - indir specifies the directory in which to look for .tex files.
      
    The return value is a dictionary.
    
    'sections': list of dictionaries. These dicts have the following entries:
     - 'name': name of the group which this dict represents.
     - 'doc': LaTeX documentation for the group which this dict represents.
     - 'origin': line number and filename of the group command.
     - 'syllables': list of syllables in this group.
    
    'table': a list with 256 entries, mapping to the same syllable dicts which
    the 'syllables' entry of the other part of the result maps to.
    
    'def_params': a dictionary containing the default syllable configuration,
    i.e. a full syllable specification except for the 'name', 'syntax',
    'opcode', 'doc' and 'origin' fields.
    
    Syllables are represented as another dict:
     - 'name': mnemonic for the syllable.
     - 'syntax': assembly syntax definition.
     - 'opcode': 9-bit binary string with dashes for don't cares defining opcode,
                 mapping to syllable bit 31..23
     - 'doc': LaTeX documentation for the syllable.
     - 'origin': line number and filename of the syllable command.
     - 'class': resource class string.
     - 'noasm': set to True if \noasm{} was specified, False otherwise.
     - 'datapath': dict with datapath control key-value pairs.
     - 'alu': dict with alu control key-value pairs.
     - 'branch': dict with branch control key-value pairs.
     - 'memory': dict with memory control key-value pairs.
     - 'multiplier': dict with multiplier control key-value pairs.
    """
    
    # Parse the file.
    groups = interpreter.parse_files(indir, {
        'section': (1, True),
        'syllable': (3, True),
        'class': (1, False),
        'datapath': (2, False),
        'alu': (2, False),
        'branch': (2, False),
        'memory': (2, False),
        'multiplier': (2, False),
        'noasm': (0, False)
    })
    
    # Apply hierarchy.
    def_params = {
        'class': 'ALU',
        'noasm': 'False',
        'datapath': {},
        'alu': {},
        'branch': {},
        'memory': {},
        'multiplier': {}
    }
    def apply_params(params, group):
        for cmd in group['subcmds']:
            if cmd[0] == 'class':
                params['class'] = cmd[1]
            elif cmd[0] == 'noasm':
                params['noasm'] = True
            else:
                params[cmd[0]][cmd[1]] = cmd[2]
    apply_params(def_params, groups[0])
    group_params = None
    sections = []
    table = [None] * 256
    for group in groups[1:]:
        if group['cmd'][0] == 'section':
            group_params = copy.deepcopy(def_params)
            apply_params(group_params, group)
            sections += [{
                'name': group['cmd'][1].strip(),
                'doc': group['doc'],
                'origin': group['origin'],
                'syllables': []
            }]
        elif group['cmd'][0] == 'syllable':
            if len(sections) == 0:
                raise Exception('syllable defined before the first section at ' +
                            group['origin'])
            syllable = copy.deepcopy(group_params)
            apply_params(syllable, group)
            
            opcode = group['cmd'][1].strip()
            if len(opcode) != 9:
                raise Exception('Number of bits in opcode must be 9 at ' +
                            group['origin'])
            for c in opcode:
                if c not in ['0', '1', '-']:
                    raise Exception('Invalid character in opcode at ' +
                                group['origin'])
            
            syllable['name'] = group['cmd'][2].strip().upper()
            syllable['syntax'] = group['cmd'][2].strip().lower() + ' ' + group['cmd'][3].strip()
            syllable['opcode'] = opcode
            syllable['doc'] = group['doc']
            syllable['origin'] = group['origin']
            
            # Add syllable to the latest defined section.
            sections[-1]['syllables'] += [syllable]
            
            # Add syllable to the decoding table and check for conflicts.
            for x in range(256):
                for i, b in enumerate(opcode[:8]):
                    if b == '-':
                        continue
                    elif (b == '1') == (x & (128 >> i) > 0):
                        continue
                    break
                else:
                    if table[x] is not None:
                        raise Exception(('Conflict for opcode 0x%02X at ' % x) +
                                        group['origin'])
                    else:
                        table[x] = syllable
        else:
            raise Exception('Unrecognized group command at ' +
                            group['origin'])
    
    return {
        'sections': sections,
        'table': table,
        'def_params': def_params
    }

def get_brfmt(syl):
    if 'brFmt' in syl['datapath']:
        if syl['datapath']['brFmt'] == "'1'":
            return 1
    return 0

def get_imm_sw(syl):
    if '\\ry' in syl['syntax']:
        # Output both.
        imm_sws = [0, 1]
    else:
        # The value of imm_sw is don't care, so output once.
        imm_sws = [0]
    if syl['opcode'][8] == '0':
        # Instruction doesn't support immediate mode.
        imm_sws = [0]
    elif syl['opcode'][8] == '1':
        # Instruction doesn't support register mode.
        imm_sws = [1]
    return imm_sws

def format_syntax(s, style, syl, imm_sw, require_curly_brackets=False):
    """Formats the syntax definitions into a given style.
    
    Style may be 'plain', 'latex' or 'vhdl'."""
    
    # Figure out the right replacement table for 
    if style == 'vhdl':
        table = {
            '\\rd': 'r#.%r1',
            '\\rx': 'r#.%r2',
            '\\ry': 'r#.%r3',
            '\\rs': 'r#.1',
            '\\bd': 'b#.%b2',
            '\\bs': 'b#.%b3',
            '\\lr': 'l#.0',
            '\\of': '%bt',
            '\\sa': '%bi',
            '\\lt': '%i1',
            '\\li': '%i2'
        }
        if imm_sw == 1:
            table['\\ry'] = '%ih'
        if get_brfmt(syl) == 1:
            table['\\bd'] = 'b#.%b3'
            table['\\bs'] = 'b#.%b1'
    else:
        table = {
            '\\rd': '$r0.d',
            '\\rx': '$r0.x',
            '\\ry': '$r0.y',
            '\\rs': '$r0.1',
            '\\bd': '$b0.bd',
            '\\bs': '$b0.bs',
            '\\lr': '$l0.0',
            '\\of': 'offs',
            '\\sa': 'stackadj',
            '\\lt': 'tgt',
            '\\li': 'imm'
        }
        if imm_sw is None:
            table['\\ry'] = '[$r0.y|imm]'
        elif imm_sw == 1:
            table['\\ry'] = 'imm'
        if style == 'latex':
            for cmd in table:
                table[cmd] = '\code{' + table[cmd] + '}'
            if imm_sw is None:
                table['\\ry'] = '[ \code{$r0.y} | \code{imm} ]'
            elif imm_sw == 1:
                table['\\ry'] = '\code{imm}'
    
    # Apply replacements.
    for cmd in table:
        s = s.replace(cmd + '{}', table[cmd])
    if not require_curly_brackets:
        for cmd in table:
            s = s.replace(cmd, table[cmd])
    
    return s

def get_bitfields(syl, imm_sw):
    """Returns the bit format which describe the given syllable."""
    
    fields = []
    for i, b in enumerate(syl['opcode']):
        if b != '-':
            fields += [{
                'range': str(31 - i),
                'name': b,
                'group': 'opcode' if i < 8 else 'imm_sw'
            }]
    if '\\rd' in syl['syntax']:
        fields += [{
            'range': '22..17',
            'name': 'd',
            'group': 'd'
        }]
    if '\\rx' in syl['syntax']:
        fields += [{
            'range': '16..11',
            'name': 'x',
            'group': 'x'
        }]
    if '\\ry' in syl['syntax']:
        if imm_sw == 0:
            fields += [{
                'range': '10..5',
                'name': 'y',
                'group': 'y'
            }]
        else:
            fields += [{
                'range': '10..2',
                'name': 'imm',
                'group': 'imm'
            }]
        if syl['opcode'][8] == '-':
            fields += [{
                'range': '23',
                'name': str(imm_sw),
                'group': 'imm_sw'
            }]
    if '\\bd' in syl['syntax']:
        if get_brfmt(syl) == 0:
            fields += [{
                'range': '19..17',
                'name': 'bd',
                'group': 'bd'
            }]
        else:
            fields += [{
                'range': '4..2',
                'name': 'bd',
                'group': 'bd'
            }]
    if '\\bs' in syl['syntax']:
        if get_brfmt(syl) == 0:
            fields += [{
                'range': '4..2',
                'name': 'bs',
                'group': 'bs'
            }]
        else:
            fields += [{
                'range': '26..24',
                'name': 'bs',
                'group': 'bs'
            }]
    if '\\of' in syl['syntax']:
        fields += [{
            'range': '23..5',
            'name': 'offs',
            'group': 'offs'
        }]
    if '\\sa' in syl['syntax']:
        fields += [{
            'range': '23..5',
            'name': 'stackadj',
            'group': 'stackadj'
        }]
    if '\\lt' in syl['syntax']:
        fields += [{
            'range': '27..25',
            'name': 'tgt',
            'group': 'tgt'
        }]
    if '\\li' in syl['syntax']:
        fields += [{
            'range': '24..2',
            'name': 'imm',
            'group': 'imm'
        }]
    fields += [{
        'range': '1',
        'name': 'S',
        'group': 'S'
    }]
    
    try:
        fields = bitfields.parse(fields, {'name': ''})
    except Exception as e:
        raise Exception('Some fields needed to describe ' + syl['name'] +
                        ' (line ' + str(syl['origin']) + ') overlap: ' +
                        str(e))
    
    return fields

