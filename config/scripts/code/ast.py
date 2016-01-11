"""This module defines the abstract syntax tree class, which is used for the
intermediate representation."""

from excepts import *

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
        return str(self.value)
    
    @property
    def origin(self):
        """Returns the origin of this node in the code."""
        if self._orig is None and len(self.children) > 0:
            return self.children[0].origin
        if self._orig is None:
            return '<internal>'
        return self._orig
    
    def apply_dfs(self, fun):
        """Applies a function of type x -> y to each node in the tree,
        depth-first. If the function returns None, the tree is not modified. If
        it returns a list of nodes, the node which it was applied to is replaced
        with the returned list. This function returns the new version of the
        node it was called upon, or the old version if it was not replaced."""
        self._apply_dfs(fun)
        ret = fun(self)
        if ret is None:
            return self
        elif len(ret) == 1:
            return ret[0]
        else:
            return ret
        
    def _apply_dfs(self, fun):
        children = []
        for child in self.children:
            child._apply_dfs(fun)
            ret = fun(child)
            if ret is None:
                children.append(child)
            else:
                children += ret
        for i, child in enumerate(children):
            child.parent = self
            child.parent_idx = i
        self.children = children
        
    def apply_xform_dfs(self, xform):
        return self.apply_dfs(xform.proxy)
    
    
    def generate(self, key):
        """Generates code by applying str.format() to the attribute specified
        by key, using the generate() output from subnodes as parameters."""
        return self[key].format(*[x.generate(key) for x in self])
    
    
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
            if hasattr(child, '_pp_ast'):
                tree.append(child._pp_ast())
            else:
                tree.append(['ERROR: ' + repr(child)])
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
            child.parent = self
            child.parent_idx = i
        
        self.node_type = type
        self.children = children
        self.value = None
        self._orig = None
        self.annot = {}
        self.parent = None
        self.parent_idx = None


class Transformation(object):
    
    def proxy(self, node):
        try:
            fun = getattr(self, node.node_type)
        except AttributeError:
            return None
        try:
            return fun(node)
        except Exception as e:
            except_prefix(e, 'error on %s: ' % node.origin)
    
