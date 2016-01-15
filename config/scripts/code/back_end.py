"""This module contains all the functions which do the actual code generation,
i.e. the back-end."""

from type_sys import *
from environment import *
from excepts import *

def generate_vhdl_libfuncs():
    """'Generates' the VHDL functions which the generated code needs to work."""
    
    return """
-- Coerces string literal x to an std_logic_vector.
function bitvec_lit(x: std_logic_vector) return std_logic_vector is
begin
  return x;
end bitvec_lit;

-- Coerces string literal x to an unsigned.
function unsigned_lit(x: unsigned) return unsigned is
begin
  return x;
end unsigned_lit;

-- Reduces an std_logic_vector to a single std_logic using OR.
function vec2bit(x: std_logic_vector) return std_logic is
  variable y : std_logic;
begin
  y := '0';
  for i in x'range loop
    y := y or x(i);
  end loop;
  return y;
end vec2bit;

-- Returns an std_logic_vector of size s with bit 0 set to std_logic x and the
-- rest to '0'.
function bit2vec(x: std_logic; s: natural) return std_logic_vector is
  variable result: std_logic_vector(s-1 downto 0) := (others => '0');
begin
  result(0) := x;
  return result;
end bit2vec;

-- Returns boolean x as an std_logic using positive logic.
function bool2bit(x: boolean) return std_logic is
begin
  if x then
    return '1';
  else
    return '0';
  end if;
end bool2bit;

-- Returns std_logic x as a boolean using positive logic.
function bit2bool(x: std_logic) return boolean is
begin
  return x = '1';
end bit2bool;

-- Returns 1 for true and 0 for false.
function bool2int(x: boolean) return natural is
begin
  if x then
    return 1;
  else
    return 0;
  end if;
end bool2int;

-- Returns true for nonzero and false for zero.
function int2bool(x: integer) return boolean is
begin
  return x /= 0;
end int2bool;
"""



def generate_declaration_vhdl(ob, init=None):
    """Generates the code for a VHDL object declaration. If ob is a constant,
    init should be set to a string representing the value."""
    
    obtype = ob.atyp.name()
    
    # Generate VHDL syntax.
    if obtype == 'variable':
        vhdl = 'variable %s' % ob.name
    elif obtype == 'constant':
        vhdl = 'constant %s' % ob.name
    elif obtype == 'register':
        vhdl = 'signal %s' % ob.name
    else:
        vhdl = ob.name
    vhdl = vhdl + ' ' * (28 - len(vhdl)) + ': '
    if obtype == 'input':
        vhdl += 'in  '
    elif obtype == 'output':
        vhdl += 'out '
    vhdl += ob.atyp.typ.name_vhdl()
    if obtype == 'constant':
        vhdl += ' := %s' % init
    return vhdl + ';\n'


def generate_literal(val, typ):
    """Returns a two-tuple with a VHDL literal in the first entry and a C
    literal in the second."""
    
    cls = typ.cls()
    
    # Generate VHDL syntax.
    if cls == 'boolean':
        if val != 0:
            vhdl = 'true'
        else:
            vhdl = 'false'
    
    elif cls == 'natural':
        vhdl = '%d' % val
        
    elif cls == 'bit':
        vhdl = "'%d'" % val
    
    elif cls.startswith('bitvec'):
        vhdl = ('bitvec_lit("{0:0%db}")' % typ.size).format(val)
    
    elif cls.startswith('unsigned'):
        vhdl = ('unsigned_lit("{0:0%db}")' % typ.size).format(val)
    
    else:
        raise CodeError('unknown literal type class %s.' % cls)
    
    # Generate C syntax.
    return (vhdl, '%dull' % val)


