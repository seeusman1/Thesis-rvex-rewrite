"""This file transforms the parsed AST to the final AST. It also drives the
front-end and back-end."""

from ast import *
from front_end import *
from back_end import *
from type_sys import *
from environment import *
from excepts import *
from indentation import *

def transform_code(code, templates, gen_values, env, source):
    """Converts a block of language-agnostic code (statements) to VHDL and C.
    
     - code: must be a list of two-tuples, wherein the first entry is a string
       identifying the origin of the source code line specified in the second
      entry.
     - templates: TODO
     - gen_values: a dictionary from generator name (for instance 'n' for \n{})
       to its numeric value.
     - env: specifies the variable environment.
     - source: should be a string which identifies where this block of code came
       from, for instance a register/field name, ending in a colon and a space.
       It is prefixed to all error messages to make the source of the error
       easier to find.
    
    Returns a two-tuple, with the VHDL code in the first entry and the C code in
    the second.
    """
    try:
        
        # Expand templates.
        # TODO
        
        # Parse the code.
        ast = parse(code, gen_values)
        print(ast.pp_ast())
        
        # Resolve literals and references.
        ast = ast.apply_xform_dfs(Resolve(env))
        print(ast.pp_ast())
        
    except Exception as e:
        except_prefix(e, source)


def transform_expression(exp, origin, typ, gen_values, env, source, single_line=False, debug=False):
    """Converts a block of language-agnostic code (statements) to VHDL and C.
    
     - exp: a single line of expression code expressed as a string.
     - origin: the origin of the line.
     - typ: the desired result type class of the expression, from code_types.py.
     - gen_values: a dictionary from generator name (for instance 'n' for \n{})
       to its numeric value.
     - env: specifies the variable environment.
     - source: should be a string which identifies where this block of code came
       from, for instance a register/field name, ending in a colon and a space.
       It is prefixed to all error messages to make the source of the error
       easier to find.
     - single_line: if true, aggregates will not print on multiple lines.
    
    Returns a two-tuple, with the VHDL code in the first entry and the C code in
    the second.
    """
    try:
        
        # Print debug message.
        if debug:
            print('%s%s: parsing expression:\n    %s\nas type %s...\n' %
                  (source, origin, exp, typ))
        
        # Parse the expression.
        ast = parse_exp(exp, origin, gen_values)
        if debug:
            print('Pretty-printed:\n    %s\n', str(ast))
            print('AST:')
            print(ast.pp_ast())
            print('')
        
        # Resolve literals and references.
        ast = ast.apply_xform_dfs(Resolve(env))
        if debug:
            print('AST after resolving:')
            print(ast.pp_ast())
            print('')
        
        # Handle aggregates.
        ast = generate_expression_ast(ast, typ)
        if debug:
            print('AST after generating:')
            print(ast.pp_ast())
            print('')
        
        # Merge all the generated bits of code together.
        vhdl = ast.generate('vhdl')
        c = ast.generate('c')
        
        # Pretty-print the output as requested.
        if single_line:
            vhdl = vhdl.replace('\n', '')
            c = c.replace('\n', '')
        else:
            vhdl = indentify(vhdl, 'vhdl')
            c = indentify(c, 'c')
        
        # Print and return result.
        if debug:
            print('Generated VHDL code:')
            print(vhdl)
            print('')
            print('Generated C code:')
            print(c)
            print('')
        
        return (vhdl, c)
        
    except Exception as e:
        except_prefix(e, source)


class Resolve(Transformation):
    """Resolves literals, object references and type names.
    
     - All 'lit_*' nodes are converted to 'lit', with the following annotations:
        - value --> representative integer value.
        - typ --> type class.
     
     - All 'reference' nodes are annotated:
        - ob --> Object class of the resolved object.
        - ctxt --> None, int or str for the context specifier.
        - typ --> type class of the resolved object, with PerCtxt removed.
     
     - All 'member' nodes are annotated:
        - typ --> type class of the resolved object
        - member --> member name
     
     - All 'member_name' nodes are removed.
     
     - All 'slice' nodes are annotated:
        - typ --> type class of the sliced object.
     
     - All 'cast' nodes are annotated:
        - typ --> cast return type.
        
     - All 'cast_type' nodes are removed.
     
    """
    
    def __init__(self, env):
        self.env = env
    
    # Literal conversion. ------------------------------------------------------
    def lit_true(self, node):
        node.node_type = 'lit'
        node['value'] = 1
        node['typ'] = Boolean()

    def lit_false(self, node):
        node.node_type = 'lit'
        node['value'] = 0
        node['typ'] = Boolean()

    def lit_nat(self, node):
        val = int(node.value, 0)
        if val > 0x7FFFFFFF:
            raise CodeError('natural literal out of 31-bit range.')
        
        node.node_type = 'lit'
        node['value'] = val
        node['typ'] = Natural()

    def lit_bit(self, node):
        val = int(node.value[1])
        
        node.node_type = 'lit'
        node['value'] = val
        node['typ'] = Bit()
        
    def lit_vec(self, node):
        v = node.value.split('"')
        t = v[0].lower()
        bits_per_char = 4 if 'x' in t else 1
        if v[1] == '':
            val = 0
        else:
            val = int(v[1], 2**bits_per_char)
        size = bits_per_char * len(v[1])
        if 'u' in t:
            typ = Unsigned(size)
        else:
            typ = BitVector(size)
        
        node.node_type = 'lit'
        node['value'] = val
        node['typ'] = typ
    
    # Reference resolution and manipulation. -----------------------------------
    def reference(self, node):
        ob, ctxt = self.env.lookup(node.value)
        node['ob'] = ob
        node['ctxt'] = ctxt
        typ = ob.atyp.typ
        if isinstance(typ, PerCtxt):
            typ = typ.el_typ
        node['typ'] = typ
    
    def member_name(self, node):
        ob = node.parent[0]
        if node.value.endswith('{others}'):
            raise CodeError('the \'others\' keyword can only be used in aggregates.')
        typ = ob['typ'].member_type(node.value)
        if typ is None:
            raise CodeError('%s is not a member of type %s.' %
                            (node.value, ob['typ']))
        node['typ'] = typ
    
    def member(self, node):
        # Put the data from the member_name node in here as annotations and get
        # rid of the name node.
        node['member'] = node[1].value
        node['typ'] = node[1]['typ']
        node.children = node.children[0:1]
        
    def slice(self, node):
        typ = node[0]['typ']
        if not typ.can_slice():
            raise CodeError('type %s cannot be sliced.' % typ)
        typ = typ.slice_type(node['size'])
        if typ is None:
            raise CodeError('invalid slice mode for type %s.' % typ)
        node['typ'] = typ
    
    # Typecast type resolution. ------------------------------------------------
    def cast_type(self, node):
        node['typ'] = parse_type(node.value)
    
    def cast(self, node):
        # Put the data from the cast_type node in here as annotations and get
        # rid of the type node.
        node['typ'] = node[0]['typ']
        node['explicit'] = True
        node.children = node.children[1:2]
    
    
