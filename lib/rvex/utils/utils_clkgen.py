
import math

class Mmcm:
	"""This class represents a reconfigurable MMCM instantiated from
	utils_clkgen_*.vhd, accessed using pyrvd. It can automatically configure
	the MMCM based on the desired input frequencies."""
	
	def __init__(self, rvd, address):
		self.rvd = rvd
		self.address = address
		self.request = {}
		self.request_elaborated = False
	
	def __getitem__(self, index):
		if index < 0 or index > 127:
			raise RuntimeError('register index out of range (0-127): {}'.format(index))
		return self.rvd.readInt(self.address + index*4, 4)
	
	def __setitem__(self, index, value):
		if index < 0 or index > 127:
			raise RuntimeError('register index out of range (0-127): {}'.format(index))
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
		return (self[0] & (1 << 2)) != 0
	
	def bandwidth(self):
		"""Returns the MMCM bandwidth setting."""
		return 'low' if (self[0] & (1 << 5)) != 0 else 'high'
	
	def refclk(self):
		"""Returns the reference clock frequency in MHz."""
		f = 1000000.0 / (self[0] >> 8)
		self.refclk = lambda: f
		return f
	
	def request_clear(self):
		"""Clears any previously set request_clk() commands."""
		self.request = {}
		self.request_elaborated = False
	
	def request_clk(self, index, frequency, phase=0.0, weight=1.0):
		"""Requests an output clock. frequency is specified in MHz. phase is
		specified in degrees. weight specifies the importance of this clock
		frequency w.r.t. the other clocks when a VCO compromise is needed."""
		
		# Check the index.
		index = int(index)
		if index < 0 or index > 6:
			raise RuntimeError('cannot configure clock {}: no such clock'.format(index))
		
		# Add the request to the dictionary.
		self.request[index] = {
			'req_freq': frequency,
			'req_phase': phase,
			'weight': weight
		}
		self.request_elaborated = False
	
	def request_get(self):
		"""Returns the currently requested configuration and best possible
		configuration as a dict (key=output clock index or 'vco') of dicts. The
		keys in the inner dicts for output clocks are:
		 - req_freq [MHz].
		 - req_phase [degrees].
		 - weight.
		 - act_freq [MHz].
		 - act_phase [degrees].
		 - divide
		 - delay_time
		 - phase_mux
		The keys for the 'vco' dict are:
		 - ref_freq
		 - ref_divide
		 - fb_divide
		 - vco_freq
		"""
		self._request_elaborate()
		return self.request
	
	def request_print(self):
		"""Print the currently requested configuration and best possible
		configuration."""
		r = self.request_get()
		print('')
		print('Reference clock:      %4.3f MHz' % r['vco']['ref_freq'])
		print('VCO clock (600-1200): %4.3f MHz' % r['vco']['vco_freq'])
		for i in range(7):
			if i in r:
				c = r[i]
				print('')
				print('Output clock %d (weight %f):' % (i, c['weight']))
				print(' - Requested specs:   %4.3f MHz %3.1f deg.' % (c['req_freq'], c['req_phase']))
				print(' - Actual specs:      %4.3f MHz %3.1f deg.' % (c['act_freq'], c['act_phase']))
		print('')
	
	def _request_elaborate(self):
		"""Determine the best VCO frequency and configuration for the current
		requests."""
		
		# Don't need to elaborate if we already elaborated.
		if self.request_elaborated:
			return
		
		# Determine the best VCO configuration.
		f_ref = self.refclk()
		min_cost = float('inf')
		best_ref_div = -1
		best_fb_div = -1
		for ref_div in range(1, 80+1):
			f_div = f_ref / ref_div
			if f_div < 10.0:
				continue
			for fb_div in range(5, 64+1):
				f_vco = f_div * fb_div
				if f_vco < 600:
					continue
				if f_vco > 1200:
					continue
				
				# Determine the cost of this VCO frequency option.
				cost = 0
				for i in range(7):
					if i in self.request:
						f_req = self.request[i]['req_freq']
						divide = round(f_vco / f_req)
						if divide < 1:
							divide = 1
						elif divide > 126:
							divide = 126
						f_act = f_vco / divide
						c = (math.log(f_act) - math.log(f_req)) ** 2
						c *= self.request[i]['weight']
						cost += c
				
				# If this configuration has a lower cost than any other, use
				# this one.
				if cost < min_cost:
					min_cost = cost
					best_ref_div = ref_div
					best_fb_div = fb_div
		
		# Store the VCO configuration.
		f_vco = (f_ref / best_ref_div) * best_fb_div
		self.request['vco'] = {
			'ref_freq': f_ref,
			'ref_divide': best_ref_div,
			'fb_divide': best_fb_div,
			'vco_freq': f_vco
		}
		
		# Determine the output clock configurations.
		for i in range(7):
			if i in self.request:
				
				# Determine divider and actual frequency.
				f_req = self.request[i]['req_freq']
				divide = round(f_vco / f_req)
				if divide < 1:
					divide = 1
				elif divide > 126:
					divide = 126
				f_act = f_vco / divide
				self.request[i]['divide'] = divide
				self.request[i]['act_freq'] = f_act
				
				# Determine phase configuration.
				phase = self.request[i]['req_phase']
				
				# Rotate phase to the 0..360 degrees range.
				phase -= math.floor(phase / 360.0) * 360.0
				
				# Convert the phase angle to VCO clock cycles.
				phase *= divide / 360.0
				
				# There are 8 VCO phase taps. Select one of them.
				phase_cfg = int(round(phase * 8))
				
				# Calculate the actual phase for the return value.
				self.request[i]['act_phase'] = (phase_cfg * 45.0) / divide
				
				# Extract delay time and phase mux.
				self.request[i]['delay_time'] = phase_cfg // 8
				self.request[i]['phase_mux'] = phase_cfg % 8
		
		# Finished elaborating.
		self.request_elaborated = True
	
	def reconfigure(self):
		"""Configures the MMCM with the requested configuration."""
		
		# Elaborate the configuration if this hasn't been done already.
		self._request_elaborate()
		
		# Ensure the requested clocks aren't unrealistically high.
		for i in range(7):
			if i in self.request:
				if self.request[i]['act_freq'] > 300.0:
					raise RuntimeError('cowardly refusing to set clock {} to {} (max 300 MHz)'.format(
						i, self.request[i]['act_freq']))
		
		# Assert MMCM reset.
		self.reset()
		
		# Set the power bits.
		self[0x28] = 0xFFFF
		
		# Configure the VCO.
		self._cfg_vco(self.request['vco']['ref_divide'], self.request['vco']['fb_divide'])
		
		# Configure the output clocks.
		for i in range(7):
			if i in self.request:
				c = self.request[i]
				self._cfg_clk(i, c['divide'], c['delay_time'], c['phase_mux'])
			else:
				self._cfg_clk(i, 64, 0, 0)
		
		# Restart the VCO.
		self.start()
	
	def _div_cfg(self, divide):
		"""Determines clock divider configuration parameters for a given
		divider value."""
		divide = int(divide)
		if divide < 1 or divide > 126:
			raise RuntimeError('clock division out of range 1-126: {}'.format(divide))
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
		return low_time, high_time, no_count, edge
	
	def _cfg_clk(self, index, divide, delay_time=0, phase_mux=0):
		"""Configures the given clock output."""
		
		# Check the configuration parameters.
		divide = int(divide)
		if divide < 1 or divide > 126:
			raise RuntimeError('clock division out of range 1-126: {}'.format(divide))
		
		delay_time = int(delay_time)
		if delay_time < 0 or delay_time > 63:
			raise RuntimeError('delay time out of range 0-63: {}'.format(delay_time))
		
		phase_mux = int(phase_mux)
		if phase_mux < 0 or phase_mux > 7:
			raise RuntimeError('phase mux out of range 0-7: {}'.format(phase_mux))
		
		# Determine high time, low time, edge, and no_count.
		low_time, high_time, no_count, edge = self._div_cfg(divide)
		
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
	
	def _cfg_vco(self, ref_divide, fb_divide):
		
		# Check limits.
		ref_divide = int(ref_divide)
		if ref_divide < 1 or ref_divide > 80:
			raise RuntimeError('cannot configure VCO: ref clk divide out of range 1-80: {}'.format(ref_divide))
		fb_divide = int(fb_divide)
		if fb_divide < 5 or fb_divide > 64:
			raise RuntimeError('cannot configure VCO: feedback clk divide out of range 5-64: {}'.format(fb_divide))
		
		# Lookup table for lock and filter registers. Extracted from the
		# Verilog reference design for MMCM reconfiguration.
		data = { # lock, filter low, filter high/optimized
			 1: (0b0011000110111110100011111010010000000001, 0b0001011111, 0b0101111100),
			 2: (0b0011000110111110100011111010010000000001, 0b0001010111, 0b1111111100),
			 3: (0b0100001000111110100011111010010000000001, 0b0001111011, 0b1111110100),
			 4: (0b0101101011111110100011111010010000000001, 0b0001011011, 0b1111100100),
			 5: (0b0111001110111110100011111010010000000001, 0b0001101011, 0b1111111000),
			 6: (0b1000110001111110100011111010010000000001, 0b0001110011, 0b1111000100),
			 7: (0b1001110011111110100011111010010000000001, 0b0001110011, 0b1111000100),
			 8: (0b1011010110111110100011111010010000000001, 0b0001110011, 0b1111011000),
			 9: (0b1100111001111110100011111010010000000001, 0b0001110011, 0b1111101000),
			10: (0b1110011100111110100011111010010000000001, 0b0001001011, 0b1111101000),
			11: (0b1111111111111000010011111010010000000001, 0b0001001011, 0b1111101000),
			12: (0b1111111111110011100111111010010000000001, 0b0001001011, 0b1110110000),
			13: (0b1111111111101110111011111010010000000001, 0b0010110011, 0b1111110000),
			14: (0b1111111111101011110011111010010000000001, 0b0001010011, 0b1111110000),
			15: (0b1111111111101000101011111010010000000001, 0b0001010011, 0b1111110000),
			16: (0b1111111111100111000111111010010000000001, 0b0001010011, 0b1111110000),
			17: (0b1111111111100011111111111010010000000001, 0b0001010011, 0b1111110000),
			18: (0b1111111111100010011011111010010000000001, 0b0001010011, 0b1111110000),
			19: (0b1111111111100000110111111010010000000001, 0b0001010011, 0b1111110000),
			20: (0b1111111111011111010011111010010000000001, 0b0001010011, 0b1111110000),
			21: (0b1111111111011101101111111010010000000001, 0b0001010011, 0b1110110000),
			22: (0b1111111111011100001011111010010000000001, 0b0001010011, 0b1110110000),
			23: (0b1111111111011010100111111010010000000001, 0b0001010011, 0b1110110000),
			24: (0b1111111111011001000011111010010000000001, 0b0001100011, 0b1111101000),
			25: (0b1111111111011001000011111010010000000001, 0b0001100011, 0b1101110000),
			26: (0b1111111111010111011111111010010000000001, 0b0001100011, 0b1100001000),
			27: (0b1111111111010101111011111010010000000001, 0b0001100011, 0b1101110000),
			28: (0b1111111111010101111011111010010000000001, 0b0001100011, 0b1101110000),
			29: (0b1111111111010100010111111010010000000001, 0b0001100011, 0b1111101000),
			30: (0b1111111111010100010111111010010000000001, 0b0001100011, 0b1111101000),
			31: (0b1111111111010010110011111010010000000001, 0b0001100011, 0b1111101000),
			32: (0b1111111111010010110011111010010000000001, 0b0001100011, 0b0111001000),
			33: (0b1111111111010010110011111010010000000001, 0b0001100011, 0b1100110000),
			34: (0b1111111111010001001111111010010000000001, 0b0001100011, 0b1100110000),
			35: (0b1111111111010001001111111010010000000001, 0b0001100011, 0b1110101000),
			36: (0b1111111111010001001111111010010000000001, 0b0001100011, 0b0110001000),
			37: (0b1111111111001111101011111010010000000001, 0b0001100011, 0b0110001000),
			38: (0b1111111111001111101011111010010000000001, 0b0010010011, 0b0110001000),
			39: (0b1111111111001111101011111010010000000001, 0b0010010011, 0b0111110000),
			40: (0b1111111111001111101011111010010000000001, 0b0010010011, 0b0110001000),
			41: (0b1111111111001111101011111010010000000001, 0b0010010011, 0b0100010000),
			42: (0b1111111111001111101011111010010000000001, 0b0010010011, 0b0100010000),
			43: (0b1111111111001111101011111010010000000001, 0b0010010011, 0b0100010000),
			44: (0b1111111111001111101011111010010000000001, 0b0010010011, 0b0100010000),
			45: (0b1111111111001111101011111010010000000001, 0b0010010011, 0b0100010000),
			46: (0b1111111111001111101011111010010000000001, 0b0010010011, 0b0100010000),
			47: (0b1111111111001111101011111010010000000001, 0b0010010011, 0b0011100000),
			48: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			49: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			50: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			51: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			52: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			53: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			54: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			55: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			56: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			57: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			58: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			59: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			60: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			61: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			62: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			63: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000),
			64: (0b1111111111001111101011111010010000000001, 0b0010100011, 0b0011100000)
		}[fb_divide]
		lock_data = data[0]
		filter_data = data[1 if self.bandwidth() == 'low' else 2]
		
		# Configure the reference divider.
		low_time, high_time, no_count, edge = self._div_cfg(ref_divide)
		reg = self[0x16] & 0b1100000000000000
		reg |= edge << 13
		reg |= no_count << 12
		reg |= high_time << 6
		reg |= low_time << 0
		self[0x16] = reg
		
		# Configure the feedback divider.
		self._cfg_clk('fb', fb_divide)
		
		# Configure LockReg1.
		reg = self[0x18] & 0b1111110000000000
		reg |= ((lock_data >> 20) & 0b1111111111) << 0
		self[0x18] = reg
		
		# Configure LockReg2.
		reg = self[0x19] & 0b1000000000000000
		reg |= ((lock_data >> 30) & 0b11111) << 10
		reg |= ((lock_data >> 0) & 0b1111111111) << 0
		self[0x19] = reg
		
		# Configure LockReg3.
		reg = self[0x1A] & 0b1000000000000000
		reg |= ((lock_data >> 35) & 0b11111) << 10
		reg |= ((lock_data >> 10) & 0b1111111111) << 0
		self[0x1A] = reg
		
		# Configure FiltReg1.
		reg = self[0x4E] & 0b0110011011111111
		reg |= ((filter_data >> 9) & 0b1) << 15
		reg |= ((filter_data >> 7) & 0b11) << 11
		reg |= ((filter_data >> 6) & 0b1) << 8
		self[0x4E] = reg
		
		# Configure FiltReg2.
		reg = self[0x4F] & 0b0110011001101111
		reg |= ((filter_data >> 5) & 0b1) << 15
		reg |= ((filter_data >> 3) & 0b11) << 11
		reg |= ((filter_data >> 1) & 0b11) << 7
		reg |= ((filter_data >> 0) & 0b1) << 4
		self[0x4F] = reg

