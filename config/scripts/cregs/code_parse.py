
import re
import code_types

from funcparserlib.lexer import *
from funcparserlib.parser import *

class ParseTree(object):
    """Represents a parse tree."""
    
    def __init__(self, origin):
        self.origin = origin
    
    def error(s):
        raise Exception('Parse error on %s: %s.' % (self.origin, s))
    

class PTLiteral(ParseTree):
    """Literal parse tree object."""
    
    def __init__(self, literal):
        ParseTree.__init__(self, literal.origin)
        
        if literal.type == 'lit_true':
            self.value = 1
            self.typ = code_types.Boolean()
            
        elif literal.type == 'lit_false':
            self.value = 0
            self.typ = code_types.Boolean()
            
        elif literal.type == 'lit_nat':
            self.value = int(literal.value, 0)
            self.typ = code_types.Natural()
            
        elif literal.type == 'lit_bit':
            self.value = int(literal.value[1], 0)
            self.typ = code_types.Bit()
            
        elif literal.type == 'lit_vec':
            v = literal.value.split('"')
            t = v[0].lower()
            bits_per_char = 4 if 'x' in t else 1
            if v[1] == '':
                self.value = 0
            else:
                self.value = int(v[1], 2**bits_per_char)
            size = bits_per_char * len(v[1])
            if 'u' in t:
                self.typ = code_types.Unsigned(size)
            else:
                self.typ = code_types.BitVector(size)
            
        else:
            raise Exception('Unknown literal type %s.' % literal.type)
        
    def __repr__(self):
        return self.typ.name() + ':' + str(self.value)


class PTReference(ParseTree):
    """Reference parse tree object."""
    
    def __init__(self, toks):
        ParseTree.__init__(self, toks[0].origin)
        self.name = toks[0].value
        self.members = [x.value for x in toks[1]]
        self.slic = None
        if toks[2] is not None:
            self.slic = toks[2].value
    
    def __repr__(self):
        s = self.name + ''.join(['.' + x for x in self.members])
        if self.slic is not None:
            if type(self.slic) is tuple:
                s += '[%s, %s]' % (str(self.slic[0]), str(self.slic[1]))
            else:
                s += '[%s]' % str(self.slic)
        return s


class PTExpression(ParseTree):
    """Expression parse tree object."""
    
    def __init__(self, operator, operands):
        
        # Find out the origin of this expression.
        if len(operands) == 1:
            ParseTree.__init__(self, operator.origin)
        else:
            ParseTree.__init__(self, operands[0].origin)
        
        self.operator = operator.value
        self.operands = operands
    
    def __repr__(self):
        if len(self.operands) == 1:
            return str(self.operator) + str(self.operands[0])
        else:
            return '(%s %s %s)' % (
                str(self.operands[0]),
                str(self.operator),
                str(self.operands[1]))


class PTBlock(ParseTree):
    """Block statement parse tree object."""
    
    def __init__(self, tokens, bare=False):
        ParseTree.__init__(self, tokens[0].origin)
        if bare:
            self.statements = tokens
        else:
            self.statements = tokens[1]
    
    def __repr__(self):
        return ''.join([str(x) for x in self.statements])


class PTAssignment(ParseTree):
    """Assignment statement parse tree object."""
    
    def __init__(self, tokens):
        ParseTree.__init__(self, tokens[0].origin)
        self.lvalue = tokens[0]
        self.rvalue = tokens[2]
    
    def __repr__(self):
        return str(self.lvalue) + ' = ' + str(self.rvalue) + ';\n'


class PTConditional(ParseTree):
    """If/else statement parse tree object."""
    
    def __init__(self, tokens):
        ParseTree.__init__(self, tokens[0].origin)
        self.condition = tokens[2]
        self.true = tokens[4]
        if tokens[5] is not None:
            self.false = tokens[5][1]
        else:
            self.false = []
    
    def __repr__(self):
        true = '  ' + '\n  '.join(str(self.true).split('\n'))[:-2]
        false = '  ' + '\n  '.join(str(self.false).split('\n'))[:-2]
        return (
            'if (' + str(self.condition) + ') {\n' + true +
            '} else {\n' + false + '}\n')


class PTVerbatim(ParseTree):
    """Verbatim statement parse tree object."""
    
    def __init__(self, tokens):
        ParseTree.__init__(self, tokens[0].origin)
        self.lang = tokens[0].value[2:]
        self.contents = [('verbatim', tokens[1].value)]
        for tok in tokens[2]:
            self.contents.append(('name', tok[0].value))
            self.contents.append(('verbatim', tok[1].value))
    
    def __repr__(self):
        return '<?' + self.lang + ''.join([x[1] for x in self.contents]) + '?>'


