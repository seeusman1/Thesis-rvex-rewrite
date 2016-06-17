"""This module contains all the classes which represent the types available in
the language-agnostic code."""

from excepts import *
import re

class Type(object):
    """Represents a data type."""
    
    def name(self):
        """Returns the language-agnostic name of the type."""
        return None
        
    def cls(self):
        """Returns the language-agnostic type class. NOTE: a lot of code checks
        whether a type is an instance of bitvec or unsigned by using
        startswith(). Thus, don't ever make a new class which starts with one of
        those words because shit will be on fire."""
        return self.name()
        
    def name_vhdl(self):
        """Returns the VHDL name of the type, or None if it does not exist. A
        declaration will be """
        return self.name()
        
    def name_vhdl_array(self):
        """Returns the VHDL name of the array type for this type, or None if it
        does not exist."""
        return None
        
    def name_c(self):
        """Returns the C name of the type, or None if it does not exist."""
        return '%s_t' % self.name()
    
    def typedef_c(self):
        """Returns the C typedef for this type."""
        return None
    
    def can_slice(self):
        """Returns whether this type can be sliced."""
        return False
    
    def slice_type(self, size):
        """Returns the type which slicing will result in with the given size
        bounds, or None if this type cannot be sliced in this way."""
        return None
    
    def exists_per_context(self):
        """Returns True if this is a per-context type, or False if it is a
        global type."""
        return False
    
    def get_members(self):
        """Returns a dictionary of all the members in this type if it is an
        aggregate, or None otherwise."""
        return None
    
    def get_member_order(self):
        """Returns a list of all the members in this type, before expanding
        arrays, in the right order. This information is needed for constructing
        C aggregate initializers."""
        return None
    
    def member_type(self, member):
        """Returns the type of an aggregate member of this type, i.e., something
        after a dot. Returns None if the member does not exist."""
        return None

    def member_name(self, member):
        """Properly capitalizes the member name."""
        return None

    def __eq__(self, other):
        if type(self) is type(other):
            return self.__dict__ == other.__dict__
        else:
            return False
        
    def __ne__(self, other):
        return not self.__eq__(other)

    def __str__(self):
        return self.name()

    def __repr__(self):
        return 'Type(%s)' % self.name()


class Aggregate(Type):
    """Record/struct type. Aggregates may kind of contain arrays (although they
    can only be indexed by decimal numbers, not even just any literal), but they
    cannot contain PerCtxt() types. The members also need to be hardcoded as
    subclasses of this type."""
    
    def __init__(self):
        self.member_order = []
        self.members = {}
        self.member_names = {}
        self.c_typedef = []
    
    def add_entry(self, name, typ):
        """Adds a scalar to the aggregate."""
        namel = name.lower()
        if namel in self.member_order:
            raise CodeError(('duplicate entry name \'%s\' in \'%s\' aggregate ' +
                            'definition.') % (name, self.name()))
        self.member_order.append(namel)
        self.members[namel] = typ
        self.member_names[namel] = name
        self.c_typedef.append('    %s_t %s;\n' % (typ.name(), name))
    
    def add_array(self, name, size, typ):
        """Adds an array to the aggregate."""
        namel = name.lower()
        if namel in self.member_order:
            raise CodeError(('duplicate entry name \'%s\' in \'%s\' aggregate ' +
                            'definition.') % (name, self.name()))
        self.member_order.append(namel)
        self.member_names[namel] = name
        for i in range(size):
            self.members['%s{%d}' % (namel, i)] = typ
            self.member_names['%s{%d}' % (namel, i)] = '%s{%d}' % (name, i)
        self.c_typedef.append('    %s_t %s[%d];\n' % (typ.name(), name, size))
    
    def name(self):
        return 'aggregate'
        
    def cls(self):
        return 'aggregate %s' % self.name()
    
    def typedef_c(self):
        return 'typedef struct {\n%s} %s;\n' % (''.join(self.c_typedef), self.name_c())
    
    def get_members(self):
        return self.members
    
    def get_member_order(self):
        return self.member_order
    
    def member_type(self, member):
        member = member.lower().split(r'\.', 1)
        if member[0] not in self.members:
            return None
        member_typ = self.members[member[0]]
        if len(member) == 1:
            return member_typ
        else:
            return member_typ.member_type(member[1])

    def member_name(self, member):
        member = member.lower().split(r'\.', 1)
        if member[0] not in self.member_names:
            return member
        member_name = self.member_names[member[0]]
        if len(member) == 1:
            return member_name
        else:
            member_typ = self.members[member[0]]
            return member_name + '.' + member_typ.member_name(member[1])


