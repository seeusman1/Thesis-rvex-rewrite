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

#include "../rvsim/components/core/Core.h"
#include "MtiHelper.h"
#include "Updaters.h"

#include <inttypes.h>
#include <mti.h>
#include <new>

using namespace std;

/**
 * Core structure which contains pretty much all the data for the rvex core
 * simulator.
 */
typedef struct {

	// Processes.
	updatedProcess_t stallOutProc;
	updatedProcess_t clockProc;

	// Core simulator class.
	Core::Core core;

	// Just a place to store the current value of the clock signal.
	uint8_t clk;

} rvexCore_t;

/**
 * Macro for adding the clock to a process.
 */
#define ADD_CLK(proc, name, hint) updaters_addInput( \
	&(core->proc), \
	mti_FindPortX(ports, #name), \
	&(core->name), \
	sizeof(core->name), \
	hint, 1)

/**
 * Macro for adding a sensitive input to a process.
 */
#define ADD_INS(proc, name, hint) updaters_addInput( \
	&(core->proc), \
	mti_FindPortX(ports, #name), \
	&(core->core.in.name), \
	sizeof(core->core.in.name), \
	hint, 1)

/**
 * Macro for adding a non-sensitive input to a process.
 */
#define ADD_INN(proc, name, hint) updaters_addInput( \
	&(core->proc), \
	mti_FindPortX(ports, #name), \
	&(core->core.in.name), \
	sizeof(core->core.in.name), \
	hint, 0)

/**
 * Macro for adding an output to a process.
 */
#define ADD_OUT(proc, name, hint) updaters_addOutput( \
	&(core->proc), \
	mti_FindPortX(ports, #name), \
	&(core->core.getOut()->name), \
	sizeof(core->core.getOut()->name), \
	hint)


//==============================================================================
// Stall output process.
//==============================================================================

/**
 * Simulates the combinatorial stall output signal.
 */
static void stallOut_update(void *param) {
	rvexCore_t *core = (rvexCore_t*)param;

	// Simulate the combinatorial logic.
	try {
		core->core.stallOut();
	} catch (const Core::GenericsException& e) {
		mti_PrintFormatted("FATAL: generic configuration error: %s.\n", e.what());
		mti_FatalError();
	}

}

/**
 * Initializes the stallOut process.
 */
static void stallOut_init(rvexCore_t *core, mtiInterfaceListT *ports) {

	// Create the process.
	updaters_createProcess(
			&(core->stallOutProc), // Process structure.
			"stallOut_proc",       // Process name.
			core,                  // Core structure.
			stallOut_update,       // Update function.
			0);                    // Gate function.

	// Common memory interface.
	ADD_INS(stallOutProc, mem2rv_stallIn, 0);
	ADD_OUT(stallOutProc, rv2mem_stallOut, 0);

	// Control/debug bus interface.
	ADD_INS(stallOutProc, dbg2rv_addr, 0);
	ADD_INS(stallOutProc, dbg2rv_readEnable, 0);
	ADD_INS(stallOutProc, dbg2rv_writeEnable, 0);
	ADD_INS(stallOutProc, dbg2rv_writeMask, 0);
	ADD_INS(stallOutProc, dbg2rv_writeData, 0);

	// We also depend on the clock process due to the trace unit. This is
	// handled in the clock process by scheduling a wakeup of this process
	// whenever it completes.

}


//==============================================================================
// Clock process.
//==============================================================================

/**
 * Gate function for the clock process. Makes sure that the process is only run
 * on the rising edge of the clock instead of on any event.
 */
static int clock_gate(void *param) {
	rvexCore_t *core = (rvexCore_t*)param;
	return core->clk & 1;
}

/**
 * Simulates all registered signals.
 */
static void clock_update(void *param) {
	rvexCore_t *core = (rvexCore_t*)param;

	// Simulate the clock cycle.
	try {
		core->core.clock();
	} catch (const Core::GenericsException& e) {
		mti_PrintFormatted("FATAL: generic configuration error: %s.\n", e.what());
		mti_FatalError();
	}

	// Wake up the stallOut process, since it depends on internal registered
	// values.
	mti_ScheduleWakeup(core->stallOutProc.pid, 0);

}

/**
 * Initializes the clock process.
 */
