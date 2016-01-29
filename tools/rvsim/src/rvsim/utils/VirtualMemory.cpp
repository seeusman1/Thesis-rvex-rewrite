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

#include "VirtualMemory.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>

/**
 * Creates a virtual memory. Bits specifies the number of used address bits.
 * initial specifies the initial byte value of the memory.
 */
VirtualMemory::VirtualMemory(int bits, int initial) :
		bits(bits), initial(initial)
{

	if (bits > 16) {

		lookupTableShift = bits - 9;

		// Implement the memory virtually.
		lookupTable = (VirtualMemory**)calloc(512, sizeof(VirtualMemory*));
		if (!lookupTable) {
			perror("out of memory");
			exit(1);
		}
		lookupTableSize = 512;
		memory = 0;
		memorySize = 0;

	} else {

		// Implement the memory directly.
		lookupTable = 0;
		lookupTableSize = 0;
		lookupTableShift = 0;
		memory = (char*)malloc(1 << bits);
		if (!memory) {
			perror("out of memory");
			exit(1);
		}
		memorySize = 1 << bits;
		memset(memory, initial, memorySize);

	}

}

/**
 * Destroys this virtual memory.
 */
VirtualMemory::~VirtualMemory() {

	// Free the lookup table and all its entries.
	if (lookupTable) {
		for (int i = 0; i < lookupTableSize; i++) {
			if (lookupTable[i]) {
				delete lookupTable[i];
				lookupTable[i] = 0;
			}
		}
		free(lookupTable);
		lookupTable = 0;
		lookupTableSize = 0;
	}

	// Free the memory.
	if (memory) {
		free(memory);
		memory = 0;
		memorySize = 0;
	}

}

/**
 * Accesses the memory. addr specifies the start address, buffer specifies
 * the data buffer, count is the number of bytes to read/write, direction is
 * 1 for writes and 0 for reads.
 */
void VirtualMemory::access(uint32_t addr, char *buffer, int count, int direction) {

	//printf("Accessing addr 0x%08X, %d bytes, %d addr bits...\n", addr, count, bits);

	while (count) {

		// Clear the bits which we should ignore.
		addr &= (1ull << bits) - 1ull;

		//printf("addr 0x%08X after masking with 0x%08X...\n", addr, (uint32_t)((1ull << bits) - 1ull));

		int len = count;

		if (memory) {

			// Access our memory bank.
			if (len > memorySize-addr) {
				len = memorySize-addr;
			}
			//printf("Addr 0x%08X -> %d from local mem...\n", addr, count);
			if (direction) {
				memcpy(memory+addr, buffer, len);
			} else {
				memcpy(buffer, memory+addr, len);
			}

		} else {

			// Access a submemory.
			int idx = addr >> lookupTableShift;
			uint32_t offs = addr & ((1 << lookupTableShift) - 1);

			// Allocate the submemory if it hasn't been already.
			if (lookupTable[idx] == 0) {
				lookupTable[idx] = new VirtualMemory(lookupTableShift, initial);
			}

			if (len > (1 << lookupTableShift)-offs) {
				len = (1 << lookupTableShift)-offs;
			}
			//printf("Addr 0x%08X -> %d from submem 0x%03X at 0x%08X...\n", addr, len, idx, offs);
			lookupTable[idx]->access(offs, buffer, len, direction);

		}

		addr += len;
		buffer += len;
		count -= len;
	}
}

/**
 * Reads from the memory.
 */
void VirtualMemory::read(uint32_t addr, char *buffer, int count) {
	access(addr, buffer, count, 0);
}

/**
 * Writes to the memory.
 */
void VirtualMemory::write(uint32_t addr, char *buffer, int count) {
	access(addr, buffer, count, 1);
}
