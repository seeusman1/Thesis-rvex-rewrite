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

#ifndef RVSIM_COMPONENTS_PERIPH_MEMORY_H
#define RVSIM_COMPONENTS_PERIPH_MEMORY_H

#include "../bus/Bus.h"
#include "../../utils/VirtualMemory.h"
#include "../Simulation.h"

namespace Periph {

class Memory: public Entity, public VirtualMemory, public Bus::busSlave_t {
private:

	/**
	 * Whether we're in the middle of a burst.
	 */
	int bursting;

	/**
	 * Previously requested address, used for determining whether we're in a
	 * valid burst.
	 */
	uint32_t previousAddress;

	/**
	 * Number of busy cycles remaining before we should acknowledge the transfer.
	 */
	int busyCyclesRemaining;

	/**
	 * Latency metrics. Refer to the public setter functions for more
	 * information.
	 */
	int readLatency;
	int writeLatency;
	int readPeriod;
	int writePeriod;

	/**
	 * Stores the bitmask applied to the address in order to get a page.
	 */
	int burstMask;

protected:

	/**
	 * Called in preparation for the first clock cycle. The return value should
	 * be 0 for OK or -1 if the simulator should shut down.
	 */
	virtual int init();

	/**
	 * Runs a clock cycle, reading only from inputs and writing only to outputs.
	 * This is called in an OpenMP accelerated loop, so it may be called from
	 * any thread.
	 */
	virtual void clock();

	/**
	 * This should propagate the outputs of this entity to the inputs of other
	 * entities and, if necessary, perform communication with things outside the
	 * simulation. It is only called from the main thread. The return value
	 * should be 0 for OK or -1 if the simulator should shut down.
	 */
	virtual int synchronize();

	/**
	 * Same as synchronize, except that it's only called every n cycles.
	 */
	virtual int occasional();

	/**
	 * Called after the last synchronize() call in the simulation.
	 */
	virtual void fini();


public:

	/**
	 * Constructs a memory peripheral. numBits specifies the log2 of the number
	 * of bytes in the memory, initialValue specifies the initial value of all
	 * the memory locations.
	 */
	Memory(const char *name, int numBits, int initialValue);

	/**
	 * Destroys this memory peripheral.
	 */
	virtual ~Memory();

	/**
	 * Sets the amount of busy cycles which are injected into a bus request that
	 * is not a continuation of a burst.
	 */
	void setLatency(int cycles);

	/**
	 * Like setLatency, but only for reads.
	 */
	void setReadLatency(int cycles);

	/**
	 * Like setLatency, but only for writes.
	 */
	void setWriteLatency(int cycles);

	/**
	 * Sets the amount of busy cycles which are injected into a bus request that
	 * IS a continuation of a burst.
	 */
	void setPeriod(int cycles);

	/**
	 * Like setPeriod, but only for reads.
	 */
	void setReadPeriod(int cycles);

	/**
	 * Like setPeriod, but only for writes.
	 */
	void setWritePeriod(int cycles);

	/**
	 * Sets the burst boundary size as log2 of bytes (i.e. address bits).
	 * Whenever a burst boundary is crossed, the normal read/write latency
	 * penalty is applied instead of the period penalty. Bits may be set to 32
	 * or greater if no such boundary exists.
	 */
	void setBurstBoundary(int bits);

};

} /* namespace Periph */

#endif
