from code_types import *
from code_environment import *

class Code(object):
    
    def __init__(self, vhdl, c):
        """Constructs a list of VHDL and C statements."""
        self.vhdl = vhdl
        self.c = c
    
    def indent(self, vhdl_level, c_level):
        """Makes a copy of this Code with the given indentation levels
        applied."""
        vhdl = ['  '*vhdl_level + s for s in self.vhdl]
        c = ['  '*c_level + s for s in self.c]
        return Code(vhdl, c)
    
    def output_vhdl(self, indent):
        """Returns the VHDL code as a string with newlines, using the given
        indentation level."""
        indent = '  '*indent
        return indent + ('\n' + indent).join(self.vhdl) + '\n'
    
    def output_c(self, indent):
        """Returns the C code as a string with newlines, using the given
        indentation level."""
        indent = '  '*indent
        return indent + ('\n' + indent).join(self.c) + '\n'
    
    def __str__(self):
        return '<?vhdl\n' + self.output_vhdl(1) + '=?c=\n' + self.output_c(1) + '?>\n'
    

class Expression(object):
    
    def __init__(self, vhdl, c, typ):
        """Constructs a VHDL and C expression of the given type."""
        self.vhdl = vhdl
        self.c = c
        self.typ = typ

    def pattern(self, vhdl, c):
        return Code(vhdl % self.vhdl, c % self.c)

    def cast(self, to_typ):
        return cast(self, to_typ)
        

def access(ob, direction='r', ctxt=None, slic=None):
    """Generates an Expression for how to read from or write to object ob
    (Object) from context ctxt (Expression or None) using slice slic
    (Expression, (Expression, Expression) or None). direction should be 'r' or
    'w'. No type or name checks are performed at this point."""
    
    # Generate VHDL syntax.
    vhdl = ob.name
    if ctxt is not None:
        vhdl = '%s(%s)' % (vhdl, ctxt.vhdl)
    if slic is not None:
        if type(slic) is tuple:
            vhdl = '%s(%s downto %s)' % (vhdl, slic[0].vhdl, slic[1].vhdl)
        else:
            vhdl = '%s(%s)' % (vhdl, slic.vhdl)
    
    # Generate C syntax. Note how everything is promoted to uint64_t. This makes
    # sure that all operations support all 64 possible bits which we support.
    # Compiler optimization will demote this sort of thing when it determines
    # that the upper results are not used.
    if ob.atyp.name() in ['input', 'output']:
        if ctxt is not None:
            c = '(uint64_t)cxiface[%s]->%s' % (ctxt.c, ob.name)
        else:
            c = '(uint64_t)gbiface->%s' % ob.name
    elif ob.atyp.name() in ['register']:
        if direction == 'r':
            qd = 'q'
        else:
            qd = 'd'
        if ctxt is not None:
            c = '(uint64_t)cxr%s[%s]->%s' % (qd, ctxt.c, ob.name)
        else:
            c = '(uint64_t)gbr%s->%s' % (qd, ob.name)
    else:
        if ctxt is not None:
            c = '(uint64_t)%s[%s]' % (ctxt.c, ob.name)
        else:
            c = '(uint64_t)%s' % ob.name
    
    # Emulate slices in C.
    if slic is not None:
        if type(slic) is tuple:
            c = '((%s)&((1ull<<((%s)+1ull))-1ull))>>(%s)' % (c, slic[0].c, slic[1].c)
        else:
            c = '((%s)>>(%s))&1' % (c, slic.c)
    
    return Expression(vhdl, c, ob.atyp.typ)


def read(ob, ctxt=None, slic=None):
    """Generates an Expression for how to read object ob (Object) from context
    ctxt (Expression or None) using slice slic (Expression,
    (Expression, Expression) or None). No type or name checks are performed at
    this point."""
    return access(ob, 'r', ctxt, slic)


def write(ob, ctxt=None):
    """Generates an Expression for how to write to object ob (Object) from
    context ctxt (Expression or None). Slices are not supported here because
    they require changing the to-be-assigned expression. No type or name checks
    are performed at this point."""
    return access(ob, 'w', ctxt)


def assign(ob, expr, ctxt=None, slic=None):
    """Generates a Code object for how to assign expr (Expression) to object ob
    (Object) from context ctxt (Expression or None) using the given slice
    (Expression, (Expression, Expression) or None). No type or name checks are
    performed at this point."""
    
    # Get the object name in both languages.
    e = write(ob, ctxt)
    vhdl = e.vhdl
    c = e.c
    
    # Handle VHDL slice and assignment type.
    if slic is not None:
        if type(slic) is tuple:
            vhdl = '%s(%s downto %s)' % (vhdl, slic[0].vhdl, slic[1].vhdl)
        else:
            vhdl = '%s(%s)' % (vhdl, slic.vhdl)
    vhdl = ['%s %s %s;' % (vhdl, ob.atyp.vhdl_assign_type(), expr.vhdl)]
    
    # Emulate slices in C.
    if slic is None:
        c = ['%s = %s;' % (c, expr.c)]
    elif type(slic) is tuple:
        c = ['if (1) {',
             '  uint32_t __shift = %s;' % slic[1].c,
             '  uint64_t __mask = ((1ull<<((%s)+1ull-__shift))-1ull) << __shift;' % slic[0].c,
             '  %s &= ~__mask;' % c,
             '  %s |= ((%s)<<__shift)&__mask;' % (c, expr.c),
             '}']
    else:
        c = ['if (1) {',
             '  uint64_t __shift = %s;' % slic.c,
             '  %s &= ~(1ull << __shift);' % c,
             '  %s |= ((%s)&1) << __shift;' % (c, expr.c),
             '}']
    
    return Code(vhdl, c)


def cast(expr, to_typ):
    """Typecasts the given expression to the given type."""
    
    # Nothing needs to be done if this is already the desired type.
    if self.typ == to_typ:
        return self
    
    # TODO
    
    # Failed to cast.
    raise TypError('Cannot cast %s to %s.' % (self.typ, to_typ))


if __name__ == "__main__":
    x = Object('', 'x', Variable(BitVector(3, 5)))
    y = Object('', 'y', Variable(BitVector(1, 3)))
    print(assign(y, read(x, slic=read(x)), slic=read(x)))
