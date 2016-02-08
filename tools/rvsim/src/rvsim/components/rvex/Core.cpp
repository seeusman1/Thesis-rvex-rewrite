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

#include "../rvex/Core.h"

#include <cstring>
#include <cstdio>
#include <cstdlib>

using namespace std;

// HINT: if your editor supports code folding, fold the namespace Core {}
// blocks which you don't want to see.

//==============================================================================
// Syllable execution function.
//==============================================================================
namespace Core {

/**
 * This function is the kernel which handles syllable execution simulation. It
 * simulates a lot of the VHDL code from core_pipelane.vhd, as well as all the
 * functional units. This function is encapsulated by generated functions which
 * provide it with a constant value for o, so any branches based on values in o
 * are optimized away. This should result in, for instance, the ALU result not
 * being computed if it is never used by a certain syllable.
 */
static inline __attribute__((always_inline)) void simSyl(
		laneState_t *s,
		const contextState_t *c,
		const int st,
		const opcodeTableEntry_t o
) {
	// [OPMUX], ALU, MUL, MEM, BRK -> uses inputs, generates outputs & traps

}

/**
 * Function pointer for an encapsulated simSyl function.
 */
typedef void (*simSylFunPtr_t)(
		laneState_t *s,
		const contextState_t *c,
		const int st);

} /* namespace Core */


