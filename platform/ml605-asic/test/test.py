
from pyrvd import Rvd
import os
import math
r = Rvd()


def memtest():
	up = bytearray(os.urandom(4096))
	r.write(0, up)
	code, addr, count, dl = r.read(0, 4096)
	if up != dl:
		print("Uploaded:")
		print(repr(up))
		print("Downloaded:")
		print(repr(dl))
		print("Memtest failed.")
		exit()


#memtest()





class Mmcm:
	
	def __init__(self, rvd, address):
		self.rvd = rvd
		self.address = address
	
	def __getitem__(self, index):
		return self.rvd.readInt(self.address + index*4, 4)
	
	def __setitem__(self, index, value):
		self.rvd.writeInt(self.address + index*4, 4, value)
	
	
	def start(self):
		"""(Re)starts the MMCM."""
		self[0] = 0
	
	def reset(self):
		"""Stops/resets the MMCM."""
		self[0] = 1
	
	def pdown(self):
		"""Powers down the MMCM."""
		self[0] = 3
	
	def resetting(self):
		"""Returns whether the MMCM is currently held in reset. The MMCM cannot
		be programmed if not."""
		return (self[0] & (1 << 0)) != 0
	
	def locked(self):
		"""Returns whether the MMCM is locked."""
		return (self[0] & (1 << 3)) != 0
	
	def refclk(self):
		"""Returns the reference clock frequency in MHz."""
		f = 1000000.0 / (self[0] >> 8)
		self.refclk = lambda: f
		return f
	
	
	def cfg_clk(self, index, divide, phase=0.0):
		"""Configures the given clock output to divide the clock by the given
		integer division ratio with the given phase offset (in degrees).
		Returns the actual phase."""
		
		divide = int(divide)
		if divide < 1 or divide > 64:
			raise RuntimeError('clock division out of range 1-64: {}'.format(divide))
		
		# Rotate phase to the 0..360 degrees range.
		phase -= math.floor(phase / 360.0) * 360.0
		
		# Convert the phase angle to VCO clock cycles.
		phase *= divide / 360.0
		
		# There are 8 VCO phase taps. Select one of them.
		phase_mux = int(round(phase * 8))
		
		# Calculate the actual phase for the return value.
		phase = (phase_mux * 45.0) / divide;
		
		# Extract delay time and phase mux.
		delay_time = phase_mux // 8
		phase_mux = phase_mux % 8
		
		# Determine high time, low time, edge, and no_count.
		if divide == 1:
			no_count = 1
			low_time = 1
			high_time = 1
			edge = 0
		elif divide % 2 == 1:
			no_count = 0
			low_time = divide // 2 + 1
			high_time = divide // 2
			edge = 1
		else:
			no_count = 0
			low_time = divide // 2
			high_time = divide // 2
			edge = 0
		
		# Determine the register index.
		indices = {
			0: 0x08,
			1: 0x0A,
			2: 0x0C,
			3: 0x0E,
			4: 0x10,
			5: 0x06,
			6: 0x12,
			'fb': 0x14
		}
		if index not in indices:
			raise RuntimeError('cannot configure clock {}: no such clock'.format(index))
		index = indices[index]
		
		# Update ClkReg1.
		reg = self[index] & 0b0001000000000000
		reg |= phase_mux << 13
		reg |= high_time << 6
		reg |= low_time << 0
		self[index] = reg
		
		# Update ClkReg2.
		reg = self[index+1] & 0b1111110000000000
		reg |= edge << 7
		reg |= no_count << 6
		reg |= delay_time << 0
		self[index+1] = reg
		
		# Return the actual phase.
		return phase
	
	#def cfg_vco


m = Mmcm(r, 0x80000000)
m.reset()
m.cfg_clk(0, 14)
m.start()


memtest()