def generate_aggregate(members, typ):
    """Generates the code for a VHDL aggregate/C compound literal. members if
    a dictionary mapping each member of aggregate type typ to a two-tuple
    representing the expression which that member should be set to, with the
    VHDL code in the first entry and the C code in the second. Returns a
    two-tuple with a VHDL code in the first entry and a C code in the
    second."""
    
    vhdl = ['(\n']
    c = ['(%s) {{\n' % typ.name_c()]
    
    nothing = True
    for partial in typ.get_member_order():
        if partial in members:
            code = members[partial]
            nothing = False
            
            # Append scalar initializer.
            vhdl.append('%s => ' % partial)
            vhdl.append(code[0])
            vhdl.append(',\n')
            c.append('/* %s */ {{\n' % partial)
            c.append(code[1])
            c.append(', \n')
            
            continue
        
        # Append array initializer opening.
        vhdl.append('%s => (\n' % partial)
        vhdl.append('')
        c.append('/* %s */ {{\n' % partial)
        c.append('')
        
        i = 0
        while True:
            name = '%s{%d}' % (partial, i)
            if name not in members:
                break
            code = members[name]
            nothing = False
            
            # Append array initializer entry.
            vhdl.append('%d => ' % i)
            vhdl.append(code[0])
            vhdl.append(',\n')
            c.append('/* %d */ ' % i)
            c.append(code[1])
            c.append(', \n')
            
            i += 1
        
        # Replace the last comma with the closing bracket.
        vhdl[-1] = '\n)'
        vhdl.append(', \n')
        c[-1] = '\n}}'
        c.append(', \n')
        
    if nothing:
        raise CodeError(('something horrible went wrong. Is aggregate type ' +
                        '%s empty?') % typ)
    
    # Replace the last comma with the closing bracket.
    vhdl[-1] = '\n)'
    c[-1] = '\n}}'
    
    return (''.join(vhdl), ''.join(c))

def generate_reference(ob, ctxt, direction='r'):
    """Generates the code for reading from or writing to an object. Returns a
    two-tuple with the VHDL code in the first entry and the C code in the
    second."""
    
    name = ob.name
    
    # Generate VHDL syntax.
    vhdl = name
    if ctxt is not None:
        vhdl = '%s(%s)' % (vhdl, ctxt)
    
    # Generate C syntax.
    if ob.atyp.name() in ['input', 'output']:
        if ctxt is not None:
            c = 'cxiface[%s]->%s' % (ctxt, name)
        else:
            c = 'gbiface->%s' % name
    elif ob.atyp.name() in ['register']:
        if direction == 'r':
            qd = 'q'
        else:
            qd = 'd'
        if ctxt is not None:
            c = 'cxr%s[%s]->%s' % (qd, ctxt, name)
        else:
            c = 'gbr%s->%s' % (qd, name)
    else:
        if ctxt is not None:
            c = '%s[%s]' % (name, ctxt)
        else:
            c = '%s' % name
    
    return (vhdl, c)
    

def generate_member(member):
    """Generates the code for accessing a member of an aggregate type. Returns a
    two-tuple with the VHDL code in the first entry and the C code in the
    second. {0} is used as a template for the aggregate object. This works for
    both reading and writing to objects."""
    return ('{0}.%s' % member.replace('{', '(').replace('}', ')'),
            '{0}.%s' % member.replace('{', '[').replace('}', ']'))
    

def generate_slice_read(size):
    """Generates the code for slicing a bitvec or unsigned type. size defines
    the size of the slice, or None to do an index operation. Returns a two-tuple
    with the VHDL code in the first entry and the C code in the second. {0} is
    used as a template for the object, {1} for the index expression. This only
    works for reading; writing is handled by generate_assignment()."""
    
    # We can get away with just a rightshift in C because the higher order bits
    # in bitvec and unsigned types are ignored by all operations by convention.
    if size is None:
        return('{0}({1})',
               '{0}>>({1})')
    else:
        return('{0}(({1})+%d downto {1})' % (size - 1),
               '{0}>>({1})')


