from __future__ import print_function

from sys import argv
from sys import exit
import traps

# Parse command line.
if len(argv) != 3:
    print('Usage: python traps-latex.py <infile.tex> <outfile.tex>')
    exit(2)
infile = argv[1]
outfile = argv[2]

# Parse the input file.
traptable, trapdoc = traps.parse(infile)

# Start writing to the output file.
with open(outfile, 'w') as f:
    f.write('\\newcounter{TrapCounter}\n')
    f.write('\\begin{itemize}\n')
    for doc in trapdoc:
        f.write('\\setcounter{enumi}{' + str(doc['traps'][0] - 1) + '}\n')
        for i, trap_id in enumerate(doc['traps']):
            if i > 0:
                f.write('\\vskip -10 pt\\relax\n')
            trap = traptable[trap_id]
            f.write('\\item \\refstepcounter{TrapCounter} \\label{trap:%s} \\trap{%s} = 0x%02X\n' %
                    (trap['mnemonic'], trap['mnemonic'], trap_id))
        f.write('\\\\[6 pt]\n' + doc['doc'] + '\n\n')
    f.write('\\end{itemize}\n')
