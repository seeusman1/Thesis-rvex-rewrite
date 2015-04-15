import sys
import re

re_make = re.compile(r"make")
re_make_error = re.compile(r"make.*Error")
re_vsim = re.compile(r"vsim")
re_error = re.compile(r"# \*\* Error:")
re_running = re.compile(r"# \*\* Note: Running test case file (.*)...$")
re_success = re.compile(r"# \*\* Note: Reached end of test case (.*): SUCCESS.$")
re_failure = re.compile(r"# \*\* Warning: (.*) line (.*): FAILURE.$")
re_abort = re.compile(r"# \*\* Warning: (.*) line (.*): ABORT ")

curfile = None
error = False

while True:
	s = sys.stdin.readline()
	if s == '':
		break
	s = s[:-1]
	
	if re.match(re_make, s):
		print(s)
		if re.match(re_make_error, s):
			error = True
		continue
	
	if re.match(re_vsim, s):
		print('Starting simulation...')
		continue
	
	if re.match(re_error, s):
		print('ERROR:   ' + s)
		error = True
		continue
	
	m = re.match(re_running, s)
	if m:
		if curfile:
			print('ERROR:   Test case file %s was started, but no result was detected?' % curfile)
			error = True
		curfile = m.group(1)
		continue
	
	m = re.match(re_success, s)
	if m and curfile:
		print('SUCCESS: %s (%s)' % (m.group(1), curfile))
		curfile = None
		continue
	
	m = re.match(re_failure, s)
	if m and curfile:
		print('ERROR:   test case %s (%s): FAILED at line %s.' % (m.group(1), curfile, m.group(2)))
		error = True
		curfile = None
		continue
	
	m = re.match(re_abort, s)
	if m and curfile:
		print('WARNING: %s (%s) was inconclusive.' % (m.group(1), curfile))
		curfile = None
		continue

if error:
	print('CONFORMANCE TEST FAILED.')
	exit(1)
else:
	print('conformance test passed.')

