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

#ifndef RVSIM_COMPONENTS_CORE_SYSTEM_H
#define RVSIM_COMPONENTS_CORE_SYSTEM_H

#include "../Simulation.h"
#include "../bus/Bus.h"
#include "../rvex/Core.h"

namespace Core {

class MemorySystem;

/**
 * Simulates an rvex core with debug bus slave and interrupt controller. A
 * memory system implementation must be supplied to handle the connection from
 * the core memory interface signals to the bus.
 */
class System : public Core, public Entity {
	friend class MemorySystem;
private:

	/**
	 * Memory system for this core.
	 */
	MemorySystem *memorySystem;

	/**
	 * The bus which this system is connected to.
	 */
	Bus::Bus *bus;

	/**
	 * Saves whether a generics exception occured during clock(), so the
	 * simulation can be stopped at the next synchronize().
	 */
	int error = 0;

	/**
	 * Number of cycles to reset.
	 */
	int resetCycles = 0;

	/**
	 * Debug bus slave interface.
	 */
	Bus::busSlave_t debugBusSlave;

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
	 * Creates an rvex core simulation entity.
	 */
	System(const char *name, const coreInterfaceGenerics_t *generics,
			MemorySystem *memorySystem, Bus::Bus *bus,
			Bus::busDemuxFunPtr_t debugBusDemuxFun, void *debugBusDemuxParam);

	/*
	 * Destroys this rvex core.
	 */
	virtual ~System();

	/**
	 * Resets the system for cycleCount cycles.
	 */
	void reset(int cycleCount);

};


class MemorySystem {
	friend class System;
private:

	/**
	 * Pointer to the memory system.
	 */
	System *system = 0;

protected:

	/**
	 * Returns the rvex core system which this memory system is a part of.
	 */
	System *getSystem() { return system; }

	/**
	 * Called in preparation for the first clock cycle. The return value should
	 * be 0 for OK or -1 if the simulator should shut down.
	 */
	virtual int init() = 0;

	/**
	 * This is called by clock() before core::stallOut().
	 */
	virtual void preClockPreStall() = 0;

	/**
	 * This is called by clock() after core::stallOut() but before
	 * core::clock().
	 */
	virtual void preClockPostStall() = 0;

	/**
	 * This is called by clock() after core::clock().
	 */
	virtual void postClock() = 0;

	/**
	 * This should propagate the outputs of this entity to the inputs of other
	 * entities and, if necessary, perform communication with things outside the
	 * simulation. It is only called from the main thread. The return value
	 * should be 0 for OK or -1 if the simulator should shut down.
	 */
	virtual int synchronize() = 0;

	/**
	 * Same as synchronize, except that it's only called every n cycles.
	 */
	virtual int occasional() = 0;

	/**
	 * Called after the last synchronize() call in the simulation.
	 */
	virtual void fini() = 0;

public:

	/**
	 * Creates an rvex core simulation entity.
	 */
	MemorySystem() {};

	/**
	 * Destroys this rvex core.
	 */
	virtual ~MemorySystem() {};

};


} /* namespace Core */

#endif