def cls_size(cls):
    """Returns the size of a type class."""
    # FIXME: I am very ugly indeed.
    if cls.startswith('bitvec'):
        return int(cls[6:])
    elif cls.startswith('unsigned'):
        return int(cls[8:])
    else:
        raise ValueError()


#===============================================================================
# Type definitions
#===============================================================================
TYPE_LIST = []


class Boolean(Type):
    """Boolean/predicate data type, used for conditional statements.
    
    C storage: 0 for false, 1 for true. All other values are illegal."""

    def name(self):
        return 'boolean'
        
    def typedef_c(self):
        """Returns the C typedef for this type."""
        return 'typedef uint8_t %s;\n' % self.name_c()

TYPE_LIST.append(Boolean())
    

class Natural(Type):
    """31-bit natural number data type, used for indexing operations.
    
    C storage: 0..0x7FFFFFFF. All other values are illegal."""

    def name(self):
        return 'natural'
        
    def typedef_c(self):
        """Returns the C typedef for this type."""
        return 'typedef uint32_t %s;\n' % self.name_c()

TYPE_LIST.append(Natural())


class Bit(Type):
    """Bit data type.
    
    C storage: LSB determines value. All other bits should be ignored."""

    def name(self):
        return 'bit'
        
    def name_vhdl(self):
        return 'std_logic'
    
    def name_vhdl_array(self):
        return 'std_logic_vector'
    
    def typedef_c(self):
        """Returns the C typedef for this type."""
        return 'typedef uint8_t %s;\n' % self.name_c()

TYPE_LIST.append(Bit())


class BitVector(Type):
    """Bit vector data type.
    
    Storage: first size LSBs determine value. All other bits should be
    ignored."""
    
    def __init__(self, size):
        self.size = size
    
    def name(self):
        return 'bitvec%d' % (self.size)
        
    def cls(self):
        return 'bitvec%d' % (self.size)
    
    def name_vhdl(self):
        return 'std_logic_vector(%d downto 0)' % (self.size-1)
    
    def typedef_c(self):
        """Returns the C typedef for this type."""
        if self.size > 32:
            size = 64
        elif self.size > 16:
            size = 32
        elif self.size > 8:
            size = 16
        else:
            size = 8
        return 'typedef uint%d_t %s;\n' % (size, self.name_c())
    
    def can_slice(self):
        return True
    
    def slice_type(self, size):
        if size is None:
            return Bit()
        if size > self.size:
            return None
        if size < 1:
            return None
        return BitVector(size)

TYPE_LIST += [BitVector(x) for x in range(1, 64+1)]


class Unsigned(BitVector):
    """Unsigned data type. Used for add and subtract operations."""
    
    def name(self):
        return 'unsigned%d' % (self.size)
        
    def cls(self):
        return 'unsigned%d' % (self.size)
    
    def name_vhdl(self):
        return 'unsigned(%d downto 0)' % (self.size-1)
    
    def slice_type(self, size):
        if size is None:
            return Bit()
        if size > self.size:
            return None
        if size < 1:
            return None
        return Unsigned(size)

TYPE_LIST += [Unsigned(x) for x in range(1, 64+1)]


class Byte(BitVector):
    """8-bit data data type."""

    def __init__(self):
        BitVector.__init__(self, 8)
    
    def name(self):
        return 'byte'
    
    def name_vhdl(self):
        return 'rvex_byte_type'
    
    def name_vhdl_array(self):
        return 'rvex_byte_array'
    
TYPE_LIST.append(Byte())


class Data(BitVector):
    """32-bit data data type."""

    def __init__(self):
        BitVector.__init__(self, 32)
    
    def name(self):
        return 'data'
    
    def name_vhdl(self):
        return 'rvex_data_type'
    
    def name_vhdl_array(self):
        return 'rvex_data_array'

TYPE_LIST.append(Data())


