
def srec_checksum(line):
	checked = line[2:-2]
	s = 0
	for i in range(0, len(checked), 2):
		s += int(checked[i:i+2], 16)
	s %= 256
	s = 255 - s
	o = int(line[-2:], 16)
	line = line[:-2] + '%02X' % s
	return (line, o == s)


def handle_line(line, imem, dmem, pmem, data):
	if len(line) < 2:
		return
	if not line.startswith('S'):
		return
	
	# Decode length.
	length = int(line[2:4], 16)
	
	if line[1] in '0789':
		
		# Header/termination record.
		imem.write(line + '\n')
		dmem.write(line + '\n')
		pmem.write(line + '\n')
		
	elif line[1] in '123':
		
		# Data record.
		
		# Decode byte count, address and data.
		w = (int(line[1])+1)*2
		byte_count = length - (w/2 + 1);
		addr = line[4:4+w]
		addr = int(addr, 16)
		sdata = line[4+w:-2]
		
		# Determine the memory which this line belongs to and transform the address.
		if addr < 0x10000000:
			mem = imem
			data = data['i']
		elif addr < 0x80000000:
			mem = dmem
			data = data['d']
			addr -= 0x10000000
		else:
			mem = pmem
			data = data['p']
			addr -= 0x80000000
		
		# Reconstruct the S-record line with the new address.
		line = 'S3%02X%08X%s00' % (byte_count + 5, addr, sdata)
		line, dummy = srec_checksum(line)
		
		# Append the line to the appropriate output file.
		mem.write(line + '\n')
		
		# Store the data for img writing.
		for i in range(byte_count):
			d = int(sdata[i*2:i*2+2], 16)
			data[addr + i] = d

def write_bin(fn, data):
	print('split-mem.py: writing %s...' % fn)
	with open(fn, 'wb') as f:
		addr = 0
		while data:
			f.write(bytearray([data.pop(addr, 0)]))
			addr += 1

import sys
if len(sys.argv) != 2:
	print('Usage: python split-idmem.py <input.srec>')
	sys.exit(2)

mem_fn = sys.argv[1]

parts = mem_fn.rsplit('.', 1)
imem_srec_fn = parts[0] + '.imem.' + parts[1]
dmem_srec_fn = parts[0] + '.dmem.' + parts[1]
pmem_srec_fn = parts[0] + '.pmem.' + parts[1]
imem_bin_fn = parts[0] + '.bin'
dmem_bin_fn = parts[0] + '_data.bin'
pmem_bin_fn = parts[0] + '_param.bin'

data = {
	'i': {},
	'd': {},
	'p': {}
}

print('split-mem.py: reading %s and writing %s, %s and %s...' % (mem_fn, imem_srec_fn, dmem_srec_fn, pmem_srec_fn))
with open(mem_fn, 'r') as mem:
	with open(imem_srec_fn, 'w') as imem:
		with open(dmem_srec_fn, 'w') as dmem:
			with open(pmem_srec_fn, 'w') as pmem:
				for line in mem:
					handle_line(line.strip(), imem, dmem, pmem, data)

write_bin(imem_bin_fn, data['i'])
write_bin(dmem_bin_fn, data['d'])
write_bin(pmem_bin_fn, data['p'])