//==============================================================================
// Context execution function.
//==============================================================================
namespace Core {

/**
 * This function is the kernel which handles context simulation. It simulates
 * pretty much everything aside from the register files, reconfiguration and
 * what's done centrally in Core::simulateContext(). This is encapsulated and
 * inlined by generated functions for which stage is constant, so branches based
 * on stage are free.
 */
static inline __attribute__((always_inline)) void simCtxt(
		const cfgVect_t *CFG,
		const coreInterfaceIn_t *in,
		coreInterfaceOut_t *out,
		coreState_t *cost,
		const int ctxt,
		contextState_t *cst,
		const int stage
) {
	const int NUM_LANES = 1 << CFG->numLanesLog2;
	const int NUM_GROUPS = 1 << CFG->numLaneGroupsLog2;
	const int NUM_CONTEXTS = 1 << CFG->numContextsLog2;

	// Initialize all signals which aren't undefined.
	if (stage == L_IF) {
		for (int l = 0; l < (int)cst->rcfg.laneCount; l++) {
			int lane = l + cst->rcfg.firstLaneIdx;
			laneState_t *lst = l + cst->rcfg.firstLane;
			sylState_t *ss = lst->s[stage];
			ss->valid = 0;
			ss->limmValid = 0;
			ss->brkValid = 0;
			ss->gpRegWriteRequested = 0;
			ss->brRegWriteRequested = 0;
			ss->linkRegWriteRequested = 0;
			ss->invalidDueToStop = 0;
			ss->idle = 1;
		    ss->dp.resValid = 0;
			ss->dp.resLinkValid = 0;
			ss->dp.resBrValid = 0;
			ss->br.trapPending = 0;
			ss->tr.trap.active = 0;
			ss->tr.debugTrap.active = 0;
			ss->trace.stop = 0;
			ss->trace.instr_enable = 0;
		}
	}

	//--------------------------------------------------------------------------
	// VHDL: "Handle instruction fetch result and instruction validity signals"
	//--------------------------------------------------------------------------
	for (int l = 0; l < (int)cst->rcfg.laneCount; l++) {
		int lane = l + cst->rcfg.firstLaneIdx;
		laneState_t *lst = l + cst->rcfg.firstLane;
		sylState_t *ss = lst->s[stage];

		// VHDL: "Copy the signals broadcast by the active branch unit into the
		// pipeline." These signals come from cxplif. We must thus also simulate
		// cxplif here.
		if (stage == S_IF) {
			ss->PC        = cst->branch.br2cxplif_PC;
			ss->valid     = cst->branch.br2cxplif_valid;
			ss->limmValid = cst->branch.br2cxplif_limmValid;
			ss->brkValid  = cst->branch.br2cxplif_brkValid
					&& !(cst->cregIface.cxreg2cxplif_resuming & 1);

			// cxplif invalidates lanes which come before the current program
			// counter. This handles the weird cases where the program counter
			// is not properly aligned to a bundle boundary due to returning
			// from a trap which occurred in a more narrow configuration than
			// the current configuration.
			int pcIndex = ss->PC >> 2;
			pcIndex &= (1 << CFG->bundleAlignLog2) - 1;
			pcIndex &= cst->rcfg.laneCount - 1;
			int laneIdx = lane - cst->rcfg.firstLaneIdx;
			if (laneIdx < pcIndex) {
				ss->valid = 0;
			}
		}

		// VHDL: "Copy the instruction fetch result into the pipeline." These
		// signals come from the instruction buffer. We must thus also simulate
		// ibuf here.
		if (stage == S_IF + L_IF) {

			// Get the syllable.
			int shift = 0;
			if (CFG->bundleAlignLog2 < CFG->numLanesLog2) {

				// Determine the number of instructions to shift by. For
				// example, if the PC is two syllables after the cache alignment
				// point, shift will be 2.
				shift = ss->PC;
				shift >>= 2;
				shift &= NUM_LANES - 1;
				shift &= ~((1 << CFG->bundleAlignLog2) - 1);

			}

			// If shift is nonzero, we need to take the right syllables from
			// the instruction buffers and the incoming instructions. If can
			// be thought of as indexing into the concatenation of all the
			// instruction buffers and all the
			if (shift) {

				int fromLane = l - cst->rcfg.laneCount + shift;
				if (fromLane < 0) {

					// From an instruction buffer.
					fromLane += cst->rcfg.laneCount;
					ss->syllable = cst->rcfg.firstLane[fromLane].insnBuf;

				} else {

					// From the memory.
					fromLane += cst->rcfg.firstLaneIdx;
					ss->syllable = in->imem2rv_instr[fromLane];

				}

			} else {

				// No instruction buffer shift needed.
				ss->syllable = in->imem2rv_instr[lane];

			}

			// Handle the instruction fetch trap.
			if ((ss->valid) && (!ss->tr.trap.active)) {
				if (in->imem2rv_busFault[lane] & 1) {
					ss->tr.trap.active = 1;
					ss->tr.trap.cause = TRAP_FETCH_FAULT;
					ss->tr.trap.arg = 0;
				}
			}

		}

		// VHDL: "Copy the instruction fetch data into the trace record as well,
		// before it is maybe modified further on in the pipeline."
		if (stage == S_IF) {
			ss->trace.instr_enable = ss->limmValid;
		}
		if (stage == S_IF + L_IF) {
			ss->trace.instr_syllable = in->imem2rv_instr[lane];
		}

		// VHDL: "Copy instruction cache performance data into the trace
		// records."
		if (stage == S_IF + L_IF) {
			int laneGroup = lane >> (CFG->numLanesLog2 - CFG->numLaneGroupsLog2);
			ss->trace.cache_status.instr_access =
					in->mem2rv_cacheStatus[laneGroup].instr_access;
			ss->trace.cache_status.instr_miss =
					in->mem2rv_cacheStatus[laneGroup].instr_miss;
		}

	}

    //--------------------------------------------------------------------------
    // VHDL: "Compute PC+1 related signals"
    //--------------------------------------------------------------------------
	// Nothing needs to be done here. We do all PC+1 stuff in the next section
	// along with the stop bits.

    //--------------------------------------------------------------------------
    // VHDL: "Handle stop bits and move the branch syllable to the last lane"
    //--------------------------------------------------------------------------
	// We simulate the stop bit logic behaviorally here.
	if (stage == S_STOP) {
		if (CFG->genBundleSizeLog2 != CFG->bundleAlignLog2) {

			// Whether we've encountered a stop bit yet.
			int stopFound = 0;

			// Whether the syllable with the stop bit set is a branch syllable
			// and if it is, the syllable.
			int branchSylFound = 0;
			uint32_t branchSyl;

			cst->branch.bundleSize = 0;
			for (int l = 0; l < (int)cst->rcfg.laneCount; l++) {
				laneState_t *lst = l + cst->rcfg.firstLane;
				sylState_t *ss = lst->s[stage];

				if (!stopFound) {
					int stop = (ss->syllable & 2) && lst->HAS_STOP;
					if (stop) {

						// Last instruction (stop bit set).
						int brinst = OPCODE_TABLE[ss->syllable >> 24]
										  .branchCtrl.isBranchInstruction;
						if (brinst) {

							// Last instruction = branch instruction.
							stopFound = 1;

							// Move the syllable to the last lane.
							branchSylFound = ss->valid;
							branchSyl = ss->syllable;
							ss->invalidDueToStop = ss->valid;
							ss->limmValid = 0;
							ss->valid = 0;

						} else {

							// Last instruction != branch instruction.
							stopFound = 1;

						}
					}

					// Increment bundle size.
					cst->branch.bundleSize += 4;

				} else if (branchSylFound && (l == (int)cst->rcfg.laneCount-1)){

					// Branch syllable was found, and this is the last lane.
					ss->syllable = branchSyl;
					ss->valid = 1;

				} else {

					// Instruction after the stop bit.
					ss->invalidDueToStop = ss->valid;
					ss->limmValid = 0;
					ss->valid = 0;

				}

			}

		} else {

			// Stop bits not enabled. Bundle size (PC add value) is always the
			// full issue width.
			cst->branch.bundleSize = cst->rcfg.laneCount * 4;

		}

	}
}

/**
 * Function pointer for an encapsulated simCtxt function.
 */
typedef void (*simCtxtFunPtr_t)(
		const cfgVect_t *CFG,
		const coreInterfaceIn_t *in,
		coreInterfaceOut_t *out,
		coreState_t *cost,
		const int ctxt,
		contextState_t *cst,
		const int lane,
		laneState_t *lst);

} /* namespace Core */

//==============================================================================
// Generated stuff.
//==============================================================================
namespace Core {

/**
 * Include generated code. We want this to be in the same compilation unit as
 * the non-generated code, so gcc can better perform optimizations.
 */
#include "../rvex/Generated.cpp.inc"

} /* namespace Core */