"""
Literals
--------
 - true and false:        boolean
 - decimal number:        natural
 - 0 octal number:        natural
 - 0b binary number:      natural
 - 0x hexadecimal number: natural
 - '0' and '1':           bit
 - "0101":                bitvect
 - X"DEADBEEF":           bitvect
 - U"0101":               unsigned
 - UX"0101":              unsigned

Note that there is no aggregate literal.


References
----------

TODO


Expressions
-----------

Precedence
 |                      .----------.----------.----------.----------.----------.
 V       Operand types: | boolean  | natural  | bit      | bitvect  | unsigned |
----.-------------------+----------+----------+----------+----------+----------|
 () | typecast          | ...      | ...      | ...      | ...      | ...      |
 ~  | one's complement  |          | natural  | bit      | bitvect  | bitvect  |
 !  | boolean not       | boolean  | boolean  | bit      |          |          |
----+-------------------+----------+----------+----------+----------+----------|
 *  | multiplication    |          | natural  |          |          |          |
 /  | division          |          | natural  |          |          |          |
 %  | modulo            |          | natural  |          |          |          |
----+-------------------+----------+----------+----------+----------+----------|
 +  | addition          |          | natural  |          | unsigned | unsigned |
 -  | subtraction       |          | natural  |          | unsigned | unsigned |
 $  | concatenation     | bitvect  |          | bitvect  | bitvect  | bitvect  |
----+-------------------+----------+----------+----------+----------+----------|
 << | shift left*       |          | natural  |          | unsigned | unsigned |
 >> | shift right*      |          | natural  |          | unsigned | unsigned |
----+-------------------+----------+----------+----------+----------+----------|
 <= | less/equal        |          | boolean  |          | boolean  | boolean  |
 <  | less              |          | boolean  |          | boolean  | boolean  |
 >= | greater/equal     |          | boolean  |          | boolean  | boolean  |
 >  | greater           |          | boolean  |          | boolean  | boolean  |
----+-------------------+----------+----------+----------+----------+----------|
 == | equal             | boolean  | boolean  | boolean  | boolean  | boolean  |
 != | not equal         | boolean  | boolean  | boolean  | boolean  | boolean  |
----+-------------------+----------+----------+----------+----------+----------|
 &  | bitwise and       |          | natural  | bitvect  | bitvect  | bitvect  |
----+-------------------+----------+----------+----------+----------+----------|
 ^  | bitwise xor       |          | natural  | bitvect  | bitvect  | bitvect  |
----+-------------------+----------+----------+----------+----------+----------|
 |  | bitwise or        |          | natural  | bitvect  | bitvect  | bitvect  |
----+-------------------+----------+----------+----------+----------+----------|
 && | boolean and       | boolean  | boolean  | bit      |          |          |
----+-------------------+----------+----------+----------+----------+----------|
 ^^ | boolean xor       | boolean  | boolean  | bit      |          |          |
----+-------------------+----------+----------+----------+----------+----------|
 || | boolean or        | boolean  | boolean  | bit      |          |          |
----'-------------------'----------'----------'----------'----------'----------'

*second operand must always be a natural.
"""


