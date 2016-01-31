/**
 * r-VEX simulator.
 *
 * Copyright (C) 2008-2015 by TU Delft.
 * All Rights Reserved.
 *
 * THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
 * YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.
 *
 * No portion of this work may be used by any commercial entity, or for any
 * commercial purpose, without the prior, written permission of TU Delft.
 * Nonprofit and noncommercial use is permitted as described below.
 *
 * 1. r-VEX is provided AS IS, with no warranty of any kind, express
 * or implied. The user of the code accepts full responsibility for the
 * application of the code and the use of any results.
 *
 * 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
 * downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
 * educational, noncommercial research, and noncommercial scholarship
 * purposes provided that this notice in its entirety accompanies all copies.
 * Copies of the modified software can be delivered to persons who use it
 * solely for nonprofit, educational, noncommercial research, and
 * noncommercial scholarship purposes provided that this notice in its
 * entirety accompanies all copies.
 *
 * 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
 * PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).
 *
 * 4. No nonprofit user may place any restrictions on the use of this software,
 * including as modified by the user, by any other authorized user.
 *
 * 5. Noncommercial and nonprofit users may distribute copies of r-VEX
 * in compiled or binary form as set forth in Section 2, provided that
 * either: (A) it is accompanied by the corresponding machine-readable source
 * code, or (B) it is accompanied by a written offer, with no time limit, to
 * give anyone a machine-readable copy of the corresponding source code in
 * return for reimbursement of the cost of distribution. This written offer
 * must permit verbatim duplication by anyone, or (C) it is distributed by
 * someone who received only the executable form, and is accompanied by a
 * copy of the written offer of source code.
 *
 * 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
 * Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
 * maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).
 *
 * Copyright (C) 2008-2015 by TU Delft.
 */

#include "Memory.h"

#include "stdio.h"