//==============================================================================
// Register and forwarding logic class.
//==============================================================================
namespace Core {

/**
 * Creates/destroys a new forwarding controller.
 * NOTE: NONE OF THE FUCNTIONS IN THIS CLASS ARE ALLOWED TO USE DYNAMIC
 * MEMORY ALLOCATION, AS THE MODELSIM INTERFACE REQUIRES THE USAGE OF
 * SPECIALIZED, GARBAGE COLLECTED MEMORY ALLOCATION FUNCTIONS. THIS ALSO
 * MEANS THAT THE DESTRUCTOR IS NOT NECESSARILY CALLED, AND MUST THUS BE
 * NO-OP.
 */
void RegistersAndForwarding::init(CtrlRegInterfacePerCtxt_t *cregIface,
		const cfgVect_t *CFG)
{

	// Set pointers to the context data and configuration.
	this->cregIface = cregIface;
	this->CFG = CFG;

	// Initialize the general purpose register file to zero.
	for (int i = 0; i < 64; i++) gpreg[i] = 0;
#if SIM_GPREG_2CYCLE_LATENCY
	gpregBufValid = 0;
#endif

	// Run a reset to initialize the forwarding stuff.
	reset();

}

#if SIM_GPREG_2CYCLE_LATENCY
/**
 * The general purpose register file has a cycle delay on the FPGA. This
 * function commits pending writes to the register file.
 */
void RegistersAndForwarding::updateGpRegDelay() {
	int i = 0;
	while (gpregBufValid) {
		if (gpregBufValid & 1) {
			gpreg[i] = gpregBuf[i];
		}
		gpregBufValid >>= 1;
		i++;
	}
}
#endif

/**
 * Resets the forwarding logic. Must be called in every clock cycle where
 * reset is asserted, instead of afterRead(), afterReadStalled() and
 * afterWrite().
 */
void RegistersAndForwarding::reset() {

	// Disable the write enable stuff for all forwarding stages.
	for (int i = 0; i < S_LAST_POW2; i++) {
		stages[i].v[0] = 0;
		stages[i].v[1] = 0;
	}

	// Invalidate the forwarding cache.
	cache.v[0] = 0;
	cache.v[1] = 0;

#if SIM_GPREG_2CYCLE_LATENCY
	// Update the general purpose register file delay model.
	updateGpRegDelay();
#endif

}

/**
 * Prepares the debug bus read value for the general purpose registers. This
 * just copies the specified register into debugBusRegBuffer. This is needed
 * to properly model the latency of the general purpose register file RAM
 * blocks, as the control registers are simulated after the pipeline, which
 * is the next cycle as far as this class is concerned.
 */
void RegistersAndForwarding::prepDbgBusGetGpReg(registerId_t reg) {
	debugBusGpRegBuffer = gpreg[reg];
}

/**
 * Returns the value of a register, taking forwarding etc. into account.
 * This also handles the reg63isLink generic and makes sure REG_GP0 always
 * returns 0.
 */
uint32_t RegistersAndForwarding::getReg(int stage, registerId_t reg) {

	// Compute valid bit index and mask for this register number.
	uint64_t vi = reg > 64;
	uint64_t vm = 1ull << (reg & 63);

#if SIM_CACHE_FORWARDING
	// Handle cache hits.
	if (cache.v[vi] & vm) {
		return cache.r[reg];
	}
#else
	// We can't cache if the forwarding system has multiple outputs (or rather,
	// that's not supported right now.
#warning "S_RD+L_RD != S_FW or S_SRD != S_SFW, i.e. there's multiple forwarding outputs. Simulation speed may be impaired."
#endif

	// Cache miss.
	uint32_t val;

	// Check for special registers.
	if (reg == RVREG_GP0) {
		val = 0;
	} else if (CFG->reg63isLink && reg == RVREG_GP63) {
		val = getReg(stage, RVREG_LINK);
	} else if (reg <= RVREG_GP63) {

		// Load the register from the general purpose registers.
		val = gpreg[reg];

		// Handle general purpose register forwarding if it's enabled.
		if (CFG->forwarding & 1) {
			for (int s = S_WB+L_WB; s > stage; s--) {
				fwdState_t *stage = &(stages[(offset + s) & (S_LAST_POW2-1)]);
				if (stage->v[vi] & vm) {
					val = stage->r[reg];
				}
			}
		}

	} else {

		// Special register. Load from context control register file.
		if (reg == RVREG_LINK) {
			val = cregIface->cxreg2cxplif_linkReadData;
		} else {
			val = cregIface->cxreg2cxplif_brReadData;
			val >>= reg - RVREG_BR0;
			val &= 1;
		}

		// Handle special register forwarding if it's enabled.
		if (CFG->forwarding & 1) {
			for (int s = S_WB+L_WB; s > stage; s--) {
				fwdState_t *stage = &(stages[(offset + s) & (S_LAST_POW2-1)]);
				if (stage->v[vi] & vm) {
					val = stage->r[reg];
				}
			}
		}

	}

#if SIM_CACHE_FORWARDING
	// Update the cache.
	cache.r[reg] = val;
	cache.v[vi] |= vm;
#endif

	// Return the value.
	return val;

}

/**
 * Must be called in every unstalled clock cycle after all reads.
 */
void RegistersAndForwarding::afterRead() {

#if SIM_GPREG_2CYCLE_LATENCY
	// Update the general purpose register file delay model.
	updateGpRegDelay();
#endif

	// Reset the write enable signals for the special control registers.
	cregIface->cxplif2cxreg_brWriteEnable = 0;
	cregIface->cxplif2cxreg_brWriteData = 0;
	cregIface->cxplif2cxreg_linkWriteEnable = 0;

}

/**
 * Must be called in every stalled clock cycle after all reads.
 */
void RegistersAndForwarding::afterReadStalled() {
#if SIM_GPREG_2CYCLE_LATENCY

	// Update the general purpose register file delay model.
	updateGpRegDelay();

#endif
}

/**
 * Supplies a new register value to the forwarding logic.
 */
void RegistersAndForwarding::fwdReg(int stage, registerId_t reg,
		uint32_t value)
{
	if (CFG->forwarding & 1) {

		// Compute valid bit index and mask for this register number.
		uint64_t vi = reg > 64;
		uint64_t vm = 1ull << (reg & 63);

#if SIM_CACHE_FORWARDING
		// Update the cache. Don't validate it if it was invalid though, there
		// may be a write in an earlier stage which needs to override this one.
		// We'll figure all that out during the next read.
		cache.r[reg] = value;
#endif

		// Update the writes made to this stage.
		fwdState_t *stage_ = &(stages[(offset + stage) & (S_LAST_POW2-1)]);
		stage_->r[reg] = value;
		stage_->v[vi] |= vm;

	}
}

/**
 * Invalidates a pipeline stage, removing all values which it supplied to
 * the forwarding system.
 */
void RegistersAndForwarding::invalidate(int stage) {
	fwdState_t *stage_ = &(stages[(offset + stage) & (S_LAST_POW2-1)]);

#if SIM_CACHE_FORWARDING
	// Invalidate the cache for the registers which were written by this stage.
	cache.v[0] &= ~stage_->v[0];
	cache.v[1] &= ~stage_->v[1];
#endif

	// Disable the writes from this stage.
	stage_->v[0] = 0;
	stage_->v[1] = 0;

}

/**
 * Must be called in every unstalled clock cycle after all reads and fwdReg
 * calls.
 */
void RegistersAndForwarding::afterFwdAndInval() {

	// Shift the stages array offset to make it seem like each instruction stays
	// in the same array index.
	offset--;

}

/**
 * Commits a register to the register file. This must be called even if
 * fwdReg has already been called.
 */
void RegistersAndForwarding::commitReg(registerId_t reg, uint32_t value) {
	if (reg <= (CFG->reg63isLink ? RVREG_GP62 : RVREG_GP63)) {

		// General purpose register.
#if SIM_GPREG_2CYCLE_LATENCY
		gpregBuf[reg] = value;
		gpregBufValid |= 1 << reg;
#else
		gpreg[reg] = value;
#endif

	} else if ((reg >= RVREG_BR0) && (reg <= RVREG_BR7)) {

		// Branch register. Note that these are wired-or if there are multiple
		// writes in the same cycle, just like the core is (see cxplif). Note
		// that the hardware branch forwarding logic does NOT seem to have this
		// behavior (or I missed it), so that's actually bugged a little bit.
		// Oh well. It might be worth making all of it wired-or to get rid of
		// a bunch of priority encoder levels though; might save logic (levels).
		int m = 1 << (reg - RVREG_BR0);
		if (value) {
			cregIface->cxplif2cxreg_brWriteData |= m;
		}
		cregIface->cxplif2cxreg_brWriteEnable |= m;

	} else {

		// Link register.
		cregIface->cxplif2cxreg_linkWriteData = value;
		cregIface->cxplif2cxreg_linkWriteEnable = 1;

	}

}

} /* namespace Core */