def generate_expression_ast(ast, typ):
    """Generates the code for an expression AST given the expected type and
    returns the updated AST."""
    
    # Handle regular expressions.
    if ast.node_type != 'aggregate':
        
        # Replace the root with an implicit type cast to the desired type.
        ast = ASTNode('cast', [ast])
        ast['typ'] = typ
        ast['explicit'] = False
        
        # Propagate types down the expression and cast tree and generate the
        # code for the expression while doing so.
        return ast.apply_xform_dfs(GenerateExpr())
    
    # Handle aggregates from here on.
    
    # Return an error if we're not expecting an aggregate type.
    member_types = typ.get_members()
    if member_types is None:
        raise CodeError('%s expected, aggregate found.' % typ)
    
    # Order the entries by most specific to least specific so we can apply them
    # one by one.
    entries = []
    array_others = []
    others = None
    specified = set()
    for node in ast:
        name = node[0].value.lower()
        expr = node[1]
        
        # Check for duplicates.
        if name in specified:
            raise CodeError('\'%s\' has already been specified.')
        specified.add(name)
        
        # Add the entry to its specificity-specific list.
        if name == 'others':
            others = expr
        elif name.endswith('{others}'):
            array_others.append((name, expr))
        else:
            entries.append((name, expr))
    
    # Add the specificity levels together.
    entries += array_others
    if others is not None:
        entries.append(('others', others))
    
    # Initialize the expression for all members to None, so we can detect if
    # anything has been left unspecified.
    members = {}
    for name in member_types:
        members[name] = None
    
    # Define a shorthand for generating the expression for an entry if it is not
    # already specified.
    def assign(members, name, expr):
        if members[name] is None:
            try:
                x = generate_expression_ast(expr, member_types[name])
                members[name] = (x.generate('vhdl'), x.generate('c'))
            except Exception as e:
                except_prefix(e, 'aggregate entry \'%s\': ' % name)
    
    # Work through all the entries.
    for name, expr in entries:
        if name in members:
            assert members[name] is None
            assign(members, name, expr)
            
        elif name.endswith('{others}'):
            name = name.split('{')[0]
            found = False
            for fullname in members:
                if fullname.split('{')[0] == name:
                    found = True
                    assign(members, fullname, expr)
            if not found:
                raise CodeError('\'%s\' is not a member of type %s.' %
                                (name, typ))
            
        elif name == 'others':
            for fullname in members:
                assign(members, fullname, expr)
            
        else:
            raise CodeError('\'%s\' is not a member of type %s.' %
                            (name, typ))
    
    # Check if anything is left undefined.
    for name in members:
        if members[name] is None:
            raise CodeError('\'%s\' has not been assigned a value (type %s).' %
                            (name, typ))
    
    # Generate the code.
    vhdl, c = generate_aggregate(members, typ)
    
    # Return the generated code as an AST leaf node.
    ast = ASTLeaf('aggregate', '<aggregate>', ast.origin)
    ast['vhdl'] = vhdl
    ast['c'] = c
    return ast


class GenerateExpr(Transformation):
    """Generates all code in an expression AST. 'vhdl' and 'c' annotations are
    added to each expected node, and 'typ' annotations are added where they do
    not already exist."""
    
    def lit(self, node):
        node['vhdl'], node['c'] = generate_literal(node['value'], node['typ'])
    
    def reference(self, node):
        # Check that we have the priviliges to read from this object and mark
        # that we've used it.
        ob = node['ob']
        if not ob.atyp.can_read():
            raise CodeError('cannot read from %s object \'%s\'.' % (ob.atyp.name(), ob.name))
        ob.used = True
        node['vhdl'], node['c'] = generate_reference(ob, node['ctxt'])
    
    def member(self, node):
        node['vhdl'], node['c'] = generate_member(node['member'])
    
    def slice(self, node):
        node['vhdl'], node['c'] = generate_slice_read(node['size'])

    def cast(self, node):
        node['vhdl'], node['c'], dummy = generate_typecast(
            node[0]['typ'], node['typ'].cls(), node['explicit'])
    
    def expr(self, node):
        node['vhdl'], node['c'], node['typ'] = generate_expr(
            node['op'], [x['typ'] for x in node.children])