static void clock_init(rvexCore_t *core, mtiInterfaceListT *ports) {

	// Create the process.
	updaters_createProcess(
			&(core->clockProc), // Process structure.
			"clock_proc",       // Process name.
			core,               // Core structure.
			clock_update,       // Update function.
			clock_gate);        // Gate function.

	// System control.
	ADD_INN(clockProc, reset, 0);
	ADD_OUT(clockProc, resetOut, 0);
	ADD_CLK(clockProc, clk, 0);
	ADD_INN(clockProc, clkEn, 0);

	// VHDL simulation debug information.
	ADD_OUT(clockProc, rv2sim, 0);

	// Run control interface.
	ADD_INN(clockProc, rctrl2rv_irq, 0);
	ADD_INN(clockProc, rctrl2rv_irqID, 0);
	ADD_OUT(clockProc, rv2rctrl_irqAck, 0);
	ADD_INN(clockProc, rctrl2rv_run, 0);
	ADD_OUT(clockProc, rv2rctrl_idle, 0);
	ADD_INN(clockProc, rctrl2rv_reset, 0);
	ADD_INN(clockProc, rctrl2rv_resetVect, 0);
	ADD_OUT(clockProc, rv2rctrl_done, 0);

	// Common memory interface.
	ADD_OUT(clockProc, rv2mem_decouple, 0);
	ADD_INN(clockProc, mem2rv_blockReconfig, 0);
	ADD_INN(clockProc, mem2rv_stallIn, 0);
	ADD_INN(clockProc, mem2rv_cacheStatus, "cacheStatus");

	// Instruction memory interface.
	ADD_OUT(clockProc, rv2imem_PCs, 0);
	ADD_OUT(clockProc, rv2imem_fetch, 0);
	ADD_OUT(clockProc, rv2imem_cancel, 0);
	ADD_INN(clockProc, imem2rv_instr, 0);
	ADD_INN(clockProc, imem2rv_affinity, 0);
	ADD_INN(clockProc, imem2rv_busFault, 0);

	// Data memory interface.
	ADD_OUT(clockProc, rv2dmem_addr, 0);
	ADD_OUT(clockProc, rv2dmem_readEnable, 0);
	ADD_OUT(clockProc, rv2dmem_writeData, 0);
	ADD_OUT(clockProc, rv2dmem_writeMask, 0);
	ADD_OUT(clockProc, rv2dmem_writeEnable, 0);
	ADD_INN(clockProc, dmem2rv_readData, 0);
	ADD_INN(clockProc, dmem2rv_ifaceFault, 0);
	ADD_INN(clockProc, dmem2rv_busFault, 0);

	// Control/debug bus interface.
	ADD_INN(clockProc, dbg2rv_addr, 0);
	ADD_INN(clockProc, dbg2rv_readEnable, 0);
	ADD_INN(clockProc, dbg2rv_writeEnable, 0);
	ADD_INN(clockProc, dbg2rv_writeMask, 0);
	ADD_INN(clockProc, dbg2rv_writeData, 0);
	ADD_OUT(clockProc, rv2dbg_readData, 0);

	// Trace interface.
	ADD_OUT(clockProc, rv2trsink_push, 0);
	ADD_OUT(clockProc, rv2trsink_data, 0);
	ADD_OUT(clockProc, rv2trsink_end, 0);
	ADD_INN(clockProc, trsink2rv_busy, 0);

}


//==============================================================================
// Housekeeping.
//==============================================================================

/**
 * Loads the VHDL generics into our own generics structure.
 */
