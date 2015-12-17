import copy
import pprint

def normalize(fields, empty={'name': ''}):
    """Normalizes 32-bit bitfield declarations.
    
    The fields parameter must be a list of dicts. These dicts must define at
    least the following keys:
     - 'upper_bit': start bit from 0 to 31, inclusive.
     - 'lower_bit': end bit from 0 to 31, inclusive.
     - 'name': used for informative error messages.
    
    The empty parameter is an optional dict specifying keys to be used for
    fields inserted to fill undefined bits.
    
    The output is has the same format as the input, except that it is guaranteed
    that the fields will not overlap, that all 32 bits are assigned a field
    specification by means of adding empty fields, and that they are ordered
    from high bit down to low bit. An exception is thrown if fields overlap.
    """
    
    # Assign the fields to the bits in a bit array which they include.
    bits = [empty] * 32
    for field in fields:
        
        # Do range checking.
        if field['lower_bit'] > field['upper_bit']:
            raise Exception('Invalid 32-bit range ' + str(field['upper_bit']) +
                            ' downto ' + str(field['lower_bit']) +
                            ' for field ' + field['name'])
        if field['lower_bit'] < 0:
            raise Exception('Invalid 32-bit range ' + str(field['upper_bit']) +
                            ' downto ' + str(field['lower_bit']) +
                            ' for field ' + field['name'])
        if field['upper_bit'] > 31:
            raise Exception('Invalid 32-bit range ' + str(field['upper_bit']) +
                            ' downto ' + str(field['lower_bit']) +
                            ' for field ' + field['name'])
        
        # Try to assign the field to the bits it specifies.
        for i in range(field['lower_bit'], field['upper_bit']+1):
            
            # Check for overlapping fields first.
            if bits[i] is not empty:
                raise Exception('Field ' + field['name'] + 
                                ' (' + str(field['upper_bit']) +
                                ' downto ' + str(field['lower_bit']) + ')' +
                                ' overlaps with field ' + bits[i]['name'] +
                                ' (' + str(bits[i]['upper_bit']) +
                                ' downto ' + str(bits[i]['lower_bit']) + ')')
            
            # No overlap, add to this bit.
            bits[i] = field
    
    # Turn the bits array back into the right format.
    fields = []
    prev_field = None
    upper_bit = -1
    for bit, field in list(reversed(list(enumerate(bits + [None])))) + [(-1, None)]:
        if field is not prev_field:
            if prev_field is not None:
                f = copy.deepcopy(prev_field)
                f['upper_bit'] = upper_bit
                f['lower_bit'] = bit + 1
                fields += [f]
            if field is not None:
                upper_bit = bit
            prev_field = field
    
    return fields

def parse(fields, empty={'name': ''}):
    """Parses and normalizes 32-bit bitfield declarations.
    
    fields may be a list of dicts or a single dictionary.
    
    If fields is a list of dicts, these dicts must define at least the following
    keys:
     - 'range': string with a single single bit index or a range of the form
                x..y, where x >= y.
     - 'name': used for informative error messages.
    
    If fields is a single dict, the keys are interpreted as ranges and the
    values as the field names.
    
    The output is identical to that of normalize().
    """
    
    if type(fields) is list:
        
        # Don't overwrite input dicts, just in case.
        fields = copy.deepcopy(fields)
        
    else:
        
        # Convert the input dict to the list of dicts format.
        inp = fields
        fields = []
        for r in inp:
            fields += [{'range': r, 'name': inp[r]}]
    
    # Parse ranges.
    for field in fields:
        r = field['range'].split('..')
        try:
            if len(r) > 2:
                raise ValueError()
            field['upper_bit'] = int(r[0].strip())
            field['lower_bit'] = int(r[-1].strip())
        except ValueError:
            raise Exception('Invalid range ' + str(r) +
                            ' for field ' + field['name'])
    
    # Return normalized range.
    return normalize(fields, empty)

def format_tex(fields):
    """Formats the bitfield as a LaTeX table.
    
    This will format 32 table columns (so 31 & symbols) describing the given
    bitfield. The bitfield MUST be normalized using parse() or normalize() or
    behavior is undefined.
    
    Fields may include the 'group' key. If two neighboring fields have the same
    group name, no line will be drawn between the fields. This is intended for
    single bit fields.
    
    Returns the formatted string.
    """
    pass

def format_tex_head():
    """Formats a LaTeX bitfield table header with bit indices.
    
    Use in conjunction with print_tex().
    
    Returns the formatted string.
    """
    pass

def format_comment(fields, prefix, header=True, footer=True):
    """Formats the bitfield as a LaTeX table.
    
    This will format the given bitfield as an ASCII art table. prefix is added
    to the start of every line. header and footer determine whether a table
    border is output at the top or bottom. The bitfield MUST be normalized using
    parse() or normalize() or behavior is undefined.
    
    Fields may include the 'group' key. If two neighboring fields have the same
    group name, no line will be drawn between the fields. This is intended for
    single bit fields.
    
    Returns the formatted string.
    """
    
    line = '|-:-:-:-+-:-:-:-|-:-:-:-+-:-:-:-|-:-:-:-+-:-:-:-|-:-:-:-+-:-:-:-|\n'
    
    text = ''
    if header:
        text = prefix + line
    text += prefix
    prev_group = None
    for field in fields:
        group = None
        if 'group' in field:
            group = field['group']
        if group != prev_group or group is None:
            text += '|'
        else:
            text += ' '
        prev_group = group
        l = field['upper_bit'] - field['lower_bit'] + 1
        l = l*2 - 1
        n = field['name'][:l]
        while len(n) < l:
            n = ' ' + n + ' '
        text += n[-l:]
        
    text += '|\n'
    if footer:
        text += prefix + line
    return text


#print(format_comment(parse([
#    {'range': '31', 'name': '0', 'group': 'opcode'},
#    {'range': '30', 'name': '0', 'group': 'opcode'},
#    {'range': '29', 'name': '0', 'group': 'opcode'},
#    {'range': '28', 'name': '0', 'group': 'opcode'},
#    {'range': '27..25', 'name': 'tgt', 'group': 'tgt'},
#    {'range': '24..2', 'name': 'imm', 'group': 'imm'}
#]), '// '))