class Address(BitVector):
    """32-bit address type."""

    def __init__(self):
        BitVector.__init__(self, 32)
    
    def name(self):
        return 'address'
    
    def name_vhdl(self):
        return 'rvex_address_type'
    
    def name_vhdl_array(self):
        return 'rvex_address_array'
    
TYPE_LIST.append(Address())


class SylStatus(BitVector):
    """One bit for each possible pipelane, so 16 bits."""

    def __init__(self):
        BitVector.__init__(self, 16)
    
    def name(self):
        return 'sylStatus'
    
    def name_vhdl(self):
        return 'rvex_sylStatus_type'
    
    def name_vhdl_array(self):
        return 'rvex_sylStatus_array'
    
TYPE_LIST.append(SylStatus())


class BrRegData(BitVector):
    """One bit for each branch register, so 8 bits."""

    def __init__(self):
        BitVector.__init__(self, 8)
    
    def name(self):
        return 'brRegData'
    
    def name_vhdl(self):
        return 'rvex_brRegData_type'
    
    def name_vhdl_array(self):
        return 'rvex_brRegData_array'

TYPE_LIST.append(BrRegData())


class TrapCause(BitVector):
    """Trap cause type."""

    def __init__(self):
        BitVector.__init__(self, 8)
    
    def name(self):
        return 'trapCause'
    
    def name_vhdl(self):
        return 'rvex_trap_type'
    
    def name_vhdl_array(self):
        return 'rvex_trap_array'

TYPE_LIST.append(TrapCause())


class TwoBit(BitVector):
    """Misc. 2-bit type."""

    def __init__(self):
        BitVector.__init__(self, 2)
    
    def name(self):
        return 'twoBit'
    
    def name_vhdl(self):
        return 'rvex_2bit_type'
    
    def name_vhdl_array(self):
        return 'rvex_2bit_array'

TYPE_LIST.append(TwoBit())


class ThreeBit(BitVector):
    """Misc. 3-bit type."""

    def __init__(self):
        BitVector.__init__(self, 3)
        
    def name(self):
        return 'threeBit'
    
    def name_vhdl(self):
        return 'rvex_3bit_type'
    
    def name_vhdl_array(self):
        return 'rvex_3bit_array'

TYPE_LIST.append(ThreeBit())


class FourBit(BitVector):
    """Misc. 4-bit type."""

    def __init__(self):
        BitVector.__init__(self, 4)
    
    def name(self):
        return 'fourBit'
    
    def name_vhdl(self):
        return 'rvex_4bit_type'
    
    def name_vhdl_array(self):
        return 'rvex_4bit_array'

TYPE_LIST.append(FourBit())


class SevenByte(BitVector):
    """Misc. 4-bit type."""

    def __init__(self):
        BitVector.__init__(self, 56)
    
    def name(self):
        return 'sevenByte'
    
    def name_vhdl(self):
        return 'rvex_7byte_type'
    
    def name_vhdl_array(self):
        return 'rvex_7byte_array'

TYPE_LIST.append(SevenByte())


class TrapInfo(Aggregate):
    """Trap information structure."""
    
    def __init__(self):
        Aggregate.__init__(self)
        self.add_entry('active', Bit())
        self.add_entry('cause',  TrapCause())
        self.add_entry('arg',    Address())

    def name(self):
        return 'trapInfo'
    
    def name_vhdl(self):
        return 'trap_info_type'
    
    def name_vhdl_array(self):
        return 'trap_info_array'

    def name_c(self):
        return 'trapInfo_t'

TYPE_LIST.append(TrapInfo())

        
class BreakpointInfo(Aggregate):
    """Breakpoint information structure."""
    
    def __init__(self):
        Aggregate.__init__(self)
        self.add_array('addr', 4, Address())
        self.add_array('cfg',  4, TwoBit())

    def name(self):
        return 'breakpointInfo'
    
    def name_vhdl(self):
        return 'cxreg2pl_breakpoint_info_type'
    
    def name_vhdl_array(self):
        return 'cxreg2pl_breakpoint_info_array'

    def name_c(self):
        return 'breakpointInfo_t'

TYPE_LIST.append(BreakpointInfo())


