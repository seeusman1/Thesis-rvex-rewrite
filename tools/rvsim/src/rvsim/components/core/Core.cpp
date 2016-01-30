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

using namespace std;

namespace Core {

/**
 * Creates a new core with the specified generic configuration.
 * NOTE: NONE OF THE FUCNTIONS IN THIS CLASS ARE ALLOWED TO USE DYNAMIC
 * MEMORY ALLOCATION, AS THE MODELSIM INTERFACE REQUIRES THE USAGE OF
 * SPECIALIZED, GARBAGE COLLECTED MEMORY ALLOCATION FUNCTIONS. THIS ALSO
 * MEANS THAT THE DESTRUCTOR IS NOT NECESSARILY CALLED, AND MUST THUS BE
 * NO-OP.
 */
Core::Core(const coreInterfaceGenerics_t *generics, printfFuncPtr_t printf)
	throw(GenericsException):
	printf(printf), generics(*generics)
{
}

/**
 * Generates the stall output signal, which is combinatorial based on the
 * stall input and the debug bus. Returns the output signal structure.
 */
const coreInterfaceOut_t *Core::stallOut(void) throw(GenericsException) {

	printf("Core::stallOut()\n");

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
				internalStall = 1;
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

	printf("Core::clock()\n");

	// Instruction buffer input.
	// TODO

	// Pipelanes.
	// TODO

	// Instruction buffer output.
	// TODO

	// Reconfiguration controller.
	// TODO

	// Control registers.
	// TODO

	return &out;
}

/**
 * Returns the output signal structure.
 */
const coreInterfaceOut_t *Core::getOut() const {
	// FYI: the modelsim interface code assumes that this address never changes.
	return &out;
}

} /* namespace Core */