static void load_generics(mtiInterfaceListT *generics,
		Core::coreInterfaceGenerics_t *gen)
{
	genericToC(generics, "CFG_numLanesLog2",
			(char*)&(gen->CFG.numLanesLog2),
			sizeof(gen->CFG.numLanesLog2));

	genericToC(generics, "CFG_numContextsLog2",
			(char*)&(gen->CFG.numContextsLog2),
			sizeof(gen->CFG.numContextsLog2));

	genericToC(generics, "CFG_genBundleSizeLog2",
			(char*)&(gen->CFG.genBundleSizeLog2),
			sizeof(gen->CFG.genBundleSizeLog2));

	genericToC(generics, "CFG_bundleAlignLog2",
			(char*)&(gen->CFG.bundleAlignLog2),
			sizeof(gen->CFG.bundleAlignLog2));

	genericToC(generics, "CFG_multiplierLanes",
			(char*)&(gen->CFG.multiplierLanes),
			sizeof(gen->CFG.multiplierLanes));

	genericToC(generics, "CFG_memLaneRevIndex",
			(char*)&(gen->CFG.memLaneRevIndex),
			sizeof(gen->CFG.memLaneRevIndex));

	genericToC(generics, "CFG_numBreakpoints",
			(char*)&(gen->CFG.numBreakpoints),
			sizeof(gen->CFG.numBreakpoints));

	genericToC(generics, "CFG_forwarding",
			(char*)&(gen->CFG.forwarding),
			sizeof(gen->CFG.forwarding));

	genericToC(generics, "CFG_limmhFromNeighbor",
			(char*)&(gen->CFG.limmhFromNeighbor),
			sizeof(gen->CFG.limmhFromNeighbor));

	genericToC(generics, "CFG_limmhFromPreviousPair",
			(char*)&(gen->CFG.limmhFromPreviousPair),
			sizeof(gen->CFG.limmhFromPreviousPair));

	genericToC(generics, "CFG_reg63isLink",
			(char*)&(gen->CFG.reg63isLink),
			sizeof(gen->CFG.reg63isLink));

	genericToC(generics, "CFG_cregStartAddress",
			(char*)&(gen->CFG.cregStartAddress),
			sizeof(gen->CFG.cregStartAddress));

	genericToC(generics, "CFG_resetVector0",
			(char*)&(gen->CFG.resetVectors[0]),
			sizeof(gen->CFG.resetVectors[0]));

	genericToC(generics, "CFG_resetVector1",
			(char*)&(gen->CFG.resetVectors[1]),
			sizeof(gen->CFG.resetVectors[1]));

	genericToC(generics, "CFG_resetVector2",
			(char*)&(gen->CFG.resetVectors[2]),
			sizeof(gen->CFG.resetVectors[2]));

	genericToC(generics, "CFG_resetVector3",
			(char*)&(gen->CFG.resetVectors[3]),
			sizeof(gen->CFG.resetVectors[3]));

	genericToC(generics, "CFG_resetVector4",
			(char*)&(gen->CFG.resetVectors[4]),
			sizeof(gen->CFG.resetVectors[4]));

	genericToC(generics, "CFG_resetVector5",
			(char*)&(gen->CFG.resetVectors[5]),
			sizeof(gen->CFG.resetVectors[5]));

	genericToC(generics, "CFG_resetVector6",
			(char*)&(gen->CFG.resetVectors[6]),
			sizeof(gen->CFG.resetVectors[6]));

	genericToC(generics, "CFG_resetVector7",
			(char*)&(gen->CFG.resetVectors[7]),
			sizeof(gen->CFG.resetVectors[7]));

	genericToC(generics, "CFG_unifiedStall",
			(char*)&(gen->CFG.unifiedStall),
			sizeof(gen->CFG.unifiedStall));

	genericToC(generics, "CFG_traceEnable",
			(char*)&(gen->CFG.traceEnable),
			sizeof(gen->CFG.traceEnable));

	genericToC(generics, "CFG_perfCountSize",
			(char*)&(gen->CFG.perfCountSize),
			sizeof(gen->CFG.perfCountSize));

	genericToC(generics, "CFG_cachePerfCountEnable",
			(char*)&(gen->CFG.cachePerfCountEnable),
			sizeof(gen->CFG.cachePerfCountEnable));

	genericToC(generics, "CORE_ID",
			(char*)&(gen->CORE_ID),
			sizeof(gen->CORE_ID));

	genericToC(generics, "PLATFORM_TAG",
			(char*)&(gen->PLATFORM_TAG),
			sizeof(gen->PLATFORM_TAG));

}

/**
 * Initialize an rvex core.
 */
static void init(mtiInterfaceListT *generics, mtiInterfaceListT *ports) {
	mti_PrintMessage("Modelsim is totally initializing rvsim!");

	// Allocate memory for ourselves.
	rvexCore_t *core = (rvexCore_t*)mti_Malloc(sizeof(rvexCore_t));

	// Load the generics.
	Core::coreInterfaceGenerics_t gen;
	load_generics(generics, &gen);

	// Create processes.
	stallOut_init(core, ports);
	clock_init(core, ports);

	// Construct the core simulator.
	try {
		new (&(core->core)) Core::Core(&gen, mti_PrintFormatted);
	} catch (const Core::GenericsException& e) {
		mti_PrintFormatted("FATAL: generic configuration error: %s.\n", e.what());
		mti_FatalError();
	}

}

/**
 * Output a non-C++-obfuscated symbol for initialization so Modelsim can find
 * it.
 */
extern "C" {
	void rvex_core(mtiRegionIdT region, char *parameters,
			mtiInterfaceListT *generics, mtiInterfaceListT *ports)
	{
		init(generics, ports);
	}
}

