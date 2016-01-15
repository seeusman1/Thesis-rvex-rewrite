import re
from type_sys import *
from back_end import *
from excepts import *
from transform import *
import copy

class Object(object):
    
    def __init__(self, owner, name, atyp, origin='<internal>', initspec=None):
        """Creates an Object. An object is an input, output, register, variable
        or constant made available to the user."""
        
        if name.startswith('_') and owner is not None:
            name = owner + name
        
        self.owner = owner
        self.name = name
        self.atyp = atyp
        self.origin = origin
        self.initspec = initspec
        
        # Whether this object has ever been used.
        self.used = False
        
        # Whether this object has ever been assigned.
        self.assigned = False
                
    def __str__(self):
        return '%s %s' % (self.atyp, self.name)
    
    __repr__ = __str__
    

class Environment:
    
    def __init__(self):
        self.objects = {}
        self.object_order = []
        self.implicit_ctxt = None
        self.user = ''
        self.access_checks = []
    
    def copy(self):
        e = Environment()
        e.objects = self.objects.copy()
        e.object_order = copy.copy(self.object_order)
        e.implicit_ctxt = self.implicit_ctxt
        e.user = self.user
        e.access_checks = copy.copy(self.access_checks)
        return e
    
    def with_access_check(self, fun):
        e = self.copy()
        e.access_checks.append(fun)
        return e
    
    def declare(self, ob):
        """Adds an object to the environment. Raises a CodeError if the name is
        already in use or if the name is invalid."""
        
        # Check whether the name is valid.
        if re.match(r'[a-zA-Z0-9][a-zA-Z0-9_]*$', ob.name) is None:
            raise CodeError('Illegal object name \'%s\', declared after line %s.' %
                            (ob.name, ob.origin))
        
        # Make sure the name is not already in use.
        if ob.name.lower() in self.objects:
            conflict = self.objects[ob.name.lower()]
            raise CodeError(('Name %s, declared after line %s, is already in use. ' +
                            'Conflicts with %s, declared after line %s.') %
                            (ob.name, ob.origin, conflict, conflict.origin))
        
        # Add the object. Note that we use lower() to make names
        # case-insensitive. This is necessary to be compatible with VHDL.
        self.objects[ob.name.lower()] = ob
        self.object_order.append(ob)
    
    def set_implicit_ctxt(self, ctxt):
        """Sets the context which is implicitely accessed by per-context
        generated code. Typically this will be the loop iteration variable
        name, or None for globol code."""
        self.implicit_ctxt = ctxt
    
    def set_user(self, user):
        """Sets the current user, i.e. 'cr_<reg>_<field>' or ''."""
        self.user = user
    
    def lookup(self, name):
        """Looks up a name. name is of the format [<owner>]_<name>[@<ctxt>].
        If <owner> is not specified, user is used. If <ctxt> is not specified,
        implicit_ctxt is used. If <ctxt> IS specified, but the lookup does not
        resolve to a context-specific object, a CodeError is raised. A CodeError
        is also raised if the lookup failed entirely, or if <owner> != user for
        a local object.
        
        Returns a two-tuple: (object, ctxt). ctxt is always None for globals
        and always an int or whatever was specified by set_implicit_ctxt() for
        context-specific objects."""
        
        # Extract the explicit context from the name.
        name = name.split('@', 1)
        ctxt = None
        if len(name) == 2:
            ctxt = name[1]
        name = name[0]
        
        # If name starts with an underscore, prefix user (abbreviated syntactic
        # sugar for locals).
        if name.startswith('_'):
            name = self.user + name
        
        # Look up the variable.
        if name.lower() not in self.objects:
            raise CodeError('undefined object \'%s\'.' % name)
        ob = self.objects[name.lower()]
        
        # Raise an error if this is a local and we're not the owner.
        if ob.atyp.is_local() and self.user.lower() != ob.owner.lower():
            raise CodeError('cannot access local \'%s\' from %s.' %
                            (ob.name, self.user))
        
        # Raise an error if a context is explicitly specified if this is a
        # global object.
        cxspec = ob.atyp.typ.exists_per_context()
        if not cxspec and ctxt is not None:
            raise CodeError('cannot apply @ context selection syntax to ' +
                            'global \'%s\'.' % ob.name)
        if cxspec and ctxt is None:
            ctxt = self.implicit_ctxt
            if ctxt is None:
                raise CodeError('cannot access context-specific object ' +
                                '\'%s\' without context.' % ob.name)
        
        # Run additional access checks.
        for fun in self.access_checks:
            if not fun(ob):
                raise CodeError('object \'%s\' may not be used here.' %
                                ob.name)
        
        # Lookup successful.
        return (ob, ctxt)

    def __repr__(self):
        return '\n'.join([str(self.objects[key]) for key in self.objects])

