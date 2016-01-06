import re

class TypError(Exception):
    
    def __init__(self, message):
        self.message = message
    
    def __str__(self):
        return repr(self.message)


class Type(object):
    """Represents a data type."""
    
    def name(self):
        """Returns the language-agnostic name of the type."""
        return None
        
    def name_vhdl(self):
        """Returns the VHDL name of the type, or None if it does not exist. A
        declaration will be """
        return name(self)
        
    def name_vhdl_array(self):
        """Returns the VHDL name of the array type for this type, or None if it
        does not exist."""
        return None
        
    def name_c(self):
        """Returns the C name of the type, or None if it does not exist."""
        return name(self)
    
    def decl_c(self, name):
        """Returns a C declaration for a variable of this type, or None if this
        type cannot be declared."""
        spec = self.name_c()
        if spec is None:
            return None
        return '%s %s%s' % (spec[0], name, spec[1])
        
    def index_range(self):
        """Returns the range of valid indices for this type, or None if this
        type cannot be indexed."""
        return None
    
    def can_index(self):
        """Returns whether this type can be indexed."""
        return index_range(self) is not None
    
    def index_type(self):
        """Returns the type which indexing will result in, or None if this
        type cannot be indexed."""
        return None

    def can_slice(self):
        """Returns whether this type can be sliced."""
        return False
    
    def slice_type(self, high, low):
        """Returns the type which slicing will result in with the given high and
        low bounds, or None if this type cannot be sliced in this way."""
        return None
    
    def exists_per_context(self):
        """Returns True if this is a per-context type, or False if it is a
        global type."""
        return False

    def __eq__(self, other):
        if isinstance(other, self.__class__):
            return self.__dict__ == other.__dict__
        else:
            return False
        
    def __ne__(self, other):
        return not self.__eq__(other)

    def __str__(self):
        return self.name()


class Boolean(Type):
    """Boolean/predicate data type, used for conditional statements."""

    def name(self):
        return 'boolean'
        
    def name_c(self):
        # Storage: 0 for false, 1 for true. All other values are ILLEGAL.
        return 'uint32_t'


class Natural(Type):
    """32-bit natural number data type, used for indexing operations."""

    def name(self):
        return 'natural'
        
    def name_c(self):
        # Storage: same as VHDL.
        return 'uint32_t'


class Bit(Type):
    """Bit data type."""

    def name(self):
        return 'bit'
        
    def name_vhdl(self):
        return 'std_logic'
    
    def name_vhdl_array(self):
        return 'std_logic_vector'
    
    def name_c(self):
        # Storage: LSB determines value. All other bits should be ignored.
        return 'uint32_t'


class BitVector(Type):
    """Bit vector data type."""
    
    def __init__(self, high, low):
        self.high = high
        self.low = low
    
    def name(self):
        return 'bit(%d..%d)' % (self.high, self.low)
        
    def name_vhdl(self):
        return 'std_logic_vector(%d downto %d)' % (self.high, self.low)
    
    def name_c(self):
        # Storage: first (high + 1 - low) LSBs determine value. All other bits
        # should be ignored. Note that the low bit position is not encoded.
        return 'uint64_t' if self.high > 31 else 'uint32_t'

    def index_range(self):
        return range(self.low, self.high+1)
    
    def index_type(self):
        return Bit()

    def can_slice(self):
        return True
    
    def slice_type(self, high, low):
        return BitVector(high, low)


class Unsigned(BitVector):
    """Unsigned data type. Used for add and subtract operations."""
    
    def name(self):
        return 'unsigned(%d..%d)' % (self.high, self.low)
        
    def name_vhdl(self):
        return 'unsigned(%d downto %d)' % (self.high, self.low)
    
    def slice_type(self, high, low):
        return Unsigned(high, low)


class Byte(BitVector):
    """8-bit data data type."""

    def __init__(self):
        BitVector.__init__(self, 7, 0)
    
    def name(self):
        return 'byte'
        
    def name_vhdl(self):
        return 'rvex_byte_type'
    
    def name_vhdl_array(self):
        return 'rvex_byte_array'
    

class Data(BitVector):
    """32-bit data data type."""

    def __init__(self):
        BitVector.__init__(self, 31, 0)
    
    def name(self):
        return 'data'
        
    def name_vhdl(self):
        return 'rvex_data_type'
    
    def name_vhdl_array(self):
        return 'rvex_data_array'
    

class Address(BitVector):
    """32-bit address type."""

    def __init__(self):
        BitVector.__init__(self, 31, 0)
    
    def name(self):
        return 'address'
        
    def name_vhdl(self):
        return 'rvex_address_type'
    
    def name_vhdl_array(self):
        return 'rvex_address_array'
    

class SylStatus(BitVector):
    """One bit for each possible pipelane, so 16 bits."""

    def __init__(self):
        BitVector.__init__(self, 15, 0)
    
    def name(self):
        return 'sylStatus'
        
    def name_vhdl(self):
        return 'rvex_sylStatus_type'
    
    def name_vhdl_array(self):
        return 'rvex_sylStatus_array'
    

class BrRegData(BitVector):
    """One bit for each branch register, so 8 bits."""

    def __init__(self):
        BitVector.__init__(self, 7, 0)
    
    def name(self):
        return 'brRegData'
        
    def name_vhdl(self):
        return 'rvex_brRegData_type'
    
    def name_vhdl_array(self):
        return 'rvex_brRegData_array'
    

