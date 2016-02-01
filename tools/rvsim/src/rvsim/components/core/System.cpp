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

#include "System.h"
#include <stdio.h>
#include <cstdarg>

namespace Core {

/**
 * Print function to use outside modelsim context.
 */
static void printf_fun(const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);
}

/**
 * Called in preparation for the first clock cycle. The return value should
 * be 0 for OK or -1 if the simulator should shut down.
 */
int System::init() {
	in.clkEn = 1;
	resetCycles = 10;

	return memorySystem->init();
}

/**
 * Runs a clock cycle, reading only from inputs and writing only to outputs.
 * This is called in an OpenMP accelerated loop, so it may be called from
 * any thread.
 */
void System::clock() {
	const coreInterfaceOut_t *out;

	// Handle resets.
	if (resetCycles) {
		in.reset = 1;
		resetCycles--;
		if (!resetCycles) {
			in.reset = 0;
		}
	}

	// Handle the memory system.
	memorySystem->preClockPreStall();

	// Forward the debug bus request.
	if (debugBusSlave.request) {
		in.dbg2rv_addr        = debugBusSlave.request->address;
		in.dbg2rv_readEnable  = !debugBusSlave.request->mask;
		in.dbg2rv_writeData   = debugBusSlave.request->data;
		in.dbg2rv_writeEnable = !!debugBusSlave.request->mask;
		in.dbg2rv_writeMask   = debugBusSlave.request->mask;
	} else {
		in.dbg2rv_readEnable  = 0;
		in.dbg2rv_writeEnable = 0;
	}

	// Simulate stall signal generation.
	out = stallOut();

	// Handle the memory system.
	memorySystem->preClockPostStall();

	// Simulate a core clock cycle.
	out = Core::clock();

	// Handle the memory system.
	memorySystem->postClock();

	// Forward the debug bus response.
	if (debugBusSlave.request) {
		debugBusSlave.response.state = Bus::BSS_OK;
		debugBusSlave.response.data = out->rv2dbg_readData;
	}

}

/**
 * This should propagate the outputs of this entity to the inputs of other
 * entities and, if necessary, perform communication with things outside the
 * simulation. It is only called from the main thread. The return value
 * should be 0 for OK or -1 if the simulator should shut down.
 */
int System::synchronize() {
	if (error) {
		return -1;
	}
	return memorySystem->synchronize();
}

/**
 * Same as synchronize, except that it's only called every n cycles.
 */
int System::occasional() {
	return memorySystem->occasional();
}

/**
 * Called after the last synchronize() call in the simulation.
 */
void System::fini() {
	memorySystem->fini();
}

/**
 * Creates an rvex core simulation entity.
 */
System::System(const char *name, const coreInterfaceGenerics_t *generics,
		MemorySystem *memorySystem, Bus::Bus *bus,
		Bus::busDemuxFunPtr_t debugBusDemuxFun, void *debugBusDemuxParam) :
	Core(generics, printf_fun), Entity(name), memorySystem(memorySystem),
	bus(bus)
{
	memorySystem->system = this;
	bus->addSlave(&debugBusSlave, debugBusDemuxFun, debugBusDemuxParam);
}

/**
 * Destroys this rvex core.
 */
System::~System() {
}

/**
 * Resets the system for cycleCount cycles.
 */
void System::reset(int cycleCount) {
	resetCycles = cycleCount;
}

} /* namespace Core */
