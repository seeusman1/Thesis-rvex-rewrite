from __future__ import print_function

import interpreter
import copy
import bitfields

def parse_opcodes(fname):
    """Parses the opcodes.tex file.
    
    Arguments:
     - fname specifies the file to read.
      
    The return value is a two-tuple.
    
    First entry of the result two-tuple: list of dictionaries. These dicts have
    the following entries:
     - 'name': name of the group which this dict represents.
     - 'doc': LaTeX documentation for the group which this dict represents.
     - 'line_nr': line number of the group command.
     - 'syllables': list of syllables in this group.
    
    The second entry of the result two-tuple is a list with 256 entries, mapping
    to the same syllable dicts which the 'syllables' entry of the other part of
    the result maps to.
    
    Syllables are represented as another dict:
     - 'name': mnemonic for the syllable.
     - 'syntax': assembly syntax definition.
     - 'opcode': 9-bit binary string with dashes for don't cares defining opcode,
                 mapping to syllable bit 31..23
     - 'doc': LaTeX documentation for the syllable.
     - 'line_nr': line number of the syllable command.
     - 'class': resource class string.
     - 'noasm': set to True if \noasm{} was specified, False otherwise.
     - 'datapath': dict with datapath control key-value pairs.
     - 'alu': dict with alu control key-value pairs.
     - 'branch': dict with branch control key-value pairs.
     - 'memory': dict with memory control key-value pairs.
     - 'multiplier': dict with multiplier control key-value pairs.
    """
    
    # Parse the file.
    groups = interpreter.parse_file(fname, {
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
                'line_nr': group['line_nr'],
                'syllables': []
            }]
        elif group['cmd'][0] == 'syllable':
            if len(sections) == 0:
                raise Exception('syllable defined before the first section at ' +
                            fname + ':' + str(group['line_nr']))
            syllable = copy.deepcopy(group_params)
            apply_params(syllable, group)
            
            opcode = group['cmd'][1].strip()
            if len(opcode) != 9:
                raise Exception('Number of bits in opcode must be 9 at ' +
                            fname + ':' + str(group['line_nr']))
            for c in opcode:
                if c not in ['0', '1', '-']:
                    raise Exception('Invalid character in opcode at ' +
                                fname + ':' + str(group['line_nr']))
            
            syllable['name'] = group['cmd'][2].strip().upper()
            syllable['syntax'] = group['cmd'][2].strip().lower() + ' ' + group['cmd'][3].strip()
            syllable['opcode'] = opcode
            syllable['doc'] = group['doc']
            syllable['line_nr'] = group['line_nr']
            
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
                                        fname + ':' + str(group['line_nr']))
                    else:
                        table[x] = syllable
        else:
            raise Exception('Unrecognized group command at ' +
                            fname + ':' + str(group['line_nr']))
    
    return (sections, table)

def get_bitfields(syl, imm_sw):
    """Returns the bit format which describe the given syllable."""
    
    fields = []
    for i, b in enumerate(syl['opcode']):
        if b != '-':
            fields += [{
                'range': str(31 - i),
                'name': b,
                'group': 'opcode'
            }]
    if '\\rd' in syl['syntax']:
        fields += [{
            'range': '22..17',
            'name': '$r0.d',
            'group': '$r0.d'
        }]
    if '\\rx' in syl['syntax']:
        fields += [{
            'range': '16..11',
            'name': '$r0.x',
            'group': '$r0.x'
        }]
    if '\\ry' in syl['syntax']:
        if imm_sw == 0:
            fields += [{
                'range': '10..5',
                'name': '$r0.y',
                'group': '$r0.y'
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
                'group': 'opcode'
            }]
    brfmt = 0
    if 'brFmt' in syl['datapath']:
        if syl['datapath']['brFmt'] == "'1'":
            brfmt = 1
    if '\\bd' in syl['syntax']:
        if brfmt == 0:
            fields += [{
                'range': '19..17',
                'name': '$b0.d',
                'group': '$b0.d'
            }]
        else:
            fields += [{
                'range': '4..2',
                'name': '$b0.d',
                'group': '$b0.d'
            }]
    if '\\bs' in syl['syntax']:
        if brfmt == 0:
            fields += [{
                'range': '4..2',
                'name': '$b0.s',
                'group': '$b0.s'
            }]
        else:
            fields += [{
                'range': '26..24',
                'name': '$b0.s',
                'group': '$b0.s'
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
        fields = bitfields.parse(fields, {'name': '.........................................................'})
    except Exception as e:
        raise Exception('Some fields needed to describe ' + syl['name'] +
                        ' (line ' + str(syl['line_nr']) + ') overlap: ' +
                        str(e))
    
    return fields

sections, table = parse_opcodes('../opcodes.tex')

print('|-:-:-:-+-:-:-:-|-:-:-:-+-:-:-:-|-:-:-:-+-:-:-:-|-:-:-:-+-:-:-:-|------|')
prev_syl = None
for opc, syl in enumerate(table):
    if syl is None:
        continue
    if prev_syl is syl:
        continue
    prev_syl = syl
    if '\\ry' in syl['syntax']:
        imm_sws = [0, 1]
    else:
        imm_sws = [0]
    if syl['opcode'][8] == '0':
        imm_sws = [0]
    elif syl['opcode'][8] == '1':
        imm_sws = [1]
    for i, imm_sw in enumerate(imm_sws):
        if i != 0:
            h = '    '
        elif '-' in syl['opcode'][:8]:
            h = '... '
        else:
            h = '0x%02X' % opc
        fields = get_bitfields(syl, imm_sw)
        print(bitfields.format_comment(
            fields, '', header=False, footer=False)[:-1] + ' ' + h + ' | ' + syl['syntax'])
    print('|-:-:-:-+-:-:-:-|-:-:-:-+-:-:-:-|-:-:-:-+-:-:-:-|-:-:-:-+-:-:-:-|------|')
    
    