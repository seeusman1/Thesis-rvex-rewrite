"""Language-agnostic code and expression parser.

Refer to the README file in the creg config folder for syntax information."""

import re

from code_ast import *
from funcparserlib.lexer import *
from funcparserlib.parser import *

class ASTLiteral(ASTLeaf):
    """Literal parse tree object."""
    
    def __init__(self, tok):
        ASTLeaf.__init__(self, tok.type, tok.value, tok.origin)
        

class ASTReference(ASTLeaf):
    """Reference parse tree object."""
    
    def __init__(self, tokens):
        name = tokens[0].value
        members = [x.value for x in tokens[1]]
        slic = None
        if tokens[2] is not None:
            slic = tokens[2].value
        
        s = name + ''.join(['.' + x for x in members])
        if slic is not None:
            if type(slic) is tuple:
                s += '[%s, %s]' % (slic[0], slic[1])
            else:
                s += '[%s]' % slic
        
        ASTLeaf.__init__(self, 'reference', s, tokens[0].origin)
        self['name'] = name
        self['member'] = '.'.join(members) if len(members) > 0 else None
        self['slic'] = slic
    

class ASTType(ASTLeaf):
    """Type name parse tree object."""
    
    def __init__(self, tok):
        ASTLeaf.__init__(self, 'type', tok.value, tok.origin)
        

class ASTCast(ASTNode):
    """Expression parse tree object."""
    
    def __init__(self, type, expr):
        ASTNode.__init__(self, 'cast', [type, expr])
    
    def __str__(self):
        return '(%s)%s' % (self[0], self[1])


class ASTExpression(ASTNode):
    """Expression parse tree object."""
    
    def __init__(self, operator, operands):
        if len(operands) == 1:
            orig = operator.origin
        else:
            orig = operands[0].origin
        ASTNode.__init__(self, 'expr', operands)
        self['op'] = operator.value
    
    def __str__(self):
        if len(self) == 1:
            return '%s%s' % (self['op'], self[0])
        else:
            return '(%s %s %s)' % (self[0], self['op'], self[1])


class ASTBlock(ASTNode):
    """Block statement parse tree object."""
    
    def __init__(self, tokens, bare=False):
        ASTNode.__init__(self, 'block', tokens if bare else tokens[1])
        if not bare:
            self._orig = tokens[0].origin
    
    def __str__(self):
        s = ''.join([str(x) for x in self])
        if self.parent is not None:
            s = '{\n' + '\n'.join(['  ' + x for x in s.split('\n')]) + '}\n'
        return s


class ASTAssignment(ASTNode):
    """Assignment statement parse tree object."""
    
    def __init__(self, tokens):
        ASTNode.__init__(self, 'assign', [tokens[0], tokens[2]])
    
    def __str__(self):
        return '%s = %s;\n' % (self[0], self[1])


class ASTConditional(ASTNode):
    """If/else statement parse tree object."""
    
    def __init__(self, tokens):
        if tokens[5] is not None:
            ASTNode.__init__(self, 'if', [tokens[2], tokens[4], tokens[5][1]])
        else:
            ASTNode.__init__(self, 'if', [tokens[2], tokens[4], ASTBlock([], True)])
        self._orig = tokens[0].origin
        self.condition = tokens[2]
        self.true = tokens[4]
        if tokens[5] is not None:
            self.false = tokens[5][1]
        else:
            self.false = []
    
    def __str__(self):
        s = 'if (' + str(self[0]) + ') '
        s += '\n'.join(['  ' + x for x in str(self[1]).split('\n')])
        if len(self) > 2:
            s += 'else ' + '\n'.join(['  ' + x for x in str(self[2]).split('\n')])
        return s


class ASTVerbForeign(ASTLeaf):
    """Verbatim reference parse tree object."""
    
    def __init__(self, tokens):
        val = ''.join([x.value for x in tokens])
        ASTLeaf.__init__(self, 'foreign', val, tokens[0].origin)


class ASTVerbRef(ASTLeaf):
    """Verbatim reference parse tree object."""
    
    def __init__(self, tokens):
        ASTLeaf.__init__(self, 'reference', tokens[1].value, tokens[0].origin)
        self['name'] = tokens[1].value
        self['member'] = None
        self['slic'] = None
    
    def __str__(self):
        return '@%s' % self.value


class ASTVerbatim(ASTNode):
    """Verbatim statement parse tree object."""
    
    def __init__(self, tokens):
        ASTNode.__init__(self, 'verbatim', tokens[1])
        self._orig = tokens[0].origin
        self['lang'] = tokens[0].value[2:]
    
    def __str__(self):
        return '<?' + self['lang'] + ''.join([str(x) for x in self]) + '?>'


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
        foreign = False
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
                foreign = False
            elif token.type == 'verb_open':
                foreign = True
            
            # Save spacing if we're in foreign mode, trim it otherwise.
            if foreign or token.type != 'space':
                pptokens.append(token)
            
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
    ) >> (lambda x : ASTLiteral(x))
    
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
    ) >> ASTReference
    
    # Generate expressions.
    #  - Handle parentheses.
    paren = (tok.open + expression + tok.close) >> (lambda x : x[1])
    e = literal | reference | paren
    
    #  - Define what to do with sequences of unary and binary operators.
    def unary(toks):
        toks = toks[0] + [toks[1]]
        while len(toks) > 1:
            if isinstance(toks[-2], ASTType):
                toks[-2:] = [ASTCast(toks[-2], toks[-1])]
            else:
                toks[-2:] = [ASTExpression(toks[-2], [toks[-1]])]
        return toks[0]
    
    def binary(toks):
        toks = [toks[0]] + toks[1]
        while len(toks) > 1:
            toks[:2] = [ASTExpression(toks[1][0], [toks[0], toks[1][1]])]
        return toks[0]
    
    #  - Handle all unary and binary operators in order of precedence.
    cast = (tok.open + tok.name + tok.close) >> ASTType
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
    ) >> ASTBlock
    
    # Assignment statement.
    assign = (
        reference +
        tok.assign +
        expression +
        tok.semicol
    ) >> ASTAssignment
    
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
    ) >> ASTConditional
    
    # verbatim_tokens grabs any token which isn't used to break out of a
    # verbatim environment.
    verbatim_token = some(lambda tok: tok.type not in ['context', 'verb_close'])
    verbatim_tokens = oneplus(verbatim_token) >> ASTVerbForeign
    
    # Translated references in a verbatim environment.
    verbatim_ref = (tok.context + ref_name) >> ASTVerbRef
    
    # Verbatim statement.
    verbatim = (
        tok.verb_open +
        many(verbatim_tokens | verbatim_ref) +
        tok.verb_close
    ) >> ASTVerbatim
    
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
        return ASTBlock(toplevel.parse(tokens)[0], True)
    
    
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


if __name__ == '__main__':
    
    #code = """
    #if (a != b) {
    #    a = a@2 + b;
    #} else x = y;
    #"""

    code = """
    x[y]
    """

    import pprint
    print(parse_exp(code, '<internal>').pp_ast())
    #print(parse([('<internal>:%s' % i, s) for i, s in enumerate(code.split('\n'))]).pp_ast())