def parser_generate():
    
    # Create the tokenizer.
    tokspec = [
        
        # Optional spacing. ----------------------------------------------------
        ('space',    (r'\s+', re.MULTILINE)),
        
        # Literals. ------------------------------------------------------------
        ('lit_nat',  (r'([1-9][0-9]*)|0(([Xx][0-9a-fA-F]+)|([Bb][0-1]+)|([0-7]*))',)),
        ('lit_bit',  (r"'[01]'",)),
        ('lit_vec',  (r'[Uu]?(("[01]*")|([Xx]"[0-9A-Fa-f]*"))',)),
        
        # References. ----------------------------------------------------------
        ('name',     (r'[_a-zA-Z][_a-zA-Z0-9]*',)), # Object or function name.
        ('context',  (r'@',)),                      # Context specifier.
        ('member',   (r'\.(?!\.)',)),               # Member separator.
        ('sl_open',  (r'\[',)),                     # Slice open.
        ('sl_close', (r'\]',)),                     # Slice close.
        ('comma',    (r',',)),                      # Slice separator.
        
        # Parentheses. ---------------------------------------------------------
        ('open',     (r'\(',)),                     # Parenthesis open.
        ('close',    (r'\)',)),                     # Parenthesis close.
        
        # Expressions. ---------------------------------------------------------
        ('unop1',    (r'(!(?!=))|~',)),             # Level 1: unary.
        ('binop2',   (r'[\*/%]',)),                 # Level 2: mul, div, mod.
        ('binop3',   (r'[\+\-\$]',)),               # Level 3: add, sub, concat ($).
        ('binop4',   (r'(\<\<)|(\>\>)',)),          # Level 4: shifts.
        ('binop5',   (r'[\<\>](?!\?)=?',)),         # Level 5: relational.
        ('binop6',   (r'[!=]=',)),                  # Level 6: equality.
        ('binop7',   (r'\&(?!\&)',)),               # Level 7: bitwise and.
        ('binop8',   (r'\^(?!\^)',)),               # Level 8: bitwise xor.
        ('binop9',   (r'\|(?!\|)',)),               # Level 9: bitwise or.
        ('binop10',  (r'\&\&',)),                   # Level 10: logical and.
        ('binop11',  (r'\^\^',)),                   # Level 11: logical xor.
        ('binop12',  (r'\|\|',)),                   # Level 12: logical and.
        
        # Statements. ----------------------------------------------------------
        ('assign',   (r'=(?!=)',)),                 # Assignment.
        ('verb_open',(r'\<\?((vhdl)|c)',)),         # Verbatim block open.
        ('verb_close',(r'\?\>',)),                  # Verbatim block close.
        ('semicol',  (r';',)),                      # Statement separator.
        ('bl_open',  (r'\{',)),                     # Statement block open.
        ('bl_close', (r'\}',)),                     # Statement block close.
        
        # Anything which isn't known by our language. --------------------------
        ('foreign',  (r'.',))
        
    ]
    tokenize = make_tokenizer(tokspec)
    
    
    def fmt_place(place, origins, print_cols):
        s = 'line %s' % origins[place[0]-1]
        if print_cols:
            s = '%s column %s' % (s, place[1])
        return s
    
    
    class PPToken(Token):
        def __init__(self, tok, origins, print_cols):
            if type(tok) == list:
                val = ''.join([x.value for x in tok])
                Token.__init__(self, 'verbatim', val, tok[0].start, tok[-1].end)
            else:
                Token.__init__(self, tok.type, tok.value, tok.start, tok.end)
            self.origin = fmt_place(self.start, origins, print_cols)
        
        def __eq__(self, other):
            # Override with case-insensitive equality.
            return (self.type == other.type and
                self.value.lower() == other.value.lower())
        
        def __repr__(self):
            # Override with something nicer.
            return 'token \'%s\' on %s' % (self.value, self.origin)
        
        __str__ = __repr__
    
    
    class TempToken(PPToken):
        def __init__(self, type, val, tok):
            Token.__init__(self, type, val, tok.start, tok.end)
            self.origin = tok.origin
    
    
    def post_process_tokens(tokens, origins, print_cols):
        pptokens = []
        foreign_tokens = []
        foreign = False
        escape = False
        
        def flush_foreign(foreign_tokens, token):
            if len(foreign_tokens) > 0:
                pptokens.append(PPToken(foreign_tokens, origins, print_cols))
            else:
                pptokens.append(PPToken(Token(
                    'verbatim', '', token.start, token.start
                ), origins, print_cols))
        
        for token in tokens:
            
            # Replace keywords and function names.
            if token.type == 'name':
                special_names = {
                    'if':    'key_if',
                    'else':  'key_else',
                    'true':  'lit_true',
                    'false': 'lit_false',
                }
                if token.value in special_names:
                    token.type = special_names[token.value]
            
            # Use our customized token type.
            token = PPToken(token, origins, print_cols)
            
            # Exit foreign code.
            if token.type == 'verb_close':
                escape = False
                foreign = False
                flush_foreign(foreign_tokens, token)
                foreign_tokens = []
            
            if foreign:
                if escape:
                    escape = False
                    pptokens.append(token)
                
                elif token.type == 'context': # the @ symbol
                    escape = True
                    flush_foreign(foreign_tokens, token)
                    foreign_tokens = []
                
                else:
                    foreign_tokens.append(token)
                
            elif token.type != 'space':
                pptokens.append(token)
            
            # Enter foreign code.
            if token.type == 'verb_open':
                foreign = True
            
        
        return pptokens
            
    
    
    # This class makes it syntactically easy to return a parser which matches
    # exactly one token. For instance, tok.literal returns a parser which
    # matches exactly one 'literal' token.
    class TokenToParser(object):
        def __init__(self):
            self.cache = dict()
        
        def __getattr__(self, typ):
            if typ in self.cache:
                return self.cache[typ]
            p = some(lambda tok: tok.type == typ)
            self.cache[typ] = p
            return p
    tok = TokenToParser()
    
    # Handle literals.
    literal = (
        tok.lit_true  |
        tok.lit_false |
        tok.lit_nat   |
        tok.lit_bit   |
        tok.lit_vec
    ) >> (lambda x : PTLiteral(x))
    
    # Forward declaration for expressions, because we need it for slice
    # indexing.
    expression = forward_decl()
    
    # Reference name.
    ref_name = (
        tok.name +
        maybe(
            tok.context +
            tok.lit_nat
        )
    ) >> (lambda x : TempToken('ref_name',
        x[0].value + (
            ('@%d' % int(x[1][1].value, 0))
            if x[1] is not None else ''
        ),
    x[0]))
    
    # Reference member, for aggregate types.
    ref_member = (
        tok.member +
        tok.name +
        maybe(
            tok.bl_open +
            tok.lit_nat +
            tok.bl_close
        )
    ) >> (lambda x : TempToken('ref_member',
        x[1].value + (
            ('[%d]' % int(x[2][1].value, 0))
            if x[2] is not None else ''
        ),
    x[0]))
    
    # Slices for bitvec and unsigned.
    ref_slice = (
        tok.sl_open +
        expression +
        maybe(
            tok.comma +
            tok.lit_nat
        ) +
        tok.sl_close
    ) >> (lambda x : TempToken('ref_member',
        x[1] if x[2] is None
        else (x[1], int(x[2][1].value, 0)),
    x[0]))
    
    # Complete object reference.
    reference = (
        ref_name +
        many(ref_member) +
        maybe(ref_slice)
    ) >> PTReference
    
    # Generate expressions.
    #  - Handle parentheses.
    paren = (tok.open + expression + tok.close) >> (lambda x : x[1])
    e = literal | reference | paren
    
    #  - Define what to do with sequences of unary and binary operators.
    def unary(toks):
        toks = toks[0] + [toks[1]]
        while len(toks) > 1:
            toks[-2:] = [PTExpression(toks[-2], [toks[-1]])]
        return toks[0]
    
    def binary(toks):
        toks = [toks[0]] + toks[1]
        while len(toks) > 1:
            toks[:2] = [PTExpression(toks[1][0], [toks[0], toks[1][1]])]
        return toks[0]
    
    #  - Handle all unary and binary operators in order of precedence.
    cast = (tok.open + tok.name + tok.close) >> (lambda x : x[1])
    firstunop = True
    for spec in tokspec:
        toktyp = spec[0]
        
        if toktyp.startswith('unop'):
            
            # Create unary operator expression.
            op = tok.__getattr__(toktyp)
            if firstunop:
                firstunop = False
                op = op | cast
            e = many(op) + e >> unary
            
        elif toktyp.startswith('binop'):
            
            # Create binary operator expression.
            op = tok.__getattr__(toktyp)
            e = e + many(op + e) >> binary
    
    #  - Finally, define the expression with what we've got now.
    expression.define(e)
    
    # Define statements.
    statement = forward_decl()
    statements = many(statement)
    
    # Block statement.
    block = (
        tok.bl_open +
        statements +
        tok.bl_close
    ) >> PTBlock
    
    # Assignment statement.
    assign = (
        reference +
        tok.assign +
        expression +
        tok.semicol
    ) >> PTAssignment
    
    # Conditional statement.
    ifelse = (
        tok.key_if +
        tok.open + 
        expression +
        tok.close +
        statement +
        maybe(
            tok.key_else +
            statement
        )
    ) >> PTConditional
    
    # Verbatim statement.
    verbatim = (
        tok.verb_open +
        tok.verbatim +
        many(
            tok.name +
            tok.verbatim
        ) +
        tok.verb_close
    ) >> PTVerbatim
    
    # Any statement.
    statement.define(
        block |
        assign |
        ifelse |
        verbatim
    )
    
    # Define the toplevel parsers.
    toplevel_exp = expression + finished
    toplevel = statements + finished
    
    
    def parse(code):
        """Returns the parse tree for the given code, which must be a list of
        two-tuples containing origin and line, without \n."""
        
        # Unpack the line list.
        origins = [x[0] for x in code]
        code = '\n'.join([x[1] for x in code])
        
        # Tokenize.
        try:
            tokens = post_process_tokens(tokenize(code), origins, True)
        except LexerError as e:
            raise Exception('Garbage on input %s.' % fmt_place(e.place, origins, True))
        
        # Parse.
        return PTBlock(toplevel.parse(tokens)[0], True)
    
    
    def parse_exp(exp, origin):
        """Returns the parse tree for the given single-line expression."""
        
        # Make sure there's actually no line endings.
        exp = ' '.join(exp.split('\n'))
        
        # Tokenize.
        try:
            tokens = post_process_tokens(tokenize(exp), [origin], True)
        except LexerError as e:
            raise Exception('Garbage on input %s.' % fmt_place(e.place, [origin], False))
        
        # Parse.
        return toplevel_exp.parse(tokens)[0]
    
    
    return parse, parse_exp

parse, parse_exp = parser_generate()

code = """
if (a != b) {
    a = a + b;
} else x = y;
"""

code = """
a = b + c;
"""

import pprint
#pprint.pprint(parse_exp(code, '<internal>'))
pprint.pprint(parse([('<internal>:%s' % i, s) for i, s in enumerate(code.split('\n'))]))

