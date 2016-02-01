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

#include "Core.h"

#include <cstring>
#include <cstdio>
#include <cstdlib>

using namespace std;

namespace Core {

/**
 * Include generated code. We want this to be in the same compilation unit as
 * the non-generated code, so gcc can better perform optimizations.
 */
#include "Generated.cpp.inc"

/**
 * Creates a new core with the specified generic configuration.
 * NOTE: NONE OF THE FUCNTIONS IN THIS CLASS ARE ALLOWED TO USE DYNAMIC
 * MEMORY ALLOCATION, AS THE MODELSIM INTERFACE REQUIRES THE USAGE OF
 * SPECIALIZED, GARBAGE COLLECTED MEMORY ALLOCATION FUNCTIONS. THIS ALSO
 * MEANS THAT THE DESTRUCTOR IS NOT NECESSARILY CALLED, AND MUST THUS BE
 * NO-OP.
 */
Core::Core(const coreInterfaceGenerics_t *generics, printfFuncPtr_t printf) :
	printf(printf), generics(*generics)
{
	memset(&st, 0, sizeof(st));
}

/**
 * Generates the stall output signal, which is combinatorial based on the
 * stall input and the debug bus. Returns the output signal structure.
 */
const coreInterfaceOut_t *Core::stallOut(void) throw(GenericsException) {

	//printf("Core::stallOut()\n");

	// Determine stall output.
	// Sources:
	//  - core.vhd: process stall_gen
	//  - core_ctrlRegs.vhd process claim_proc
	int internalStall = 0;
	if (in.dbg2rv_writeEnable & 1) {
		if (in.dbg2rv_addr & 0x200) {
			internalStall = 1; // Writing to cxreg.
		} else if (in.dbg2rv_addr & 0x100) {
			if ((in.dbg2rv_writeMask & 0xF) == 0xF) {
				internalStall = 1; // Writing word to gpreg.
			}
		}
	} else if (in.dbg2rv_readEnable & 1) {
		if (in.dbg2rv_addr & 0x300) {
			internalStall = 1; // Reading from cxreg/gpreg.
		}
	}
	if (!internalStall && generics.CFG.unifiedStall) {
		for (int i = 0; i < CORE_MAX_LANE_GROUPS; i++) {
			if (in.mem2rv_stallIn[i] & 1) {
				internalStall = 1; // Any incoming stall stalls all contexts.
				break;
			}
		}
	}
	if (internalStall) {
		for (int i = 0; i < CORE_MAX_LANE_GROUPS; i++) {
			out.rv2mem_stallOut[i] = 1;
		}
	} else {
		memcpy(out.rv2mem_stallOut, in.mem2rv_stallIn, sizeof(in.mem2rv_stallIn));
	}

	return &out;
}

/**
 * Simulates a clock cycle and returns the output signal structure.
 */
const coreInterfaceOut_t *Core::clock(void) throw(GenericsException) {

	//printf("Core::clock()\n");

	// Only operate if clkEn is high or if we're resetting.
	if ((in.reset & 1) || (in.clkEn & 1)) {

		// Temporary code for setting up core->ctrlreg bus signals.
		// = TODO

		simulateControlRegs();

	}

	return &out;
}

/**
 * Simulates the control registers.
 */
void Core::simulateControlRegs() {

	// Temporary code: there's never any accesses from the cores.
	// TODO: this will have to be more intelligent
	for (int cx = 0; cx < (1 << generics.CFG.numLaneGroupsLog2); cx++) {
		st.cx[cx].cregIface.cxreg_address = -1;
	}
	for (int lg = 0; lg < (1 << generics.CFG.numLaneGroupsLog2); lg++) {
		st.cregIface.gbreg_coreAddress[lg] = -1;
	}

	// Handle debug bus accesses.
	int dbgBusAccess = -1;
	if ((in.dbg2rv_readEnable & 1) || (in.dbg2rv_writeEnable & 1)) {

		// Figure out which kind of register file the debug bus is accessing;
		// 0 = gbreg, 1 = gpreg, 2 or 3 = cxreg.
		int file = (in.dbg2rv_addr >> 8) & 3;
		if (file == 0) {

			// Global control register access.
			st.cregIface.gbreg_dbgAddress = in.dbg2rv_addr & 0xFF;
			if (in.dbg2rv_writeEnable & 1) {
				st.cregIface.gbreg_dbgWriteMask = in.dbg2rv_writeMask;
				st.cregIface.gbreg_dbgWriteData = in.dbg2rv_writeData;
			}
			dbgBusAccess = -2;

		} else {

			// Figure out the context which the debug bus is accessing.
			int ctxt = in.dbg2rv_addr >> 10;
			ctxt &= (1 << generics.CFG.numContextsLog2) - 1;

			if (file == 1) {

				// General purpose register access.
				int offs = (in.dbg2rv_addr & 0xFF) >> 2;
				out.rv2dbg_readData = st.cx[ctxt].gpreg[offs];
				if (in.dbg2rv_writeEnable & 1) {
					if ((in.dbg2rv_writeMask & 0xF) == 0xF) {
						st.cx[ctxt].gpreg[offs] = in.dbg2rv_writeData;
					}
				}

			} else {

				// Context control register access.
				st.cx[ctxt].cregIface.cxreg_address = in.dbg2rv_addr & 0x1FF;
				st.cx[ctxt].cregIface.cxreg_origin = 1;
				if (in.dbg2rv_writeEnable & 1) {
					st.cx[ctxt].cregIface.cxreg_writeMask = in.dbg2rv_writeMask;
					st.cx[ctxt].cregIface.cxreg_writeData = in.dbg2rv_writeData;
				}
				dbgBusAccess = ctxt;

			}
		}
	}


    // Simulate the actual control register logic. This is generated from the
    // core configuration files.
    simulateControlRegLogic();

    // Handle the read side of debug bus accesses, and reset the request here as
    // well. Then we don't have to reset it every time.
    if (dbgBusAccess == -2) {

    	// Forward the result.
    	out.rv2dbg_readData = st.cregIface.gbreg_dbgReadData;

    	// Reset the request.
		st.cregIface.gbreg_dbgAddress = -1;
		st.cregIface.gbreg_dbgWriteMask = 0;

    } else if (dbgBusAccess >= 0) {

    	// Forward the result.
    	out.rv2dbg_readData = st.cx[dbgBusAccess].cregIface.cxreg_readData;

    	// Reset the request.
		st.cx[dbgBusAccess].cregIface.cxreg_address = -1;
		st.cx[dbgBusAccess].cregIface.cxreg_origin = 0;
		st.cx[dbgBusAccess].cregIface.cxreg_writeMask = 0;

    }

}

/**
 * Returns the output signal structure.
 */
const coreInterfaceOut_t *Core::getOut() const {
	// FYI: the modelsim interface code assumes that this address never changes.
	return &out;
}

} /* namespace Core */
