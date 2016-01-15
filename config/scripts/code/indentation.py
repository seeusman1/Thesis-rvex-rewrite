
import re
from funcparserlib.lexer import *

def indentify(code, lang):
    """Attempts to apply decent indentation levels to code without
    indentation."""
    code = code.split('\n')
    
    if lang == 'vhdl':
        style = '  '
        rules = vhdl_indentation_rules
    elif lang == 'c':
        style = '    '
        rules = c_indentation_rules
    else:
        raise Exception()
    
    plvl = 0
    lvl = [0]
    for i in range(len(code)):
        
        # Look for bracket open/close and find the lowest bracket level.
        lowest, plvl = rules(code[i], plvl)
        
        # Figure out the right indentation level for this bracket level.
        while lowest < lvl[-1]:
            del lvl[-1]
        if lowest > lvl[-1]:
            lvl.append(lowest)
        ilvl = len(lvl) - 1
        
        # Apply the indentation level and remove trailing spaces while we're at
        # it.
        code[i] = style*ilvl + code[i].strip()
    
    return '\n'.join(code)


def rule_gen(tokspec):
    
    # Create the tokenizer.
    tokenize = make_tokenizer(tokspec)
    
    def rules(line, plvl):
        lowest = plvl
        for token in tokenize(line):
            val = token.type
            plvl += val[0]
            lowest = min(lowest, plvl + val[1])
        if plvl < 0:
            plvl = 0
        if lowest < 0:
            lowest = 0
        return (lowest, plvl)
    
    return rules

vhdl_indentation_rules = rule_gen([
    
    # Tokens which should increase indentation level.
    ((1, 0),  (r'\(',)),
    ((1, 0),  (r'if(?!\w)', re.IGNORECASE)),
    
    # Tokens which should decrease indentation level.
    ((-1, 0), (r'\)',)),
    ((-1, 0), (r'end(?!\w)', re.IGNORECASE)),
    
    # Tokens which should decrease indentation level only for themselves.
    ((0, -1), (r'then(?!\w)', re.IGNORECASE)),
    ((0, -1), (r'else(?!\w)', re.IGNORECASE)),
    
    # Stuff which shouldn't change indentation level.
    ((0, 0),  (r'--@user--(.(?!--@generated--))*--@generated--', re.MULTILINE + re.DOTALL)),
    ((0, 0),  (r'--.*(?=\n)', re.MULTILINE)),
    ((0, 0),  (r'"[^"]*"',)),
    
    # Stuff to make parsing a little faster.
    ((0, 0),  (r'\w+',)),
    ((0, 0),  (r'\s+', re.MULTILINE)),
    ((0, 0),  (r'.', re.DOTALL)),
    
])

c_indentation_rules = rule_gen([
    
    # Tokens which should increase indentation level.
    ((1, 0),  (r'[\(\[\{]',)),
    
    # Tokens which should decrease indentation level.
    ((-1, 0), (r'[\)\]\}]',)),
    
    # Stuff which shouldn't change indentation level.
    ((0, 0),  (r'/\*@user\*/(.(?!/\*@generated\*/))*/\*@generated\*/', re.MULTILINE + re.DOTALL)),
    ((0, 0),  (r'//.*(?=\n)', re.MULTILINE)),
    ((0, 0),  (r'/\*((?!\*/).)*\*/', re.MULTILINE + re.DOTALL)),
    
    # Stuff to make parsing a little faster.
    ((0, 0),  (r'\w+',)),
    ((0, 0),  (r'\s+', re.MULTILINE)),
    ((0, 0),  (r'.', re.DOTALL)),
    
])

del rule_gen