//==============================================================================
// Core simulator class: public methods.
//==============================================================================
namespace Core {

/**
 * Creates a new core with the specified generic configuration.
 * NOTE: NONE OF THE FUCNTIONS IN THIS CLASS ARE ALLOWED TO USE DYNAMIC
 * MEMORY ALLOCATION, AS THE MODELSIM INTERFACE REQUIRES THE USAGE OF
 * SPECIALIZED, GARBAGE COLLECTED MEMORY ALLOCATION FUNCTIONS. THIS ALSO
 * MEANS THAT THE DESTRUCTOR IS NOT NECESSARILY CALLED, AND MUST THUS BE
 * NO-OP.
 */
Core::Core(const coreInterfaceGenerics_t *generics, printfFuncPtr_t printf) :
			NUM_LANES(1 << generics->CFG.numLanesLog2),
			NUM_GROUPS(1 << generics->CFG.numLaneGroupsLog2),
			NUM_CONTEXTS(1 << generics->CFG.numContextsLog2),
			printf(printf),
			generics(*generics)
{
	memset(&st, 0, sizeof(st));
	memset(&in, 0, sizeof(in));
	memset(&out, 0, sizeof(out));
	st.cregIface.rv2gbreg_coreID = generics->CORE_ID;
	st.cregIface.rv2gbreg_platformTag = generics->PLATFORM_TAG;
	for (int ctxt = 0; ctxt < NUM_CONTEXTS; ctxt++) {
		st.cx[ctxt].regFwd.init(&(st.cx[ctxt].cregIface), &(generics->CFG));
	}
	commitConfiguration(0);

	// Determine the capabilities of each lane (see also core_pipelanes.vhd).
	int lanesPerGroup = NUM_LANES / NUM_GROUPS;
	for (int lane = 0; lane < NUM_LANES; lane++) {
		int laneIndexRev = lanesPerGroup - (lane % lanesPerGroup) - 1;
		st.lane[lane].HAS_MUL = !!(generics->CFG.multiplierLanes & (1 << lane));
		st.lane[lane].HAS_MEM = laneIndexRev == generics->CFG.memLaneRevIndex;
		st.lane[lane].HAS_BRK = st.lane[lane].HAS_MEM;
		st.lane[lane].HAS_BR = laneIndexRev == 0;
		st.lane[lane].HAS_STOP = st.lane[lane].HAS_BR ||
				(lane+1) % (1 << generics->CFG.bundleAlignLog2) == 0;
	}
}

/**
 * Generates the stall output signal, which is combinatorial based on the
 * stall input and the debug bus. Returns the output signal structure.
 */
const coreInterfaceOut_t *Core::stallOut(void) throw(GenericsException) {

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

	// Determine the basic system control signals.
	st.reset = (in.reset | st.cregIface.gbreg2rv_reset) & 1;
	st.clkEn = in.clkEn & 1;
	st.cxStall = 0;
	for (int lg = 0; lg < NUM_GROUPS; lg++) {
		int ctxt = (st.rcfgState.currentCfg >> (lg*4)) & 0xF;
		if (!(ctxt & 8)) {
			if (out.rv2mem_stallOut[lg] & 1) {
				st.cxStall |= 1 << ctxt;
			}
		}
	}
	for (int lg = 0; lg < NUM_GROUPS; lg++) {
		int ctxt = (st.rcfgState.currentCfg >> (lg*4)) & 0xF;
		if (!(ctxt & 8)) {
			if (out.rv2mem_stallOut[lg] & 1) {
				if (!(st.cxStall & (1 << ctxt))) {
					throw GenericsException("The stall signals for some "
							"coupled lane groups are not equal. This is very "
							"bad. There's no point in simulating further, and "
							"even if there were, the C model does not support "
							"it.");
				}
			}
		}
	}

	// Only operate if clkEn is high or if we're resetting.
	if (st.reset || st.clkEn) {

		// Get the gpreg read value for the debug bus before we clock the
		// register and forwarding logic.
		if (in.dbg2rv_readEnable & 1) {
			int ctxt = in.dbg2rv_addr >> 10;
			ctxt &= (1 << generics.CFG.numContextsLog2) - 1;
			registerId_t reg = (registerId_t)((in.dbg2rv_addr & 0xFF) >> 2);
			st.cx[ctxt].regFwd.prepDbgBusGetGpReg(reg);
		}

		// SIMULATE THE CONTEXTS UP TO THE REGISTER BOUNDARY.
		for (int ctxt = 0; ctxt < NUM_CONTEXTS; ctxt++) {
			contextState_t *cst = &(st.cx[ctxt]);
			if (st.reset) {

				// Context reset.
				cst->regFwd.reset();

			} else if (st.cxStall & (1 << ctxt)) {

				// Context stalled.
				cst->regFwd.afterReadStalled();

			} else {

				// Context normal.
				simulateContext(ctxt, cst);

			}
		}

		/* A WILD NOTE APPEARS
		 *
		 * *** IBUF RESULT ***
		 * per group:
		 *
		 *   # Handle traps.
		 *   if in.imem2rv_busFault:
		 *     cause TRAP_FETCH_FAULT (arg = 0) in S_IF+1
		 *
		 *   # Handle instruction muxing.
		 *   instr = mux(ibuf.buffer
		 *
		 *
		 * *** IBUF SETUP ***
		 * per group:
		 *   inputs from branch unit: PC, branching, fetch, cancel
		 *
		 *   # Drive the memory outputs.
		 *   if branching:
		 *     fetchPC = floor(PC)
		 *   else:
		 *     fetchPC = ceil(PC)
		 *   out.rv2imem_PCs = fetchPC
		 *   out.rv2imem_cancel = cancel
		 *   out.rv2imem_fetch = fetch
		 *
		 *   # Load the instruction buffer when the PC bit at the buffer size
		 *   # position changes.
		 *   PC_LSB = PC(2 + num coupled lanes)
		 *   if PC_LSB != ibuf.prevPC_LSB:
		 *     ibuf.buffer = in.imem2rv_instr
		 *   ibuf.PC_LSB_r = PC_LSB
		 *
		 *   # Figure out which mux positions should be used in the next cycle.
		 *   ibuf.mux = mux magic
		 *
		 *
		 */


		// IF result, STOP, DEC, LIMM -> uses inputs, generates traps
		// RD, SRD -> uses regFwd.read
		// TRAP result, PCP1, BTGT, BR, IF setup -> generates outputs & traps
		// simsyl
		// (STRAP)
		// [TRAP setup]
		// (RFI)
		// WB, SWB -> uses regFwd.write/fwd
		// [DIAG]



		// SIMULATE THE RECONFIGURATION CONTROLLER. This uses only registered
		// signals from the control registers and combinatorial signals from the
		// pipelanes and inputs. Its outputs are all registered, except for the
		// wakeupAck sigal to the control registers. This means we must simulate
		// the control registers after the reconfiguration control, and thus
		// also that the registered signals from the reconfiguration controller
		// to the control registers must actually be delayed.
		simulateReconfigurationCtrl();

		// SIMULATE THE CONTROL REGISTERS. This uses combinatorial signals from
		// other blocks and inputs exclusively, and only has registered outputs.
		// Therefore, this is the last thing we do before the clock edge, so we
		// don't need to copy the old outputs for use by later blocks before the
		// clock cycle.
		simulateControlRegs();

		// CLOCK EDGE IS HERE. At this point, all units will have set up their
		// register outputs. From here onwards, those can be used to generate
		// combinatorial outputs to the outside world.


	}

	return &out;
}

/**
 * Returns the output signal structure.
 */
const coreInterfaceOut_t *Core::getOut() const {
	// FYI: the modelsim interface code assumes that this address never changes.
	return &out;
}

}

