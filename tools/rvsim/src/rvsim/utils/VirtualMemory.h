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

#ifndef RVSIM_UTILS_VIRTUALMEMORY_H
#define RVSIM_UTILS_VIRTUALMEMORY_H

#include <inttypes.h>

class VirtualMemory {
private:

	/**
	 * Number of address bits.
	 */
	const int bits;

	/**
	 * Initial value for each memory position.
	 */
	const int initial;

	/**
	 * Lookup table for sub-memories.
	 */
	VirtualMemory **lookupTable;
	int lookupTableSize;
	int lookupTableShift;

	/**
	 * Actual memory.
	 */
	char *memory;
	unsigned int memorySize;

public:

	/**
	 * Creates a virtual memory. Bits specifies the number of used address bits.
	 * initial specifies the initial byte value of the memory.
	 */
	VirtualMemory(int bits, int initial);

	/**
	 * Destroys this virtual memory.
	 */
	virtual ~VirtualMemory();

	/**
	 * Accesses the memory. addr specifies the start address, buffer specifies
	 * the data buffer, count is the number of bytes to read/write, direction is
	 * 1 for writes and 0 for reads.
	 */
	void access(uint32_t addr, char *buffer, int count, int direction);

	/**
	 * Reads from the memory.
	 */
	void read(uint32_t addr, char *buffer, int count);

	/**
	 * Writes to the memory.
	 */
	void write(uint32_t addr, char *buffer, int count);

};

#endif