class MMUConfig(Aggregate):
    """MMU design-time configuration structure."""
    
    def __init__(self):
        Aggregate.__init__(self)
        self.add_entry('mmuEnable',          Boolean())
        self.add_entry('pageSizeLog2',       Natural())
        self.add_entry('largePageSizeLog2',  Natural())
        self.add_entry('asidBitWidth',       Natural())

    def name(self):
        return 'mmuConfig'
    
    def name_vhdl(self):
        return 'rvex_mmuConfig_type'
    
    def name_vhdl_array(self):
        return 'rvex_mmuConfig_array'

    def name_c(self):
        return 'mmuConfig_t'

TYPE_LIST.append(MMUConfig())


class CfgVectType(Aggregate):
    
    def __init__(self):
        Aggregate.__init__(self)
        self.add_entry('numLanesLog2',          Natural())
        self.add_entry('numLaneGroupsLog2',     Natural())
        self.add_entry('numContextsLog2',       Natural())
        self.add_entry('genBundleSizeLog2',     Natural())
        self.add_entry('bundleAlignLog2',       Natural())
        self.add_entry('multiplierLanes',       Natural())
        self.add_entry('memLaneRevIndex',       Natural())
        self.add_entry('numBreakpoints',        Natural())
        self.add_entry('forwarding',            Boolean())
        self.add_entry('limmhFromNeighbor',     Boolean())
        self.add_entry('limmhFromPreviousPair', Boolean())
        self.add_entry('reg63isLink',           Boolean())
        self.add_entry('cregStartAddress',      Address())
        self.add_array('resetVectors',       8, Address())
        self.add_entry('unifiedStall',          Boolean())
        self.add_entry('gpRegImpl',             Natural())
        self.add_entry('traceEnable',           Boolean())
        self.add_entry('perfCountSize',         Natural())
        self.add_entry('cachePerfCountEnable',  Boolean())
    
    def name(self):
        return 'cfgVect'
    
    def name_vhdl(self):
        return 'rvex_generic_config_type'
    
    def name_c(self):
        return 'cfgVect_t'

TYPE_LIST.append(CfgVectType())


#===============================================================================
# No more type definitions from here onwards.
#===============================================================================

TYPE_LOOKUP = {typ.name().lower(): typ for typ in TYPE_LIST}

def parse_type(text):
    """Converts a textual type (using the language agnostic names) which can be
    instantiated by the user into an internal Type. Raises a CodeError if 
    something goes wrong."""
    
    global TYPE_LOOKUP
    typ = TYPE_LOOKUP.get(text.lower())
    if typ is not None:
        return typ
    
    raise CodeError('unknown type \'%s\'.' % text)


def generate_c_typedefs():
    """Generates C typedefs for all the types defined here."""
    
    global TYPE_LIST
    return ''.join([typ.typedef_c() for typ in TYPE_LIST])


class PerCtxt(Type):
    """Array data type for stuff which exists per context."""
    
    def __init__(self, el_typ):
        self.el_typ = el_typ
        if el_typ.name_vhdl_array() is None:
            raise CodeError('cannot instantiate type ' + self.name() + ' per context.')

    def name(self):
        return self.el_typ.name()
        
    def cls(self):
        return self.el_typ.cls() + ' per context'
        
    def name_vhdl(self):
        return '%s(2**CFG.numContextsLog2-1 downto 0)' % self.el_typ.name_vhdl_array()
    
    def name_c(self):
        return self.el_typ.name_c()

    def exists_per_context(self):
        return True
    
    def __str__(self):
        return '%s per context' % self.name()


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
    

class CombinatorialOutput(AccessibleType):
    
    def name(self):
        return 'combinatorial output'
    
    def can_read(self):
        return False
    
    def can_assign(self):
        return False
    

class Output(AccessibleType): # This behaves like a read-only register.
    
    def name(self):
        return 'output'
    
    def can_read(self):
        return False
    

class Register(AccessibleType):
    
    def name(self):
        return 'register'
    

class GlobalVariable(AccessibleType):
    
    def name(self):
        return 'variable'
    
    def vhdl_assign_type(self):
        return ':='


class Variable(AccessibleType):
    
    def name(self):
        return 'variable'
    
    def vhdl_assign_type(self):
        return ':='
    
    def is_local(self):
        return True


class Constant(AccessibleType):
    
    def name(self):
        return 'constant'
    
    def can_assign(self):
        return False
    

class PredefinedConstant(AccessibleType):
    
    def name(self):
        return 'constant'
    
    def can_assign(self):
        return False