//==============================================================================
// Core simulator class: contexts.
//==============================================================================
namespace Core {

#if (L_IF != 1) || (L_IF_MEM != 1)
#error "L_IF and L_IF_MEM must be one."
#endif

void Core::simulateContext(int ctxt, contextState_t *cst) {

	// Set up the lookup table from stage to state.
	for (int l = 0; l < (int)cst->rcfg.laneCount; l++) {
		laneState_t *lst = cst->rcfg.firstLane + l;
		for (int i = S_FIRST; i <= S_LAST; i++) {
			lst->s[i] = lst->sbuf + ((lst->soffs + i) & (S_LAST_POW2-1));
		}
	}

	// Simulate the contexts. Later stages are processed first, because
	// forwarding stuff from traps and the branch unit may move combinatorially
	// from later stages to earlier stages, but not the other way around.
	// Commits to the register files and forwarding logic are not processed yet.
	for (int stage = S_LAST; stage >= S_FIRST; stage--) {
		// TODO: generate per stage and lookup.
		simCtxt(&(generics.CFG), &in, &out, &st, ctxt, cst, stage);
	}
	cst->regFwd.afterRead();

	// Commit to the register files and forwarding logic.
	// TODO

	// Update the forwarding logic.
	cst->regFwd.afterFwdAndInval();

	// Move every instruction in the pipeline to the next stage by
	// decrementing the stage offset.
	for (int l = 0; l < (int)cst->rcfg.laneCount; l++) {
		laneState_t *lst = cst->rcfg.firstLane + l;
		lst->soffs--;
	}

}

}

