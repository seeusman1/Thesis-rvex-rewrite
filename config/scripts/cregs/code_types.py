"""Classes for each supported data type and access type (register, variable,
port, etc.)."""

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
    
    def get_members(self):
        """Returns a dictionary of all the members in this type if it is an
        aggregate, or None otherwise."""
        return None
    
    def member_type(self, member):
        """Returns the type of an aggregate member of this type, i.e., something
        after a dot. Returns None if the member does not exist."""
        return None

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
    
    def __init__(self, size):
        self.size = size
    
    def name(self):
        return 'bitvec%d' % (self.size)
        
    def name_vhdl(self):
        return 'std_logic_vector(%d downto 0)' % (self.size-1)
    
    def name_c(self):
        # Storage: first size LSBs determine value. All other bits should be
        # ignored. Note that the low bit position is not encoded.
        return 'uint64_t' if self.size > 32 else 'uint32_t'

    def index_range(self):
        return range(self.low, self.size)
    
    def index_type(self):
        return Bit()

    def can_slice(self):
        return True
    
    def slice_type(self, high, low):
        return BitVector(high - low + 1)


class Unsigned(BitVector):
    """Unsigned data type. Used for add and subtract operations."""
    
    def name(self):
        return 'unsigned%d' % (self.size)
        
    def name_vhdl(self):
        return 'unsigned(%d downto 0)' % (self.size-1)
    
    def slice_type(self, high, low):
        return Unsigned(high - low + 1)


class Byte(BitVector):
    """8-bit data data type."""

    def __init__(self):
        BitVector.__init__(self, 8)
    
    def name_vhdl(self):
        return 'rvex_byte_type'
    
    def name_vhdl_array(self):
        return 'rvex_byte_array'
    

class Data(BitVector):
    """32-bit data data type."""

    def __init__(self):
        BitVector.__init__(self, 32)
    
    def name_vhdl(self):
        return 'rvex_data_type'
    
    def name_vhdl_array(self):
        return 'rvex_data_array'
    

class Address(BitVector):
    """32-bit address type."""

    def __init__(self):
        BitVector.__init__(self, 32)
    
    def name_vhdl(self):
        return 'rvex_address_type'
    
    def name_vhdl_array(self):
        return 'rvex_address_array'
    

class SylStatus(BitVector):
    """One bit for each possible pipelane, so 16 bits."""

    def __init__(self):
        BitVector.__init__(self, 16)
    
    def name_vhdl(self):
        return 'rvex_sylStatus_type'
    
    def name_vhdl_array(self):
        return 'rvex_sylStatus_array'
    

class BrRegData(BitVector):
    """One bit for each branch register, so 8 bits."""

    def __init__(self):
        BitVector.__init__(self, 8)
    
    def name_vhdl(self):
        return 'rvex_brRegData_type'
    
    def name_vhdl_array(self):
        return 'rvex_brRegData_array'
    

class TrapCause(BitVector):
    """Trap cause type."""

    def __init__(self):
        BitVector.__init__(self, 8)
    
    def name_vhdl(self):
        return 'rvex_trap_type'
    
    def name_vhdl_array(self):
        return 'rvex_trap_array'
    

class TwoBit(BitVector):
    """Misc. 2-bit type."""

    def __init__(self):
        BitVector.__init__(self, 2)
    
    def name_vhdl(self):
        return 'rvex_2bit_type'
    
    def name_vhdl_array(self):
        return 'rvex_2bit_array'
    

class ThreeBit(BitVector):
    """Misc. 3-bit type."""

    def __init__(self):
        BitVector.__init__(self, 3)
        
    def name_vhdl(self):
        return 'rvex_3bit_type'
    
    def name_vhdl_array(self):
        return 'rvex_3bit_array'
    

class FourBit(BitVector):
    """Misc. 4-bit type."""

    def __init__(self):
        BitVector.__init__(self, 4)
    
    def name_vhdl(self):
        return 'rvex_4bit_type'
    
    def name_vhdl_array(self):
        return 'rvex_4bit_array'
    

class Aggregate(Type):
    """Record/struct type. Aggregates may kind of contain arrays (although they
    can only be indexed by decimal numbers, not even just any literal), but they
    cannot contain PerCtxt() types. The members also need to be hardcoded as
    subclasses of this type."""
    
    def __init__(self, members):
        self.members = members
    
    def name(self):
        return 'aggregate'
        
    def get_members(self):
        return self.members
    
    def member_type(self, member):
        member.split('.', 1)
        if member[0] not in self.members:
            return None
        member_typ = self.members[member[0]]
        if len(member) == 1:
            return member_typ
        else:
            return member_typ.member_type(member[1])


