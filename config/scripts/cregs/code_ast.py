"""Abstract syntax tree class."""

class AST(object):
    
    def __len__(self):
        return len(self.children)
    
    def __getitem__(self, key):
        if type(key) is int:
            return self.children[key]
        return self.annot[key]
        
    def __setitem__(self, key, value):
        if type(key) is int:
            self.children[key] = value
        self.annot[key] = value
        
    def __delitem__(self, key):
        if type(key) is int:
            raise Exception('Cannot delete child nodes.')
        del self.annot[key]
        
    def __iter__(self):
        return self.children.__iter__()
        
    def __contains__(self, key):
        if type(key) is int:
            return key < len(self.children)
        return key in self.annot
    
    def __getattr__(self, key):
        return self.annot[key]
    
    def __str__(self):
        return self.value
    
    def replace(self, new):
        """Replaces this AST node with a new version. new may be a single
        ASTNode or a list of ASTNodes."""
        if self.parent is None:
            raise Exception('Cannot replace root node.')
        if type(new) is not list:
            new = [new]
        self.parent.children[self.parent_idx:self.parent_idx+1] = new
    
    @property
    def origin(self):
        """Returns the origin of this node in the code."""
        if self._orig is None and len(self.children) > 0:
            return self.children[0].origin
        if self._orig is None:
            return '<internal>'
        return self._orig
    
    def pp_ast(self):
        """Pretty-prints the AST (returns as a string)."""
        return '\n'.join(self._pp_ast())
    
    def _pp_ast(self):
        """Pretty-prints the AST (returns as a list of lines)."""
        if len(self.children) == 0:
            lines = ['%s: %s' % (self.node_type, repr(self.value))]
        else:
            lines = ['%s' % self.node_type]
        tree = []
        for key in self.annot:
            val = self.annot[key]
            tree.append(['%s --> %s' % (key, repr(val))])
        for child in self.children:
            tree.append(child._pp_ast())
        for sublines in tree[:-1]:
            first = True
            for subline in sublines:
                lines.append((' |--' if first else ' |  ') + subline)
                first = False
        for sublines in tree[-1:]:
            first = True
            for subline in sublines:
                lines.append((" '--" if first else '    ') + subline)
                first = False
        return lines


class ASTLeaf(AST):

    def __init__(self, type, value, origin):
        self.node_type = type
        self.children = []
        self.value = value
        self._orig = origin
        self.annot = {}
        self.parent = None
        self.parent_idx = None


class ASTNode(AST):
    
    def __init__(self, type, children):
        for i, child in enumerate(children):
            if child.parent is not None:
                raise Exception('AST node already has a parent.')
            child.parent = self
            child.parent_idx = i
        
        self.node_type = type
        self.children = children
        self.value = None
        self._orig = None
        self.annot = {}
        self.parent = None
        self.parent_idx = None

