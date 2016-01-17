"""This module handles tokenizing and parsing the language-agnostic code, i.e.
the front end."""

import re

import sys
from ast import *
from excepts import *
from funcparserlib.lexer import *
from funcparserlib.parser import *

class ASTLiteral(ASTLeaf):
    """Literal parse tree object."""
    
    def __init__(self, tok):
        ASTLeaf.__init__(self, tok.type, tok.value, tok.origin)
        

class ASTReference(ASTLeaf):
    """Reference parse tree object."""
    
    def __init__(self, tok):
        ASTLeaf.__init__(self, 'reference', tok.value, tok.origin)
    

class ASTMemberName(ASTLeaf):
    """Member name parse tree object."""

    def __init__(self, tokens):
        s = tokens[0].value
        if tokens[1] is not None:
            if tokens[1][1].value == 'others':
                s += '{others}'
            else:
                s += '{%d}' % int(tokens[1][1].value, 0)
        ASTLeaf.__init__(self, 'member_name', s, tokens[0].origin)
    

class ASTMember(ASTNode):
    """Member parse tree object."""
    
    def __init__(self, tok, name):
        ASTNode.__init__(self, 'member', [tok, name])
    
    def __str__(self):
        return '%s.%s' % (self[0], self[1] if len(self) > 1 else self['member'])


class ASTSlice(ASTNode):
    """Slice parse tree object."""
    
    def __init__(self, tokens):
        ASTNode.__init__(self, 'slice', [tokens[0], tokens[1][1]])
        self['size'] = None
        if tokens[1][2] is not None:
            self['size'] = int(tokens[1][2][1].value, 0)
    
    def __str__(self):
        if self['size'] is None:
            return '%s[%s]' % (self[0], self[1])
        else:
            return '%s[%s, %d]' % (self[0], self[1], self['size'])
    

class ASTCastType(ASTLeaf):
    """Typecast operator parse tree object."""
    
    def __init__(self, tokens):
        ASTLeaf.__init__(self, 'cast_type', tokens[1].value, tokens[0].origin)
        
    def __str__(self):
        return '(%s)' % self.value
        

class ASTCast(ASTNode):
    """Expression parse tree object."""
    
    def __init__(self, type, expr):
        ASTNode.__init__(self, 'cast', [type, expr])
    
    def __str__(self):
        if len(self) > 1:
            return '%s %s' % (self[0], self[1])
        else:
            return '(%s) %s' % (self['typ'], self[0])


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


class ASTOthers(ASTLeaf):
    """'others' keyword parse tree object."""

    def __init__(self, tok):
        ASTLeaf.__init__(self, 'others', tok.value, tok.origin)
    

class ASTAggregateEntry(ASTNode):
    """Aggregate entry parse tree object."""

    def __init__(self, tokens):
        ASTNode.__init__(self, 'aggregate_entry', [tokens[0], tokens[2]])
        if tokens[0].node_type == 'member_name':
            tokens[0].node_type = 'aggregate_entry_name'
    
    def __str__(self):
        return '%s => %s' % (self[0], self[1])


