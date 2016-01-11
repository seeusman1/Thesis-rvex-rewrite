"""This module provides some exception utilities."""

import sys

class CodeError(Exception):
    
    def __init__(self, msg):
        self.msg = msg
    
    def fmt(self, fmt):
        self.msg = fmt % self.msg
    
    def __str__(self):
        return self.msg
    

def except_prefix(e, prefix):
    if not isinstance(e, CodeError):
        e = CodeError(str(e))
    e.fmt('%s%%s' % prefix)
    raise CodeError, e, sys.exc_info()[2]