def generate_typecast(from_typ, to_cls, explicit=False):
    """Returns code for a typecast from type from_typ to type class to_cls.
    from_cls must be fully specified, to_cls may omit the size specification
    if it is not known. explicit may be set to True to force a dubious type
    cast. The result is a three-tuple with vhdl code in the first entry, c
    code in the second and the resulting type class in the third. {0} is
    used as a .format specifier for the expression which is to be cast in
    the code strings."""
    
    from_cls = from_typ.cls()
    
    # Handle trivial cases.
    if ((to_cls == from_cls) or
        (to_cls == 'bitvec' and from_cls.startswith('bitvec')) or
        (to_cls == 'unsigned' and from_cls.startswith('unsigned'))):
        return ('{0}',
                '{0}',
                from_typ)
    
    # Shorthand for the class size function.
    size = cls_size
    
    # Figures out the C bitmask for bitvec and unsigned class names or an
    # integer size.
    def c_mask(x):
        if type(x) is not int:
            x = size(x)
        return '0x%Xull' % ((1 << x) - 1)
    
    # Figures out the size for the result heuristically if possible if it
    # isn't specified.
    def to_size():
        
        # Look for an explicit size.
        try:
            return size(to_cls)
        except ValueError:
            pass
        
        # If the input is a bit or a boolean, then assume size 1.
        if from_cls in ['bit', 'boolean']:
            return 1
        
        # Use the input size.
        try:
            return size(from_cls)
        except ValueError:
            pass
        
        # Only natural is left (and aggregates, I guess, which aren't
        # supported at all). For naturals, we require an explicit size
        # through an explicit cast because just pulling a number out of
        # nowhere is a bit weird.
        raise CodeError(('cannot determine the %s size from type %s. Use ' +
                        'an explicit cast for this.') % (to_cls, from_cls))
    
    # Handle conversions to boolean.
    if to_cls == 'boolean':
        if from_cls == 'natural':
            # Returns true if nonzero, false otherwise.
            return ('int2bool({0})',
                    '!!({0})',
                    Boolean())
        
        elif from_cls == 'bit':
            # Returns true if bit is high.
            return ('bit2bool({0})',
                    '({0})&1ull',
                    Boolean())
        
        elif from_cls.startswith('bitvec'):
            # Returns true if any bit is high.
            return ('bit2bool(vec2bit({0}))',
                    '!!(({0})&%s)' % c_mask(from_cls),
                    Boolean())
        
        elif from_cls.startswith('unsigned'):
            # Returns true if any bit is high.
            return ('bit2bool(vec2bit(std_logic_vector({0})))',
                    '!!(({0})&%s)' % c_mask(from_cls),
                    Boolean())
        
    # Handle conversions to natural.
    if to_cls == 'natural':
        if from_cls == 'boolean':
            # Returns 1 for true and 0 for false.
            return ('bool2int({0})',
                    '{0}',
                    Natural())
        
        elif from_cls == 'bit':
            # Returns 1 for '1' and 0 for '0'.
            return ('bool2int(bit2bool({0}))',
                    '({0})&1ull',
                    Natural())
        
        elif from_cls.startswith('bitvec'):
            # Returns the value of the bitvec interpreted as an unsigned.
            if size(from_cls) > 31:
                if not explicit:
                    raise CodeError(('implicitely casting %s to (31-bit) ' +
                        'natural is disabled. Use an explicit cast if you ' +
                        'really want this.') % from_cls)
                return ('to_integer(resize(unsigned({0}), 31))',
                        '({0})&0x7FFFFFFFull',
                        Natural())
            return ('to_integer(unsigned({0}))',
                    '({0})&%s' % c_mask(from_cls),
                    Natural())
        
        elif from_cls.startswith('unsigned'):
            # Returns the value of the unsigned.
            if size(from_cls) > 31:
                if not explicit:
                    raise CodeError(('implicitely casting %s to (31-bit) ' +
                        'natural is disabled. Use an explicit cast if you ' +
                        'really want this.') % from_cls)
                return ('to_integer(resize({0}, 31))',
                        '({0})&0x7FFFFFFFull',
                        Natural())
            return ('to_integer({0})',
                    '({0})&%s' % c_mask(from_cls),
                    Natural())
        
    # Handle conversions to bit.
    if to_cls == 'bit':
        if from_cls == 'boolean':
            # Returns '1' for true and '0' for false.
            return ('bool2bit({0})',
                    '{0}',
                    Bit())
        
        elif from_cls == 'natural':
            # Returns '1' if nonzero, '0' otherwise.
            return ('bool2bit(int2bool({0}))',
                    '!!({0})',
                    Bit())
        
        elif from_cls.startswith('bitvec'):
            # Returns 1 if any bit is high, 0 otherwise.
            if size(from_cls) > 1 and not explicit:
                raise CodeError(('implicitely casting %s to bit is ' +
                    'disabled. Use an explicit cast if you really want ' +
                    'this, it will result in the OR of all bits.') % from_cls)
            return ('vec2bit({0})',
                    '!!(({0})&%s)' % c_mask(from_cls),
                    Bit())
        
        elif from_cls.startswith('unsigned'):
            # Returns 1 if any bit is high, 0 otherwise.
            if size(from_cls) > 1 and not explicit:
                raise CodeError(('implicitely casting %s to bit is ' +
                    'disabled. Use an explicit cast if you really want ' +
                    'this, it will result in the OR of all bits.') % from_cls)
            return ('vec2bit(std_logic_vector({0}))',
                    '!!(({0})&%s)' % c_mask(from_cls),
                    Bit())
        
    # Handle conversions to bitvec.
    if to_cls.startswith('bitvec'):
        to_size = to_size()
        if from_cls == 'boolean':
            # Returns a vector representing 1 for true and 0 for false.
            return ('bit2vec(bool2bit({0}), %d)' % to_size,
                    '({0})&1ull',
                    BitVector(to_size))
        
        elif from_cls == 'natural':
            # Integer to unsigned.
            return ('std_logic_vector(to_unsigned({0}, %d))' % to_size,
                    '{0}',
                    BitVector(to_size))
        
        elif from_cls == 'bit':
            # Returns a vector representing 1 for '1' and 0 for '0'.
            return ('bit2vec({0}, %d)' % to_size,
                    '({0})&1ull',
                    BitVector(to_size))
        
        elif from_cls.startswith('bitvec'):
            # Widens or shrinks.
            return ('std_logic_vector(resize(unsigned({0}), %d))' % to_size,
                    '({0})&%s' % c_mask(from_cls),
                    BitVector(to_size))
        
        elif from_cls.startswith('unsigned'):
            if to_size == size(from_cls):
                # Types are equivalent.
                return ('std_logic_vector({0})',
                        '{0}',
                        BitVector(to_size))
            
            # Widens or shrinks.
            return ('std_logic_vector(resize({0}, %d))' % to_size,
                    '({0})&%s' % c_mask(from_cls),
                    BitVector(to_size))
        
    # Handle conversions to unsigned.
    if to_cls.startswith('unsigned'):
        to_size = to_size()
        if from_cls == 'boolean':
            # Returns a vector representing 1 for true and 0 for false.
            return ('unsigned(bit2vec(bool2bit({0}), %d))' % to_size,
                    '({0})&1ull',
                    Unsigned(to_size))
        
        elif from_cls == 'natural':
            # Integer to unsigned.
            return ('to_unsigned({0}, %d)' % to_size,
                    '{0}',
                    Unsigned(to_size))
        
        elif from_cls == 'bit':
            # Returns a vector representing 1 for '1' and 0 for '0'.
            return ('unsigned(bit2vec({0}, %d))' % to_size,
                    '({0})&1ull',
                    Unsigned(to_size))
        
        elif from_cls.startswith('bitvec'):
            if to_size == size(from_cls):
                # Types are equivalent.
                return ('unsigned({0})',
                        '{0}',
                        Unsigned(to_size))
            
            # Widens or shrinks.
            return ('resize(unsigned({0}), %d)' % to_size,
                    '({0})&%s' % c_mask(from_cls),
                    Unsigned(to_size))
        
        elif from_cls.startswith('unsigned'):
            # Widens or shrinks.
            return ('resize({0}, %d)' % to_size,
                    '({0})&%s' % c_mask(from_cls),
                    Unsigned(to_size))
    
    # Unknown type conversion.
    raise CodeError('cannot cast %s to %s.' % (from_typ, to_cls))