namespace Periph {

/**
 * Called in preparation for the first clock cycle. The return value should
 * be 0 for OK or -1 if the simulator should shut down.
 */
int Memory::init() {
	return 0;
}

/**
 * Runs a clock cycle, reading only from inputs and writing only to outputs.
 * This is called in an OpenMP accelerated loop, so it may be called from
 * any thread.
 */
void Memory::clock() {
	if (request) {
		if (!busyCyclesRemaining) {

			// New request. Convert from word-aligned address + mask to byte
			// address and access count.
			uint32_t addr = request->address;
			int offs, count, dir;
			switch (request->mask) {
			case 0x0: offs = 0; count = 4; dir = 0; break;
			case 0x1: offs = 3; count = 1; dir = 1; break;
			case 0x2: offs = 2; count = 1; dir = 1; break;
			case 0x3: offs = 2; count = 2; dir = 1; break;
			case 0x4: offs = 1; count = 1; dir = 1; break;
			case 0x6: offs = 1; count = 2; dir = 1; break;
			case 0x7: offs = 1; count = 3; dir = 1; break;
			case 0x8: offs = 0; count = 1; dir = 1; break;
			case 0xC: offs = 0; count = 2; dir = 1; break;
			case 0xE: offs = 0; count = 3; dir = 1; break;
			case 0xF: offs = 0; count = 4; dir = 1; break;
			default:

				// Noncontiguous. Note that AHB will also not support misaligned
				// accesses, which we specifically allow here. We only allow
				// them because it simplifies the debug port.
				response.state = Bus::BSS_FAULT;
				response.data = 0;
				return;

			}

			// Process the command.
			if (dir) {
				uint8_t data[4] = {
						(uint8_t)(request->data >> 24),
						(uint8_t)(request->data >> 16),
						(uint8_t)(request->data >> 8),
						(uint8_t)(request->data)
				};
				access(addr+offs, (char*)data+offs, count, 1);
				response.data = 0;
			} else {
				uint8_t data[4];
				access(addr+offs, (char*)data+offs, count, 0);
				response.data =
						((uint32_t)data[0] << 24) |
						((uint32_t)data[1] << 16) |
						((uint32_t)data[2] << 8) |
						(uint32_t)data[3];
			}

			int startBurst = 0;

			// Stop an ongoing burst if no burst is requested.
			if (bursting && request->state != Bus::BQS_BURST_CONT) {
				bursting = 0;
			}

			// Stop an ongoing burst if the address is wrong.
			if (bursting && request->address != previousAddress + 4) {
				bursting = 0;
				startBurst = 1;
			}

			// Stop an ongoing burst if we crossed the burst boundary.
			if (bursting && (burstMask & (request->address ^ previousAddress))) {
				bursting = 0;
				startBurst = 1;
			}

			// Handle the start of a burst.
			if (request->state == Bus::BQS_BURST_START) {
				startBurst = 1;
			}

			// Figure out the latency.
			if (dir) {
				if (bursting) {
					busyCyclesRemaining = writePeriod;
				} else {
					busyCyclesRemaining = writeLatency;
				}
			} else {
				if (bursting) {
					busyCyclesRemaining = readPeriod;
				} else {
					busyCyclesRemaining = readLatency;
				}
			}

			// Remember if we're in the middle of a burst.
			if (startBurst || bursting) {
				bursting |= startBurst;
				previousAddress = request->address;
			}

		} else {
			busyCyclesRemaining--;
		}

		// Send OK after waiting for enough cycles.
		if (!busyCyclesRemaining) {
			response.state = Bus::BSS_OK;
		}

	} else {

		// No access to keep the burst going.
		bursting = 0;
		busyCyclesRemaining = 0;

	}
}

/**
 * This should propagate the outputs of this entity to the inputs of other
 * entities and, if necessary, perform communication with things outside the
 * simulation. It is only called from the main thread. The return value
 * should be 0 for OK or -1 if the simulator should shut down.
 */
int Memory::synchronize() {
	return 0;
}

/**
 * Same as synchronize, except that it's only called every n cycles.
 */
int Memory::occasional() {
	return 0;
}

/**
 * Called after the last synchronize() call in the simulation.
 */
void Memory::fini() {
}

/**
 * Constructs a memory peripheral. numBits specifies the log2 of the number
 * of bytes in the memory, initialValue specifies the initial value of all
 * the memory locations.
 */
Memory::Memory(const char *name, int numBits, int initialValue) :
		Entity(name), VirtualMemory(numBits, initialValue),
		bursting(0), previousAddress(0), busyCyclesRemaining(0),
		readLatency(0), writeLatency(0),
		readPeriod(0), writePeriod(0), burstMask(0)
{
}

/**
 * Destroys this memory peripheral.
 */
Memory::~Memory() {
}

/**
 * Sets the amount of busy cycles which are injected into a bus request that
 * is not a continuation of a burst.
 */
void Memory::setLatency(int cycles) {
	readLatency = cycles;
	writeLatency = cycles;
}

/**
 * Like setLatency, but only for reads.
 */
void Memory::setReadLatency(int cycles) {
	readLatency = cycles;
}

/**
 * Like setLatency, but only for writes.
 */
void Memory::setWriteLatency(int cycles) {
	writeLatency = cycles;
}

/**
 * Sets the amount of busy cycles which are injected into a bus request that
 * IS a continuation of a burst.
 */
void Memory::setPeriod(int cycles) {
	readPeriod = cycles;
	writePeriod = cycles;
}

/**
 * Like setPeriod, but only for reads.
 */
void Memory::setReadPeriod(int cycles) {
	readPeriod = cycles;
}

/**
 * Like setPeriod, but only for writes.
 */
void Memory::setWritePeriod(int cycles) {
	writePeriod = cycles;
}

/**
 * Sets the burst boundary size as log2 of bytes (i.e. address bits).
 * Whenever a burst boundary is crossed, the normal read/write latency
 * penalty is applied instead of the period penalty. Bits may be set to 32
 * or greater if no such boundary exists.
 */
void Memory::setBurstBoundary(int bits) {
	burstMask = ~((1 << bits) - 1);
}

} /* namespace Periph */
