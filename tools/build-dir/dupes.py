
from os.path import relpath, dirname

with open('dupes', 'r') as f:
    dupes = f.read()

dupes = [d.strip().split('\n') for d in dupes.strip().split('\n\n')]

commands = ['#!/bin/bash']

for main, *copies in dupes:
    for copy in copies:
        commands.append('ln -sf %s %s' % (relpath(main, dirname(copy)), copy))

with open('dupes-fix', 'w') as f:
    f.write(''.join([c + '\n' for c in commands]))