class TrapInfo(Aggregate):
    """Trap information structure."""
    
    def __init__(self):
        Aggregate.__init__(self, {
            'active': Bit(),
            'cause':  TrapCause(),
            'arg':    Address()
        })

    def name_vhdl(self):
        return 'trap_info_type'
    
    def name_vhdl_array(self):
        return 'trap_info_array'

    def name_c(self):
        return 'trapInfo_t'
    
        
class BreakpointInfo(Aggregate):
    """Breakpoint information structure."""
    
    def __init__(self):
        Aggregate.__init__(self, {
            'addr[0]': Address(),
            'addr[1]': Address(),
            'addr[2]': Address(),
            'addr[3]': Address(),
            'cfg[0]': TwoBit(),
            'cfg[1]': TwoBit(),
            'cfg[2]': TwoBit(),
            'cfg[3]': TwoBit()
        })

    def name_vhdl(self):
        return 'cxreg2pl_breakpoint_info_type'
    
    def name_vhdl_array(self):
        return 'cxreg2pl_breakpoint_info_array'

    def name_c(self):
        return 'breakpointInfo_t'
    
        
def parse_type(text):
    """Converts a textual type (using the language agnostic names) which can be
    instantiated by the user into an internal Type. Raises a TypError if 
    something goes wrong."""
    
    text = text.lower()
    
    SIMPLE_TYPES = {
        
        # Primitive types.
        'natural': Natural(),
        'boolean': Boolean(),
        'bit': Bit(),
        
        # bitvec's with special names to permit VHDL arrays.
        'byte': Byte(),
        'data': Data(),
        'address': Address(),
        'sylstatus': SylStatus(),
        'brregdata': BrRegData(),
        'trapcause': TrapCause(),
        'twobit': TwoBit(),
        'threebit': ThreeBit(),
        'fourbit': FourBit(),
        
        # Aggregate types.
        'trapinfo': TrapInfo(),
        'breakpointinfo': BreakpointInfo()
        
    }
    if text in SIMPLE_TYPES:
        return SIMPLE_TYPES[text]
    elif text.startswith('bitvec'):
        try:
            size = int(text[6:])
            if size > 64:
                raise TypError('bit vectors greater than 64 bits are not supported')
            elif size > 0:
                return BitVector(size)
        except ValueError:
            pass
    elif text.startswith('unsigned'):
        try:
            size = int(text[8:])
            if size > 64:
                raise TypError('unsigned vectors greater than 64 bits are not supported')
            elif size > 0:
                return Unsigned(size)
        except ValueError:
            pass
    else:
        raise TypError('unknown type \'%s\'' % text)


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

    def member_type(self, member):
        return self.el_typ.member_type(member)
    
    def __str__(self):
        return '%s per context' % self.name()


class CfgVectType(Aggregate):
    
    def __init__(self):
        Aggregate.__init__(self, {
            'numLanesLog2':          Natural(),
            'numLaneGroupsLog2':     Natural(),
            'numContextsLog2':       Natural(),
            'genBundleSizeLog2':     Natural(),
            'bundleAlignLog2':       Natural(),
            'multiplierLanes':       Natural(),
            'memLaneRevIndex':       Natural(),
            'numBreakpoints':        Natural(),
            'forwarding':            Boolean(),
            'limmhFromNeighbor':     Boolean(),
            'limmhFromPreviousPair': Boolean(),
            'reg63isLink':           Boolean(),
            'cregStartAddress':      Address(),
            'resetVectors[0]':       Address(),
            'resetVectors[1]':       Address(),
            'resetVectors[2]':       Address(),
            'resetVectors[3]':       Address(),
            'resetVectors[4]':       Address(),
            'resetVectors[5]':       Address(),
            'resetVectors[6]':       Address(),
            'resetVectors[7]':       Address(),
            'unifiedStall':          Boolean(),
            'traceEnable':           Boolean()
        })
    
    def name_vhdl(self):
        return 'rvex_generic_config_type'
    
    def name_c(self):
        return 'cfgVect_t'
    

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
    
    def needs_init(self):
        """Returns whether this access type needs a reset/init specification."""
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
    
    def needs_init(self):
        return True


class Register(AccessibleType):
    
    def name(self):
        return 'register'
    
    def needs_init(self):
        return True


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
    
    def needs_init(self):
        return True


class PredefinedConstant(AccessibleType):
    
    def name(self):
        return 'constant'
    
    def can_assign(self):
        return False

