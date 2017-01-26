
import sys
import subprocess
import time
import os

if len(sys.argv) != 3:
    print('Usage: python3 conform.py <test-name> <shell-command>')
    sys.exit(2)

name = sys.argv[1]
cmd = sys.argv[2]
start = time.time()

try:
    output = subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True)
    stop = time.time()
    lines = output.decode('latin-1').split('\n')
    output = []
    seen_ok = False
    for line in lines:
        if line.startswith('OK   '):
            seen_ok = True
        elif not line.startswith('\t') and seen_ok:
            seen_ok = False
            output.append('\t')
        if seen_ok:
            output.append('\t' + line)
    output = '\n'.join(output)
    msg = 'OK'
    ok = True
except subprocess.CalledProcessError as e:
    stop = time.time()
    msg = 'FAIL'
    output = '\t' + e.output.decode('latin-1').replace('\n', '\n\t')
    ok = False

t = stop - start
if t < 60:
    print('%-4s %5.2fs %s' % (msg, t, name))
elif t < 3600:
    t = int(t)
    print('%-4s %2dm%02ds %s' % (msg, t // 60, t % 60, name))
else:
    t = int(t) // 60
    print('%-4s %2dh%02dm %s' % (msg, t // 60, t % 60, name))

if ok:
    if output:
        print(output)
    sys.exit(0)
else:
    print('\tWorking directory: %s' % os.getcwd())
    print('\tCommand: %s' % cmd)
    print('\tOutput:')
    print(output)
    sys.exit(1)