class ASTAggregate(ASTNode):
    """Aggregate parse tree object."""
    
    def __init__(self, tokens):
        ASTNode.__init__(self, 'aggregate', [tokens[1]] + [x[1] for x in tokens[2]])

    def __str__(self):
        return '(%s)' % ', '.join([str(x) for x in self])


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
            ASTNode.__init__(self, 'ifelse', [tokens[2], tokens[4], tokens[5][1]])
        else:
            ASTNode.__init__(self, 'ifelse', [tokens[2], tokens[4], ASTBlock([], True)])
        self._orig = tokens[0].origin
    
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
        self['dir'] = 'r' if tokens[0].value == '@read' else 'w'
    
    def __str__(self):
        return ('@read %s' if self['dir'] == 'r' else '@lvalue %s') % self.value


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
        
        # Ignored stuff. -------------------------------------------------------
        ('space',     (r'\s+', re.MULTILINE)),
        ('space',     (r'//.*(?=\n)', re.MULTILINE)),
        ('space',     (r'/\*((?!\*/).)*\*/', re.MULTILINE + re.DOTALL)),
        
        # Common stuff. --------------------------------------------------------
        ('bl_open',   (r'\{',)),                     # Block open.
        ('bl_close',  (r'\}',)),                     # Block close.
        ('open',      (r'\(',)),                     # Parenthesis open.
        ('close',     (r'\)',)),                     # Parenthesis close.
        ('comma',     (r',',)),                      # Comma.
        
        # Literals. ------------------------------------------------------------
        ('lit_gen',   (r'\\[a-zA-Z]\{\}',)),
        ('lit_nat',   (r'([1-9][0-9]*)|(0(([Xx][0-9a-fA-F]+)|([Bb][0-1]+)|([0-7]*)))',)),
        ('lit_bit',   (r"'[01]'",)),
        ('lit_vec',   (r'[Uu]?(("[01]*")|([Xx]"[0-9a-fA-F]*"))',)),
        
        # Verbatim @ commands. -------------------------------------------------
        # (these need to be defined before the 'context' token)
        ('verb_read', (r'@read',)),                  # Read reference command.
        ('verb_lval', (r'@lvalue',)),                # lvalue reference command.
        
        # References. ----------------------------------------------------------
        ('name',      (r'[_a-zA-Z][_a-zA-Z0-9]*',)), # Object or function name.
        ('context',   (r'@',)),                      # Context specifier.
        ('member',    (r'\.(?!\.)',)),               # Member separator.
        ('sl_open',   (r'\[',)),                     # Slice open.
        ('sl_close',  (r'\]',)),                     # Slice close.
        
        # Expressions. ---------------------------------------------------------
        ('unop1',     (r'(!(?!=))|~',)),             # Level 1: unary.
        ('binop2',    (r'[\*/%]',)),                 # Level 2: mul, div, mod.
        ('binop3',    (r'[\+\-\$]',)),               # Level 3: add, sub, concat ($).
        ('binop4',    (r'(\<\<)|(\>\>)',)),          # Level 4: shifts.
        ('binop5',    (r'[\<\>](?!\?)=?',)),         # Level 5: relational.
        ('binop6',    (r'[!=]=',)),                  # Level 6: equality.
        ('binop7',    (r'\&(?!\&)',)),               # Level 7: bitwise and.
        ('binop8',    (r'\^(?!\^)',)),               # Level 8: bitwise xor.
        ('binop9',    (r'\|(?!\|)',)),               # Level 9: bitwise or.
        ('binop10',   (r'\&\&',)),                   # Level 10: logical and.
        ('binop11',   (r'\^\^',)),                   # Level 11: logical xor.
        ('binop12',   (r'\|\|',)),                   # Level 12: logical and.
        
        # Aggregates. ----------------------------------------------------------
        ('apply',     (r'=>',)),                     # Application.
        
        # Statements. ----------------------------------------------------------
        ('assign',    (r'=(?!=\>)',)),               # Assignment.
        ('verb_open', (r'\<\?((vhdl)|c)',)),         # Verbatim block open.
        ('verb_close',(r'\?\>',)),                   # Verbatim block close.
        ('semicol',   (r';',)),                      # Statement separator.
        
        # Anything which isn't known by our language. --------------------------
        ('foreign',   (r'.',))
        
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
    
    
    def post_process_tokens(tokens, origins, gen_values, print_cols):
        pptokens = []
        foreign = False
        for token in tokens:
            
            # Use our customized token type.
            token = PPToken(token, origins, print_cols)
            
            # Do some special transformations.
            if token.type == 'name':
                special_names = {
                    'if':     'key_if',
                    'else':   'key_else',
                    'others': 'others',
                    'true':   'lit_true',
                    'false':  'lit_false',
                }
                if token.value in special_names:
                    token.type = special_names[token.value]
            
            elif token.type == 'verb_close':
                foreign = False
            
            elif token.type == 'verb_open':
                foreign = True
            
            elif token.type == 'lit_gen':
                token.type = 'lit_nat'
                c = token.value[1]
                if c not in gen_values:
                    raise CodeError('invalid generator %s on %s.' %
                                    (token.value, token.origin))
                token.value = str(gen_values[c])
            
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
    
    # Basic reference with optional context specifier.
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
    reference = ref_name >> ASTReference
    
    # Handle member operation on references.
    ref_member = (
        tok.name +
        maybe(
            tok.bl_open +
            (tok.lit_nat | tok.others) +
            tok.bl_close
        )
    ) >> ASTMemberName
    
    def member(toks):
        toks = [toks[0]] + toks[1]
        while len(toks) > 1:
            toks[:2] = [ASTMember(toks[0], toks[1][1])]
        return toks[0]
    
    reference = (reference + many(tok.member + ref_member)) >> member
    
    # Handle index/slice operations on references.
    reference = (
        reference +
        maybe(
            tok.sl_open +
            expression +
            maybe(
                tok.comma +
                tok.lit_nat
            ) +
            tok.sl_close
        )
    ) >> (lambda x : x[0] if x[1] is None else ASTSlice(x))
    
    # Generate expressions.
    #  - Handle parentheses.
    subexpression = forward_decl()
    paren = (tok.open + subexpression + tok.close) >> (lambda x : x[1])
    e = literal | reference | paren
    
    #  - Define what to do with sequences of unary and binary operators.
    def unary(toks):
        toks = toks[0] + [toks[1]]
        while len(toks) > 1:
            if isinstance(toks[-2], ASTCastType):
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
    cast = (tok.open + tok.name + tok.close) >> ASTCastType
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
    
    #  - Define subexpression with what we've got now.
    subexpression.define(e)
    
    #  - Handle aggregates.
    others = tok.others >> ASTOthers
    
    aggregate_entry = (
        (ref_member | others) +
        tok.apply + 
        expression
    ) >> ASTAggregateEntry
    
    aggregate = (
        tok.bl_open +
        aggregate_entry +
        many(tok.comma + aggregate_entry) +
        tok.bl_close
    ) >> ASTAggregate
    
    #  - Finally, define an expression as being either an aggregate or a
    #    subexpression.
    expression.define(aggregate | subexpression)
    
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
    verbatim_token = some(lambda tok: not tok.type.startswith('verb_') and not tok.type == 'context')
    verbatim_tokens = oneplus(verbatim_token) >> ASTVerbForeign
    
    # Translated references in a verbatim environment.
    verbatim_ref = (
        (tok.verb_read | tok.verb_lval) +
        skip(many(tok.space)) +
        ref_name
    ) >> ASTVerbRef
    
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
    
    
    def parse(code, gen_values={}):
        """Returns the parse tree for the given code, which must be a list of
        two-tuples containing origin and line, without \n."""
        
        # Unpack the line list.
        origins = [x[0] for x in code]
        code = '\n'.join([x[1] for x in code])
        
        # Tokenize.
        try:
            tokens = post_process_tokens(tokenize(code), origins, gen_values, True)
        except LexerError as e:
            raise CodeError('garbage on input %s.' % fmt_place(e.place, origins, True))
        
        # Parse.
        try:
            return ASTBlock(toplevel.parse(tokens)[0], True)
        except NoParseError as e:
            # funcparserlib's parse error messages are fucking retarded.
            e.msg = e.msg.replace('should have reached <EOF>: ', 'unexpected ')
            raise NoParseError, e, sys.exc_info()[2]
    
    
    def parse_exp(exp, origin, gen_values={}):
        """Returns the parse tree for the given single-line expression."""
        
        # Make sure there's actually no line endings.
        exp = ' '.join(exp.split('\n'))
        
        # Tokenize.
        try:
            tokens = post_process_tokens(tokenize(exp), [origin], gen_values, False)
        except LexerError as e:
            raise CodeError('garbage on input %s.' % fmt_place(e.place, [origin], False))
        
        # Parse.
        try:
            return toplevel_exp.parse(tokens)[0]
        except NoParseError as e:
            # funcparserlib's parse error messages are retarded.
            e.msg = e.msg.replace('should have reached <EOF>: ', 'unexpected ')
            raise NoParseError, e, sys.exc_info()[2]
    
    
    return parse, parse_exp

parse, parse_exp = parser_generate()

