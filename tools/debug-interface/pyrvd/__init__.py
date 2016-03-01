"""This module exports Core and Rvd classes.
Example usage:
#import the package assuming you have run source debug
import pyrvd as rvd
#Create a core object with Rvd connection object, and base address.
c = rvd.Core(rvd.Rvd(), 0xd0000000)
#use the core object to access contexts registers:
c.context[0].CYC
"""

from .core_map import Core
from .rvd import Rvd