//==============================================================================
// Core simulator class: reconfiguration.
//==============================================================================
namespace Core {

/**
 * Simulates the reconfiguration controller.
 */
void Core::simulateReconfigurationCtrl() {

	printfFuncPtr_t debug = printf;

	// Update the registered signals from the reconfiguration controller to the
	// control registers using the values from the previous cycle.
	st.cregIface.cfg2gbreg_currentCfg = st.rcfgState.currentCfg;
	st.cregIface.cfg2gbreg_busy = st.rcfgState.busy;
	st.cregIface.cfg2gbreg_error = st.rcfgState.error;
	st.cregIface.cfg2gbreg_requesterID = st.rcfgState.requesterID;
	st.cregIface.cfg2cxreg_currentConfig = st.rcfgState.currentCfg;

	// Handle resets.
	if (st.reset) {
		st.rcfgState.currentCfg = 0;
		st.rcfgState.error = 0;
		st.rcfgState.requesterID = 0xF;
		st.rcfgState.busy = 0;
		commitConfiguration(0);
		return;
	}

	// Handle reconfigurations that are already in progress.
	if (st.rcfgState.busy) {

		// Handle wakeup system: there is never a wakeup while there is already
		// a reconfiguation in progress.
		st.cregIface.cfg2cxreg_wakeupAck = 0;

		// Simulate erroneous reconfiguration request timing.
		if (!st.rcfgState.newCfgValid) {
			st.rcfgState.busy--;
			if (!st.rcfgState.busy) {
				if (debug) debug("Concluding reconfiguration: error\n");
				st.rcfgState.error = 1;
			} else {
				if (debug) debug("Reconfiguring...\n");
			}
			return;
		}

		// Check whether contexts are blocking reconfiguration. If they are,
		// don't do anything and return.
		if (st.rcfgState.busy == SIM_RECONFIG_COMMIT_LATENCY) {
			for (int ctxt = 0; ctxt < NUM_CONTEXTS; ctxt++) {
				if (st.rcfgState.affectedContexts & (1 << ctxt)) {

					// The lane groups not being idle blocks reconfiguration.
					// The blockReconfig signal is driven to not idle in cxplif.
					if (!(out.rv2rctrl_idle[ctxt] & 1)) {
						if (debug) debug("Reconfiguring: waiting for context "
								"%d.\n", ctxt);
						return;
					}

					// Check if the memory system is blocking reconfiguration in
					// the same way the core does: only the last lane group
					// input is checked.
					if (st.cx[ctxt].rcfg.laneCount) {
						uint8_t group = st.cx[ctxt].rcfg.lastGroup;
						if (in.mem2rv_blockReconfig[group] & 1) {
							if (debug) debug("Reconfiguring: waiting for "
									"memory block %d mapped to context %d.\n",
									group, ctxt);
							return;
						}
					}

				}
			}
		}

		// Wait while reconfiguration is in progress.
		st.rcfgState.busy--;
		switch (st.rcfgState.busy) {

		// When we're passed the decoding stage of the reconfiguration process,
		// assert the relevant requestReconfig signals.
		case SIM_RECONFIG_COMMIT_LATENCY:
			for (int ctxt = 0; ctxt < NUM_CONTEXTS; ctxt++) {
				if (st.rcfgState.affectedContexts & (1 << ctxt)) {
					st.cx[ctxt].rcfg.requestReconfig = 1;
				}
			}
			break;

		// Handle reconfiguration completion.
		case 0:
			commitConfiguration(st.rcfgState.newCfg);
			if (debug) debug("Concluding reconfiguration: new config 0x%08X\n",
					st.rcfgState.newCfg);
			return;
		}

		if (debug) debug("Reconfiguring...\n");
		return;
	}

	// Handle wakeup system. Wake up if the wakeup system is enabled, context 0
	// has a pending interrupt, context 0 is not currently active, and there is
	// not already a reconfiguration in progress.
	int wakeup = 0;
	if (!st.cx[0].rcfg.laneCount) {
		wakeup = st.cregIface.cxreg2cfg_wakeupEnable & in.rctrl2rv_irq[0] & 1;
	}
	st.cregIface.cfg2cxreg_wakeupAck = wakeup;

	// Arbitrate among the requests.
	int rid = -1;
	uint32_t cfg;
	if (wakeup) {

		// Sleep system requesting reconfiguration to wake up.
		rid = 0x8;
		cfg = st.cregIface.cxreg2cfg_wakeupConfig;

	} else {
		for (int ctxt = 0; ctxt < NUM_CONTEXTS; ctxt++) {
			if (st.cx[ctxt].cregIface.cxreg2cfg_requestEnable & 1) {

				// Context requesting reconfiguration.
				rid = ctxt;
				cfg = st.cx[ctxt].cregIface.cxreg2cfg_requestData;
				break;
			}
		}
		if (rid == -1 && (st.cregIface.gbreg2cfg_requestEnable & 1)) {

			// Debug bus requesting reconfiguration.
			rid = 0xF;
			cfg = st.cregIface.gbreg2cfg_requestData;

		}
	}

	// If no request, we're done.
	if (rid == -1) {
		return;
	}

	// Acknowledge the reconfiguration request.
	st.rcfgState.requesterID = rid;
	st.rcfgState.newCfg = cfg;
	if (debug) debug("Accepted reconfiguration to 0x%08X from source 0x%X.\n",
			cfg, rid);

	// If the request has reserved bits set, we should immediately set the
	// error flag. Note that the generation of the mask is done by the
	// determineConfigMask function in the VHDL source during static
	// elaboration (its result is put in CONFIGURATION_MASK).
	uint32_t mask = 0;
	for (int lg = 0; lg < NUM_GROUPS; lg++) {
		mask |= 1 << ((lg*4) + 3); // Run bit.
		mask |= (NUM_CONTEXTS-1) << (lg*4); // Context selection bits.
	}
	if (cfg & ~mask) {
		if (debug) debug("Reconfiguring request error.\n");
		st.rcfgState.error = 1;
		return;
	}

	// Check for misaligned/noncontiguous contexts in the word. At the same
	// time, deduce how many cycles the hardware would need to decode the word
	// or find the first error, and figure out which contexts are affected by
	// the reconfiguration.
	int complexity = 0;
	int error = 0;
	for (int lg = NUM_GROUPS-1; lg >= 0;) {

		// Each loop iteration here represents one cycle's worth of decoding in
		// hardware.
		complexity++;

		// Handle disabled lane groups.
		int ctxt = cfg >> (lg*4);
		if (ctxt & 0x8) {
			lg--;
			continue;
		}
		ctxt &= NUM_CONTEXTS-1;

		// Find the number of lane groups associated with this context and check
		// alignment and contiguity.
		int numlg = 1;
		int contig = 1;
		for (int lg2 = lg-1; lg2 >= 0; lg2--) {
			int ctxt2 = cfg >> (lg2*4);
			ctxt2 &= NUM_CONTEXTS-1;
			if (ctxt2 != ctxt) {

				// Found a lane group mapped to a different context.
				contig = 0;

			} else if (contig) {

				// Found a contiguous lane group mapped to this context.
				numlg++;

			} else {

				// Found a noncontiguous lane group mapped to this context,
				// which is an error.
				error = 1;
				if (debug) debug("Requested configuration is not contiguous "
						"for context %d.\n", ctxt);
				break;

			}
		}
		if (error) {
			break;
		} else {

			// The number of lane groups must be a power of two.
			int i = numlg;
			while (i > 1) {
				if (i & 1) {
					error = 1;
					if (debug) debug("Requested configuration does not have a "
							"power of 2 number of lane groups mapped to "
							"context %d.\n", ctxt);
					break;
				}
				i >>= 1;
			};

			// The start position must be aligned by the number of lane groups.
			int start = lg - numlg + 1;
			if (start & (numlg - 1)) {
				if (debug) debug("Requested configuration is not aligned "
						"for context %d.\n", ctxt);
				error = 1;
			}

		}
		if (error) {
			break;
		}

		// Continue on to the next context.
		lg -= numlg;

	}

	// Starting a new configuration clears the error flag. So we need to do
	// this here regardless of whether we've already determined that the
	// configuration will be erroneous.
	st.rcfgState.error = 0;

	// Determine timing.
	if (error) {

		// New configuration is invalid. It would take the hardware
		// reconfiguration controller complexity cycles to figure that out.
		st.rcfgState.newCfgValid = 0;
		st.rcfgState.busy = complexity;

	} else {

		// New configuration is valid. The reconfiguration controller latency is
		// 2 + complexity cycles. The state in which the controller appears to
		// check whether the reconfiguration is blocked or not is
		st.rcfgState.newCfgValid = 1;
		st.rcfgState.busy = SIM_RECONFIG_COMMIT_LATENCY + complexity;

	}

}

/**
 * Commits a new configuration and cleans up after the reconfiguration
 * controller. st.cx[...].rcfg is completely written and validated. The
 * given configuration is assumed to be a valid configuration word.
 */
void Core::commitConfiguration(uint32_t cfg) {

	// Set the current configuration register.
	st.rcfgState.currentCfg = cfg;

	// Reset all the context to a defined state.
	for (int ctxt = 0; ctxt < NUM_CONTEXTS; ctxt++) {
		st.cx[ctxt].rcfg.laneCount = 0;
		st.cx[ctxt].rcfg.requestReconfig = 0;
	}

	// Load the context configuration and decouple output from the config
	// vector.
	int prevCtxt = -1;
	int lanesPerGroup = NUM_LANES / NUM_GROUPS;
	for (int lg = NUM_GROUPS-1; lg >= 0; lg--) {
		int ctxt = (cfg >> (lg*4)) & 0x8;
		if (ctxt & 8) ctxt = -1;

		// Generate decouple output.
		out.rv2mem_decouple[lg] = prevCtxt != ctxt || prevCtxt == -1;

		// Generate internal control values.
		if (ctxt >= 0) {
			st.cx[ctxt].rcfg.firstLane = st.lane + lanesPerGroup * lg;
			st.cx[ctxt].rcfg.firstLaneIdx = lanesPerGroup * lg;
			if (!st.cx[ctxt].rcfg.laneCount) {
				st.cx[ctxt].rcfg.lastGroup = lg;
			}
			st.cx[ctxt].rcfg.firstGroup = lg;
			st.cx[ctxt].rcfg.laneCount += lanesPerGroup;
		}
	}

}

}