class TrapCause(BitVector):
    """Trap cause type."""

    def __init__(self):
        BitVector.__init__(self, 7, 0)
    
    def name(self):
        return 'trapCause'
        
    def name_vhdl(self):
        return 'rvex_trap_type'
    
    def name_vhdl_array(self):
        return 'rvex_trap_array'
    

class TwoBit(BitVector):
    """Misc. 2-bit type."""

    def __init__(self):
        BitVector.__init__(self, 1, 0)
    
    def name(self):
        return 'twoBit'
        
    def name_vhdl(self):
        return 'rvex_2bit_type'
    
    def name_vhdl_array(self):
        return 'rvex_2bit_array'
    

class ThreeBit(BitVector):
    """Misc. 3-bit type."""

    def __init__(self):
        BitVector.__init__(self, 2, 0)
    
    def name(self):
        return 'threeBit'
        
    def name_vhdl(self):
        return 'rvex_3bit_type'
    
    def name_vhdl_array(self):
        return 'rvex_3bit_array'
    

class FourBit(BitVector):
    """Misc. 4-bit type."""

    def __init__(self):
        BitVector.__init__(self, 4, 0)
    
    def name(self):
        return 'fourBit'
        
    def name_vhdl(self):
        return 'rvex_4bit_type'
    
    def name_vhdl_array(self):
        return 'rvex_4bit_array'
    

class PerCtxt(Type):
    """Array data type for stuff which exists per context."""
    
    def __init__(self, el_typ):
        self.el_typ = el_typ
        if el_typ.name_vhdl_array() is None:
            raise TypError('Cannot instantiate type ' + self.name() + ' per context.')

    def name(self):
        return self.el_typ.name()
        
    def name_vhdl(self):
        return '%s(2**CFG.numContextsLog2-1 downto 0)' % self.el_typ.name_vhdl_array()
    
    def name_c(self):
        return self.el_typ.name_c()

    def index_range(self):
        return range(8)
    
    def index_type(self):
        return self.el_typ

    def exists_per_context(self):
        return True

    def __str__(self):
        return '%s per context' % self.name()


SIMPLE_TYPES = {
    'bit': Bit(),
    'byte': Byte(),
    'data': Data(),
    'address': Address(),
    'sylStatus': SylStatus(),
    'brRegData': BrRegData(),
    'trapCause': TrapCause(),
    'twoBit': TwoBit(),
    'threeBit': ThreeBit(),
    'fourBit': FourBit()
}


def parse_type(text):
    """Converts a textual type (using the language agnostic names) which can be
    instantiated by the user into an internal Type. Raises a TypError if 
    something goes wrong."""
    
    # All whitespace in types is optional, so we can just remove all of it. This
    # does mean that something like 'b i t' is arguably incorrectly accepted,
    # but whatever.
    text = re.sub(r'\s', '', text)
    
    if text in SIMPLE_TYPES:
        return SIMPLE_TYPES[text]
    elif text.startswith('bit(') and text.endswith(')'):
        text = text[4:-1].split('..')
        if len(text) != 2:
            raise TypError('range malformed')
        try:
            high = int(text[0])
            low = int(text[1])
        except ValueError:
            raise TypError('range malformed')
        if high < low:
            raise TypError('range is invalid')
        if low < 0:
            raise TypError('range is invalid')
        if high > 63:
            raise TypError('ranges beyond 64 bits are not supported')
        return BitVector(high, low)
    else:
        raise TypError('unknown type \'%s\'' % text)


class AccessibleType(object):
    
    def __init__(self, typ):
        self.typ = typ
    
    def get_type(self):
        return self.typ
    
    def name(self):
        """Returns a friendly name for this access type."""
        return 'invalid'
    
    def can_assign(self):
        """Returns whether this access type can be assigned."""
        return True
    
    def vhdl_assign_type(self):
        """Returns the VHDL assignment operator for this type."""
        return '<='
    
    def can_read(self):
        """Returns whether this access type can be read."""
        return True
    
    def can_read_before_assign(self):
        """Returns whether this access type can be read before it is
        assigned."""
        return self.can_read()
    
    def is_local(self):
        """Returns whether this access type can only be accessed locally (as in,
        in the implementation of the field which specified it)."""
        return False
    
    def __eq__(self, other):
        if isinstance(other, self.__class__):
            return self.__dict__ == other.__dict__
        else:
            return False
        
    def __ne__(self, other):
        return not self.__eq__(other)
    
    def __str__(self):
        pc = ' per context' if self.typ.exists_per_context() else ''
        return '%s %s%s' % (self.typ.name(), self.name(), pc)
    

class Input(AccessibleType):
    
    def name(self):
        return 'input'
    
    def can_assign(self):
        return False
    

class Output(AccessibleType):
    
    def name(self):
        return 'output'
    
    def can_read(self):
        return False


class Register(AccessibleType):
    
    def name(self):
        return 'register'
    

class Variable(AccessibleType):
    
    def name(self):
        return 'variable'
    
    def vhdl_assign_type(self):
        return ':='
    
    def can_read_before_assign(self):
        return False

    def is_local(self):
        return True

class Constant(AccessibleType):
    
    def name(self):
        return 'constant'
    
    def can_assign(self):
        return False