def generate_expr(operator, operands):
    """Returns code for an expression. operator is the operator as used in the
    language-agnostic code as a string, operands is a list of one or two type
    classes for the operands. The result is a three-tuple with VHDL code in the
    first entry, C code in the second and the resulting type class in the third.
    {0} and {1} are used as .format specifier for the operands in the code
    strings."""
    
    opcls = [x.cls() for x in operands]
    
    if operator in ['!', '&&', '^^', '||']:
        # Boolean logic. The operands are coerced to booleans and the result is
        # always boolean as well.
        
        # Perform coercion.
        vop = ['{0}', '{1}']
        cop = ['{0}', '{1}']
        for i in range(len(opcls)):
            vfmt, cfmt, operands[i] = generate_typecast(
                operands[i], 'boolean')
            vop[i] = vfmt.format(vop[i])
            cop[i] = cfmt.format(cop[i])
        
        # Generate the code.
        return ({'!':  'not ({0})',
                 '&&': '({0}) and ({1})',
                 '^^': '({0}) xor ({1})',
                 '||': '({0}) or ({1})'
                }[operator].format(*vop),
                {'!':  '!({0})',
                 '&&': '({0}) && ({1})',
                 '^^': '({0}) != ({1})',
                 '||': '({0}) || ({1})'
                }[operator].format(*cop),
                Boolean())
    
    
    elif operator == '~':
        # One's complement. This can be applied to all types. When applied to a
        # boolean, the result will be natural.
        
        # VHDL does not have a one's complement operator for natural types, but
        # it's easy to emulate using a subtraction. In fact, we should do that
        # in C as well to save having to do a bitwise and afterwards to get it
        # back in the 31-bit range.
        if opcls[0] in ['boolean', 'natural']:
            vop, cop, typ = generate_typecast(operands[0], 'natural')
            return (('%d - ({0})' % 0x7FFFFFFF).format(vop),
                    '0x7FFFFFFFull - ({0})'.format(cop),
                    typ)
        
        elif opcls[0] == 'bit':
            size = 1
            
        elif opcls[0].startswith('bitvec') or opcls[0].startswith('unsigned'):
            size = cls_size(opcls[0])
            
        else:
            raise CodeError('%s operator can not be applied to %s.'
                            % (operator, operands[0]))
        
        # Generate the code for bit and vector types. It doesn't matter that
        # this inverts the higher-order bits as well in C, as those are ignored
        # by convention anyway.
        return ('not ({0})',
                '~({0})',
                operands[0])
        
    
    elif operator in ['&', '^', '|']:
        # Bitwise logic. They are defined for four seperate input type patterns:
        #  - The C-like variant:
        #      [boolean, integer] x [boolean, integer] -> integer
        #  - Bitwise vector logic (result will be unsigned if first operand is
        #    unsigned):
        #      [bitvec<n>, unsigned<n>] x [bitvec<n>, unsigned<n>]
        #      -> [bitvec<n>, unsigned<n>]
        #  - Gate (applies the single bit operand to all bits in the other;
        #    operands may be reversed):
        #      [bitvec<n>, unsigned<n>]
        #      x [boolean, bit, bitvec1, unsigned1]
        #      -> [bitvec<n>, unsigned<n>]
        #  - Bit logic:
        #      bit x bit -> bit
        
        # Handle typing and coercion.
        variant = None
        vop = ['{0}', '{1}']
        cop = ['{0}', '{1}']
        if opcls[0] in ['boolean', 'natural'] and opcls[1] in ['boolean', 'natural']:
            variant = 'clike'
            typ = Natural()
            for i in range(2):
                vfmt, cfmt, operands[i] = generate_typecast(
                    operands[i], 'natural')
                vop[i] = vfmt.format(vop[i])
                cop[i] = cfmt.format(cop[i])
            
        elif opcls[0] == 'bit' and opcls[1] == 'bit':
            variant = 'normal'
            typ = Bit()
            
        elif opcls[0].startswith('bitvec') or opcls[0].startswith('unsigned'):
            s = cls_size(opcls[0])
            if opcls[1] in ['bitvec%d' % s, 'unsigned%d' % s]:
                variant = 'normal'
                typ = operands[0]
                vfmt, cfmt, operands[1] = generate_typecast(
                    operands[1], opcls[0])
                vop[1] = vfmt.format(vop[1])
                cop[1] = cfmt.format(cop[1])
        
        if variant is None:
            # Move the gate to the second operand.
            if opcls[0] in ['boolean', 'bit', 'bitvec1', 'unsigned1']:
                operands = list(reversed(operands))
                opcls = list(reversed(opcls))
                vop = list(reversed(vop))
                cop = list(reversed(cop))
            if opcls[0].startswith('bitvec') or opcls[0].startswith('unsigned'):
                if opcls[1] in ['boolean', 'bit', 'bitvec1', 'unsigned1']:
                    variant = 'normal'
                    typ = operands[0]
                    vfmt, cfmt, operands[1] = generate_typecast(
                        operands[1], 'bit')
                    vop[1] = ('(%d downto 0 => {0})' % (typ.size-1)).format(vfmt.format(vop[1]))
                    cop[1] = '((({0})&1ull)?0xFFFFFFFFFFFFFFFFull:0ull)'.format(cfmt.format(cop[1]))
        
        if variant is None:
            raise CodeError('mode %s x %s is not defined for operator %s.'
                            % (operands[0], operands[1], operator))
        
        # Generate VHDL code. VHDL doesn't support bitwise operations for
        # integer types, so we'll need to emulate the C-like operations by
        # going through unsigned(30 downto 0).
        vhdl = {'&': '({0}) and ({1})',
                '^': '({0}) xor ({1})',
                '|': '({0}) or ({1})'}[operator]
        if variant == 'clike':
            vhdl = vhdl.format('to_unsigned({0}, 31)', 'to_unsigned({1}, 31)')
            vhdl = 'to_integer(%s)' % vhdl
        vhdl = vhdl.format(*vop)
        
        # Generate C code.
        c = ('({0}) %s ({1})' % operator).format(*cop)
        
        return (vhdl, c, typ)
    
    
    elif operator == '$':
        # Concatenation of bit, bitvec and unsigned types. The resulting type
        # is unsigned if the first operand is unsigned, bitvec otherwise. The
        # size of the result is the sum of the two input sizes.
        
        # Handle typing.
        sizes = [0, 0]
        for i in range(2):
            if opcls[i].startswith('bitvec') or opcls[i].startswith('unsigned'):
                sizes[i] = cls_size(opcls[i])
            elif opcls[i] == 'bit':
                sizes[i] = 1
            else:
                raise CodeError('%s operator can not be applied to %s.'
                                % (operator, operands[i]))
        size = sum(sizes)
        
        if opcls[0].startswith('unsigned'):
            typ = Unsigned(size)
            typcls = 'unsigned'
        else:
            typ = BitVector(size)
            typcls = 'bitvec'
        
        # Coerce the operands.
        vop = ['{0}', '{1}']
        cop = ['{0}', '{1}']
        for i in range(2):
            vfmt, cfmt, operands[i] = generate_typecast(
                operands[i], typcls + str(sizes[i]))
            vop[i] = vfmt.format(vop[i])
            cop[i] = cfmt.format(cop[i])
        
        # Generate the code.
        return ('({0}) & ({1})'.format(*vop),
                ('(({0})<<%dull)|(({1})&0x%Xull)' 
                    % (sizes[1], (1<<sizes[1])-1)).format(*cop),
                typ)
        
    
    elif operator in ['+', '-']:
        # Basic arithmetic. These operations can be performed on natural,
        # boolean, bitvec, unsigned and bit. The result is a natural if both
        # operands are natural or boolean. Otherwise, the result is an unsigned
        # of size max(op size)+1 (so you get the carry bit as well). naturals
        # are cast to 31-bit unsigneds first if the arguments are a mix. bits
        # and booleans are interpreted as U"1" or U"0".
        
        # Handle typing.
        if opcls[0] in ['natural', 'boolean'] and opcls[1] in ['natural', 'boolean']:
            typ = Natural()
            
            # Coerce the operands.
            vop = ['{0}', '{1}']
            cop = ['{0}', '{1}']
            for i in range(2):
                vfmt, cfmt, operands[i] = generate_typecast(
                    operands[i], 'natural')
                vop[i] = vfmt.format(vop[i])
                cop[i] = cfmt.format(cop[i])
            
            # Garbage in higher-order bits is not allowed for natural types in
            # C, so we need to make sure it rolls over properly.
            cout = '(%s)&0x7FFFFFFFull'
            
        else:
            size = 0
            for i in range(2):
                if opcls[i].startswith('bitvec') or opcls[i].startswith('unsigned'):
                    size = max(size, cls_size(opcls[i]))
                elif opcls[i] == 'natural':
                    size = max(size, 31)
                elif opcls[i] in ['bit', 'boolean']:
                    size = max(size, 1)
                    #vfmt, cfmt, operands[i] = generate_typecast(operands[i], 'unsigned1')
                    #vop[i] = vfmt.format(vop[i])
                    #cop[i] = cfmt.format(cop[i])
                else:
                    raise CodeError('%s operator can not be applied to %s.'
                                    % (operator, operands[i]))
            size += 1
            if size > 64:
                size = 64
            typ = Unsigned(size)
            
            # Coerce the operands.
            vop = ['{0}', '{1}']
            cop = ['{0}', '{1}']
            for i in range(2):
                vfmt, cfmt, operands[i] = generate_typecast(operands[i], typ.cls())
                vop[i] = vfmt.format(vop[i])
                cop[i] = cfmt.format(cop[i])
        
            # We con't care about higher-order garbage bits in bitvec/unsigned.
            cout = '%s'
            
        # Generate the code.
        vhdl = c = '({0}) %s ({1})' % operator
        vhdl = vhdl.format(*vop)
        c = cout % c.format(*cop)
        return (vhdl, c, typ)
    
    
    elif operator in ['*', '/', '%']:
        # Complex arithmetic. These operations can only be applied to naturals
        # or booleans, and the result is always a natural.
        
        # Handle typing.
        for c in opcls:
            if c not in ['natural', 'boolean']:
                raise CodeError('%s operator can only be applied to naturals.'
                                % operator)
        
        # Coerce the operands.
        vop = ['{0}', '{1}']
        cop = ['{0}', '{1}']
        for i in range(2):
            vfmt, cfmt, operands[i] = generate_typecast(
                operands[i], 'natural')
            vop[i] = vfmt.format(vop[i])
            cop[i] = cfmt.format(cop[i])
        
        # Generate the code.
        return (('({0}) %s ({1})' % operator).format(*vop),
                ('(({0}) %s ({1}))&0x7FFFFFFFull' % operator).format(*cop),
                Natural())
    
    
    elif operator in ['<<', '>>']:
        # Bitshifts. The first operand may be bitvec, unsigned, natural or
        # boolean, the second operand must be natural or boolean.
        
        # Check second operand type.
        if opcls[1] not in ['natural', 'boolean']:
            raise CodeError('second operand of %s operator must be natural.' % operator)
        
        # Coerce the second operand.
        vop = ['{0}', '{1}']
        cop = ['{0}', '{1}']
        vfmt, cfmt, operands[1] = generate_typecast(operands[1], 'natural')
        vop[1] = vfmt.format(vop[1])
        cop[1] = cfmt.format(cop[1])
        
        if opcls[0] in ['natural', 'boolean']:
            # Handle natural x natural -> natural. This operation doesn't exist
            # in VHDL, but can be emulated easily by multiplying and dividing by
            # a power of two.
            vop[0], cop[0], typ = generate_typecast(operands[0], 'natural')
            return (('({0}) %s 2**({1})' % {'>>':'/', '<<':'*'}[operator]).format(*vop),
                    ('(({0}) %s ({1}))&0x7FFFFFFFull' % operator).format(*cop),
                    Natural())
        
        elif opcls[0].startswith('bitvec') or opcls[0].startswith('unsigned'):
            # Handle [bitvec, unsigned] x natural -> unsigned. Notice that we
            # need to mask the input vector in C before right shifting,
            # otherwise we shift in garbage.
            vop[0], cop[0], typ = generate_typecast(operands[0], 'unsigned')
            if operator == '<<':
                return (('({0}) sll ({1})').format(*vop),
                        ('({0}) << ({1})').format(*cop),
                        typ)
            else:
                print(typ.size)
                return (('({0}) srl ({1})').format(*vop),
                        ('(({0})&0x%Xull) >> ({1})' % (1<<typ.size)-1).format(*cop),
                        typ)
        
        else:
            raise CodeError(('first operand of %s operator must be natural, ' +
                            'bitvec or unsigned.') % operator)
    
    
    elif operator in ['<=', '<', '>=', '>', '==', '!=']:
        # Relational. Can be applied to all combinations of primitive values.
        # == and != can also be applied to aggregates of the same type. The
        # result is always a boolean.
        
        # Determine the minimum number of bits needed to do the comparison.
        s = 0
        special = False
        for i in range(2):
            if opcls[i] in ['boolean', 'bit']:
                s = max(s, 1)
            elif opcls[i] in ['natural']:
                s = max(s, 31)
            elif opcls[i].startswith('bitvec') or opcls[i].startswith('unsigned'):
                s = max(s, cls_size(opcls[i]))
            elif operator in ['==', '!=']:
                special = True
            else:
                raise CodeError('%s operator can not be applied to %s.'
                                % (operator, operands[i]))
        
        vop = ['{0}', '{1}']
        cop = ['{0}', '{1}']
        if special:
            
            # Handle the special case for weird but identical types.
            if operands[0] != operands[1]:
                raise CodeError('cannot compare %s with %s.'
                                % (operands[0], operands[1]))
            
        else:
            
            # Coerce both operands to unsigned<s>.
            for i in range(2):
                vfmt, cfmt, operands[i] = generate_typecast(
                    operands[i], 'unsigned%d' % s)
                vop[i] = vfmt.format(vop[i])
                cop[i] = cfmt.format(cop[i])
        
        # Generate code.
        vhdl = c = '({0}) %s ({1})' % operator
        if operator == '==':
            vhdl = '({0}) = ({1})'
        elif operator == '!=':
            vhdl = '({0}) /= ({1})'
        return (vhdl.format(*vop), c.format(*cop), Boolean())
    
    
    # Unknown operator.
    raise CodeError('unknown operator %s.' % operator)