//==============================================================================
// Core simulator class: control registers.
//==============================================================================
namespace Core {

/**
 * Simulates the control registers.
 */
void Core::simulateControlRegs() throw(GenericsException) {

	// Setup creg generated inputs for as far as they are not used directly
	// elsewhere in code.
	st.cregIface.imem2gbreg_affinity = in.imem2rv_affinity;
	for (int cx = 0; cx < NUM_CONTEXTS; cx++) {
		CtrlRegInterfacePerCtxt_t *cxr = &(st.cx[cx].cregIface);
		cxr->cxreg_reset = in.rctrl2rv_reset[cx] | cxr->cxreg2rv_reset;
		cxr->rctrl2cxreg_resetVect = in.rctrl2rv_resetVect[cx];
		if ((NUM_GROUPS != NUM_CONTEXTS) && (generics.CFG.cachePerfCountEnable)) {
			throw GenericsException("When the cache performance counters are "
					"enabled, the number of  lane groups must equal the number "
					"of contexts.");
		}
		cxr->mem2cxreg_cacheStatus = in.mem2rv_cacheStatus[cx];
	}

	// Temporary code: there's never any accesses from the cores.
	// TODO: this will have to be more intelligent
	for (int cx = 0; cx < NUM_CONTEXTS; cx++) {
		st.cx[cx].cregIface.cxreg_address = -1;
	}
	for (int lg = 0; lg < NUM_GROUPS; lg++) {
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
				out.rv2dbg_readData = st.cx[ctxt].regFwd.debugBusGpRegBuffer;
				if (in.dbg2rv_writeEnable & 1) {
					if ((in.dbg2rv_writeMask & 0xF) == 0xF) {
						int offs = (in.dbg2rv_addr & 0xFF) >> 2;
						st.cx[ctxt].regFwd.commitReg(
								(registerId_t)offs, in.dbg2rv_writeData);
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

	// Forward creg generated outputs for as far as they're not used directly.
	out.resetOut = st.cregIface.gbreg2rv_reset;
	for (int cx = 0; cx < NUM_CONTEXTS; cx++) {
		CtrlRegInterfacePerCtxt_t *cxr = &(st.cx[cx].cregIface);
		out.rv2rctrl_done[cx] = cxr->cxreg2rctrl_done;
	}

}


} /* namespace Core */
