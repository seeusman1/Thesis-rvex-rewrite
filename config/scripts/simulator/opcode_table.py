from __future__ import print_function

import common.templates
import code.type_sys
import opcode_table
import itertools
import pprint
import re

def generate(opc, header, source):
    output = []
    
    entries = [
        ['datapath',   'D', 'datapathCtrlSignals_t'],
        ['alu',        'A', 'aluCtrlSignals_t'],
        ['branch',     'B', 'branchCtrlSignals_t'],
        ['memory',     'M', 'memoryCtrlSignals_t'],
        ['multiplier', 'U', 'multiplierCtrlSignals_t']
    ]
    
    # Figure out the typedefs.
    for entry in entries:
        header.append(gen_typedefs(opc, entry))
    
    # Output the table entry typedef.
    header.append('typedef struct {\n')
    header.append('    uint8_t valid[2];\n')
    header.append('    datapathCtrlSignals_t datapathCtrl;\n')
    header.append('    aluCtrlSignals_t aluCtrl;\n')
    header.append('    branchCtrlSignals_t branchCtrl;\n')
    header.append('    memoryCtrlSignals_t memoryCtrl;\n')
    header.append('    multiplierCtrlSignals_t multiplierCtrl;\n')
    header.append('} opcodeTableEntry_t;\n\n')

    # Output the lookup table.
    header.append('extern const opcodeTableEntry_t OPCODE_TABLE[256];\n')
    source.append('const opcodeTableEntry_t OPCODE_TABLE[256] = {\n')
    for i, o in enumerate(opc['table']):
        if o is None:
            o = opc['def_params']
            name = 'undefined'
        else:
            name = o['name']
        valid_reg = 0
        valid_imm = 0
        if 'opcode' in o:
            if o['opcode'][8] in ['0', '-']:
                valid_reg = 1
            if o['opcode'][8] in ['1', '-']:
                valid_imm = 1
        source.append('    { /* 0x%02X = %s */ { %d, %d },\n' %
                      (i, name, valid_reg, valid_imm))
        for entry in entries:
            source.append('        { ')
            for key in entry[3]:
                value = o[entry[0]][key]
                if value in ["'0'", "'1'"]:
                    value = value[1]
                else:
                    value = '%s_%s_%s' % (entry[1], key.upper(), value)
                source.append(value)
                source.append(', ')
            source[-1] = ' '
            source.append('},\n')
        source[-1] = '}}'
        source.append(',\n')
    source[-1] = '\n};\n'


def gen_typedefs(opc, entry):
    output = []
    entry_name, prefix, typename = entry
    
    # Get all values for each entry.
    values = {}
    for o in itertools.chain([opc['def_params']], opc['table']):
        if o is None:
            continue
        d = o[entry_name]
        for key in d:
            value = d[key]
            if key not in values:
                values[key] = set()
            values[key].add(value)
    
    # Infer the type (enum or bit) from the values and generate the typedefs.
    order = []
    bits = []
    struct_enum = ['typedef struct {\n']
    struct_bits = []
    for key in values:
        is_std_logic = False
        is_enum = False
        for value in values[key]:
            if value in ["'0'", "'1'"]:
                is_std_logic = True
                continue
            if not re.match(r'[A-Z][A-Z0-9_]*$', value):
                raise Exception(('Opcode attribute %s.%s is assigned \'%s\' ' +
                                 'somewhere, which is not a legal enum or ' +
                                 'std_logic value (note that enum entries ' +
                                 'must be uppercase).') % (entry_name, key, value))
            is_enum = True
        if is_enum and is_std_logic:
            raise Exception(('Opcode attribute %s.%s is assigned both enum ' +
                             'and std_logic values.') % (entry_name, key))
        elif not is_enum and not is_std_logic:
            raise Exception('You broke it, didn\'t you?')
        if is_enum:
            typ = '%s%s%s_t' % (entry_name, key[0].upper(), key[1:])
            output.append('typedef enum {\n')
            for value in values[key]:
                output.append('    %s_%s_%s' % (prefix, key.upper(), value))
                output.append(',\n')
            output[-1] = '\n'
            output.append('} %s;\n\n' % typ)
            struct_enum.append('    %s %s;\n' % (typ, key))
            order.append(key)
        else:
            struct_bits.append('    unsigned int %s : 1;\n' % key)
            bits.append(key)
    order += bits
    output.append(''.join(struct_enum))
    output.append(''.join(struct_bits))
    output.append('} %s;\n\n' % typename)
    
    entry.append(order)
    return ''.join(output)


#def gen_entry(o, entry, prefix, order, output)