def generate_assignment(atyp, slic=False, size=None):
    """Generates an assignment statement. atyp should be the access type of the
    lvalue, needed to determine whether to use a <= or a := in VHDL. If slic is
    False (default), the entire lvalue, represented as {0}, will be set to {1}.
    If slic is True and size is None, index {2} of lvalue {0} will be set to
    {1}. Finally, if size is an integer, a slice of that size within lvalue {0},
    starting at {2}, will be set to {0}."""
    
    # Generate VHDL.
    vhdl = '{0}'
    if slic:
        if size is None:
            vhdl += '({2})'
        else:
            vhdl += '(({2})+%d downto {2})' % (size-1)
    vhdl = '%s %s {1};\n' % (vhdl, atyp.vhdl_assign_type())
    
    # Generate C.
    if not slic:
        c = '{0} = {1};\n'
    elif size is None:
        c = ('if (1) {{\n' +
             'uint64_t __shift = {2};\n' +
             '{0} &= ~(1ull << __shift);\n' +
             '{0} |= (({1})&1) << __shift;\n' +
             '}}\n')
    else:
        c = ('if (1) {{\n' +
             'uint64_t __shift = {2};\n' +
             'uint64_t __mask = 0x%Xull << __shift;\n' % ((1 << size) - 1) +
             '{0} &= ~__mask;\n' +
             '{0} |= (({1})<<__shift)&__mask;\n' +
             '}}\n')
    
    return (vhdl, c)


def generate_ifelse():
    """Generates the code for an if/else statement. Returns a two-tuple with a
    VHDL code in the first entry and a C code in the second. {0} represents the
    condition expression, {1} represents the true block, {2} the false block."""
    return ('if ({0}) then\n{1} else\n{2} end if;\n',
            'if ({0}) {{\n{1}}} else {{\n{2}}}\n')
    
