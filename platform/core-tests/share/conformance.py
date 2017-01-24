import sys
import re
import time

re_make = re.compile(r"make")
re_make_error = re.compile(r"make.*Error")
re_vsim = re.compile(r"START_SIM")
re_error = re.compile(r"# \*\* Error:")
re_running = re.compile(r"# \*\* Note: Running test case file (.*)...$")
re_success = re.compile(r"# \*\* Note: Reached end of test case (.*): SUCCESS.$")
re_failure = re.compile(r"# \*\* Warning: (.*) line (.*): FAILURE.$")
re_abort = re.compile(r"# \*\* Warning: (.*) line (.*): ABORT ")

curfile = None
error = False

checkpoint = [time.time()]

def time_str():
	now = time.time()
	t = now - checkpoint[0]
	checkpoint[0] = now
	if t < 60:
		return '%5.2fs' % t
	elif t < 3600:
		t = int(t)
		return '%2dm%02ds' % (t // 60, t % 60)
	else:
		t = int(t) // 60
		return '%2dh%02dm' % (t // 60, t % 60)


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
		print('OK   %-6s Compile & elaborate VHDL' % time_str())
		continue
	
	if re.match(re_error, s):
		if not error:
			print('FAIL %-6s Compile & elaborate VHDL' % time_str())
		print('\t' + s)
		error = True
		continue
	
	m = re.match(re_running, s)
	if m:
		if curfile:
			print('ERROR: test case file %s was started, but no result was detected?' % curfile)
			error = True
		curfile = m.group(1)
		continue
	
	m = re.match(re_success, s)
	if m and curfile:
		print('OK   %-6s %s' % (time_str(), m.group(1)))
		curfile = None
		continue
	
	m = re.match(re_failure, s)
	if m and curfile:
		print('FAIL %-6s %s' % (time_str(), m.group(1)))
		print('\tFile: %s' % curfile)
		print('\tLine number: %s' % m.group(2))
		error = True
		curfile = None
		continue
	
	m = re.match(re_abort, s)
	if m and curfile:
		#print('WARN ------ %s' % m.group(1))
		#print('\tTest case inconclusive.')
		#print('\tFile: %s' % curfile)
		curfile = None
		continue

if error:
	#print('CONFORMANCE TEST FAILED.')
	exit(1)
#else:
	#print('conformance test passed.')

