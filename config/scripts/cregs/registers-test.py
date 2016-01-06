from __future__ import print_function

from sys import argv
from sys import exit
import registers
import pprint
import common.bitfields
bitfields = common.bitfields

# Parse command line.
if len(argv) != 2:
    print('Usage: python registers-latex.py <indir>')
    exit(2)
indir = argv[1]

# Parse the input file.
pprint.pprint(registers.parse(indir))
