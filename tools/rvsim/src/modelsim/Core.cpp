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

#include <inttypes.h>
#include <mti.h>

using namespace std;

typedef struct {

	// System control.
	mtiSignalIdT reset;
	mtiDriverIdT resetOut;
	mtiSignalIdT clk;
	mtiSignalIdT clkEn;

	// VHDL simulation debug information.
	mtiDriverIdT rv2sim;

	// Run control interface.
	mtiSignalIdT rctrl2rv_irq;
	mtiSignalIdT rctrl2rv_irqID;
	mtiDriverIdT rv2rctrl_irqAck;
	mtiSignalIdT rctrl2rv_run;
	mtiDriverIdT rv2rctrl_idle;
	mtiSignalIdT rctrl2rv_reset;
	mtiSignalIdT rctrl2rv_resetVect;
	mtiDriverIdT rv2rctrl_done;

	// Common memory interface.
	mtiDriverIdT rv2mem_decouple;
	mtiSignalIdT mem2rv_blockReconfig;
	mtiSignalIdT mem2rv_stallIn;
	mtiDriverIdT rv2mem_stallOut;
	mtiSignalIdT mem2rv_cacheStatus;

	// Instruction memory interface.
	mtiDriverIdT rv2imem_PCs;
	mtiDriverIdT rv2imem_fetch;
	mtiDriverIdT rv2imem_cancel;
	mtiSignalIdT imem2rv_instr;
	mtiSignalIdT imem2rv_affinity;
	mtiSignalIdT imem2rv_busFault;

	// Data memory interface.
	mtiDriverIdT rv2dmem_addr;
	mtiDriverIdT rv2dmem_readEnable;
	mtiDriverIdT rv2dmem_writeData;
	mtiDriverIdT rv2dmem_writeMask;
	mtiDriverIdT rv2dmem_writeEnable;
	mtiSignalIdT dmem2rv_readData;
	mtiSignalIdT dmem2rv_ifaceFault;
	mtiSignalIdT dmem2rv_busFault;

	// Control/debug bus interface.
	mtiSignalIdT dbg2rv_addr;
	mtiSignalIdT dbg2rv_readEnable;
	mtiSignalIdT dbg2rv_writeEnable;
	mtiSignalIdT dbg2rv_writeMask;
	mtiSignalIdT dbg2rv_writeData;
	mtiDriverIdT rv2dbg_readData;

	// Trace interface.
	mtiDriverIdT rv2trsink_push;
	mtiDriverIdT rv2trsink_data;
	mtiDriverIdT rv2trsink_end;
	mtiSignalIdT trsink2rv_busy;

} rvexCorePorts_t;

typedef struct {

	// Modelsim ports.
	rvexCorePorts_t ports;

	// Core simulator class.
	Core::Core core;

} rvexCore_t;

/**
 * Loads the VHDL generics into our own generics structure.
 */
static void load_generics(mtiInterfaceListT *generics,
		volatile Core::coreInterfaceGenerics_t *gen)
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
 * Looks up all VHDL ports and creates drivers for the outputs.
 */
static void load_ports(mtiInterfaceListT *ports, rvexCorePorts_t *prts) {

	// System control.
	prts->reset = mti_FindPortX(ports, "reset");
	prts->resetOut = mti_CreateDriver(mti_FindPortX(ports, "resetOut"));
	prts->clk = mti_FindPortX(ports, "clk");
	prts->clkEn = mti_FindPortX(ports, "clkEn");

	// VHDL simulation debug information.
	prts->rv2sim = mti_CreateDriver(mti_FindPortX(ports, "rv2sim"));

	// Run control interface.
	prts->rctrl2rv_irq = mti_FindPortX(ports, "rctrl2rv_irq");
	prts->rctrl2rv_irqID = mti_FindPortX(ports, "rctrl2rv_irqID");
	prts->rv2rctrl_irqAck = mti_CreateDriver(mti_FindPortX(ports, "rv2rctrl_irqAck"));
	prts->rctrl2rv_run = mti_FindPortX(ports, "rctrl2rv_run");
	prts->rv2rctrl_idle = mti_CreateDriver(mti_FindPortX(ports, "rv2rctrl_idle"));
	prts->rctrl2rv_reset = mti_FindPortX(ports, "rctrl2rv_reset");
	prts->rctrl2rv_resetVect = mti_FindPortX(ports, "rctrl2rv_resetVect");
	prts->rv2rctrl_done = mti_CreateDriver(mti_FindPortX(ports, "rv2rctrl_done"));

	// Common memory interface.
	prts->rv2mem_decouple = mti_CreateDriver(mti_FindPortX(ports, "rv2mem_decouple"));
	prts->mem2rv_blockReconfig = mti_FindPortX(ports, "mem2rv_blockReconfig");
	prts->mem2rv_stallIn = mti_FindPortX(ports, "mem2rv_stallIn");
	prts->rv2mem_stallOut = mti_CreateDriver(mti_FindPortX(ports, "rv2mem_stallOut"));
	prts->mem2rv_cacheStatus = mti_FindPortX(ports, "mem2rv_cacheStatus");

	// Instruction memory interface.
	prts->rv2imem_PCs = mti_CreateDriver(mti_FindPortX(ports, "rv2imem_PCs"));
	prts->rv2imem_fetch = mti_CreateDriver(mti_FindPortX(ports, "rv2imem_fetch"));
	prts->rv2imem_cancel = mti_CreateDriver(mti_FindPortX(ports, "rv2imem_cancel"));
	prts->imem2rv_instr = mti_FindPortX(ports, "imem2rv_instr");
	prts->imem2rv_affinity = mti_FindPortX(ports, "imem2rv_affinity");
	prts->imem2rv_busFault = mti_FindPortX(ports, "imem2rv_busFault");

	// Data memory interface.
	prts->rv2dmem_addr = mti_CreateDriver(mti_FindPortX(ports, "rv2dmem_addr"));
	prts->rv2dmem_readEnable = mti_CreateDriver(mti_FindPortX(ports, "rv2dmem_readEnable"));
	prts->rv2dmem_writeData = mti_CreateDriver(mti_FindPortX(ports, "rv2dmem_writeData"));
	prts->rv2dmem_writeMask = mti_CreateDriver(mti_FindPortX(ports, "rv2dmem_writeMask"));
	prts->rv2dmem_writeEnable = mti_CreateDriver(mti_FindPortX(ports, "rv2dmem_writeEnable"));
	prts->dmem2rv_readData = mti_FindPortX(ports, "dmem2rv_readData");
	prts->dmem2rv_ifaceFault = mti_FindPortX(ports, "dmem2rv_ifaceFault");
	prts->dmem2rv_busFault = mti_FindPortX(ports, "dmem2rv_busFault");

	// Control/debug bus interface.
	prts->dbg2rv_addr = mti_FindPortX(ports, "dbg2rv_addr");
	prts->dbg2rv_readEnable = mti_FindPortX(ports, "dbg2rv_readEnable");
	prts->dbg2rv_writeEnable = mti_FindPortX(ports, "dbg2rv_writeEnable");
	prts->dbg2rv_writeMask = mti_FindPortX(ports, "dbg2rv_writeMask");
	prts->dbg2rv_writeData = mti_FindPortX(ports, "dbg2rv_writeData");
	prts->rv2dbg_readData = mti_CreateDriver(mti_FindPortX(ports, "rv2dbg_readData"));

	// Trace interface.
	prts->rv2trsink_push = mti_CreateDriver(mti_FindPortX(ports, "rv2trsink_push"));
	prts->rv2trsink_data = mti_CreateDriver(mti_FindPortX(ports, "rv2trsink_data"));
	prts->rv2trsink_end = mti_CreateDriver(mti_FindPortX(ports, "rv2trsink_end"));
	prts->trsink2rv_busy = mti_FindPortX(ports, "trsink2rv_busy");

}

/**
 * Initialize an rvex core.
 */
static void init(mtiInterfaceListT *generics, mtiInterfaceListT *ports) {
	mti_PrintMessage("Modelsim is totally initializing rvsim!");

	// Allocate memory for ourselves.
	rvexCore_t *core = (rvexCore_t*)mti_Malloc(sizeof(rvexCore_t));

	// Load the generics.
	volatile Core::coreInterfaceGenerics_t gen;
	load_generics(generics, &gen);

	// Load the ports.
	load_ports(ports, &(core->ports));

	mti_PrintFormatted("Number of lanes log2: %d\n", gen.CFG.numLanesLog2);
	mti_PrintFormatted("CREG start: 0x%08X\n", gen.CFG.cregStartAddress);

	// Construct the core simulator.
	/*try {
		new ((void*)&(core->core)) Core::Core(&gen);
	} catch (const Core::GenericsException& e) {
		mti_PrintFormatted("FATAL: generic configuration error: %s.\n", e.what());
		mti_FatalError();
	}*/

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

